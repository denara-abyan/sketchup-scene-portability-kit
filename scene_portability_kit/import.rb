module ScenePortabilityKit
  module Import
    def self.select_import_file
      begin
        filepath = UI.openpanel("Select Scene JSON", "", "*.json")
        return if filepath.nil? || filepath.empty?

        ScenePortabilityKit.imported_data = JSON.parse(File.read(filepath))

        meta = {
          name:           ScenePortabilityKit.imported_data["name"]    || "Imported Scene",
          description:    ScenePortabilityKit.imported_data["description"] || "",
          has_camera:     ScenePortabilityKit.imported_data.key?("camera"),
          has_style_fog:  ScenePortabilityKit.imported_data.key?("style_fog"),
          has_shadows:    ScenePortabilityKit.imported_data.key?("shadow_info"),
          has_env:        ScenePortabilityKit.imported_data.key?("env_rendering") || ScenePortabilityKit.imported_data.key?("env_shadow"),
          has_section:    ScenePortabilityKit.imported_data.key?("active_section_planes"),
          has_hidden:     ScenePortabilityKit.imported_data.key?("top_level_hidden"),
          has_tags:       ScenePortabilityKit.imported_data.key?("visible_tags"),
          has_axes:       ScenePortabilityKit.imported_data.key?("axes"),
          has_viewport:   ScenePortabilityKit.imported_data.key?("viewport")
        }

        ScenePortabilityKit.dialog.execute_script("onImportFileLoaded(#{meta.to_json});")
      rescue => e
        ScenePortabilityKit.imported_data = nil
        UI.messagebox("Failed to load file:\n#{e.message}")
        puts e.backtrace
      end
    end

    def self.apply_import(scene_name,
        import_camera, import_style_fog, import_shadows,
        import_env, import_section, import_hidden, import_tags, import_axes, import_viewport)

      unless ScenePortabilityKit.imported_data
        UI.messagebox("No imported data available. Please select a JSON file first.")
        return
      end

      begin
        model = Sketchup.active_model
        model.start_operation("Import Scene: #{scene_name}", true)

        if import_viewport && (vp_data = ScenePortabilityKit.imported_data["viewport"])
          w = vp_data["width"]
          h = vp_data["height"]
          if w && h && w > 0 && h > 0
            ViewportResizer.resize_viewport(w.to_i, h.to_i)
          end
        end

        if import_camera && (cam_data = ScenePortabilityKit.imported_data["camera"])
          eye    = Geom::Point3d.new(cam_data["eye"])
          target = Geom::Point3d.new(cam_data["target"])
          up     = Geom::Vector3d.new(cam_data["up"])
          cam    = Sketchup::Camera.new(eye, target, up)
          cam.perspective = cam_data["perspective"] if cam_data.key?("perspective")
          cam.fov         = cam_data["fov"]         if cam_data.key?("fov")
          cam.height      = cam_data["height"]      if cam_data.key?("height")
          model.active_view.camera = cam
        end

        if import_style_fog && (sf = ScenePortabilityKit.imported_data["style_fog"])
          ro = model.rendering_options
          sf.each { |k, v| Serialization.deserialize_key(ro, k, v) }
        end

        if import_shadows && (sh = ScenePortabilityKit.imported_data["shadow_info"])
          si = model.shadow_info
          sh.each { |k, v| Serialization.deserialize_key(si, k, v) }
        end

        if import_env
          if (er = ScenePortabilityKit.imported_data["env_rendering"])
            er.each { |k, v| Serialization.deserialize_key(model.rendering_options, k, v) }
          end
          if (es = ScenePortabilityKit.imported_data["env_shadow"])
            es.each { |k, v| Serialization.deserialize_key(model.shadow_info, k, v) }
          end
        end

        if import_section && (sp_list = ScenePortabilityKit.imported_data["active_section_planes"])
          sp_list.each do |item|
            saved_plane = item["plane"]
            sp_name     = item["name"]   || ""
            sp_symbol   = item["symbol"] || ""

            existing = model.entities.grep(Sketchup::SectionPlane).find do |sp|
              sp.plane.zip(saved_plane).all? { |a, b| (a.to_f - b.to_f).abs < 1e-3 }
            end

            if existing
              model.entities.active_section_plane = existing
            else
              new_sp = model.entities.add_section_plane(saved_plane)
              if new_sp
                new_sp.name   = sp_name   if new_sp.respond_to?(:name=)   && !sp_name.empty?
                new_sp.symbol = sp_symbol if new_sp.respond_to?(:symbol=) && !sp_symbol.empty?
                model.entities.active_section_plane = new_sp
              end
            end
          end
        end

        if import_hidden && (hidden_list = ScenePortabilityKit.imported_data["top_level_hidden"])
          hidden_list.each do |item|
            pid      = item["persistent_id"]
            e_type   = item["type"]
            e_name   = item["name"]   || ""
            def_name = item["definition_name"] || ""

            ent = model.find_entity_by_persistent_id(pid) rescue nil

            if ent.nil?
              ent = model.entities.find do |e|
                next false unless e.class.name == e_type
                if e.respond_to?(:name) && !e_name.empty?
                  e.name == e_name
                elsif e.respond_to?(:definition) && !def_name.empty?
                  e.definition.name == def_name
                else
                  false
                end
              end
            end

            ent.hidden = true if ent
          end
        end

        page = model.pages.add(scene_name)
        page.description = ScenePortabilityKit.imported_data["description"] || ""

        if (vp_data = ScenePortabilityKit.imported_data["viewport"])
          page.set_attribute("ScenePortabilityKit", "viewport_width", vp_data["width"])
          page.set_attribute("ScenePortabilityKit", "viewport_height", vp_data["height"])
        end

        if import_tags && (tags_list = ScenePortabilityKit.imported_data["visible_tags"])
          tags_list.each do |item|
            tag_name = item["name"]
            visible  = item["visible"]
            layer = model.layers[tag_name] || model.layers.add(tag_name)
            page.set_visibility(layer, visible)
          end
        end

        if import_axes && (ax_data = ScenePortabilityKit.imported_data["axes"])
          origin = Geom::Point3d.new(ax_data["origin"])
          xaxis  = Geom::Vector3d.new(ax_data["xaxis"])
          yaxis  = Geom::Vector3d.new(ax_data["yaxis"])
          zaxis  = Geom::Vector3d.new(ax_data["zaxis"])
          model.axes.set(origin, xaxis, yaxis, zaxis)
        end

        page.use_camera             = import_camera
        page.use_rendering_options  = import_style_fog || import_env
        page.use_shadow_info        = import_shadows   || import_env
        page.use_section_planes     = import_section
        page.use_hidden_layers      = import_tags
        page.use_axes               = import_axes

        if page.respond_to?(:use_hidden_geometry=)
          page.use_hidden_geometry = import_hidden
          page.use_hidden_objects  = import_hidden
        elsif page.respond_to?(:use_hidden=)
          page.use_hidden = import_hidden
        end

        model.commit_operation

        escaped = scene_name.gsub("'", "\\\\'")
        ScenePortabilityKit.dialog.execute_script("onImportSuccess('#{escaped}');")
        ScenePortabilityKit.imported_data = nil
      rescue => e
        model.abort_operation
        UI.messagebox("Import operation failed:\n#{e.class}: #{e.message}")
        puts e.backtrace
      end
    end
  end
end

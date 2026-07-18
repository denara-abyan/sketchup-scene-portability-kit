module ScenePortabilityKit
  module Export
    def self.layer_visible_in_page?(layer, page)
      hidden_by_default = (layer.page_behavior & LAYER_HIDDEN_BY_DEFAULT) == LAYER_HIDDEN_BY_DEFAULT
      is_exception      = page.layers.include?(layer)
      hidden_by_default ^ is_exception ? false : true
    end

    def self.export_scene(scene_name,
        export_camera, export_style_fog, export_shadows,
        export_env, export_section, export_hidden, export_tags, export_axes, export_viewport)
      begin
        model = Sketchup.active_model
        page  = model.pages[scene_name]

        unless page
          UI.messagebox("Scene '#{scene_name}' not found in this model.")
          return
        end

        filepath = UI.savepanel("Export Scene JSON", "", "#{scene_name}.json")
        return if filepath.nil? || filepath.empty?
        filepath += ".json" unless filepath.downcase.end_with?(".json")

        view = model.active_view
        page.set_attribute("ScenePortabilityKit", "viewport_width", view.vpwidth)
        page.set_attribute("ScenePortabilityKit", "viewport_height", view.vpheight)

        data = {
          "name"        => page.name,
          "description" => page.description || "",
          "version"     => "1.2.0"
        }

        if export_camera
          cam = page.camera
          data["camera"] = {
            "eye"         => cam.eye.to_a,
            "target"      => cam.target.to_a,
            "up"          => cam.up.to_a,
            "perspective" => cam.perspective?,
            "fov"         => cam.fov,
            "height"      => cam.height
          }
        end

        if export_style_fog
          data["style_fog"] = Serialization.serialize_keys(page.rendering_options, STYLE_FOG_KEYS)
        end

        if export_shadows
          data["shadow_info"] = Serialization.serialize_keys(page.shadow_info, SHADOW_KEYS)
        end

        if export_env
          data["env_rendering"] = Serialization.serialize_keys(page.rendering_options, ENV_RENDERING_KEYS)
          data["env_shadow"]    = Serialization.serialize_keys(page.shadow_info,       ENV_SHADOW_KEYS)
        end

        if export_section
          active_planes = []
          if page.respond_to?(:active_section_planes)
            active_planes = page.active_section_planes
          else
            prev_active_page = model.pages.selected_page
            prev_transition = model.options["PageOptions"]["ShowTransition"] rescue true
            model.options["PageOptions"]["ShowTransition"] = false if model.options["PageOptions"]

            model.pages.selected_page = page

            model.entities.each do |ent|
              active_planes << ent if ent.is_a?(Sketchup::SectionPlane) && ent.active?
            end
            model.definitions.each do |defn|
              defn.entities.each do |ent|
                active_planes << ent if ent.is_a?(Sketchup::SectionPlane) && ent.active?
              end
            end

            model.pages.selected_page = prev_active_page if prev_active_page
            model.options["PageOptions"]["ShowTransition"] = prev_transition if model.options["PageOptions"]
          end

          section_planes_data = []
          active_planes.each do |sp|
            section_planes_data << {
              "plane" => sp.plane,
              "name" => sp.respond_to?(:name) ? sp.name : "",
              "symbol" => sp.respond_to?(:symbol) ? sp.symbol : ""
            }
          end
          data["active_section_planes"] = section_planes_data
        end

        if export_hidden
          top_ids = model.entities.map(&:persistent_id).to_set
          hidden_list = page.hidden_entities.select { |e| top_ids.include?(e.persistent_id) }.map do |ent|
            {
              "persistent_id"   => ent.persistent_id,
              "type"            => ent.class.name,
              "name"            => ent.respond_to?(:name)       ? ent.name       : "",
              "definition_name" => ent.respond_to?(:definition) ? ent.definition.name : ""
            }
          end
          data["top_level_hidden"] = hidden_list
        end

        if export_tags
          layers_list = model.layers.map do |layer|
            { "name" => layer.name, "visible" => layer_visible_in_page?(layer, page) }
          end
          data["visible_tags"] = layers_list
        end

        if export_axes
          ax = page.axes
          data["axes"] = {
            "origin" => ax.origin.to_a,
            "xaxis"  => ax.xaxis.to_a,
            "yaxis"  => ax.yaxis.to_a,
            "zaxis"  => ax.zaxis.to_a
          }
        end

        if export_viewport
          data["viewport"] = {
            "width"  => view.vpwidth,
            "height" => view.vpheight,
            "ratio"  => view.vpwidth.to_f / view.vpheight
          }
        end

        File.write(filepath, JSON.pretty_generate(data))

        escaped = page.name.gsub("'", "\\\\'")
        ScenePortabilityKit.dialog.execute_script("onExportSuccess('#{escaped}');")
        ScenePortabilityKit.refresh_scenes
      rescue => e
        UI.messagebox("Export failed:\n#{e.class}: #{e.message}")
        puts e.backtrace
      end
    end
  end
end

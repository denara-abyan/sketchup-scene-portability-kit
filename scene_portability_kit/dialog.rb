module ScenePortabilityKit
  module Dialog
    def self.show
      if ScenePortabilityKit.dialog && ScenePortabilityKit.dialog.visible?
        ScenePortabilityKit.dialog.bring_to_front
        return
      end

      options = {
        dialog_title: "Nadenra Scene Portability Kit",
        preferences_key: "com.antigravity.scene_portability_kit",
        width: 480,
        height: 680,
        style: UI::HtmlDialog::STYLE_DIALOG,
        resizable: true
      }

      ScenePortabilityKit.dialog = UI::HtmlDialog.new(options)
      html_path = File.join(File.dirname(__FILE__), "dialog.html")
      ScenePortabilityKit.dialog.set_file(html_path)

      ScenePortabilityKit.dialog.add_action_callback("get_scenes") do |_ctx|
        self.get_scenes
      end

      ScenePortabilityKit.dialog.add_action_callback("export_scene") do |_ctx,
          scene_name, exp_camera, exp_style_fog, exp_shadows,
          exp_env, exp_section, exp_hidden, exp_tags, exp_axes, exp_viewport|
        Export.export_scene(scene_name,
          exp_camera, exp_style_fog, exp_shadows,
          exp_env, exp_section, exp_hidden, exp_tags, exp_axes, exp_viewport)
      end

      ScenePortabilityKit.dialog.add_action_callback("select_import_file") do |_ctx|
        Import.select_import_file
      end

      ScenePortabilityKit.dialog.add_action_callback("apply_import") do |_ctx,
          scene_name, imp_camera, imp_style_fog, imp_shadows,
          imp_env, imp_section, imp_hidden, imp_tags, imp_axes, imp_viewport|
        Import.apply_import(scene_name,
          imp_camera, imp_style_fog, imp_shadows,
          imp_env, imp_section, imp_hidden, imp_tags, imp_axes, imp_viewport)
      end

      ScenePortabilityKit.dialog.add_action_callback("activate_scene") do |_ctx, scene_name|
        self.activate_scene(scene_name)
      end

      ScenePortabilityKit.dialog.show
    end

    def self.get_scenes
      begin
        model = Sketchup.active_model
        scenes = model.pages.map do |page|
          vp_w = page.get_attribute("ScenePortabilityKit", "viewport_width")
          vp_h = page.get_attribute("ScenePortabilityKit", "viewport_height")

          if vp_w.nil? || vp_h.nil?
            aspect = page.camera.aspect_ratio
            vp_size_str = aspect > 0 ? "Aspect: #{aspect.round(2)}" : "Match Viewport"
          else
            vp_size_str = "#{vp_w}x#{vp_h}"
          end

          camera = page.camera
          fov = camera.fov.round(1) rescue 0
          projection = camera.perspective? ? "Perspective" : "Parallel"
          camera_str = camera.perspective? ? "#{projection} (FOV: #{fov}°)" : "#{projection} (Height: #{camera.height.to_f.round(2)})"

          fog_enabled = false
          sky_enabled = false
          ground_enabled = false
          begin
            fog_enabled = page.rendering_options["DisplayFog"]
            sky_enabled = page.rendering_options["DrawSky"]
            ground_enabled = page.rendering_options["DrawGround"]
          rescue
          end

          shadows_enabled = false
          begin
            shadows_enabled = page.shadow_info["DisplayShadows"]
          rescue
          end

          {
            name: page.name,
            description: page.description || "",
            viewport_size: vp_size_str,
            camera_settings: camera_str,
            fog_active: fog_enabled,
            env_active: sky_enabled || ground_enabled,
            shadow_active: shadows_enabled
          }
        end

        ScenePortabilityKit.dialog.execute_script("updateSceneList(#{scenes.to_json});")
      rescue => e
        puts "ScenePortabilityKit#get_scenes error: #{e.message}"
        puts e.backtrace
      end
    end

    def self.activate_scene(scene_name)
      begin
        model = Sketchup.active_model
        page = model.pages[scene_name]
        if page
          model.pages.selected_page = page

          vp_w = page.get_attribute("ScenePortabilityKit", "viewport_width")
          vp_h = page.get_attribute("ScenePortabilityKit", "viewport_height")
          if vp_w && vp_h && vp_w > 0 && vp_h > 0
            ViewportResizer.resize_viewport(vp_w.to_i, vp_h.to_i)
          end
        end
      rescue => e
        puts "ScenePortabilityKit#activate_scene error: #{e.message}"
        puts e.backtrace
      end
    end
  end
end

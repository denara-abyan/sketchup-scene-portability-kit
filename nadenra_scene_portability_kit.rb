require 'sketchup.rb'
require 'extensions.rb'

module ScenePortabilityKit
  ext = SketchupExtension.new('Nadenra Scene Portability Kit', 'nadenra_scene_portability_kit/main.rb')
  ext.version = '1.2.0'
  ext.description = 'Export and import SketchUp scene/page properties (camera, style, fog, shadow, environment, section planes, hidden geometry, and tags) via JSON.'
  ext.creator = 'Nadenra'
  ext.copyright = '2026'
  
  Sketchup.register_extension(ext, true)
end

require 'sketchup.rb'
require 'json'
begin
  require 'set'
rescue LoadError
end

begin

require_relative 'constants'
require_relative 'viewport_resizer'
require_relative 'serialization'
require_relative 'export'
require_relative 'import'
require_relative 'dialog'

module ScenePortabilityKit
  @dialog = nil
  @imported_data = nil

  def self.dialog
    @dialog
  end

  def self.dialog=(val)
    @dialog = val
  end

  def self.imported_data
    @imported_data
  end

  def self.imported_data=(val)
    @imported_data = val
  end

  def self.refresh_scenes
    Dialog.get_scenes
  end

  unless file_loaded?(__FILE__)
    toolbar = UI::Toolbar.new("Scene Portability Kit")
    
    cmd = UI::Command.new("Scene Portability Kit") { Dialog.show }
    
    icon_path = File.join(File.dirname(__FILE__), 'images', 'icon.png')
    cmd.small_icon = icon_path
    cmd.large_icon = icon_path
    
    toolbar.add_item(cmd)
    toolbar.restore
    
    UI.menu("Plugins").add_item("Scene Portability Kit") { Dialog.show }
    
    file_loaded(__FILE__)
  end
end

rescue => e
  UI.messagebox("Scene Portability Kit failed to load:\n#{e.message}\n\nCheck Ruby Console for details.")
  puts "ScenePortabilityKit LOAD ERROR: #{e.class}: #{e.message}"
  puts e.backtrace
end

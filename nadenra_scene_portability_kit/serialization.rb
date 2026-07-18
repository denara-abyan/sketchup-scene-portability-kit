module ScenePortabilityKit
  module Serialization
    def self.serialize_keys(src_dict, keys)
      result = {}
      keys.each do |k|
        begin
          val = src_dict[k]
          result[k] =
            case val
            when Time            then val.to_i
            when Sketchup::Color then [val.red, val.green, val.blue, val.alpha]
            when TrueClass, FalseClass, Numeric, String then val
            end
        rescue
        end
      end
      result.compact
    end

    def self.deserialize_key(target, key, val)
      begin
        if key == "ShadowTime" && val.is_a?(Numeric)
          target[key] = Time.at(val)
        elsif val.is_a?(Array) && val.length >= 3 && val.all? { |x| x.is_a?(Numeric) }
          target[key] = Sketchup::Color.new(val[0].to_i, val[1].to_i, val[2].to_i, (val[3] || 255).to_i)
        else
          target[key] = val
        end
      rescue => e
        puts "ScenePortabilityKit: warning – skipped '#{key}': #{e.message}"
      end
    end

    def self.hex_to_rgb(hex_str)
      h = hex_str.to_s.gsub('#', '').strip
      return [128, 128, 128] if h.length < 6
      [h[0..1].to_i(16), h[2..3].to_i(16), h[4..5].to_i(16)]
    end
  end
end

module ScenePortabilityKit
  STYLE_FOG_KEYS = [
    "DrawBackground", "BackgroundColor", "EdgeColor", "EdgeMode", "RenderMode",
    "ModelTransparency", "DrawHidden", "DisplayColorByLayer", "DrawSilhouette",
    "SilhouetteWidth", "EdgeColorMode", "DisplayInstanceAxes",
    "SectionActiveColor", "SectionDefaultColor", "SectionInactiveColor",
    "DisplayFog", "FogColor", "FogStartDist", "FogEndDist", "FogUseBkColor"
  ].freeze

  ENV_RENDERING_KEYS = [
    "DrawSky", "SkyColor", "DrawGround", "GroundColor", "GroundTransparency"
  ].freeze

  ENV_SHADOW_KEYS = [
    "City", "Country", "Latitude", "Longitude", "TZOffset",
    "DisplayNorth", "NorthAngle"
  ].freeze

  SHADOW_KEYS = [
    "DisplayShadows", "DisplaySun", "Dark", "Light",
    "UseSunForAllShading", "ShadowTime"
  ].freeze
end

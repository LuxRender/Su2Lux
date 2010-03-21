require "LuxrenderTypes"


settings_panel = HTML_block_panel.new("settings_panel", [
    HTML_block_collapse.new(
      "Camera",
      LuxSelection.new(
        "camera_type",
        [
          LuxChoice.new("perspective", LuxFloat.new("fov", 35)),
          LuxChoice.new("orthographic", LuxFloat.new("scale", 7.1)),
          LuxChoice.new("environment")
        ],
        name="Type")#end LuxSelection
      ),#end HTML_block_collapse
    HTML_block_collapse.new(
      "Environment",
      LuxSelection.new(
        "environment_light_type",
        [
          LuxChoice.new("none"),
          LuxChoice.new("infinite"),
          LuxChoice.new("sunsky")
        ],
        name="Environment Light Type"
        )#end LuxSelection
      )#end HTML_block_collapse
  ])

web_page = HTML_block_main.new("SettingsPage")
web_page.add_element!(settings_panel)

  print """
HTML GENERATION: 
#{web_page.html}

LXS GENERATION:

"""
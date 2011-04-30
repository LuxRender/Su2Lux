def create_toolbar
	main_menu = UI.menu("Plugins").add_submenu("Luxrender Exporter")
	main_menu.add_item("Render") { (SU2LUX.export_dialog)}
	main_menu.add_item("Export Copy") {(SU2LUX.export_copy)}
	main_menu.add_item("Settings") { (SU2LUX.show_settings_editor)}
	main_menu.add_item("Material Editor") {(SU2LUX.show_material_editor)}
	main_menu.add_item("About") {(SU2LUX.about)}

	toolbar = UI::Toolbar.new("Luxrender")

	cmd_render = UI::Command.new("Render"){(SU2LUX.export_dialog)}
	cmd_render.small_icon = "icons\\lux_icon.png"
	cmd_render.large_icon = "icons\\lux_icon.png"
	cmd_render.tooltip = "Export and Render with LuxRender"
	cmd_render.menu_text = "Render"
	cmd_render.status_bar_text = "Export and Render with LuxRender"
	toolbar = toolbar.add_item(cmd_render)#would be nicer/more consistant with toolbar.add_item!(cmd_render)

	cmd_settings = UI::Command.new("Settings"){(SU2LUX.show_settings_editor)}
	cmd_settings.small_icon = "icons\\lux_icon_settings.png"
	cmd_settings.large_icon = "icons\\lux_icon_settings.png"
	cmd_settings.tooltip = "Open SU2LUX Settings Window"
	cmd_settings.menu_text = "Settings"
	cmd_settings.status_bar_text = "Open SU2LUX Settings Window"
	toolbar = toolbar.add_item(cmd_settings)

	cmd_settings = UI::Command.new("Material"){(SU2LUX.show_material_editor)}
	cmd_settings.small_icon = "icons\\lux_icon_settings.png"
	cmd_settings.large_icon = "icons\\lux_icon_settings.png"
	cmd_settings.tooltip = "Open SU2LUX Material Editor"
	cmd_settings.menu_text = "Material Editor"
	cmd_settings.status_bar_text = "Open SU2LUX Material Editor"
	toolbar = toolbar.add_item(cmd_settings)

	toolbar = toolbar.add_separator
	
	cmd_addprim = UI::Command.new("Settings"){(select_my_tool())}
	cmd_addprim.small_icon = "icons\\box.png"
	cmd_addprim.large_icon = "icons\\box.png"
	cmd_addprim.tooltip = "Create LuxCube Primative"
	cmd_addprim.menu_text = "LuxCube"
	cmd_addprim.status_bar_text = "Create LuxCube Primative"
	toolbar = toolbar.add_item(cmd_addprim)

	toolbar.show
end
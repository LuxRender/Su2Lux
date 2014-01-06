def create_toolbar
	main_menu = UI.menu("Plugins").add_submenu("LuxRender")
	main_menu.add_item("Render") { (SU2LUX.export_dialog)}
	main_menu.add_item("Material Editor") {(SU2LUX.show_material_editor)}
	main_menu.add_item("Settings Editor") { (SU2LUX.show_settings_editor)}
	main_menu.add_item("About") {(SU2LUX.about)}
	
	toolbar = UI::Toolbar.new("LuxRender")

	cmd_render = UI::Command.new("Render"){(SU2LUX.export_dialog)}
	cmd_render.small_icon = "icons\\lux_icon.png"
	cmd_render.large_icon = "icons\\lux_icon.png"
	cmd_render.tooltip = "Export and Render with LuxRender"
	cmd_render.menu_text = "Render"
	cmd_render.status_bar_text = "Export and Render with LuxRender"
	toolbar = toolbar.add_item(cmd_render)

	cmd_material = UI::Command.new("Material"){(SU2LUX.show_material_editor)}
	cmd_material.small_icon = "icons\\lux_material_settings.png"
	cmd_material.large_icon = "icons\\lux_material_settings.png"
	cmd_material.tooltip = "Open SU2LUX Material Editor"
	cmd_material.menu_text = "Material Editor"
	cmd_material.status_bar_text = "Open SU2LUX Material Editor"
	toolbar = toolbar.add_item(cmd_material)
    
	cmd_settings = UI::Command.new("Settings"){(SU2LUX.show_settings_editor)}
	cmd_settings.small_icon = "icons\\lux_icon_settings.png"
	cmd_settings.large_icon = "icons\\lux_icon_settings.png"
	cmd_settings.tooltip = "Open SU2LUX Settings Window"
	cmd_settings.menu_text = "Settings"
	cmd_settings.status_bar_text = "Open SU2LUX Settings Window"
	toolbar = toolbar.add_item(cmd_settings)

	toolbar.show
end

def create_context_menu
	UI.add_context_menu_handler do |menu|
		if( SU2LUX.selected_face_has_texture? )
			menu.add_separator
			uvs = SU2LUX_UV.new
			lux_menu = menu.add_submenu("SU2LUX Add-ons")
			su2lux_menu = lux_menu.add_submenu("UV Manager")
			su2lux_menu.add_item("Save UV coordinates") { uvs.get_selection_uvs(1) }
		end
	end
end
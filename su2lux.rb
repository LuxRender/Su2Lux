# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307, USA, or go to
# http://www.gnu.org/copyleft/lesser.txt.
#-----------------------------------------------------------------------------
# Name         : su2lux.rb
# Description  : Model exporter and material editor for Luxrender http://www.luxrender.net
# Menu Item    : Plugins\Luxrender Exporter
# Authors      : Alexander Smirnov (aka Exvion)  e-mail: exvion@gmail.com
#                Mimmo Briganti (aka mimhotep)
#                Initialy based on SU exporters: SU2KT by Tomasz Marek, Stefan Jaensch,Tim Crandall, 
#                SU2POV by Didier Bur and OGRE exporter by Kojack
# Usage        : Copy script to PLUGINS folder in SketchUp folder, run SU, go to Plugins\Luxrender exporter
# Date         : 2010-02-01
# Type         : Exporter
# Version      : 0.1 dev



require 'sketchup.rb'

module SU2LUX

# Module constants
	CONFIG_FILE = "luxrender_path.txt"
	DEBUG = true #duplicated
	DEFAULT_FOLDER = "Luxrender_export" #unused
	FRONT_FACE_MATERIAL = "SU2LUX Front Face"
	PLUGIN_FOLDER = "su2lux"
	PREFIX_TEXTURES = "TX_"
	SCENE_EXTENSION = ".lxs"
	SCENE_NAME = "Untitled.lxs"
	SUFFIX_MATERIAL = "-mat.lxm"
	SUFFIX_OBJECT = "-geom.lxo"
	SUFFIX_VOLUME = "-vol.lxv"

	##
	# prints a message in the Ruby console only when in debug mode
	##
	if (DEBUG)
		def SU2LUX.dbg_p(message)
			p message
		end
	else
		def SU2LUX.dbg_p(message)
		end
	end

	##
	#
	##
	def SU2LUX.create_observers
		$SU2LUX_view_observer = SU2LUX_view_observer.new
		Sketchup.active_model.active_view.add_observer($SU2LUX_view_observer)
		$SU2LUX_rendering_options_observer = SU2LUX_rendering_options_observer.new
		Sketchup.active_model.rendering_options.add_observer($SU2LUX_rendering_options_observer)
		$SU2LUX_materials_observer = SU2LUX_materials_observer.new
		Sketchup.active_model.materials.add_observer($SU2LUX_materials_observer)
	end

	##
	#
	##
	def SU2LUX.remove_observers
		Sketchup.active_model.active_view.remove_observer $SU2LUX_view_observer
		Sketchup.active_model.rendering_options.remove_observer $SU2LUX_rendering_options_observer
		Sketchup.active_model.materials.remove_observer $SU2LUX_materials_observer
	end
	
	##
	#
	##
	def SU2LUX.get_os
		return (Object::RUBY_PLATFORM =~ /mswin/i) ? :windows : ((Object::RUBY_PLATFORM =~ /darwin/i) ? :mac : :other)
	end # END get_os

	##
	# variables initializazion
	##
	def SU2LUX.initialize_variables
	
		os = OSSpecific.new
		@os_specific_vars = os.get_variables 

		@lrs= LuxrenderSettings.new
		@luxrender_filename = @os_specific_vars["luxrender_filename"]
		#TODO: check if the following variables needs to be a module variable
		@luxrender_path = "" #needs to go with luxrender settings
		@os_separator = @os_specific_vars["path_separator"]
	end # END initialize_variables

	##
	# resetting values of all istance variables
	##
	def SU2LUX.reset_variables
		@animation=false #check_meaning
		@copy_textures = true #duplicated/unused here
		@exp_distorted = false
		@export_full_frame=false #check_meaning
		@luxrender_path = SU2LUX.get_luxrender_path #see initialize variables
		@model_textures={} #duplicated/unused here
		@texturewriter=Sketchup.create_texture_writer #duplicated
		@selected=false

		@components = {} #unused
		@export_materials = true #unused
		@export_meshes = true #unused
		@export_lights = true #unused
		@face=0 #unused
		@frame=0 #unused
		@instanced=true #unused
		@lights = [] #unused
		@model_name="" #unused in this file
		@n_cameras=0 #unused
		@n_pointlights=0 #unused
		@n_spotlights=0 #unused
		@scene_export = false #unused  True when exporting a model for each scene
		@status_prefix = ""   #unused  Identifies which scene is being processed in status bar
		@used_materials = [] #unused
	end # END reset_variables
  
	##
	# exporting geometry, lights, materials and settings to a LuxRender file
	##
	def SU2LUX.export
		#Sketchup.send_action "showRubyPanel:"
		SU2LUX.reset_variables
		model = Sketchup.active_model
		entities = model.active_entities
		selection = model.selection
		materials = model.materials

		le=LuxrenderExport.new(@export_file_path,@os_separator)
		le.reset
		file_basename = File.basename(@export_file_path, SCENE_EXTENSION)
		
		file_dirname = File.dirname(@export_file_path)
		file_fullname = file_dirname + @os_separator + file_basename
		
		#Exporting geometry
		out_geom = File.new(file_fullname + SUFFIX_OBJECT, "w")
		le.export_mesh(out_geom)
		out_geom.close

		#Exporting all materials
		out_mat = File.new(file_fullname + SUFFIX_MATERIAL, "w")
		le.export_used_materials(materials, out_mat)
		# le.export_textures(out_mat)
		out_mat.close

		out = File.new(@export_file_path,"w")
		le.export_global_settings(out)
		le.export_camera(model.active_view, out)
		le.export_film(out)
		le.export_render_settings(out)
		entity_list=model.entities
		out.puts 'WorldBegin'
		
		out.puts "Include \"" + file_basename + SUFFIX_MATERIAL + "\"\n\n"
		out.puts "Include \"" + file_basename + SUFFIX_OBJECT + "\"\n\n"
		le.export_light(out)
		out.puts 'WorldEnd'
		out.close
		le.write_textures
		@count_tri = le.count_tri
	end # END export

	##
	#	 showing the export dialog box
	##
	def SU2LUX.export_dialog(render=true)
		"""The argument: 'render' is a boolean which indicates
		whether or not to render the lxs after it has been exported
		"""
		SU2LUX.remove_observers

		##### --- awful hack --- 1.0 ####
		# @lrs=LuxrenderSettings.new
		@export_file_path = @lrs.export_file_path #shouldn't need this
		#####################

		SU2LUX.reset_variables
		
		#check whether file path has already been chosen
		if @export_file_path != ""
			start_time = Time.new
			SU2LUX.export
		#launch appropriate report window and render (according to variable: render)
			if render == true
				result = SU2LUX.report_window(start_time, ask_render=true)
				SU2LUX.launch_luxrender if result == 6
			else if render == false
				SU2LUX.report_window(start_time, ask_render=false)
				end
			end
		#choose a new name for export file path
		else 
			saved = SU2LUX.new_export_file_path
			if saved
				start_time = Time.new
				SU2LUX.export
			
			#launch appropriate report window and render (according to variable: render)
				if render == true
					result = SU2LUX.report_window(start_time, ask_render=true)
					SU2LUX.launch_luxrender if result == 6
				else if render == false
					SU2LUX.report_window(start_time, ask_render=false)
					end
				end
			end
		end
		SU2LUX.create_observers
	end # END export_dialog
	
	##
	# exporting the LuxRender file without asking for rendering
	##
	def SU2LUX.export_copy

		# @lrs=LuxrenderSettings.new
		#temporary file path for exporting copy
		old_export_file_path = @lrs.export_file_path 
		
		SU2LUX.new_export_file_path
		SU2LUX.export_dialog(render=false) #don't bother rendering
		
		@lrs.export_file_path = old_export_file_path
	end # END export_copy

#### Some Dialogs (colour select, browse file path, etc..)###########
#####################################################################

	##
	#
	##
	def SU2LUX.new_export_file_path
	"""This function browses for a new export file path and sets it in the lxs settings
	it is currently required for the browse button in the settings panel and the button in the 
	plugin menu.
	"""
		##### --- awful hack --- 1.0 ####
		# @lrs=LuxrenderSettings.new
		@export_file_path = @lrs.export_file_path #shouldn't need this
		#####################
		
		model = Sketchup.active_model
		model_filename = File.basename(model.path)
		if model_filename.empty?
			export_filename = SCENE_NAME
		else
			dot_position = model_filename.rindex(".")
			export_filename = model_filename.slice(0..(dot_position - 1))
			export_filename += SCENE_EXTENSION
		end
		#	if model.path.empty?
		default_folder = SU2LUX.find_default_folder
		export_folder = default_folder
		export_folder = File.dirname(model.path) if ! model.path.empty?
		
		user_input = UI.savepanel("Save lxs file", export_folder, export_filename)
		
		#check whether user has pressed cancel
		if user_input
			user_input.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
			user_input.gsub!(/\\/, '/') if user_input.include?('\\')
			#store file path for quick exports
			@export_file_path = user_input
				
			@lrs.export_file_path = @export_file_path
			#would be nice to store export_file_path in luxrender preferences (attatch to skp)
				
			if @export_file_path == @export_file_path.chomp(SCENE_EXTENSION)
				@export_file_path += SCENE_EXTENSION
					
				#### --- awful hack --- 1.0 #####
				@lrs.export_file_path = @export_file_path
				#####################
					
				@luxrender_path = SU2LUX.get_luxrender_path
			end
			return true #user has selected a path
		end
		return false #user has not selected a path
	end # END new_export_file_path

	##
	#
	##
	def SU2LUX.load_env_image
		
		model = Sketchup.active_model
		model_filename = File.basename(model.path)
		# if model_filename.empty?
			# export_filename = SCENE_NAME
		# else
			# dot_position = model_filename.rindex(".")
			# export_filename = model_filename.slice(0..(dot_position - 1))
			# export_filename += SCENE_EXTENSION
		# end
		default_folder = SU2LUX.find_default_folder
		export_folder = default_folder
		export_folder = File.dirname(model.path) if ! model.path.empty?
		
		user_input = UI.openpanel("Open background image", export_folder, "*")
		
		#check whether user has pressed cancel
		if user_input
			user_input.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
			user_input.gsub!(/\\/, '/') if user_input.include?('\\')
			#store file path for quick exports
				
			@lrs.environment_infinite_mapname = user_input
			
			return true #user has selected a path
		end
		return false #user has not selected a path
	end # END new_export_file_path

	##
	#
	##
	def SU2LUX.load_image(title, object, method, prefix)
		
		model = Sketchup.active_model
		model_filename = File.basename(model.path)
		default_folder = SU2LUX.find_default_folder
		export_folder = default_folder
		export_folder = File.dirname(model.path) if ! model.path.empty?
		
		user_input = UI.openpanel(title, export_folder, "*")
		
		#check whether user has pressed cancel
		if user_input
			user_input.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
			user_input.gsub!(/\\/, '/') if user_input.include?('\\')
			#store file path for quick exports
			prefix += '_' unless prefix.empty?
			object.send(prefix + method+"=", user_input)
			return true #user has selected a path
		end
		return false #user has not selected a path
	end # END new_export_file_path

	##
	#
	##
	#TODO: try to write better code for the function
	def SU2LUX.get_luxrender_path
		find_luxrender = true
		path = ENV['LUXRENDER_ROOT']
		if ( ! path.nil?)
			luxrender_path = path + @os_separator + @luxrender_filename
			if (File.exists?(luxrender_path))
				find_luxrender = false
			end
		end
		
		if (find_luxrender == true)
			path=File.dirname(__FILE__) + @os_separator + CONFIG_FILE
			if File.exist?(path)
				path_file = File.open(path, "r")
				luxrender_path = path_file.read
				path_file.close
				find_luxrender = false
			end
		end
		
		os = OSSpecific.new
		path = os.search_multiple_installations
		if ( ! path.nil?)
			luxrender_path = path + @os_separator + @luxrender_filename
			if (SU2LUX.luxrender_path_valid?(luxrender_path))
				path=File.dirname(__FILE__) + @os_separator + CONFIG_FILE
				path_file = File.new(path, "w")
				path_file.write(luxrender_path)
				path_file.close
				find_luxrender = false
			end
		end
		
		if (find_luxrender == true)
			luxrender_path = UI.openpanel("Locate Luxrender", "", "")
			return nil if luxrender_path.nil?
			if (luxrender_path && SU2LUX.luxrender_path_valid?(luxrender_path))
				path=File.dirname(__FILE__) + @os_separator + CONFIG_FILE
				path_file = File.new(path, "w")
				path_file.write(luxrender_path)
				path_file.close
			end
		end
		if SU2LUX.luxrender_path_valid?(luxrender_path)
			return luxrender_path
		else
			return nil
		end 
	end #END get_luxrender_path

	##
	#
	##
	def SU2LUX.change_luxrender_path
		luxrender_path = UI.openpanel("Locate Luxrender", "", "")
		@luxrender_path = nil if luxrender_path.nil?
		if (luxrender_path && SU2LUX.luxrender_path_valid?(luxrender_path))
			path=File.dirname(__FILE__) + @os_separator + CONFIG_FILE
			path_file = File.new(path, "w")
			path_file.write(luxrender_path)
			path_file.close
		end
		message = ""
		if SU2LUX.luxrender_path_valid?(luxrender_path)
			@luxrender_path = luxrender_path
			message = "New path for LuxRender is : #{@luxrender_path}"
		else
			@luxrender_path = nil
			message = "Invalid or no path selected."
		end
		result = UI.messagebox(message,MB_OK)
	end

	##
	#
	##
	def SU2LUX.find_default_folder
		folder = @os_specific_vars["default_save_folder"]
		return folder
	end # END find_default_folder

	##
	#
	##
	def SU2LUX.get_luxrender_filename
		# filename = @os_specific_vars["luxrender_filename"]
		# return filename
		return @luxrender_filename
	end # END get_luxrender_filename

	##
	#
	##
	def SU2LUX.report_window(start_time, ask_render=true)
		SU2LUX.dbg_p "SU2LUX.report_window"
		end_time=Time.new
		elapsed=end_time-start_time
		time=" exported in "
			(time=time+"#{(elapsed/3600).floor}h ";elapsed-=(elapsed/3600).floor*3600) if (elapsed/3600).floor>0
			(time=time+"#{(elapsed/60).floor}m ";elapsed-=(elapsed/60).floor*60) if (elapsed/60).floor>0
			time=time+"#{elapsed.round}s. "

		SU2LUX.status_bar(time+" Triangles = #{@count_tri}")
		export_text="Model & Lights saved in file:\n"
		#export_text="Selection saved in file:\n" if @selected==true
		if ask_render
			result=UI.messagebox(export_text + @export_file_path +  " \n\nOpen exported model in Luxrender?",MB_YESNO)
		else
			result=UI.messagebox(export_text + @export_file_path,MB_OK)
		end
		return result
	end # END report_window

##
#
##
def SU2LUX.luxrender_path_valid?(luxrender_path)
	(! luxrender_path.nil? and File.exist?(luxrender_path) and (File.basename(luxrender_path).upcase.include?("LUXRENDER")))
	#check if the path to Luxrender is valid
end #END luxrender_path_valid?
  
	##
	#
	##
	def SU2LUX.launch_luxrender
		@luxrender_path = SU2LUX.get_luxrender_path if @luxrender_path.nil?
		return if @luxrender_path.nil?
		Dir.chdir(File.dirname(@luxrender_path))
		export_path = "#{@export_file_path}"
		export_path = File.join(export_path.split(@os_separator))
		if (ENV['OS'] =~ /windows/i)
		 command_line = "start \"max\" \/#{@lrs.priority} \"#{@luxrender_path}\" \"#{export_path}\""
		 puts command_line
		 system(command_line)
		 else
			Thread.new do
				system(`#{@luxrender_path} "#{export_path}"`)
			end
		end
	end # END launch_luxrender

	##
	#
	##
	def SU2LUX.get_luxrender_console_path
		path=SU2LUX.get_luxrender_path
		return nil if not path
		root=File.dirname(path)
		c_path=File.join(root,"luxconsole.exe")

		if FileTest.exist?(c_path)
			return c_path
		else		
			return nil
		end
	end # END get_luxrender_console_path

	##
	# send text to status bar
	##
	def SU2LUX.status_bar(stat_text)
		statbar = Sketchup.set_status_text stat_text
	end # END status_bar

	##
	#
	##
	def SU2LUX.show_material_editor
		if not @material_editor
			@material_editor=LuxrenderMaterialEditor.new
		end
		@material_editor.show
	end # END show_material_editor

	##
	#
	##
	def SU2LUX.create_material_editor
		if not @material_editor
			@material_editor=LuxrenderMaterialEditor.new
		end
	end # END show_material_editor

	##
	#
	##
	def SU2LUX.show_settings_editor

		if not @settings_editor
			@settings_editor=LuxrenderSettingsEditor.new
		end
		@settings_editor.show
	end # END show_settings_editor

	##
	#
	##
	def SU2LUX.about
		UI.messagebox("SU2LUX version 0.1-dev 29th January 2010
	SketchUp Exporter to Luxrender
	Authors: Alexander Smirnov (aka Exvion); Mimmo Briganti (aka mimhotep)
	E-mail: exvion@gmail.com; 

	For further information please visit
	Luxrender Website & Forum - www.luxrender.net" , MB_MULTILINE , "SU2LUX - Sketchup Exporter to Luxrender")
	end # END

	##
	#
	##
	def SU2LUX.get_editor(type)
		case type
			when "settings"
				editor = @settings_editor
			when "material"
				editor = @material_editor
		end
		return editor
	end # END get_editor

	##
	#
	##
	def SU2LUX.selected_face_has_texture?
		has_texture = false
		model = Sketchup.active_model
		selection = model.selection
		sel = selection.first
		if sel.valid? and sel.is_a? Sketchup::Face
			mesh = sel.mesh 5
			material = sel.material
			material = sel.back_material if material.nil?
			if material and material.materialType > 0
				has_texture = true
			end
		end
		return has_texture
	end
	
end # END module SU2LUX

class SU2LUX_view_observer < Sketchup::ViewObserver

	include SU2LUX

	def onViewChanged(view)
		settings_editor = SU2LUX.get_editor("settings")
		@lrs = LuxrenderSettings.new
		if Sketchup.active_model.active_view.camera.perspective?
			@lrs.camera_type = 'perspective'
			# camera_type = 'perspective'
		else
			@lrs.camera_type = 'orthographic'
			# camera_type = 'orthographic'
		end
		if (settings_editor)
			if (Sketchup.active_model.active_view.camera.perspective?)
				fov = Sketchup.active_model.active_view.camera.fov
				fov = format("%.2f", fov)
				@lrs.fov = fov
				settings_editor.setValue("fov", fov)
				focal_length = Sketchup.active_model.active_view.camera.focal_length
				focal_length = format("%.2f", focal_length)
				@lrs.focal_length = focal_length
				settings_editor.setValue("focal_length", focal_length)
			end
	#		settings_editor.setValue("camera_type", @lrs.camera_type)
			settings_editor.setValue("camera_type", @lrs.camera_type)
		end
	end # END onViewChanged
	
end # END class SU2LUX_view_observer

class SU2LUX_app_observer < Sketchup::AppObserver
	def onNewModel(model)
		SU2LUX.create_observers
		@lrs = LuxrenderSettings.new
		@lrs.reset
		@lrs.fleximage_xresolution = Sketchup.active_model.active_view.vpwidth
		@lrs.fleximage_yresolution = Sketchup.active_model.active_view.vpheight

		settings_editor = SU2LUX.get_editor("settings")
		# @lrs.camera_scale = nil
		if (settings_editor && settings_editor.visible?)
			settings_editor.setValue("xresolution", @lrs.fleximage_xresolution)
			settings_editor.setValue("yresolution", @lrs.fleximage_yresolution)
			settings_editor.close
			# settings_editor.setValue("camera_scale", @lrs.camera_scale)
		end
		material_editor = SU2LUX.get_editor("material")
		if (material_editor && material_editor.visible?)
			material_editor.close
		end
		for mat in model.materials
			luxmat = LuxrenderMaterial.new(mat)
			luxmat.reset
		end
	end # END onNewModel

	def onOpenModel(model)
		SU2LUX.create_observers
		@lrs = LuxrenderSettings.new
		settings_editor = SU2LUX.get_editor("settings")
		if(settings_editor && settings_editor.visible?)
			settings_editor.close
		end
		material_editor = SU2LUX.get_editor("material")
		if (material_editor && material_editor.visible?)
			material_editor.close
		end
		# loaded = LuxrenderAttributeDictionary.load_from_model(@lrs.dictionary_name)
		loaded = @lrs.load_from_model
		@lrs.reset unless loaded
		for mat in model.materials
			luxmat = LuxrenderMaterial.new(mat)
			loaded = luxmat.load_from_model
			luxmat.reset unless loaded
		end
		SU2LUX.create_material_editor
		material_editor = SU2LUX.get_editor("material")
		material_editor.refresh
	end
	
end # END class SU2LUX_app_observer

class SU2LUX_rendering_options_observer < Sketchup::RenderingOptionsObserver
	def onRenderingOptionsChanged(renderoptions, type)
		if (type == 12)
			color = renderoptions["BackgroundColor"]
			@lrs = LuxrenderSettings.new
			#set the background color radio button in settings editor
		end
	end
end

class SU2LUX_materials_observer < Sketchup::MaterialsObserver
	def onMaterialSetCurrent(materials, material)
		SU2LUX.dbg_p "onMaterialSetCurrent: #{material.name}"
		material_editor = SU2LUX.get_editor("material")
		if (material_editor)
			luxmat = LuxrenderMaterial.new(material)
			material_editor.set_current(luxmat.name)
			material_editor.current = luxmat
			if (material_editor.visible?)
				material_editor.sendDataFromSketchup
				material_editor.fire_event("#type", "change", "")
			end
		end
	end
	
	def onMaterialAdd(materials, material)
		SU2LUX.create_material_editor
		material_editor = SU2LUX.get_editor("material")
		material_editor.refresh() if (material_editor);
		SU2LUX.dbg_p "onMaterialAdd"
		# material_editor.set_material_list() if (material_editor)
		# luxmat = LuxrenderMaterial.new(material)
		# material_editor.set_current(luxmat.name) if (material_editor)
	end

	def onMaterialRemove(materials, material)
		SU2LUX.create_material_editor
		material_editor = SU2LUX.get_editor("material")
		material_editor.refresh() if (material_editor);
		SU2LUX.dbg_p "onMaterialRemove"
		# material_editor.set_material_list() if (material_editor)
		# luxmat = LuxrenderMaterial.new(material)
		# material_editor.set_current(luxmat.name) if (material_editor)
	end
	
	def onMaterialChange(materials, material)
		material_editor = SU2LUX.get_editor("material")
		if (material_editor)
			luxmat = material_editor.find(material.name)
			luxmat.color = material.color
			material_editor.updateSettingValue("matte_kd_R")
			material_editor.updateSettingValue("matte_kd_G")
			material_editor.updateSettingValue("matte_kd_B")

			if material.texture
				texture_name = material.texture.filename
				texture_name.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
				texture_name.gsub!(/\\/, '/') if texture_name.include?('\\')
				luxmat.kd_imagemap_Sketchup_filename = texture_name
				luxmat.kd_texturetype = 'sketchup'
				luxmat.use_diffuse_texture = true
			else
				luxmat.kd_imagemap_Sketchup_filename = ''
				if (luxmat.kd_texturetype == 'sketchup')
					luxmat.kd_texturetype = 'none'
					luxmat.use_diffuse_texture = false
				end
			end
			material_editor.updateSettingValue("kd_imagemap_Sketchup_filename")
			material_editor.updateSettingValue("kd_texturetype")
			material_editor.updateSettingValue("use_diffuse_texture")
		end
	end
	
end

if( not file_loaded?(__FILE__) )

	case SU2LUX.get_os
		when :mac
			load File.join(SU2LUX::PLUGIN_FOLDER, "MacSpecific.rb")
		when :windows
			load File.join(SU2LUX::PLUGIN_FOLDER, "WindowsSpecific.rb")
		when :other
			UI.messagebox("Unknown operating system: contact developer to add support for it")
	end

	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderAttributeDictionary.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderSettings.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderSettingsEditor.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderMaterial.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderMaterialEditor.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderTextureEditor.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "MeshCollector.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderExport.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderToolbar.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "SU2LUX_UV.rb")
  # load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderPrimatives.rb")
  
	SU2LUX.initialize_variables

  create_toolbar()
	create_context_menu()
  
	#observers
	SU2LUX.create_observers
	$SU2LUX_app_observer = SU2LUX_app_observer.new
	Sketchup.add_observer($SU2LUX_app_observer)
	# $SU2LUX_view_observer = SU2LUX_view_observer.new
	# Sketchup.active_model.active_view.add_observer($SU2LUX_view_observer)
	# $SU2LUX_rendering_options_observer = SU2LUX_rendering_options_observer.new
	# Sketchup.active_model.rendering_options.add_observer($SU2LUX_rendering_options_observer)
	# $SU2LUX_materials_observer = SU2LUX_materials_observer.new
	# Sketchup.active_model.materials.add_observer($SU2LUX_materials_observer)
	
	#The following code is needed because the AppObserver methods are not called when a Sketchup scene
	#is loaded by double clicking on it
	#TODO: insert the following code into a function
	@lrs = LuxrenderSettings.new
	loaded = @lrs.load_from_model
	@lrs.reset unless loaded
	for mat in Sketchup.active_model.materials
		luxmat = LuxrenderMaterial.new(mat)
		loaded = luxmat.load_from_model
		luxmat.reset unless loaded
	end
	SU2LUX.create_material_editor
	material_editor = SU2LUX.get_editor("material")
	material_editor.refresh
end


file_loaded(__FILE__)

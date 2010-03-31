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

#if ! defined? INCLUDE_FLAG
	DEBUG = true
	#FRONTF = "SU2LUX Front Face"
	SCENE_NAME = "Untitled.lxs"
	EXT_SCENE = ".lxs"
	SUFFIX_MATERIAL = "-mat.lxm" #moved to class LuxrenderExport
	SUFFIX_OBJECT = "-geom.lxo"
	SUFFIX_VOLUME = "-vol.lxv"
	DEFAULT_FOLDER = "Luxrender_export"
	CONFIG_FILE = "luxrender_path.txt"
#end
#INCLUDE_FLAG = 1 if ! defined? INCLUDE_FLAG

#####################################################################
###### - printing debug messages - 										######
#####################################################################
if (DEBUG)
	def SU2LUX.p_debug(message)
		p message
	end
else
	def SU2LUX.p_debug(message)
	end
end

#####################################################################
#####################################################################

#Changed Windows separator from "\/" to "\\"
#@os_separator = (ENV['OS'] =~ /windows/i) ? "\\" : "/" # directory separator for Windows : OS X

def SU2LUX.initialize_variables
  @luxrender_path = "" #needs to go with luxrender settings
  
  if on_mac? #group the mac initializations together: making porting easier
    @os_separator = "/" 
    @luxrender_filename = "Luxrender.app/Contents/MacOS/Luxrender"
    #there are probably more
  else if not on_mac?
    @luxrender_filename = "luxrender.exe"
    @os_separator = "\\"
  end
end
end

#####################################################################
#####################################################################
def SU2LUX.reset_variables
	@n_pointlights=0
	@n_spotlights=0
	@n_cameras=0
	@face=0
	@copy_textures = true
	@export_materials = true
	@export_meshes = true
	@export_lights = true
	@instanced=true
	@model_name=""
	@textures_prefix = "TX_"
	@texturewriter=Sketchup.create_texture_writer
	@model_textures={}
	@lights = []
	@components = {}
	@selected=false
	@exp_distorted = false
	@animation=false
	@export_full_frame=false
	@frame=0
	@status_prefix = ""   # Identifies which scene is being processed in status bar
	@scene_export = false # True when exporting a model for each scene
	@status_prefix=""
	@luxrender_path = SU2LUX.get_luxrender_path
	@used_materials = []
end
  
#####################################################################
#####################################################################
def SU2LUX.export
	#Sketchup.send_action "showRubyPanel:"
	SU2LUX.reset_variables
	model = Sketchup.active_model
	entities = model.active_entities
	selection = model.selection
	materials = model.materials

	le=LuxrenderExport.new(@export_file_path,@os_separator)
	le.reset
	out = File.new(@export_file_path,"w")
	le.export_global_settings(out)
	le.export_camera(model.active_view, out)
	le.export_film(out)
	le.export_render_settings(out)
	entity_list=model.entities
	out.puts 'WorldBegin'
	le.export_light(out)
	
	file_basename = File.basename(@export_file_path, EXT_SCENE)
	out.puts "Include \"" + file_basename + SUFFIX_MATERIAL + "\"\n\n"
	out.puts "Include \"" + file_basename + SUFFIX_OBJECT + "\"\n\n"
	out.puts 'WorldEnd'
	out.close
	
	file_dirname = File.dirname(@export_file_path)
	file_fullname = file_dirname + @os_separator + file_basename
	
	#Exporting geometry
	out_geom = File.new(file_fullname + SUFFIX_OBJECT, "w")
	le.export_mesh(out_geom)
	out_geom.close

	#Exporting all materials
	out_mat = File.new(file_fullname + SUFFIX_MATERIAL, "w")
	le.export_used_materials(materials, out_mat)
	le.export_textures(out_mat)
	out_mat.close
	le.write_textures
end

#####################################################################
#####################################################################
def SU2LUX.export_dialog(render=true)
	"""The argument: 'render' is a boolean which indicates
	whether or not to render the lxs after it has been exported
	"""
	##### --- awful hack --- 1.0 ####
	@lrs=LuxrenderSettings.new
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
end #end export_dialog

def SU2LUX.export_copy

	@lrs=LuxrenderSettings.new
	#temporary file path for exporting copy
	old_export_file_path = @lrs.export_file_path 
	
	SU2LUX.new_export_file_path
	SU2LUX.export_dialog(render=false) #don't bother rendering
	
	@lrs.export_file_path = old_export_file_path
end	

#### Some Dialogs (colour select, browse file path, etc..)###########
#####################################################################

def SU2LUX.new_export_file_path
"""This function browses for a new export file path and sets it in the lxs settings
it is currently required for the browse button in the settings panel and the button in the 
plugin menu.
"""
	##### --- awful hack --- 1.0 ####
	@lrs=LuxrenderSettings.new
	@export_file_path = @lrs.export_file_path #shouldn't need this
	#####################
	
	model = Sketchup.active_model
    model_filename = File.basename(model.path)
    if model_filename.empty?
      export_filename = SCENE_NAME
    else
      dot_position = model_filename.rindex(".")
      export_filename = model_filename.slice(0..(dot_position - 1))
      export_filename += EXT_SCENE
    end
  #	if model.path.empty?
    default_folder = SU2LUX.find_default_folder
    export_folder = default_folder
    export_folder = File.dirname(model.path) if ! model.path.empty?
	
	user_input = UI.savepanel("Save lxs file", export_folder, export_filename)
	
	#check whether user has pressed cancel
    if user_input
      #store file path for quick exports
      @export_file_path = user_input
      
      @lrs.export_file_path = @export_file_path
      #would be nice to store export_file_path in luxrender preferences (attatch to skp)
      
      if @export_file_path == @export_file_path.chomp(EXT_SCENE)
        @export_file_path += EXT_SCENE
        
        #### --- awful hack --- 1.0 #####
        @lrs.export_file_path = @export_file_path
        #####################
        
        @luxrender_path = SU2LUX.get_luxrender_path
      end
	  return true #user has selected a path
	end
	return false #user has not selected a path
end

#####################################################################
#####################################################################
def SU2LUX.find_default_folder
	folder = ENV["USERPROFILE"]
	folder = File.expand_path("~") if on_mac?
	return folder
end

#####################################################################
#####################################################################
def SU2LUX.on_mac?
	return (Object::RUBY_PLATFORM =~ /mswin/i) ? FALSE : ((Object::RUBY_PLATFORM =~ /darwin/i) ? TRUE : :other)
end

#####################################################################
#####################################################################
def SU2LUX.get_luxrender_filename
	filename = "luxrender.exe"
	filename = "Luxrender.app/Contents/MacOS/Luxrender" if on_mac?
	return filename
end

#####################################################################
#####################################################################
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
	
	mac_path = SU2LUX.search_mac_luxrender
	if ( ! mac_path.nil?)
		luxrender_path = mac_path + @os_separator + @luxrender_filename
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
end

#####################################################################
#####################################################################
def SU2LUX.report_window(start_time, ask_render=true)
	SU2LUX.p_debug "SU2LUX.report_window"
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
end

#####################################################################
#####################################################################
def SU2LUX.search_mac_luxrender
	luxrender_folder = []
	if on_mac?
		start_folder = "/Applications"
		#start_folder = "C:\\Program Files"
		applications = Dir.entries(start_folder)
		applications.each { |app|
			luxrender_folder.push app if app =~ /luxrender/i
		}
		if luxrender_folder.length > 1
			paths = luxrender_folder.join("|")
			input = UI.inputbox(["folder"], [luxrender_folder[0]], [paths], "Choose Luxrender folder")
			luxrender_folder = input[0] if input
		elsif luxrender_folder.length == 1
			luxrender_folder = luxrender_folder[0]
		else
			return nil
		end
	end
	if luxrender_folder.empty?
		folder = nil
	else
		folder = start_folder + @os_separator + luxrender_folder
	end
	return folder
end
  
#####################################################################
#####################################################################
def SU2LUX.luxrender_path_valid?(luxrender_path)
	(! luxrender_path.nil? and File.exist?(luxrender_path) and (File.basename(luxrender_path).upcase.include?("LUXRENDER")))
	#check if the path to Luxrender is valid
end
  
#####################################################################
#####################################################################
def SU2LUX.launch_luxrender
	@luxrender_path = SU2LUX.get_luxrender_path if @luxrender_path.nil?
	return if @luxrender_path.nil?
	Dir.chdir(File.dirname(@luxrender_path))
	export_path = "#{@export_file_path}"
	export_path = File.join(export_path.split(@os_separator))
	if (ENV['OS'] =~ /windows/i)
	 command_line = "start \"max\" \"#{@luxrender_path}\" \"#{export_path}\""
	 puts command_line
	 system(command_line)
	 else
		Thread.new do
			system(`#{@luxrender_path} "#{export_path}"`)
		end
	end
end


#####################################################################
#####################################################################
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
end




#####################################################################
###### - Send text to status bar - 										######
#####################################################################
def SU2LUX.status_bar(stat_text)
	
	statbar = Sketchup.set_status_text stat_text
	
end


  
#####################################################################
#####################################################################
def SU2LUX.show_material_editor
	if not @material_editor
		@material_editor=LuxrenderMaterialEditor.new
	end
	@material_editor.show
end

#####################################################################
#####################################################################
def SU2LUX.show_settings_editor

	if not @settings_editor
		@settings_editor=LuxrenderSettingsEditor.new
	end
	@settings_editor.show
end


#####################################################################
#####################################################################
def SU2LUX.about
	UI.messagebox("SU2LUX version 0.1-dev 29th January 2010
SketchUp Exporter to Luxrender
Authors: Alexander Smirnov (aka Exvion); Mimmo Briganti (aka mimhotep)
E-mail: exvion@gmail.com; 

For further information please visit
Luxrender Website & Forum - www.luxrender.net" , MB_MULTILINE , "SU2LUX - Sketchup Exporter to Luxrender")
end

def SU2LUX.get_editor(type)
	case type
		when "settings"
			editor = @settings_editor
		when "material"
			editor = @material_editor
	end
	return editor
end

end #end module SU2LUX

class SU2LUX_view_observer < Sketchup::ViewObserver

include SU2LUX

def onViewChanged(view)

	settings_editor = SU2LUX.get_editor("settings")
	if (settings_editor)
		@lrs = LuxrenderSettings.new
		if (Sketchup.active_model.active_view.camera.perspective?)
			fov = Sketchup.active_model.active_view.camera.fov
			fov = format("%.2f", fov)
			settings_editor.setValue("fov", fov)
			focal_length = Sketchup.active_model.active_view.camera.focal_length
			focal_length = format("%.2f", focal_length)
			settings_editor.setValue("focal_length", focal_length)
			settings_editor.setValue("camera_type", "perspective")
			@lrs.camera_type = "perspective"
		else
			settings_editor.setValue("camera_type", "orthographic")
			@lrs.camera_type = "orthographic"
		end
	end
end
end

class SU2LUX_app_observer < Sketchup::AppObserver
	def onNewModel(model)
		model.active_view.add_observer(SU2LUX_view_observer.new)
		
		@lrs = LuxrenderSettings.new
		@lrs.xresolution = Sketchup.active_model.active_view.vpwidth
		@lrs.yresolution = Sketchup.active_model.active_view.vpheight
		settings_editor = SU2LUX.get_editor("settings")
		if settings_editor
			settings_editor.setValue("xresolution", @lrs.xresolution)
			settings_editor.setValue("yresolution", @lrs.yresolution)
		end
	end

	def onOpenModel(model)
		model.active_view.add_observer(SU2LUX_view_observer.new)
	end
end

if( not file_loaded?(__FILE__) )
	SU2LUX.initialize_variables

	main_menu = UI.menu("Plugins").add_submenu("Luxrender Exporter")
	main_menu.add_item("Render") { (SU2LUX.export_dialog)}
	main_menu.add_item("Export Copy") {(SU2LUX.export_copy)}
	main_menu.add_item("Settings") { (SU2LUX.show_settings_editor)}
	#main_menu.add_item("Material Editor") {(SU2LUX.show_material_editor)}
	main_menu.add_item("About") {(SU2LUX.about)}

	toolbar = UI::Toolbar.new("Luxrender")

	cmd_render = UI::Command.new("Render"){(SU2LUX.export_dialog)}
	cmd_render.small_icon = "su2lux\\lux_icon.png"
	cmd_render.large_icon = "su2lux\\lux_icon.png"
	cmd_render.tooltip = "Export and Render with LuxRender"
	cmd_render.menu_text = "Render"
	cmd_render.status_bar_text = "Export and Render with LuxRender"
	toolbar = toolbar.add_item(cmd_render)#would be nicer/more consistant with toolbar.add_item!(cmd_render)

	cmd_settings = UI::Command.new("Settings"){(SU2LUX.show_settings_editor)}
	cmd_settings.small_icon = "su2lux\\lux_icon_settings.png"
	cmd_settings.large_icon = "su2lux\\lux_icon_settings.png"
	cmd_settings.tooltip = "Open SU2LUX Settings Window"
	cmd_settings.menu_text = "Settings"
	cmd_settings.status_bar_text = "Open SU2LUX Settings Window"
	toolbar = toolbar.add_item(cmd_settings)

	toolbar.show  

	load File.join("su2lux","LuxrenderSettings.rb")
	load File.join("su2lux","LuxrenderSettingsEditor.rb")
	load File.join("su2lux","LuxrenderMaterial.rb")
	load File.join("su2lux","LuxrenderMaterialEditor.rb")
	load File.join("su2lux","MeshCollector.rb")
	load File.join("su2lux","LuxrenderExport.rb")
	
	#observers
	Sketchup.add_observer(SU2LUX_app_observer.new)
	Sketchup.active_model.active_view.add_observer(SU2LUX_view_observer.new)
end


file_loaded(__FILE__)

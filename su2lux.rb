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
# Description  : Model exporter and material editor for LuxRender http://www.luxrender.net
# Menu Item    : Plugins\LuxRender Exporter
# Authors      : Abel Groenewolt
#                Alexander Smirnov (aka Exvion)  e-mail: exvion@gmail.com
#                Mimmo Briganti (aka mimhotep)
#                Initially based on SU exporters: SU2KT by Tomasz Marek, Stefan Jaensch,Tim Crandall, 
#                SU2POV by Didier Bur and OGRE exporter by Kojack
# Usage        : Copy script to PLUGINS folder in SketchUp folder, run SketchUp, go to Plugins\LuxRender exporter
# Type         : Exporter

require 'sketchup.rb'
require 'su2lux/fileutils.rb'

module SU2LUX

    # Module constants
    SU2LUX_VERSION = "0.38"
    SU2LUX_DATE = "7 January 2014"
	CONFIG_FILE = "luxrender_path.txt"
	DEBUG = true
	FRONT_FACE_MATERIAL = "SU2LUX Front Face"
	PLUGIN_FOLDER = "su2lux"
	SCENE_EXTENSION = ".lxs"
	SCENE_NAME = "Untitled.lxs"
	SUFFIX_MATERIAL = "-mat.lxm"
	SUFFIX_OBJECT = "-geom.lxo"
	SUFFIX_VOLUME = "-vol.lxv"
    SUFFIX_DISTORTED_TEXTURE = "_SU2LUX_distort"
    PREFIX_DISTORTED_TEXTURE = "SU2LUX_dist_tex_"
    SUFFIX_DATAFOLDER = "_luxdata"
    GEOMETRYFOLDER = "/geometry/"
    TEXTUREFOLDER = "/textures/"

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
        $SU2LUX_model_observer = SU2LUX_model_observer.new
        Sketchup.active_model.add_observer($SU2LUX_model_observer)
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
        @luxconsole_executable = @os_specific_vars["luxconsole_filename"]
		@os_separator = @os_specific_vars["path_separator"]
        @material_preview_path = @os_specific_vars["material_preview_path"]
		
        # create folder and files needed for material preview
        Dir.mkdir(@material_preview_path) unless File.exists?(@material_preview_path)
        required_files = ["preview.lxs01","preview.lxs02","preview.lxs03","ansi.txt"]
        for required_file_name in required_files
            old_path = File.dirname(File.expand_path(__FILE__)) + "\/su2lux\/" + required_file_name
            new_path = os.get_variables["material_preview_path"] + required_file_name
            FileUtils.copy_file(old_path,new_path) unless File.exists?(new_path)
        end
        
	end # END initialize_variables

	##
	# resetting values of all instance variables
	##
	def SU2LUX.reset_variables
		@model_textures={} 
		@texturewriter=Sketchup.create_texture_writer
		@selected=false
		@components = {} #unused
		@export_materials = true #unused
		@export_meshes = true #unused
		@export_lights = true #unused
		@face=0 #unused
		@frame=0 #unused
		@instanced=true #unused
		@lights = [] #unused
		@model_name=""
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
		SU2LUX.reset_variables
		model = Sketchup.active_model
		entities = model.active_entities
		selection = model.selection
		materials = model.materials
		@luxrender_path = SU2LUX.get_luxrender_path # path to LuxRender executable
        # todo: add .lxs if it doesn't end in .lxs
        if File.extname(@lrs.export_file_path) != ".lxs"
            @lrs.export_file_path += ".lxs"
        end
        
        exportpath = @lrs.export_file_path

		      
		le=LuxrenderExport.new(exportpath,@os_separator)
		le.reset
		file_basename = File.basename(exportpath, SCENE_EXTENSION)
		file_dirname = File.dirname(exportpath)
		file_fullname = file_dirname + @os_separator + file_basename
        file_datafolder = file_fullname+SU2LUX::SUFFIX_DATAFOLDER + @os_separator
        
        # create scene data folder
        if !FileTest.exist?(file_fullname+SU2LUX::SUFFIX_DATAFOLDER)
            Dir.mkdir(file_fullname+SU2LUX::SUFFIX_DATAFOLDER)
        end
        
        # copy textures to luxdata folder
        if (@lrs.texexport=="all")
                collectedtextures = []
                puts "EXPORTING ALL TEXTURES"
                # collect material paths
                @material_editor.materials_skp_lux.values.each {|luxmat|
                    for channel in luxmat.texturechannels
                        texturepath = luxmat.send(channel+"_imagemap_filename")
                        if (texturepath != "")
                            collectedtextures << texturepath
                        end
                    end
                }
                destinationfolder = (file_fullname+SU2LUX::SUFFIX_DATAFOLDER)
                for texturepath in collectedtextures.uniq
                    puts "texture found: " + texturepath
                    FileUtils.cp(texturepath,destinationfolder)
                end
        end
        
		#Exporting geometry
		out_geom = File.new(file_datafolder + file_basename  + SUFFIX_OBJECT, "w")
		le.export_mesh(out_geom)
		out_geom.close

		#Exporting all materials
		out_mat = File.new(file_datafolder + file_basename + SUFFIX_MATERIAL, "w")
        relative_datafolder = file_basename+SU2LUX::SUFFIX_DATAFOLDER
        puts "RELATIVE DATA FOLDER: " + relative_datafolder
		le.export_used_materials(materials, out_mat, @lrs.texexport, relative_datafolder)
        le.export_distorted_materials(out_mat, relative_datafolder) # uses materials stored in LuxrenderExport
		out_mat.close
        
        # write lxs file
		out = File.new(exportpath,"w")
		le.export_global_settings(out)
		le.export_camera(model.active_view, out)
		le.export_film(out,file_basename)
		le.export_render_settings(out)
		entity_list=model.entities
		out.puts 'WorldBegin'
		out.puts "Include \"" + file_basename+SU2LUX::SUFFIX_DATAFOLDER + '/' + file_basename + SUFFIX_MATERIAL + "\"\n\n"
		out.puts "Include \"" + file_basename+SU2LUX::SUFFIX_DATAFOLDER + '/' + file_basename + SUFFIX_OBJECT + "\"\n\n"
		le.export_light(out)
		out.puts 'WorldEnd'
		out.close
        
        # write texture files
		le.write_textures
		@count_tri = le.count_tri
	end # END export

	##
	#	 showing the export dialog box
	##
	def SU2LUX.export_dialog(render=true)
        puts "LuxRender export started, running export_dialog function"
        
		"""The argument: 'render' is a boolean which indicates
		whether or not to render the lxs after it has been exported
		"""
		SU2LUX.remove_observers
		SU2LUX.reset_variables
		
		# check whether file path has been set (default path is "")
		if (@lrs.export_file_path != "")
            puts "export_file_path was set"
			start_time = Time.new
			SU2LUX.export
            #launch appropriate report window and render (according to variable: render)
			if render == true
                puts "launching luxrender"
				result = SU2LUX.report_window(start_time, ask_render=true)
				SU2LUX.launch_luxrender if result == 6
			else if render == false
                puts "not launching luxrender"
				SU2LUX.report_window(start_time, ask_render=false)
				end
			end
		
		else # set new export file path
            puts "export_file_path was not set"
			saved = SU2LUX.new_export_file_path
			if saved
				start_time = Time.new
				SU2LUX.export
			
                #launch appropriate report window and render (according to variable: render)
				if render == true
                    puts "export_file_path was not set, launching luxrender"
					result = SU2LUX.report_window(start_time, ask_render=true)
					SU2LUX.launch_luxrender if result == 6
                else if render == false
                    puts "export_file_path was not set, not launching luxrender"
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

		old_export_file_path = @lrs.export_file_path
		
		SU2LUX.new_export_file_path
		SU2LUX.export_dialog(render=false) # don't render
		
		@lrs.export_file_path = old_export_file_path
	end # END export_copy

#### Some Dialogs (colour select, browse file path, etc..)###########
#####################################################################

	##
	#
	##
	def SU2LUX.new_export_file_path # browses for a new export file path and sets it in the lxs settings
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
			@lrs.export_file_path = user_input
				
			if @lrs.export_file_path == @lrs.export_file_path.chomp(SCENE_EXTENSION)
				@lrs.export_file_path += SCENE_EXTENSION
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
	end

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
	end

	##
	#   get LuxRender path, prompt user if it hasn't been defined
	##
	def SU2LUX.get_luxrender_path
		storedpath = Sketchup.read_default("SU2LUX","luxrenderpath")
		if (storedpath.nil?)
			# prompt user for path
			storedpath = UI.openpanel("Locate LuxRender", "", "")
			Sketchup.write_default("SU2LUX", "luxrenderpath", storedpath.unpack('H*')[0])
        else
            # convert path back to usable form
            storedpath = storedpath.to_a.pack('H*')
		end
		return storedpath
	end #END get_luxrender_path

	##
	#
	##
	def SU2LUX.change_luxrender_path 
		# set path
		providedpath = UI.openpanel("Locate LuxRender", "", "")
		# provide feedback in popup window
		message = ""
		if SU2LUX.luxrender_path_valid?(providedpath)
			@luxrender_path = providedpath
			Sketchup.write_default("SU2LUX", "luxrenderpath", providedpath.unpack('H*')[0])
			message = "New path for LuxRender is : #{@luxrender_path}"
            # result = UI.messagebox(message,MB_OK)
		else
			@luxrender_path = nil
			message = "No valid path selected."
            result = UI.messagebox(message,MB_OK)
		end	
		# store settings
		@lrs.export_luxrender_path = @luxrender_path
        # update path in settings window
        cmd = "document.getElementById('export_luxrender_path').value='" + @luxrender_path + "'"
        @settings_editor.settings_dialog.execute_script(cmd)
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
			result=UI.messagebox(export_text + @lrs.export_file_path +  " \n\nOpen exported model in LuxRender?",MB_YESNO)
		else
			result=UI.messagebox(export_text + @lrs.export_file_path,MB_OK)
		end
		return result
	end # END report_window

    ##
    #
    ##
    def SU2LUX.luxrender_path_valid?(luxrender_path)
        (! luxrender_path.nil? and File.exist?(luxrender_path) and (File.basename(luxrender_path).upcase.include?("LUXRENDER")))
    end #END luxrender_path_valid?
  
	##
	#
	##
	def SU2LUX.launch_luxrender
        @luxrender_path = SU2LUX.get_luxrender_path if @luxrender_path.nil?
		return if @luxrender_path.nil?
		Dir.chdir(File.dirname(@luxrender_path))
		export_path = "#{@lrs.export_file_path}"
		export_path = File.join(export_path.split(@os_separator))
		if (ENV['OS'] =~ /windows/i)
		 command_line = "start \"max\" \/#{@lrs.priority} \"#{@luxrender_path}\" \"#{export_path}\""
		 puts command_line
		 system(command_line)
        else
            fullpath = @luxrender_path + @os_specific_vars["file_appendix"]
			Thread.new do
				system(`#{fullpath} "#{export_path}"`)
			end
		end
	end # END launch_luxrender

	##
	#
	##
	def SU2LUX.get_luxrender_console_path
		path=SU2LUX.get_luxrender_path
        # puts "get_luxrender_path returned:"
        # puts path
		return nil if not path
		root=File.dirname(path)
		c_path=File.join(root,@luxconsole_executable)
        # puts "c_path is:"
        # puts c_path
		if FileTest.exist?(c_path)
			return c_path
		else
            UI.messagebox("cannot find luxconsole")
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
		if @material_editor
            SU2LUX.dbg_p "reusing existing material editor"
        else
            SU2LUX.dbg_p "creating new material editor"
			@material_editor=LuxrenderMaterialEditor.new
		end
        
        @material_editor.set_material_lists

        if @material_editor.visible?
			puts "hiding material editor"
			@material_editor.hide
            #@material_editor_dialog.close
		else
			puts "showing material editor"
			@material_editor.show
			puts "setting active material"
			Sketchup.active_model.materials.current = Sketchup.active_model.materials.current 
			puts "done setting active material"
		end
		
    # set preview section height (OS X; for Windows this gets done in refresh function)
    setdivheightcmd = 'setpreviewheight(' + @lrs.preview_size.to_s + ',' + @lrs.preview_time.to_s + ')'
    puts setdivheightcmd
    @material_editor.material_editor_dialog.execute_script(setdivheightcmd)
        
        
	end # END show_material_editor

	##
	#
	##
	def SU2LUX.create_material_editor
		if not @material_editor
			@material_editor=LuxrenderMaterialEditor.new
		end
		return @material_editor
	end # END create_material_editor

	##
	#
	##
	def SU2LUX.show_settings_editor
        puts "show settings editor"
        puts @settings_editor
		if not @settings_editor
			@settings_editor=LuxrenderSettingsEditor.new
		end
        if @settings_editor.visible?
            puts "hiding settings editor"
            @settings_editor.close
        else
            puts "showing settings editor"
            @settings_editor.show
        end
    end # END show_settings_editor

	##
	#
	##
	def SU2LUX.about
		UI.messagebox("SU2LUX, SketchUp Exporter to LuxRender
version #{SU2LUX::SU2LUX_VERSION}, #{SU2LUX::SU2LUX_DATE}

Authors:
Abel Groenewolt (aka pistepilvi)
Alexander Smirnov (aka Exvion)
Luke Frisken (aka lfrisken)
Martijn Berger (aka Juicyfruit)
Mimmo Briganti (aka mimhotep)
    
SU2LUX makes use of the jQuery library and the Farbtastic color picker.

For further information please visit LuxRender's Website & Forum at www.luxrender.net" , MB_MULTILINE , "SU2LUX - Sketchup Exporter to LuxRender")
	end # END

	##
	#
	##
	def SU2LUX.get_editor(type)
		case type
			when "settings"
                if @settings_editor
                      editor = @settings_editor
                else
                      editor = LuxrenderSettingsEditor.new
                end
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
                      
class SU2LUX_model_observer < Sketchup::ModelObserver
    def onPreSaveModel(model)
        # for all materials, save settings
        mateditor = SU2LUX.get_editor("material")
        mateditor.materials_skp_lux.each do |skpmat, luxmat|
            luxmat.save_to_model()
        end
        # for settings window, save settings
        @lrs = LuxrenderSettings.new
        @lrs.save_to_model
    end
                      
end
                      
                      
class SU2LUX_view_observer < Sketchup::ViewObserver

	include SU2LUX

	def onViewChanged(view)
		settings_editor = SU2LUX.get_editor("settings")
		@lrs = LuxrenderSettings.new
        # if not environment:
        if (@lrs.camera_type != 'environment')
            if Sketchup.active_model.active_view.camera.perspective?
			    @lrs.camera_type = 'perspective'
			    # camera_type = 'perspective'
		    else
			    @lrs.camera_type = 'orthographic'
			    # camera_type = 'orthographic'
            end
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
		SU2LUX.initialize_variables
		@lrs = LuxrenderSettings.new
		loaded = @lrs.load_from_model
		@lrs.reset unless loaded    
		@lrs.fleximage_xresolution = Sketchup.active_model.active_view.vpwidth
		@lrs.fleximage_yresolution = Sketchup.active_model.active_view.vpheight
		
		settings_editor = SU2LUX.get_editor("settings")
		if (settings_editor && settings_editor.visible?)
			settings_editor.setValue("xresolution", @lrs.fleximage_xresolution)
			settings_editor.setValue("yresolution", @lrs.fleximage_yresolution)
			settings_editor.close
		end

		Sketchup.active_model.materials.current = Sketchup.active_model.materials[0]
		SU2LUX.create_material_editor
		material_editor = SU2LUX.get_editor("material")
		material_editor.materials_skp_lux = Hash.new
		material_editor.current = nil
		material_editor.refresh

		SU2LUX.create_observers	
		
	end # END onNewModel

	def onOpenModel(model)
		SU2LUX.create_observers
		@lrs = LuxrenderSettings.new
		settings_editor = SU2LUX.get_editor("settings")
		if(settings_editor && settings_editor.visible?)
			settings_editor.close
		end

		# loaded = LuxrenderAttributeDictionary.load_from_model(@lrs.dictionary_name)
		
        loaded = @lrs.load_from_model
		@lrs.reset unless loaded
                      
        SU2LUX.create_material_editor
        material_editor = SU2LUX.get_editor("material")
        material_editor.materials_skp_lux = Hash.new
        material_editor.current = nil
                    
		for mat in model.materials
			luxmat = LuxrenderMaterial.new(mat)
			loaded = luxmat.load_from_model
            #luxmat.reset unless loaded
            material_editor.materials_skp_lux[mat] = luxmat
		end
              
        material_editor.refresh
		if (material_editor.visible?)
			material_editor.close
		end
		puts "running onOpenModel, about to run refresh material_editor"

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
		material_editor = SU2LUX.get_editor("material")
		SU2LUX.dbg_p "onMaterialSetCurrent triggered by material #{material.name}"
		
		current_mat = material #Sketchup.active_model.materials.current
		# puts "current_mat", current_mat
		
		if (Sketchup.active_model.materials.include? current_mat)
			if material_editor.materials_skp_lux.include?(current_mat)
				material_editor.current = material_editor.materials_skp_lux[current_mat]
				puts "onMaterialSetCurrent reusing LuxRender material "
			else
				material_editor.refresh()
				#material_editor.current = LuxrenderMaterial.new(current_mat)
				#material_editor.materials_skp_lux[current_mat] = material_editor.current 
				#puts "onMaterialSetCurrent creating new LuxRender material" # , material_editor.current
			end
			material_editor.set_current(material_editor.current.name) # sets name of current material in dropdown, updates swatches
			material_editor.sendDataFromSketchup
            material_editor.settexturefields(current_mat.name)
            material_editor.showhideIOR()
			material_editor.fire_event("#type", "change", "")
			material_editor.load_preview_image()
		else
			puts "current material is not used"
		end
	end
	
    def onMaterialAdd(materials, material)
        puts "onMaterialAdd added material: ", material.name
		# adding a material will set it current, onMaterialSetCurrent will take over
        # except on OS X
        if (SU2LUX.get_os == :mac)
            puts "CREATING NEW MATERIAL"
            material_editor = SU2LUX.get_editor("material")
            newmaterial = material_editor.find(material.name)
            if (material.texture)
                newmaterial.kd_texturetype = "sketchup"
            end
            material_editor.refresh()
        end
	end

    def onMaterialRemove(materials, material)
        SU2LUX.dbg_p "onMaterialRemove triggered"
        material_editor = SU2LUX.create_material_editor # reuses material editor if it exists
        material_editor.materials_skp_lux.delete(material)
		material_editor.refresh() if (material_editor);
	end
	
	def onMaterialChange(materials, material)
        puts "observer catching SketchUp material change"
		material_editor = SU2LUX.get_editor("material")
        if (material_editor && material_editor.materials_skp_lux.include?(material))
            # test if material name exists; if not, follow name_changed logic
            material_editor.matname_changed = true
            material_editor.materials_skp_lux.values.each{|luxmat|
                # puts luxmat.name_string, material.name, luxmat.name_string==material.name
                if luxmat.name_string==material.name
                  material_editor.matname_changed = false
                end
            }
            #puts "@matname_changed: ", material_editor.matname_changed
            
			## deal with material name change
            if (material_editor.matname_changed == true)
                puts "onMaterialChange triggered by material name change"
                material_editor.current.name_string = material.name.to_s
                material_editor.matname_changed = false
                material_editor.set_material_lists()
                material_editor.set_current(material_editor.current.name)
            else ## deal with other material changes
                puts "onMaterialChange triggered SU2LUX material editor or SketchUp material editor"
                luxmaterial = material_editor.materials_skp_lux[material]
                    
                # if color has changed significantly (>1/255), update luxmat colors
                skpR = material.color.red
                skpG = material.color.green
                skpB = material.color.blue
                luxR = 255.0 * luxmaterial.kd_R.to_f
                luxG = 255.0 * luxmaterial.kd_G.to_f
                luxB = 255.0 * luxmaterial.kd_B.to_f
                puts skpR, skpG, skpB, luxR, luxG, luxB
                updateswatches = false
                if ((skpR-luxR).abs > 1 || (skpG-luxG).abs > 1 || (skpB-luxB).abs > 1)
                    luxmaterial.color = material.color
                    updateswatches = true
                    colorarray=[skpR/255.0,skpG/255.0,skpB/255.0]
                end

                if material.texture
                    puts "material has a texture"
                    texture_name = material.texture.filename
                    texture_name.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
                    texture_name.gsub!(/\\/, '/') if texture_name.include?('\\')
                    luxmaterial.kd_imagemap_Sketchup_filename = texture_name
                    luxmaterial.kd_texturetype = 'sketchup' if (luxmaterial.kd_texturetype != 'imagemap')
                    luxmaterial.use_diffuse_texture = true
                else
                    luxmaterial.kd_imagemap_Sketchup_filename = ''
                    if (luxmaterial.kd_texturetype == 'sketchup') # todo: check if non-sketchup texture is being used
                        luxmaterial.kd_texturetype = 'none'
                        luxmaterial.current.use_diffuse_texture = false
                    end
                end
                      
                if material_editor.materials_skp_lux[material] == material_editor.current
                      puts "modified material is current"
                      material_editor.updateSettingValue("kd_imagemap_Sketchup_filename")
                      material_editor.updateSettingValue("kd_texturetype")
                      material_editor.updateSettingValue("use_diffuse_texture")
                      if (updateswatches == true)
                        material_editor.material_editor_dialog.execute_script("update_RGB('#kt_R','#kt_G','#kt_B','#{colorarray[0]}','#{colorarray[1]}','#{colorarray[2]}')")
                        material_editor.material_editor_dialog.execute_script("update_RGB('#kd_R','#kd_G','#kd_B','#{colorarray[0]}','#{colorarray[1]}','#{colorarray[2]}')")
                      end
                      material_editor.update_swatches()
                else
                      puts "modified material is not current"
                end
            end
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
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderMeshCollector.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderExport.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "LuxrenderToolbar.rb")
	load File.join(SU2LUX::PLUGIN_FOLDER, "SU2LUX_UV.rb")

	SU2LUX.initialize_variables
    
    create_toolbar()
	create_context_menu()
  	
	Sketchup.active_model.materials.current = Sketchup.active_model.materials[0]

	@lrs = LuxrenderSettings.new
	loaded = @lrs.load_from_model
	@lrs.reset unless loaded                      
	for mat in Sketchup.active_model.materials
		luxmat = LuxrenderMaterial.new(mat)
		loaded = luxmat.load_from_model
		luxmat.reset unless loaded
	end
                      
    @lrs.export_luxrender_path = Sketchup.read_default("SU2LUX","luxrenderpath").to_a.pack('H*') # copy stored executable path to settings, so it shows in settings window
                      
	@lme = SU2LUX.create_material_editor
	material_editor = SU2LUX.get_editor("material")
    SU2LUX.dbg_p "material editor created, now starting refresh function"
	material_editor.refresh
	#observers
	$SU2LUX_app_observer = SU2LUX_app_observer.new
	Sketchup.add_observer($SU2LUX_app_observer)
	SU2LUX.create_observers	
end


file_loaded(__FILE__)

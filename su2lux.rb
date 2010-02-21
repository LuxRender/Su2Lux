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
	DEBUG = false
	FRONTF = "SU2LUX Front Face"
	SCENE_NAME = "Untitled.lxs"
	EXT_SCENE = ".lxs"
	SUFFIX_MATERIAL = "-mat.lxm"
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
def SU2LUX.reset_variables
	@n_pointlights=0
	@n_spotlights=0
	@n_cameras=0
	@face=0
	@scale = 0.0254
	@copy_textures = true
	@export_materials = true
	@export_meshes = true
	@export_lights = true
	@instanced=true
	@model_name=""
	@textures_prefix = "TX_"
	@texturewriter=Sketchup.create_texture_writer
	@model_textures={}
	@count_tri = 0
	@count_faces = 0
	@lights = []
	@materials = {}
	@fm_materials = {}
	@components = {}
	@selected=false
	@exp_distorted = false
	@exp_default_uvs = false
	@clay=false
	@animation=false
	@export_full_frame=false
	@frame=0
	@parent_mat=[]
	@fm_comp=[]
	@status_prefix = ""   # Identifies which scene is being processed in status bar
	@scene_export = false # True when exporting a model for each scene
	@status_prefix=""
	#Changed Windows separator from "\/" to "\\"
#	@os_separator = (ENV['OS'] =~ /windows/i) ? "\\" : "/" # directory separator for Windows : OS X
	@os_separator = on_mac? ? "/" : "\\"
	@luxrender_path = ""
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
	@luxrender_path = SU2LUX.get_luxrender_path
	SU2LUX.file_export_window
	out = File.new(@export_file_path,"w")
	start_time = Time.new
	SU2LUX.export_global_settings(out)
	SU2LUX.export_camera(model.active_view, out)
	SU2LUX.export_film(out)
	SU2LUX.export_render_settings(out)
	entity_list=model.entities
	out.puts 'WorldBegin'
	SU2LUX.export_light(out)
	file_basename = File.basename(@export_file_path, EXT_SCENE)
	out.puts "Include \"" + file_basename + SUFFIX_MATERIAL + "\"\n\n"
	out.puts "Include \"" + file_basename + SUFFIX_OBJECT + "\"\n\n"
	out.puts 'WorldEnd'
	SU2LUX.finish_close(out)

	file_dirname = File.dirname(@export_file_path)
	file_fullname = file_dirname + @os_separator + file_basename
	
	#Exporting geometry
	out_geom = File.new(file_fullname + SUFFIX_OBJECT, "w")
	SU2LUX.export_mesh(out_geom)
	SU2LUX.finish_close(out_geom)

	#Exporting all materials
	out_mat = File.new(file_fullname + SUFFIX_MATERIAL, "w")
	SU2LUX.export_used_materials(materials, out_mat)
	SU2LUX.finish_close(out_mat)
	
	result = SU2LUX.report_window(start_time)
	SU2LUX.launch_luxrender if result == 6
end

#####################################################################
#####################################################################
def SU2LUX.file_export_window
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
	
	@export_file_path = UI.savepanel("Save lxs file", export_folder, export_filename)
	#export default folder and filename instead
	if @export_file_path.nil?
		if ! File.exists?(default_folder + @os_separator + DEFAULT_FOLDER)
			Dir.mkdir(default_folder + @os_separator + DEFAULT_FOLDER)
		end
		@export_file_path = export_folder + @os_separator + DEFAULT_FOLDER + @os_separator + export_filename
	end

	if @export_file_path == @export_file_path.chomp(EXT_SCENE)
		@export_file_path += EXT_SCENE
	end
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
		luxrender_path = path + @os_separator + SU2LUX.get_luxrender_filename
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
		luxrender_path = mac_path + @os_separator + SU2LUX.get_luxrender_filename
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
def SU2LUX.report_window(start_time)
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
	result=UI.messagebox export_text + @export_file_path +  " \n\nOpen exported model in Luxrender?",MB_YESNO
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
def SU2LUX.export_light(out)
   	sun_direction = Sketchup.active_model.shadow_info['SunDirection']
	sunsky = <<-eos
AttributeBegin
	LightGroup "default"
	LightSource "sunsky"
	"float gain" [1.000000]
	"vector sundir" [#{sun_direction.x} #{sun_direction.y} #{sun_direction.z}]

	"float relsize" [1.000000]
	"float turbidity" [2.200000]
AttributeEnd

	eos
	out.puts sunsky
end

#####################################################################
#####################################################################
def SU2LUX.export_used_materials(materials, out)
	materials.each { |mat|
		luxrender_mat = LuxrenderMaterial.new(mat)
		p_debug luxrender_mat.name
		SU2LUX.export_mat(luxrender_mat, out)
	}
end

#####################################################################
#####################################################################
def SU2LUX.export_mat(mat, out)
	SU2LUX.p_debug "export_mat"
	out.puts "# Material '" + mat.name + "'"
	case mat.type
		when "matte", "glass"
		out.puts "MakeNamedMaterial \"" + mat.name + "\""
		SU2LUX.p_debug "mat.name " + mat.name
		out.puts  "\"string type\" [\"matte\"]"
		out.puts  "\"color Kd\" [#{"%.6f" %(mat.color.red.to_f/255)} #{"%.6f" %(mat.color.green.to_f/255)} #{"%.6f" %(mat.color.blue.to_f/255)}]"  #"%.6f" %(user_up.y)
		when "light"
		out.puts "Texture \"" + mat.name + ":light:L\" \"color\" \"blackbody\"
			\"float temperature\" [6500.000000]"
	end
	out.puts("\n")
end

#####################################################################
#####################################################################
def SU2LUX.export_mesh(out)
	SU2LUX.collect_faces(Sketchup.active_model.entities, Geom::Transformation.new)
	@current_mat_step = 1
	SU2LUX.export_faces(out)
	SU2LUX.export_fm_faces(out)
end

#####################################################################
###### - Send text to status bar - 										######
#####################################################################
def SU2LUX.status_bar(stat_text)
	
	statbar = Sketchup.set_status_text stat_text
	
end

#####################################################################
#####################################################################
def SU2LUX.export_global_settings(out)
	out.puts "# Lux Render Scene File"
	out.puts "# Exported by SU2LUX 0.1-devel"
	out.puts "# Global Information"
end

  # -----------Extract the camera parameters of the current view ------------------------------------

#####################################################################
#####################################################################
def SU2LUX.export_camera(view, out)
	@lrs=LuxrenderSettings.new

	user_camera = view.camera
	user_eye = user_camera.eye
	#p user_eye
	user_target=user_camera.target
	#p user_target
	user_up=user_camera.up
	#p user_up;
	out_user_target = "%12.6f" %(user_target.x.to_m.to_f) + " " + "%12.6f" %(user_target.y.to_m.to_f) + " " + "%12.6f" %(user_target.z.to_m.to_f)

	out_user_up = "%12.6f" %(user_up.x) + " " + "%12.6f" %(user_up.y) + " " + "%12.6f" %(user_up.z)

	out.puts "LookAt"
	out.puts "%12.6f" %(user_eye.x.to_m.to_f) + " " + "%12.6f" %(user_eye.y.to_m.to_f) + " " + "%12.6f" %(user_eye.z.to_m.to_f)
	out.puts out_user_target
	out.puts out_user_up
	out.print "\n"

	fov = SU2LUX.compute_fov(@lrs.xresolution, @lrs.yresolution)
	case @lrs.camera_type
		when "perspective"
			out.puts "Camera \"#{@lrs.camera_type}\""
			out.puts "	\"float fov\" [%.6f" %(fov) + "]"
		when "orthographic"
			out.puts "Camera \"#{@lrs.camera_type}\""
		when "environment"
			out.puts "Camera \"#{@lrs.camera_type}\""
	end
	
	sw = SU2LUX.compute_screen_window
	out.puts	"\t\"float screenwindow\" [" + "%.6f" %(sw[0]) + " " + "%.6f" %(sw[1]) + " " + "%.6f" %(sw[2]) + " " + "%.6f" %(sw[3]) +"]\n"
	#TODO  depends aspect_ratio and resolution 
	#http://www.luxrender.net/wiki/index.php?title=Scene_file_format#Common_Camera_Parameters
			
	out.print "\n"
end

#####################################################################
#####################################################################
def SU2LUX.export_film(out)
	out.puts "Film \"fleximage\""
	out.puts "\t\"integer xresolution\" [#{@lrs.xresolution}]"
	out.puts "\t\"integer yresolution\" [#{@lrs.yresolution}]"
	out.puts "\t\"integer haltspp\" [#{@lrs.haltspp}]"
	
	out.puts '
	"bool premultiplyalpha" ["false"]
   "string tonemapkernel" ["reinhard"]
   "float reinhard_prescale" [1.000000]
   "float reinhard_postscale" [1.200000]
   "float reinhard_burn" [6.000000]
   "integer displayinterval" [4]
   "integer writeinterval" [10]
   "string ldr_clamp_method" ["lum"]
   "bool write_exr" ["false"]
   "bool write_png" ["true"]
   "string write_png_channels" ["RGB"]
   "bool write_png_16bit" ["false"]
   "bool write_png_gamutclamp" ["true"]
   "bool write_tga" ["false"]
   "string filename" ["exported_image"]
   "bool write_resume_flm" ["false"]
   "bool restart_resume_flm" ["true"]
   "integer reject_warmup" [128]
   "bool debug" ["true"]
   "float colorspace_white" [0.314275 0.329411]
   "float colorspace_red" [0.630000 0.340000]
   "float colorspace_green" [0.310000 0.595000]
   "float colorspace_blue" [0.155000 0.070000]
   "float gamma" [2.200000]'
end

#####################################################################
#####################################################################
def SU2LUX.compute_fov(xres, yres)
	fov_vertical = @lrs.fov.to_f
	fov_vertical_rad = fov_vertical * Math::PI / 180.0
	# height = Float(Sketchup.active_model.active_view.vpheight)
	# width = Float(Sketchup.active_model.active_view.vpwidth)
	width = xres.to_f
	height = yres.to_f
	focal_distance = 0.5 * height / Math.tan(0.5 * fov_vertical_rad)

	fov_horizontal_rad = 2.0 * Math.atan2(0.5 * width, focal_distance)
	fov_horizontal = fov_horizontal_rad * 180.0 / Math::PI
	if(width >= height)
		fov = fov_vertical
	else
		fov = fov_horizontal
	end
	SU2LUX.p_debug fov_vertical
	SU2LUX.p_debug fov_horizontal
	return fov
end

#####################################################################
#####################################################################
def SU2LUX.compute_screen_window
	ratio = @lrs.xresolution.to_f / @lrs.yresolution.to_f
	inv_ratio = 1.0 / ratio
	if (ratio > 1.0)
		screen_window = [-ratio, ratio, -1.0, 1.0]
	else
		screen_window = [-1.0, 1.0, -inv_ratio, inv_ratio]
	end
end

#####################################################################
#####################################################################
def SU2LUX.export_render_settings(out)
	@lrs=LuxrenderSettings.new
	
	#pixel filter
	out.print "\n"
	out.print "PixelFilter \"#{@lrs.pixelfilter_type}\"\n"
	case @lrs.pixelfilter_type
		when "box"
		when "gaussian"
		when "mitchell"
			out.print "	\"float xwidth\" [#{@lrs.pixelfilter_mitchell_xwidth}]\n"
			out.print "	\"float ywidth\" [#{@lrs.pixelfilter_mitchell_ywidth}]\n"
		when "sinc"
		when "triangle"
	end

	#sampler
	out.print "\n"
	out.print "Sampler \"#{@lrs.sampler_type}\"\n"
	case @lrs.sampler_type
		when "metropolis"
			out.puts '"float largemutationprob" [0.400000]'
		when "lowdiscrepancy"
			out.puts '"string pixelsampler" ["lowdiscrepancy"]
			"integer pixelsamples" [1]'
	end

	# SurfaceIntegrator "bidirectional"
	out.print "\n"
	out.puts "SurfaceIntegrator \"#{@lrs.sintegrator_type}\"\n"
	case @lrs.sintegrator_type
		when "bidirectional"
			if @lrs.sintegrator_showadvanced
				out.print "   \"integer eyedepth\" [#{@lrs.sintegrator_bidir_eyedepth}]\n"
				out.print "   \"integer lightdepth\" [#{@lrs.sintegrator_bidir_lightdepth}]\n"
				out.print "   \"string strategy\" [\"#{@lrs.sintegrator_bidir_strategy}\"]\n"
				out.puts '"   float eyerrthreshold" [0.000000]'
				out.puts '"   float lightrrthreshold" [0.000000]'
			else
				out.print "	\"integer eyedepth\" [#{@lrs.sintegrator_bidir_bounces}]\n"
				out.print "	\"integer lightdepth\" [#{@lrs.sintegrator_bidir_bounces}]\n"
			end
		when 'path'
			if @lrs.sintegrator_showadvanced
				out.print "	\"integer maxdepth\" [#{@lrs.sintegrator_path_maxdepth}]\n"
				#"integer maxdepth" [10]
				#"bool includeenvironment" ["true"]
			else
				 #  "integer maxdepth" [10]
				#	"string strategy" ["auto"]
				#	"string rrstrategy" ["efficiency"]
				#	"bool includeenvironment" ["true"]
			end
		when "distributedpath"
			out.puts '   "bool directsampleall" ["true"]' if @lrs.sintegrator_distributedpath_directsampleall
			out.puts '   "bool directsampleall" ["false"]' if not @lrs.sintegrator_distributedpath_directsampleall
			out.print "   \"integer directsamples\" [#{@lrs.sintegrator_distributedpath_directsamples}]\n"
			out.puts '   "bool directdiffuse" ["true"]' if @lrs.sintegrator_distributedpath_directdiffuse
			out.puts '   "bool directdiffuse" ["false"]' if not @lrs.sintegrator_distributedpath_directdiffuse
			out.puts '   "bool directglossy" ["true"]' if @lrs.sintegrator_distributedpath_directglossy
			out.puts '   "bool directglossy" ["false"]' if not @lrs.sintegrator_distributedpath_directglossy
			out.puts '   "bool indirectsampleall" ["true"]' if @lrs.sintegrator_distributedpath_indirectsampleall
			out.puts '   "bool indirectsampleall" ["false"]' if not @lrs.sintegrator_distributedpath_indirectsampleall
			out.print "   \"integer indirectsamples\" [#{@lrs.sintegrator_distributedpath_indirectsamples}]\n"
			out.puts '   "bool indirectdiffuse" ["true"]' if @lrs.sintegrator_distributedpath_indirectdiffuse
			out.puts '   "bool indirectdiffuse" ["false"]' if not @lrs.sintegrator_distributedpath_indirectdiffuse
			out.puts '   "bool indirectglossy" ["true"]' if @lrs.sintegrator_distributedpath_indirectglossy
			out.puts '   "bool indirectglossy" ["false"]' if not @lrs.sintegrator_distributedpath_indirectglossy
			out.print "   \"integer diffusereflectdepth\" [#{@lrs.sintegrator_distributedpath_diffusereflectdepth}]\n"
			out.print "   \"integer diffusereflectsamples\" [#{@lrs.sintegrator_distributedpath_diffusereflectsamples}]\n"
			out.print "   \"integer diffuserefractdepth\" [#{@lrs.sintegrator_distributedpath_diffuserefractdepth}]\n"
			out.print "   \"integer diffuserefractsamples\" [#{@lrs.sintegrator_distributedpath_diffuserefractsamples}]\n"
			out.print "   \"integer glossyreflectdepth\" [#{@lrs.sintegrator_distributedpath_glossyreflectdepth}]\n"
			out.print "   \"integer glossyreflectsamples\" [#{@lrs.sintegrator_distributedpath_glossyreflectsamples}]\n"
			out.print "   \"integer glossyrefractdepth\" [#{@lrs.sintegrator_distributedpath_glossyrefractdepth}]\n"
			out.print "   \"integer glossyrefractsamples\" [#{@lrs.sintegrator_distributedpath_glossyrefractsamples}]\n"
			out.print "   \"integer specularreflectdepth\" [#{@lrs.sintegrator_distributedpath_specularreflectdepth}]\n"
			out.print "   \"integer specularrefractdepth\" [#{@lrs.sintegrator_distributedpath_specularrefractdepth}]\n"
			out.puts '   "bool directglossy" ["true"]' if @lrs.sintegrator_distributedpath_causticsonglossy
			out.puts '   "bool directglossy" ["false"]' if not @lrs.sintegrator_distributedpath_causticsonglossy
			out.puts '   "bool indirectglossy" ["true"]' if @lrs.sintegrator_distributedpath_causticsondiffuse
			out.puts '   "bool indirectglossy" ["false"]' if not @lrs.sintegrator_distributedpath_causticsondiffuse
			out.print "   \"string strategy\" [\"#{@lrs.sintegrator_distributedpath_strategy}\"]\n"
		when "directlighting"
			out.print "	\"integer maxdepth\" [#{@lrs.sintegrator_dlighting_maxdepth}]"
		when "exphotonmap"
			p "select exphotonmap"
		when "igi"
			p "select igi"
	end
	
	#VolumeIntegrator
	out.print "\n"
	out.print "VolumeIntegrator \"#{@lrs.volume_integrator_type}\"\n"
	#VolumeIntegrator
	case @lrs.volume_integrator_type
		when "single"  
			out.puts '"float stepsize" [1.000000]'
		when "emission"
			out.puts '"float stepsize" [1.000000]'
	end

   
	#accelerator
	out.print "\n"
	out.print "Accelerator \"#{@lrs.accelerator_type}\"\n"
	case @lrs.accelerator_type
		when "kdtree"
		when "grid"
			out.puts '	"bool refineimmediately" ["false"]'
	end


  end


#####################################################################
###### - collect entities to an array -						 		######
#####################################################################
def SU2LUX.collect_faces(object, trans)

	if object.class == Sketchup::ComponentInstance
		entity_list=object.definition.entities
	elsif object.class == Sketchup::Group
		entity_list=object.entities
	else
		entity_list=object
	end

	SU2LUX.p_debug "entity count="+entity_list.count.to_s

	text=""
	text="Component: " + object.definition.name if object.class == Sketchup::ComponentInstance
	text="Group" if object.class == Sketchup::Group
	
	SU2LUX.status_bar("Collecting Faces - Level #{@parent_mat.size} - #{text}")

	for e in entity_list
	  
		if (e.class == Sketchup::Group and e.layer.visible?)
			SU2LUX.get_inside(e,trans,false) #e,trans,false - not FM component
		end
		if (e.class == Sketchup::ComponentInstance and e.layer.visible? and e.visible?)
			SU2LUX.get_inside(e,trans,e.definition.behavior.always_face_camera?) # e,trans, fm_component?
		end
		if (e.class == Sketchup::Face and e.layer.visible? and e.visible?)
			
			face_properties=SU2LUX.find_face_material(e)
			mat=face_properties[0]
			uvHelp=face_properties[1]
			mat_dir=face_properties[2]

			if @fm_comp.last==true
				(@fm_materials[mat] ||= []) << [e,trans,uvHelp,mat_dir]
			else
				(@materials[mat] ||= []) << [e,trans,uvHelp,mat_dir] if (@animation==false or (@animation and @export_full_frame))
			end
			@count_faces+=1
		end
	end  
end

#####################################################################
#####################################################################
def SU2LUX.find_face_material(e)
	mat = Sketchup.active_model.materials[FRONTF]
	mat = Sketchup.active_model.materials.add FRONTF if mat.nil?
	front_color = Sketchup.active_model.rendering_options["FaceFrontColor"]
	scale = 0.8 / 255.0
	mat.color = Sketchup::Color.new(front_color.red * scale, front_color.green * scale, front_color.blue * scale)
	uvHelp=nil
	mat_dir=true
	if e.material!=nil
		mat=e.material
	else
		if e.back_material!=nil
			mat=e.back_material
			mat_dir=false
		else
			mat=@parent_mat.last if @parent_mat.last!=nil
		end
	end

	# if (mat.respond_to?(:texture) and mat.texture !=nil)
		# ret=SU2KT.store_textured_entities(e,mat,mat_dir)
		# mat=ret[0]
		# uvHelp=ret[1]
	# end

	return [mat,uvHelp,mat_dir]
end
  
  
#####################################################################
#####################################################################
def SU2LUX.get_inside(e,trans,face_me)
	@fm_comp.push(face_me)
	if e.material != nil
		mat = e.material
		@parent_mat.push(e.material)
		#SU2KT.store_textured_entities(e,mat,true) if (mat.respond_to?(:texture) and mat.texture!=nil)
	else
		@parent_mat.push(@parent_mat.last)
	end
	SU2LUX.collect_faces(e, trans*e.transformation)
	@parent_mat.pop
	@fm_comp.pop
end
  

#####################################################################
#####################################################################
def SU2LUX.export_faces(out)
	@materials.each{|mat,value|
		if (value!=nil and value!=[])
			SU2LUX.export_face(out,mat,false)
			@materials[mat]=nil
		end}
	@materials={}
end

#####################################################################
#####################################################################
def SU2LUX.export_fm_faces(out)
	@fm_materials.each{|mat,value|
		if (value!=nil and value!=[])
			SU2LUX.export_face(out,mat,true)
			@fm_materials[mat]=nil
		end}
	@fm_materials={}
end


#####################################################################
#####################################################################
def SU2LUX.point_to_vector(p)
	Geom::Vector3d.new(p.x,p.y,p.z)
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
#####################################################################
def SU2LUX.export_face(out,mat,fm_mat)
	SU2LUX.p_debug "export face"
	meshes = []
	polycount = 0
	pointcount = 0
	mirrored=[]
	mat_dir=[]
	default_mat=[]
	distorted_uv=[]
	
	if fm_mat
		export=@fm_materials[mat]
	else
		export=@materials[mat]
	end
	
	has_texture = false
	if mat.respond_to?(:name)
		matname = mat.display_name.gsub(/[<>]/,'*')
		# has_texture = true if mat.texture!=nil
	else
		matname = "Default"
		# has_texture=true if matname!=FRONTF
	 end
	
	matname="FM_"+matname if fm_mat

	#if mat
	 #  matname = mat.display_name
	  # p "matname="+matname
	  # matname=matname.gsub(/[<>]/, '*')
	  # if mat.texture
		# has_texture = true
	  # end
	 #else
	  # matname = "Default"
	 #end
	
	#matname="FM_"+matname if fm_mat
		
	#Introduced by SJ
	total_mat = @materials.length + @fm_materials.length
	mat_step = " [" + @current_mat_step.to_s + "/" + total_mat.to_s + "]"
	@current_mat_step += 1

	total_step = 4
	if (has_texture and @clay==false) or @exp_default_uvs==true
		total_step += 1
	end
	current_step = 1
	rest = export.length*total_step
	SU2LUX.status_bar("Converting Faces to Meshes: " + matname + mat_step + "...[" + current_step.to_s + "/" + total_step.to_s + "]" + " #{rest}")
	#####
	
	for ft in export
		SU2LUX.status_bar("Converting Faces to Meshes: " + matname + mat_step + "...[" + current_step.to_s + "/" + total_step.to_s + "]" + " #{rest}") if (rest%500==0)
		rest-=1
	
	  	polymesh=(ft[3]==true) ? ft[0].mesh(5) : ft[0].mesh(6)
		trans = ft[1]
		trans_inverse = trans.inverse
		default_mat.push (ft[0].material==nil)
		distorted_uv.push ft[2]
		mat_dir.push ft[3]

		polymesh.transform! trans
	  
	 
		xa = SU2LUX.point_to_vector(ft[1].xaxis)
		ya = SU2LUX.point_to_vector(ft[1].yaxis)
		za = SU2LUX.point_to_vector(ft[1].zaxis)
		xy = xa.cross(ya)
		xz = xa.cross(za)
		yz = ya.cross(za)
		mirrored_tmp = true
	  
		if xy.dot(za) < 0
			mirrored_tmp = !mirrored_tmp
		end
		if xz.dot(ya) < 0
			mirrored_tmp = !mirrored_tmp
		end
		if yz.dot(xa) < 0
			mirrored_tmp = !mirrored_tmp
		end
		mirrored << mirrored_tmp

		meshes << polymesh
		@count_faces-=1

		polycount=polycount + polymesh.count_polygons
		pointcount=pointcount + polymesh.count_points
	end
	
	startindex = 0
	
	# Exporting vertices
	#has_texture = false
	current_step += 1
	
	
	out.puts 'AttributeBegin'
	i=0
	
	luxrender_mat=LuxrenderMaterial.new(mat)
	#Exporting faces indices
	#light
	# LightGroup "default"
	# AreaLightSource "area" "texture L" ["material_name:light:L"]
   # "float power" [100.000000]
   # "float efficacy" [17.000000]
   # "float gain" [1.000000]
	case luxrender_mat.type
		when "matte", "glass"
			out.puts "NamedMaterial \""+luxrender_mat.name+"\""
		when "light"
			out.puts "LightGroup \"default\""
			out.puts "AreaLightSource \"area\" \"texture L\" [\""+luxrender_mat.name+":light:L\"]"
			out.puts '"float power" [100.000000]
			"float efficacy" [17.000000]
			"float gain" [1.000000]'
	end
	out.puts 'Shape "trianglemesh" "integer indices" ['
	for mesh in meshes
	  	mirrored_tmp = mirrored[i]
		mat_dir_tmp = mat_dir[i]
		for poly in mesh.polygons
			v1 = (poly[0]>=0?poly[0]:-poly[0])+startindex
			v2 = (poly[1]>=0?poly[1]:-poly[1])+startindex
			v3 = (poly[2]>=0?poly[2]:-poly[2])+startindex
			#out.print "#{v1-1} #{v2-1} #{v3-1}\n"
			if !mirrored_tmp
				if mat_dir_tmp==true
					out.print "#{v1-1} #{v2-1} #{v3-1}\n"
				else
					out.print "#{v1-1} #{v3-1} #{v2-1}\n"
				end
			else
				if mat_dir_tmp==true
					out.print "#{v2-1} #{v1-1} #{v3-1}\n"
				else
					out.print "#{v2-1} #{v3-1} #{v1-1}\n"
				end
			end		
		
		@count_tri = @count_tri + 1
	  end
	  startindex = startindex + mesh.count_points
	  i+=1
	end
	out.puts ']'
	
	
	#Exporting verticies  points
	out.puts '"point P" ['
	for mesh in meshes
		for p in (1..mesh.count_points)
			pos = mesh.point_at(p).to_a
			out.print "#{"%.6f" %(pos[0]*@scale)} #{"%.6f" %(pos[1]*@scale)} #{"%.6f" %(pos[2]*@scale)}\n"
		end
	end
	out.puts ']'
	out.puts 'AttributeEnd'
	#Exporting Material
end

  
  
#####################################################################
#####################################################################
def SU2LUX.material_editor
	if not @material_editor
		@material_editor=LuxrenderMaterialEditor.new
	end
	@material_editor.show
end

#####################################################################
#####################################################################
def SU2LUX.render_settings

	if not @luxrender_settings
		@luxrender_settings=LuxrenderSettingsEditor.new
	end
	@luxrender_settings.show
end


#####################################################################
#####################################################################
def SU2LUX.finish_close(out)
	out.close
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
  
end #end module SU2LUX



class LuxrenderSettings
	#Default settings from preset 0 Preview - Global Illumination
	#TODO define all variables 
	#Camera
	@@camera_type="perspective"
	@@fov=35
	@@near_far_clipping=false
	@@hither=0.1
	@@yon=100  
	#end Camera

	#Environment 
	@@environment_light_type='infinite'
	#end Environment

	#Sampler
	@@sampler_showadvanced=false
	@@sampler_type='lowdiscrepancy'
	@@sampler_lowdisc_pixelsamples=1
	@@sampler_lowdisc_pixelsampler='lowdiscrepancy'
	@@sampler_metro_strength=0.6
	@@sampler_metro_lmprob=0.4
	@@sampler_metro_maxrejects=512
	@@sampler_metro_usevariance=false
	#end Sampler
  
	#Integrator
	@@sintegrator_showadvanced=false
	@@sintegrator_type='distributedpath'
	@@sintegrator_distributedpath_directsampleall=true
	@@sintegrator_distributedpath_directsamples=1
	@@sintegrator_distributedpath_directdiffuse=true
	@@sintegrator_distributedpath_directglossy=true
	@@sintegrator_distributedpath_indirectsampleall=false
	@@sintegrator_distributedpath_indirectsamples=1
	@@sintegrator_distributedpath_indirectdiffuse=true
	@@sintegrator_distributedpath_indirectglossy=true
	@@sintegrator_distributedpath_diffusereflectdepth=1
	@@sintegrator_distributedpath_diffusereflectsamples=4
	@@sintegrator_distributedpath_diffuserefractdepth=4
	@@sintegrator_distributedpath_diffuserefractsamples=1
	@@sintegrator_distributedpath_glossyreflectdepth=1
	@@sintegrator_distributedpath_glossyreflectsamples=2
	@@sintegrator_distributedpath_glossyrefractdepth=4
	@@sintegrator_distributedpath_glossyrefractsamples=1
	@@sintegrator_distributedpath_specularreflectdepth=2
	@@sintegrator_distributedpath_specularrefractdepth=4
	@@sintegrator_distributedpath_causticsonglossy=true
	@@sintegrator_distributedpath_causticsondiffuse=false
	@@sintegrator_distributedpath_strategy='auto'
	
	@@sintegrator_dlighting_maxdepth=5
	
	@@sintegrator_bidir_bounces=16
	@@sintegrator_bidir_eyedepth=16
	@@singtegrator_bidir_lightdepth=16
	@@sintegrator_bidir_strategy='auto'
	
	@@sintegrator_path_maxdepth=10
	@@singtegrator_path_ienvironment=true
	
	@@singtegrator_path_strategy='auto'
	@@sintegrator_path_rrstrategy='efficiency'
	@@sintegrator_path_rrcontinueprob=0.65
	#end Integrator
  
	#Volume Integrator
  
	#end VolumeIntegrator
  
	#Filter
	@@pixelfilter_showadvanced=false
	@@pixelfilter_type='mitchell'
	@@pixelfilter_mitchell_sharp=0.250 
	@@pixelfilter_mitchell_xwidth=2.0 
	@@pixelfilter_mitchell_ywidth=2.0 
	@@pixelfilter_mitchell_optmode='slider'
	#end Filter
  
	#Film
	@@film_type="fleximage"
	@@xresolution = Sketchup.active_model.active_view.vpwidth#800
	@@yresolution = Sketchup.active_model.active_view.vpheight#600
	@@film_displayinterval=4
	@@haltspp=0
	@@halttime=0
	#end Film
  
	#Accelerator
	@@accelerator_type="grid"
	@@refineimmediately=false
	#end Accelerator
  
	#Other
	@@useparamkeys=false
	
	
	
	
	#TODO rename all and put above or remove
	@@premultuplyalpha="false"
	@@tonamapkernel="reinhard"
	@@reinhard_prescale="1.000000"
	@@reinhard_postscale="1.200000"
	@@reinhard_burn="6.000000"
	@@writeinterval=120
	@@ldr_clam_method="lum"
	@@write_exr="false"
  @@write_png="false"
  @@write_tga="false"
  @@filename=""
  @@write_resume_flm="false"
  @@restart_resume_flm="true"
  @@reject_warmup=128
  @@debug="true"
  # "float colorspace_white" [0.314275 0.329411]
  # "float colorspace_red" [0.630000 0.340000]
  # "float colorspace_green" [0.310000 0.595000]
  # "float colorspace_blue" [0.155000 0.070000]
  @@gamma=2.200000
  #filter
  @@filter_type="mitchell"
  @@B=0.750000
  @@C=0.125000
  #sampler
  @@sampler_type="lowdiscrepancy"
  @@pixel_sampler="lowdiscrepancy"
  @@pixelsamples=1

  @@volume_integrator_type="emission"
  @@stepsize=1

  @@accelerator_type="grid"
  @@refineimmediately=false

def self.new
	@instance ||= super
end


def initialize
	@model=Sketchup.active_model
	@view=@model.active_view
	@dict="luxrender_settings"
end
  
  
#TODO - fill get and set all parameters
  
#template 
# def param_name
	# @model.get_attribute(@dict,'param_name',@@param_name)
# end
  
# def param_name=(value)
	# @model.set_attribute(@dict,'param_name',value)
# end
  
#Camera
def camera_type
	@model.get_attribute(@dict,'camera_type',@@camera_type)
end

def camera_type=(value)
	@model.set_attribute(@dict,'camera_type',value)
end
  
def fov
	@model.get_attribute(@dict,'fov',@@fov.to_s)
end

def fov=(value)
	@model.set_attribute(@dict,'fov',value)
end
  
def near_far_clipping 
	@model.get_attribute(@dict,'near_far_clipping',@@near_far_clipping)
end
  
def near_far_clipping=(value)
	@model.set_attribute(@dict,'near_far_clipping',value)
end
  
def hither
	@model.get_attribute(@dict,'hither',@@hither)
end

def hither=(value)
	@model.set_attribute(@dict,'hither',value)
end
  
def yon
	@model.get_attribute(@dict,'yon',@@yon)
end
  
def yon=(value)
	@model.set_attribute(@dict,'yon',value)
end
#end Camera
  
#Environment
def environment_light_type
	@model.get_attribute(@dict,'environment_light_type',@@environment_light_type)
end
  
def environment_light_type=(value)
	@model.set_attribute(@dict,'environment_light_type',value)
end
#end Environment
  
#Sampler
def sampler_showadvanced
	@model.get_attribute(@dict,'sampler_showadvanced',@@sampler_showadvanced)
end

def sampler_showadvanced=(value)
	@model.set_attribute(@dict,'sampler_showadvanced',@sampler_showadvanced)
end

def sampler_type
	@model.get_attribute(@dict,'sampler_type',@@sampler_type)
end

def sampler_type=(value)
	@model.set_attribute(@dict,'sampler_type',value)
end

def sampler_lowdisc_pixelsamples
	@model.get_attribute(@dict,'sampler_lowdisc_pixelsamples',@@sampler_lowdisc_pixelsamples)
end

def sampler_lowdisc_pixelsamples=(value)
	@model.set_attribute(@dict,'sampler_lowdisc_pixelsamples',value)
end

def sampler_lowdisc_pixelsampler
	@model.get_attribute(@dict,'sampler_lowdisc_pixelsampler',@@sampler_lowdisc_pixelsampler)
end

def sampler_lowdisc_pixelsampler=(value)
	@model.set_attribute(@dict,'sampler_lowdisc_pixelsampler',value)
end

def sampler_metro_strength
	@model.get_attribute(@dict,'sampler_metro_strength',@@sampler_metro_strength)
end

def sampler_metro_strength=(value)
	@model.set_attribute(@dict,'sampler_metro_strength',value)
end

def sampler_metro_lmprob
	@model.get_attribute(@dict,'sampler_metro_lmprob',@@sampler_metro_lmprob)
end

def sampler_metro_lmprob=(value)
	@model.set_attribute(@dict,'sampler_metro_lmprob',value)
end

def sampler_metro_maxrejects
	@model.get_attribute(@dict,'sampler_metro_maxrejects',@@sampler_metro_maxrejects)
end

def sampler_metro_maxrejects=(value)
	@model.set_attribute(@dict,'sampler_metro_maxrejects',value)
end

def sampler_metro_usevariance
	@model.get_attribute(@dict,'sampler_metro_usevariance',@@sampler_metro_usevariance)
end

def sampler_metro_usevariance=(value)
	@model.set_attribute(@dict,'sampler_metro_usevariance',value)
end
#end Sampler
  
#Integrator
def sintegrator_showadvanced
	@model.get_attribute(@dict,'sintegrator_showadvanced',@@sintegrator_showadvanced)
end

def sintegrator_showadvanced=(value)
	@model.set_attribute(@dict,'sintegrator_showadvanced',value)
end

def sintegrator_type
	@model.get_attribute(@dict,'sintegrator_type',@@sintegrator_type)
end

def sintegrator_type=(value)
	@model.set_attribute(@dict,'sintegrator_type',value)
end

def sintegrator_dlighting_maxdepth
	@model.get_attribute(@dict,'sintegrator_dlighting_maxdepth',@@sintegrator_dlighting_maxdepth)
end

def sintegrator_dlighting_maxdepth=(value)
	@model.set_attribute(@dict,'sintegrator_dlighting_maxdepth',value)
end

def sintegrator_bidir_bounces
	@model.get_attribute(@dict,'sintegrator_bidir_bounces',@@sintegrator_bidir_bounces)
end

def sintegrator_bidir_bounces=(value)
	@model.set_attribute(@dict,'sintegrator_bidir_bounces',value)
end

def sintegrator_bidir_eyedepth
	@model.get_attribute(@dict,'sintegrator_bidir_eyedepth',@@sintegrator_bidir_eyedepth)
end

def sintegrator_bidir_eyedepth=(value)
	@model.set_attribute(@dict,'sintegrator_bidir_eyedepth',value)
end

def singtegrator_bidir_lightdepth
	@model.get_attribute(@dict,'singtegrator_bidir_lightdepth',@@singtegrator_bidir_lightdepth)
end

def singtegrator_bidir_lightdepth=(value)
	@model.set_attribute(@dict,'singtegrator_bidir_lightdepth',value)
end

def sintegrator_bidir_maxdepth
	@model.get_attribute(@dict,'sintegrator_bidir_maxdepth',@@sintegrator_bidir_maxdepth)
end

def sintegrator_bidir_maxdepth=(value)
	@model.set_attribute(@dict,'sintegrator_bidir_maxdepth',value)
end

def sintegrator_bidir_strategy
	@model.get_attribute(@dict,'sintegrator_bidir_strategy',@@sintegrator_bidir_strategy)
end

def sintegrator_bidir_strategy=(value)
	@model.set_attribute(@dict,'sintegrator_bidir_strategy',value)
end

def sintegrator_distributedpath_causticsonglossy
	@model.get_attribute(@dict,'sintegrator_distributedpath_causticsonglossy',@@sintegrator_distributedpath_causticsonglossy)
end

def sintegrator_distributedpath_causticsonglossy=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_causticsonglossy',value)
end

def sintegrator_distributedpath_directsampleall
	@model.get_attribute(@dict,'sintegrator_distributedpath_directsampleall',@@sintegrator_distributedpath_directsampleall)
end

def sintegrator_distributedpath_directsampleall=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_directsampleall',value)
end

def sintegrator_distributedpath_directsamples
	@model.get_attribute(@dict,'sintegrator_distributedpath_directsamples',@@sintegrator_distributedpath_directsamples)
end

def sintegrator_distributedpath_directsamples=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_directsamples',value)
end

def sintegrator_distributedpath_directdiffuse
	@model.get_attribute(@dict,'sintegrator_distributedpath_directdiffuse',@@sintegrator_distributedpath_directdiffuse)
end

def sintegrator_distributedpath_directdiffuse=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_directdiffuse',value)
end

def sintegrator_distributedpath_directglossy
	@model.get_attribute(@dict,'sintegrator_distributedpath_directglossy',@@sintegrator_distributedpath_directglossy)
end

def sintegrator_distributedpath_directglossy=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_directglossy',value)
end

def sintegrator_distributedpath_indirectsampleall
	@model.get_attribute(@dict,'sintegrator_distributedpath_indirectsampleall',@@sintegrator_distributedpath_indirectsampleall)
end

def sintegrator_distributedpath_indirectsampleall=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_indirectsampleall',value)
end

def sintegrator_distributedpath_indirectsamples
	@model.get_attribute(@dict,'sintegrator_distributedpath_indirectsamples',@@sintegrator_distributedpath_indirectsamples)
end

def sintegrator_distributedpath_indirectsamples=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_indirectsamples',value)
end

def sintegrator_distributedpath_indirectdiffuse
	@model.get_attribute(@dict,'sintegrator_distributedpath_indirectdiffuse',@@sintegrator_distributedpath_indirectdiffuse)
end

def sintegrator_distributedpath_indirectdiffuse=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_indirectdiffuse',value)
end

def sintegrator_distributedpath_indirectglossy
	@model.get_attribute(@dict,'sintegrator_distributedpath_indirectglossy',@@sintegrator_distributedpath_indirectglossy)
end

def sintegrator_distributedpath_indirectglossy=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_indirectglossy',value)
end

def sintegrator_distributedpath_diffusereflectdepth
	@model.get_attribute(@dict,'sintegrator_distributedpath_diffusereflectdepth',@@sintegrator_distributedpath_diffusereflectdepth)
end

def sintegrator_distributedpath_diffusereflectdepth=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_diffusereflectdepth',value)
end

def sintegrator_distributedpath_diffusereflectsamples
	@model.get_attribute(@dict,'sintegrator_distributedpath_diffusereflectsamples',@@sintegrator_distributedpath_diffusereflectsamples)
end

def sintegrator_distributedpath_diffusereflectsamples=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_diffusereflectsamples',value)
end

def sintegrator_distributedpath_diffuserefractdepth
	@model.get_attribute(@dict,'sintegrator_distributedpath_diffuserefractdepth',@@sintegrator_distributedpath_diffuserefractdepth)
end

def sintegrator_distributedpath_diffuserefractdepth=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_diffuserefractdepth',value)
end

def sintegrator_distributedpath_diffuserefractsamples
	@model.get_attribute(@dict,'sintegrator_distributedpath_diffuserefractsamples',@@sintegrator_distributedpath_diffuserefractsamples)
end

def sintegrator_distributedpath_diffuserefractsamples=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_diffuserefractsamples',value)
end

def sintegrator_distributedpath_glossyreflectdepth
	@model.get_attribute(@dict,'sintegrator_distributedpath_glossyreflectdepth',@@sintegrator_distributedpath_glossyreflectdepth)
end

def sintegrator_distributedpath_glossyreflectdepth=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_glossyreflectdepth',value)
end

def sintegrator_distributedpath_glossyreflectsamples
	@model.get_attribute(@dict,'sintegrator_distributedpath_glossyreflectsamples',@@sintegrator_distributedpath_glossyreflectsamples)
end

def sintegrator_distributedpath_glossyreflectsamples=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_glossyreflectsamples',value)
end

def sintegrator_distributedpath_glossyrefractdepth
	@model.get_attribute(@dict,'sintegrator_distributedpath_glossyrefractdepth',@@sintegrator_distributedpath_glossyrefractdepth)
end

def sintegrator_distributedpath_glossyrefractdepth=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_glossyrefractdepth',value)
end

def sintegrator_distributedpath_glossyrefractsamples
	@model.get_attribute(@dict,'sintegrator_distributedpath_glossyrefractsamples',@@sintegrator_distributedpath_glossyrefractsamples)
end

def sintegrator_distributedpath_glossyrefractsamples=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_glossyrefractsamples',value)
end

def sintegrator_distributedpath_specularreflectdepth
	@model.get_attribute(@dict,'sintegrator_distributedpath_specularreflectdepth',@@sintegrator_distributedpath_specularreflectdepth)
end

def sintegrator_distributedpath_specularreflectdepth=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_specularreflectdepth',value)
end

def sintegrator_distributedpath_specularrefractdepth
	@model.get_attribute(@dict,'sintegrator_distributedpath_specularrefractdepth',@@sintegrator_distributedpath_specularrefractdepth)
end

def sintegrator_distributedpath_specularrefractdepth=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_specularrefractdepth',value)
end

def sintegrator_distributedpath_causticsondiffuse
	@model.get_attribute(@dict,'sintegrator_distributedpath_causticsondiffuse',@@sintegrator_distributedpath_causticsondiffuse)
end

def sintegrator_distributedpath_causticsondiffuse=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_causticsondiffuse',value)
end

def sintegrator_distributedpath_strategy
	@model.get_attribute(@dict,'sintegrator_distributedpath_strategy',@@sintegrator_distributedpath_strategy)
end

def sintegrator_distributedpath_strategy=(value)
	@model.set_attribute(@dict,'sintegrator_distributedpath_strategy',value)
end
#end Integrator
  
#Volume Integrator
def volume_integrator_type
	@model.get_attribute(@dict,'volume_integrator_type',@@volume_integrator_type)
end

def volume_integrator_type=(value)
	@model.set_attribute(@dict,'volume_integrator_type',value)
end
#end VolumeIntegrator
  
#Filter
def pixelfilter_showadvanced
	@model.get_attribute(@dict,'pixelfilter_showadvanced',@@pixelfilter_showadvanced)
end

def pixelfilter_showadvanced=(value)
	@model.set_attribute(@dict,'pixelfilter_showadvanced',value)
end

def pixelfilter_type
	@model.get_attribute(@dict,'pixelfilter_type',@@pixelfilter_type)
end

def pixelfilter_type=(value)
	@model.set_attribute(@dict,'pixelfilter_type',value)
end

def pixelfilter_mitchell_sharp
	@model.get_attribute(@dict,'pixelfilter_mitchell_sharp',@@pixelfilter_mitchell_sharp)
end

def pixelfilter_mitchell_sharp=(value)
	@model.set_attribute(@dict,'pixelfilter_mitchell_sharp',@@pixelfilter_mitchell_sharp)
end

def pixelfilter_mitchell_xwidth
	@model.get_attribute(@dict,'pixelfilter_mitchell_xwidth',@@pixelfilter_mitchell_xwidth)
end

def pixelfilter_mitchell_xwidth=(value)
	@model.set_attribute(@dict,'pixelfilter_mitchell_xwidth',value)
end

def pixelfilter_mitchell_ywidth
	@model.get_attribute(@dict,'pixelfilter_mitchell_ywidth',@@pixelfilter_mitchell_ywidth)
end

def pixelfilter_mitchell_ywidth=(value)
	@model.set_attribute(@dict,'pixelfilter_mitchell_ywidth',value)
end

def pixelfilter_mitchell_optmode
	@model.get_attribute(@dict,'pixelfilter_mitchell_optmode',@@pixelfilter_mitchell_optmode)
end

def pixelfilter_mitchell_optmode=(value)
	@model.set_attribute(@dict,'pixelfilter_mitchell_optmode',value)
end
#end Filter
  
#Film
def xresolution
	@model.get_attribute(@dict,'xresolution',@@xresolution.to_s)
end

def xresolution=(value)
	@model.set_attribute(@dict,'xresolution',value)
end

def yresolution
	@model.get_attribute(@dict,'yresolution',@@yresolution.to_s)
end

def yresolution=(value)
	@model.set_attribute(@dict,'yresolution',value)
end

def film_displayinterval
	@model.get_attribute(@dict,'film_displayinterval',@@film_displayinterval)
end

def film_displayinterval=(value)
	@model.set_attribute(@dict,'film_displayinterval',value)
end

def haltspp
	@model.get_attribute(@dict,'haltspp',@@haltspp)
end

def haltspp=(value)
	@model.set_attribute(@dict,'haltspp',value)
end

def halttime
	@model.get_attribute(@dict,'halttime',@@halttime)
end

def halttime=(value)
	@model.set_attribute(@dict,'halttime',value)
end
#end Film

#Accelerator
def accelerator_type
	@model.get_attribute(@dict,'accelerator_type',@@accelerator_type)
end

def accelerator_type=(value)
	@model.set_attribute(@dict,'accelerator_type',value)
end
#end Accelerator
  
#Other
def useparamkeys
	@model.get_attribute(@dict,'useparamkeys',@@useparamkeys)
end

def useparamkeys=(value)
	@model.set_attribute(@dict,'useparamkeys',value)
end
#end Other
  
end #end class LuxrenderSettings


class LuxrenderSettingsEditor

def initialize
	#FIXME parameters width, height of the webdialog
	pref_key="LuxrenderSettingsEditor"
	@settings_dialog=UI::WebDialog.new("Luxrender Render Settings", true,pref_key,500,500, 10,10,true)
	@settings_dialog.max_width = 500
	setting_html_path = Sketchup.find_support_file "settings.html" ,"Plugins/su2lux"
	@settings_dialog.set_file(setting_html_path)
	@lrs=LuxrenderSettings.new
	@settings_dialog.add_action_callback("param_generate") {|dialog, params|
			SU2LUX.p_debug params
			pair=params.split("=")
			id=pair[0]		   
			value=pair[1]
			case id
				#Camera
				when "camera_type"
					@lrs.camera_type=value
				when "fov"
					@lrs.fov=value
				when "near_far_clipping"
					@lrs.near_far_clipping=true if value=="true"
					@lrs.near_far_clipping=false if value=="false"
				when "hither"
					@lrs.hither=value
				when "yon"
					@lrs.yon=value
				when "dof_bokeh"
					@lrs.dof_bokeh=true if value=="true"
					@lrs.dof_bokeh=false if value=="false"
				#end Camera
				
				#Environment
				
				#end Environment
				
				#Sampler
				when "sampler_type"
					@lrs.sampler_type=value	
				#end Sampler
				
				#Integerator
				when "sintegrator_type"
					SU2LUX.p_debug 'set integrator '+value
					@lrs.sintegrator_type=value
				#end Integrator
				
				#Accelerator
				when "accelerator_type"
					@lrs.accelerator_type=value
				#end Accelerator
			end	
	}
	
	
	#TODO: fill presets (list of presets see in file settings.html  "var presets") 
	@settings_dialog.add_action_callback("preset") {|d,p|
	case p
		when '0' #<option value='0'>0 Preview - Global Illumination</option> in settings.html
			SU2LUX.p_debug "set preset 0 Preview - Global Illumination"
			@lrs.film_displayinterval=4
			@lrs.haltspp=0
			@lrs.halttime=0
			
		#TODO add "def param ... end" for other paramters in class LuxrenderSettings
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=1
			@lrs.sampler_lowdisc_pixelsampler='lowdiscrepancy'
			
			@lrs.sintegrator_type='distributedpath'
			@lrs.sintegrator_distributedpath_directsampleall=true
			@lrs.sintegrator_distributedpath_directsamples=1
			@lrs.sintegrator_distributedpath_directdiffuse=true
			@lrs.sintegrator_distributedpath_directglossy=true
			@lrs.sintegrator_distributedpath_indirectsampleall=false
			@lrs.sintegrator_distributedpath_indirectsamples=1
			@lrs.sintegrator_distributedpath_indirectdiffuse=true
			@lrs.sintegrator_distributedpath_indirectglossy=true
			@lrs.sintegrator_distributedpath_diffusereflectdepth=1
			@lrs.sintegrator_distributedpath_diffusereflectsamples=4
			@lrs.sintegrator_distributedpath_diffuserefractdepth=4
			@lrs.sintegrator_distributedpath_diffuserefractsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectdepth=1
			@lrs.sintegrator_distributedpath_glossyreflectsamples=2
			@lrs.sintegrator_distributedpath_glossyrefractdepth=4
			@lrs.sintegrator_distributedpath_glossyrefractsamples=1
			@lrs.sintegrator_distributedpath_specularreflectdepth=2
			@lrs.sintegrator_distributedpath_specularrefractdepth=4
			@lrs.sintegrator_distributedpath_causticsonglossy=true
			@lrs.sintegrator_distributedpath_causticsondiffuse=false
			@lrs.sintegrator_distributedpath_strategy='auto'
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '0b'
			SU2LUX.p_debug 'set preset 0b Preview - Direct Lighting'
			@lrs.film_displayinterval=4
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=1
			@lrs.sampler_lowdisc_pixelsampler='lowdiscrepancy'
			
			@lrs.sintegrator_type='directlighting'
			@lrs.sintegrator_dlighting_maxdepth=5

			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '1'
			SU2LUX.p_debug 'set preset 1 Final - MLT/Bidir Path Tracing (interior) (recommended)'
			@lrs.film_displayinterval=8
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='metropolis'
			@lrs.sampler_metro_strength=0.6
			@lrs.sampler_metro_lmprob=0.4
			@lrs.sampler_metro_maxrejects=512
			@lrs.sampler_metro_usevariance=false
			
			@lrs.sintegrator_type='bidirectional'
			@lrs.sintegrator_bidir_bounces=16
			@lrs.sintegrator_bidir_eyedepth=16
			@lrs.singtegrator_bidir_lightdepth=16

			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '2'
			SU2LUX.p_debug 'set preset 2 Final - MLT/Path Tracing (exterior)'
			@lrs.film_displayinterval=8
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='metropolis'
			@lrs.sampler_metro_strength=0.6
			@lrs.sampler_metro_lmprob=0.4
			@lrs.sampler_metro_maxrejects=512
			@lrs.sampler_metro_usevariance=false
			
			@lrs.sintegrator_type='path'
			@lrs.sintegrator_bidir_bounces=10
			@lrs.sintegrator_bidir_maxdepth=10

			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '5'
			SU2LUX.p_debug 'set preset 5 Progressive - Bidir Path Tracing (interior)'
			@lrs.film_displayinterval=8
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=1
			@lrs.sampler_lowdisc_pixelsampler='lowdiscrepancy'
			
			@lrs.sintegrator_type='bidirectional'
			@lrs.sintegrator_bidir_bounces=16
			@lrs.sintegrator_bidir_eyedepth=16
			@lrs.singtegrator_bidir_lightdepth=16

			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '6'
			SU2LUX.p_debug 'set preset 6 Progressive - Path Tracing (exterior)'
			@lrs.film_displayinterval=8
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=1
			@lrs.sampler_lowdisc_pixelsampler='lowdiscrepancy'
			
			@lrs.sintegrator_type='path'
			@lrs.sintegrator_bidir_bounces=10
			@lrs.sintegrator_bidir_maxdepth=10
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '8'
			SU2LUX.p_debug 'set preset 8 Bucket - Bidir Path Tracing (interior)'
			@lrs.film_displayinterval=8
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=64
			@lrs.sampler_lowdisc_pixelsampler='hilbert'
			
			@lrs.sintegrator_type='bidirectional'
			@lrs.sintegrator_bidir_bounces=8
			@lrs.sintegrator_bidir_eyedepth=8
			@lrs.singtegrator_bidir_lightdepth=10
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.250 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when '9'
			SU2LUX.p_debug 'set preset 9 Bucket - Path Tracing (exterior)'
			@lrs.film_displayinterval=8
			@lrs.haltspp=0
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=64
			@lrs.sampler_lowdisc_pixelsampler='hilbert'
			
			@lrs.sintegrator_type='path'
			@lrs.sintegrator_bidir_bounces=8
			@lrs.sintegrator_bidir_maxdepth=8
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.333 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when 'B'
			SU2LUX.p_debug 'set preset B Anim - Distributed/GI low Q'
			@lrs.film_displayinterval=8
			@lrs.haltspp=1
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=16
			@lrs.sampler_lowdisc_pixelsampler='hilbert'
			
			@lrs.sintegrator_type='distributedpath'
			@lrs.sintegrator_distributedpath_causticsonglossy=true
			@lrs.sintegrator_distributedpath_directsampleall=true
			@lrs.sintegrator_distributedpath_directsamples=1
			@lrs.sintegrator_distributedpath_directdiffuse=true
			@lrs.sintegrator_distributedpath_directglossy=true
			@lrs.sintegrator_distributedpath_indirectsampleall=false
			@lrs.sintegrator_distributedpath_indirectsamples=1
			@lrs.sintegrator_distributedpath_indirectdiffuse=true
			@lrs.sintegrator_distributedpath_indirectglossy=true
			@lrs.sintegrator_distributedpath_diffusereflectdepth=2
			@lrs.sintegrator_distributedpath_diffusereflectsamples=1
			@lrs.sintegrator_distributedpath_diffuserefractdepth=5
			@lrs.sintegrator_distributedpath_diffuserefractsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectdepth=2
			@lrs.sintegrator_distributedpath_glossyreflectsamples=1
			@lrs.sintegrator_distributedpath_glossyrefractdepth=5
			@lrs.sintegrator_distributedpath_glossyrefractsamples=1
			@lrs.sintegrator_distributedpath_specularreflectdepth=2
			@lrs.sintegrator_distributedpath_specularrefractdepth=5
			@lrs.sintegrator_distributedpath_causticsondiffuse=false
			@lrs.sintegrator_distributedpath_strategy='auto'
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.333 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when 'C'
			SU2LUX.p_debug 'set preset C Anim - Distributed/GI medium Q'
			@lrs.film_displayinterval=8
			@lrs.haltspp=1
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=64
			@lrs.sampler_lowdisc_pixelsampler='hilbert'
			
			@lrs.sintegrator_distributedpath_causticsonglossy=true
			@lrs.sintegrator_distributedpath_diffuserefractdepth=5
			@lrs.sintegrator_distributedpath_indirectglossy=true
			@lrs.sintegrator_distributedpath_directsamples=1
			@lrs.sintegrator_distributedpath_diffuserefractsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectdepth=2
			@lrs.sintegrator_distributedpath_causticsondiffuse=false
			@lrs.sintegrator_distributedpath_directsampleall=true
			@lrs.sintegrator_distributedpath_indirectdiffuse=true
			@lrs.sintegrator_distributedpath_specularreflectdepth=3
			@lrs.sintegrator_distributedpath_diffusereflectsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectsamples=1
			@lrs.sintegrator_distributedpath_glossyrefractdepth=5
			@lrs.sintegrator_distributedpath_diffusereflectdepth=2
			@lrs.sintegrator_distributedpath_indirectsamples=1
			@lrs.sintegrator_distributedpath_indirectsampleall=false
			@lrs.sintegrator_distributedpath_glossyrefractsamples=1
			@lrs.sintegrator_distributedpath_directdiffuse=true
			@lrs.sintegrator_distributedpath_directglossy=true
			@lrs.sintegrator_distributedpath_strategy='auto'
			@lrs.sintegrator_distributedpath_specularrefractdepth=5
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.333 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when 'D'
			SU2LUX.p_debug 'set preset D Anim - Distributed/GI high Q'
			@lrs.film_displayinterval=8
			@lrs.haltspp=1
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=256
			@lrs.sampler_lowdisc_pixelsampler='hilbert'
			
			@lrs.sintegrator_distributedpath_causticsonglossy=true
			@lrs.sintegrator_distributedpath_diffuserefractdepth=5
			@lrs.sintegrator_distributedpath_indirectglossy=true
			@lrs.sintegrator_distributedpath_directsamples=1
			@lrs.sintegrator_distributedpath_diffuserefractsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectdepth=2
			@lrs.sintegrator_distributedpath_causticsondiffuse=false
			@lrs.sintegrator_distributedpath_directsampleall=true
			@lrs.sintegrator_distributedpath_indirectdiffuse=true
			@lrs.sintegrator_distributedpath_specularreflectdepth=3
			@lrs.sintegrator_distributedpath_diffusereflectsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectsamples=1
			@lrs.sintegrator_distributedpath_glossyrefractdepth=5
			@lrs.sintegrator_distributedpath_diffusereflectdepth=2
			@lrs.sintegrator_distributedpath_indirectsamples=1
			@lrs.sintegrator_distributedpath_indirectsampleall=false
			@lrs.sintegrator_distributedpath_glossyrefractsamples=1
			@lrs.sintegrator_distributedpath_directdiffuse=true
			@lrs.sintegrator_distributedpath_directglossy=true
			@lrs.sintegrator_distributedpath_strategy='auto'
			@lrs.sintegrator_distributedpath_specularrefractdepth=5
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.333 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
		when 'E'
			SU2LUX.p_debug 'set preset E Anim - Distributed/GI very high Q'
			@lrs.film_displayinterval=8
			@lrs.haltspp=1
			@lrs.halttime=0
			@lrs.useparamkeys=false
			@lrs.sampler_showadvanced=false
			@lrs.sintegrator_showadvanced=false
			@lrs.pixelfilter_showadvanced=false
			
			@lrs.sampler_type='lowdiscrepancy'
			@lrs.sampler_lowdisc_pixelsamples=512
			@lrs.sampler_lowdisc_pixelsampler='hilbert'
			
			@lrs.sintegrator_distributedpath_causticsonglossy=true
			@lrs.sintegrator_distributedpath_diffuserefractdepth=5
			@lrs.sintegrator_distributedpath_indirectglossy=true
			@lrs.sintegrator_distributedpath_directsamples=1
			@lrs.sintegrator_distributedpath_diffuserefractsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectdepth=2
			@lrs.sintegrator_distributedpath_causticsondiffuse=false
			@lrs.sintegrator_distributedpath_directsampleall=true
			@lrs.sintegrator_distributedpath_indirectdiffuse=true
			@lrs.sintegrator_distributedpath_specularreflectdepth=3
			@lrs.sintegrator_distributedpath_diffusereflectsamples=1
			@lrs.sintegrator_distributedpath_glossyreflectsamples=1
			@lrs.sintegrator_distributedpath_glossyrefractdepth=5
			@lrs.sintegrator_distributedpath_diffusereflectdepth=2
			@lrs.sintegrator_distributedpath_indirectsamples=1
			@lrs.sintegrator_distributedpath_indirectsampleall=false
			@lrs.sintegrator_distributedpath_glossyrefractsamples=1
			@lrs.sintegrator_distributedpath_directdiffuse=true
			@lrs.sintegrator_distributedpath_directglossy=true
			@lrs.sintegrator_distributedpath_strategy='auto'
			@lrs.sintegrator_distributedpath_specularrefractdepth=5
			
			@lrs.pixelfilter_type='mitchell'
			@lrs.pixelfilter_mitchell_sharp=0.333 
			@lrs.pixelfilter_mitchell_xwidth=2.0 
			@lrs.pixelfilter_mitchell_ywidth=2.0 
			@lrs.pixelfilter_mitchell_optmode='slider'
	end
	}
end


def show
	@settings_dialog.show{SendDataFromSketchup()}
end

#set parameters in inputs of settings.html
def	SendDataFromSketchup()  
	setValue("fov",@lrs.fov)
	setValue("xresolution",@lrs.xresolution)
	setValue("yresolution",@lrs.yresolution)
	setValue("camera_type",@lrs.camera_type)
	setValue("accelerator_type",@lrs.accelerator_type)
	setValue("sintegrator_type",@lrs.sintegrator_type)
	setValue("sampler_type",@lrs.sampler_type)
	setValue("volume_integrator_type",@lrs.volume_integrator_type)	
end 

def setValue(id,value)
	new_value=value.to_s
	cmd="$('##{id}').val('#{new_value}');" #syntax jquery
	SU2LUX.p_debug cmd
	@settings_dialog.execute_script(cmd)
  end
end #end class LuxrenderSettingsEditor
 

class LuxrenderMaterialEditor

def initialize
	@material_editor_dialog=UI::WebDialog.new("Luxrender Material Editor", true, "LuxrenderMaterialEditor",500, 500,900,400,true)
	material_editor_dialog_path = Sketchup.find_support_file "materialeditor.html" ,"Plugins/su2lux"
	@material_editor_dialog.max_width = 800
	@material_editor_dialog.set_file(material_editor_dialog_path)
	
	@material_editor_dialog.add_action_callback('param_generate') {|dialog, params|
			#p 'param_generate'
			SU2LUX.p_debug params
			# Get the data from the Webdialog.
			parameters = string_to_hash(params)
			# Prepare the data
			material_type=parameters['material_type']
			#p material_type
			material_name=parameters['material_name']
			#p material_name
			#p "su_material"
			luxmat=self.find(material_name)
			luxmat.type=material_type
	}
	
	@material_editor_dialog.add_action_callback('set_material_list') {
	self.setmateriallist()
	}
	
	@material_editor_dialog.add_action_callback('select_material'){|dialog, matname|
	SU2LUX.p_debug "matname_2"+matname
	luxrender_material=self.find(matname)
	SU2LUX.p_debug "type="+luxrender_material.type
	cmd="$(\"#material_type option[value='"+luxrender_material.type+"']\").attr(\"selected\",\"selected\");"
	SU2LUX.p_debug cmd
	@material_editor_dialog.execute_script(cmd)
	}
end

# Takes a string like "key1=value1,key2=value2" and creates an hash.
def string_to_hash(string)
	hash = {}
	datapairs = string.split('|')
	datapairs.each { |datapair|
	  data = datapair.split('=')
	  hash[data[0]] = data[1]
	}
	return hash
end
	
def find(display_name) 
	materials=Sketchup.active_model.materials
	display_names = materials.collect {|m| m.display_name}
	names=materials.collect {|m| m.name}
	index=display_names.index(display_name)
	mat=index ? materials[names[index]] : nil  #get the SU material
	if mat
		return LuxrenderMaterial.new(mat)
	else
		return nil
	end
end 

	
def show
	@material_editor_dialog.show{refreshMaterialsList()}
end

   
def refreshMaterialsList()

	#cmd="clearMaterialList()"
	#@material_editor_dialog.execute_script(cmd)
	mat_list=Sketchup.active_model.materials.collect {|m| m.name}
	mat_list.sort!
	id="material_name"
	mat_list.each {|mat_name|
	#cmd="createMapOption(\"#{id}\",\"#{mat_name}\",\"#{mat_name}\")"
	cmd="createMapOption(\"#{id}\",\"wwwww\",\"wwww\")"
	SU2LUX.p_debug cmd
	@material_editor_dialog.execute_script(cmd)
}
end

def setmateriallist() 
	cmd="$('#material_name').append( $('"
	for mat in Sketchup.active_model.materials
		luxrender_mat=LuxrenderMaterial.new(mat)
		cmd=cmd+"<option value=\"#{luxrender_mat.name}\">#{luxrender_mat.name}</option>"
	end
	cmd=cmd+"'));"	
	#p cmd
	@material_editor_dialog.execute_script(cmd)	
end
  
def setmaterialtype()
	SU2LUX.p_debug "set material type"
end
end #end class LuxrenderMaterialEditor

class LuxrenderMaterial
	@@dict="luxrender_materials"
	@@type="matte"
  
	attr_reader :mat
def initialize(su_material)
	@mat=su_material
	#materials=Sketchup.active_model.materials
	#names = materials.collect {|m| m.display_name}
	#puts names
	#index=names.index(name)
	#puts index
	#@su_material=index ? materials[names[index]] : nil  #get the SU material
	#@su_material.set_attribute(@@dict,'type','matte')
	#@mat=materials.at 0
	#@mat=su_material
	#dicts=@mat.attribute_dictionaries if @mat
	#return if not dicts
end

def name
	return mat.display_name.gsub(/[<>]/, '*')  #replaces <> characters with *
end
  
def type
	t=@mat.get_attribute(@@dict,'type')  #check if the type has been set
	
	if not t
	  if @mat.alpha<1.0
		return "glass"
	  else
		return @@type
	  end
	else
	  return t
	end
end

def type=(value)
	@mat.set_attribute(@@dict,'type',value)
end

def color
	mat.color
end

def color=(value)
	mat.color=(value)
end

end #end class LuxrenderMaterial


if( not file_loaded?(__FILE__) )
	main_menu = UI.menu("Plugins").add_submenu("Luxrender Exporter")
	main_menu.add_item("Render") { ( SU2LUX.export)}
	main_menu.add_item("Settings") { (SU2LUX.render_settings)}
	#main_menu.add_item("Material Editor") {(SU2LUX.material_editor)}
	main_menu.add_item("About") {(SU2LUX.about)}
end


file_loaded(__FILE__)

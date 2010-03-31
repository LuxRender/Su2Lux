class LuxrenderExport

	EXT_SCENE = ".lxs"
	DEBUG = true
	FRONTF = "SU2LUX Front Face"
#####################################################################
###### - printing debug messages - 										######
#####################################################################
if (DEBUG)
	def p_debug(message)
		p message
	end
else
	def p_debug(message)
	end
end

def initialize (export_file_path,os_separator)
@export_file_path=export_file_path
@os_separator=os_separator
@model_name=File.basename(@export_file_path)
@model_name=@model_name.split(".")[0]

@path_textures=File.dirname(@export_file_path)
end

def reset
	@materials = {}
	@fm_materials = {}
	@count_faces = 0
	@clay=false
	@exp_default_uvs = false
	@scale = 0.0254
	@count_tri = 0
	@model_textures={}
	@textures_prefix = "TX_"
	@lrs=LuxrenderSettings.new
	@lrs.xresolution = Sketchup.active_model.active_view.vpwidth unless @lrs.xresolution
	@lrs.yresolution = Sketchup.active_model.active_view.vpheight unless @lrs.yresolution
end
	
#####################################################################
#####################################################################
def export_global_settings(out)
	out.puts "# Lux Render Scene File"
	out.puts "# Exported by SU2LUX 0.1-devel"
	out.puts "# Global Information"
end

  # -----------Extract the camera parameters of the current view ------------------------------------

#####################################################################
#####################################################################
def export_camera(view, out)
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

	case @lrs.camera_type
		when "perspective"
			fov = compute_fov(@lrs.xresolution, @lrs.yresolution)
			out.puts "Camera \"#{@lrs.camera_type}\""
			out.puts "	\"float fov\" [%.6f" %(fov) + "]"
		when "orthographic"
			out.puts "Camera \"#{@lrs.camera_type}\""
			# No more scale parameter exporting due to Lux complainig for it
			# out.puts "	\"float scale\" [%.6f" %(@lrs.camera_scale) + "]"
		when "environment"
			out.puts "Camera \"#{@lrs.camera_type}\""
	end
	
	sw = compute_screen_window
	out.puts	"\t\"float screenwindow\" [" + "%.6f" %(sw[0]) + " " + "%.6f" %(sw[1]) + " " + "%.6f" %(sw[2]) + " " + "%.6f" %(sw[3]) +"]\n"
	
	# out.puts "	\"float hither\" [%.6f" %(@lrs.hither) + "]"
	# out.puts "	\"float yon\" [%.6f" %(@lrs.yon) + "]"
	
	#TODO  depends aspect_ratio and resolution 
	#http://www.luxrender.net/wiki/index.php?title=Scene_file_format#Common_Camera_Parameters
			
	out.print "\n"
end

#####################################################################
#####################################################################
def compute_fov(xres, yres)
	camera = Sketchup.active_model.active_view.camera
	fov_vertical = camera.fov
	width = xres.to_f
	height = yres.to_f
	if(width >= height)
		fov = fov_vertical
	else
		focal_distance = 0.5 * height / Math.tan(0.5 * fov_vertical.degrees)
		fov_horizontal = (2.0 * Math.atan2(0.5 * width, focal_distance)).radians
		fov = fov_horizontal
	end

	if (camera.aspect_ratio != 0.0)
		focal_length = camera.focal_length
		image_width = 2 * focal_length * Math::tan(0.5 * fov.degrees)
		aspect_ratio_inverse = height /width
		image_width = image_width * aspect_ratio_inverse
		fov = 2.0 * Math.atan2(0.5 * image_width, focal_length)
		fov = fov.radians
	end
	return fov
end

#####################################################################
#####################################################################
def compute_screen_window
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
def export_film(out)
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

def export_render_settings(out)
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
	out.puts "\n"
	out.puts "Accelerator \"#{@lrs.accelerator_type}\""
	case @lrs.accelerator_type
		when "kdtree", "tabreckdtree"
			out.puts "\t\"integer intersectcost\" [#{@lrs.intersection_cost}]"
			out.puts "\t\"integer traversalcost\" [#{@lrs.traversal_cost}]"
			out.puts "\t\"float emptybonus\" [#{"%.6f" %(@lrs.empty_bonus)}]"
			out.puts "\t\"integer maxprims\" [#{@lrs.max_prims}]"
			out.puts "\t\"integer maxdepth\" [#{@lrs.max_depth}]"
		when "grid"
			value = "\"false\""
			value = "\"true\"" if @lrs.refine_immediately
			out.puts "\t\"bool refineimmediately\" [#{value}]"
		when "bvh"
		when "qbvh"
			out.puts "\t\"integer maxprimsperleaf\" [#{@lrs.max_prims_per_leaf}]"
			out.puts "\t\"integer skipfactor\" [#{@lrs.skip_factor}]"
	end
	out.puts "\n"
end

#####################################################################
#####################################################################
def export_light(out)
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
def export_mesh(out)
	mc=MeshCollector.new(@model_name,@os_separator)
	mc.collect_faces(Sketchup.active_model.entities, Geom::Transformation.new)
	@materials=mc.materials
	@fm_materials=mc.fm_materials
	@model_textures=mc.model_textures
	@texturewriter=mc.texturewriter
	@count_faces=mc.count_faces
	@current_mat_step = 1
	p 'export faces'
	export_faces(out)
	p 'export fmfaces'
	export_fm_faces(out)
end



#####################################################################
#####################################################################
def export_faces(out)
	@materials.each{|mat,value|
		if (value!=nil and value!=[])
			export_face(out,mat,false)
			@materials[mat]=nil
		end}
	@materials={}
end

#####################################################################
#####################################################################
def export_fm_faces(out)
	@fm_materials.each{|mat,value|
		if (value!=nil and value!=[])
			export_face(out,mat,true)
			@fm_materials[mat]=nil
		end}
	@fm_materials={}
end


#####################################################################
#####################################################################
def point_to_vector(p)
	Geom::Vector3d.new(p.x,p.y,p.z)
end

#####################################################################
#####################################################################
def export_face(out,mat,fm_mat)
	p 'export face'
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
		p 'matname: '+matname
		has_texture = true if mat.texture!=nil
	else
		matname = "Default"
		has_texture=true if matname!=FRONTF
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
	Sketchup.set_status_text("Converting Faces to Meshes: " + matname + mat_step + "...[" + current_step.to_s + "/" + total_step.to_s + "]" + " #{rest}")
	#####
	
	for ft in export
		Sketchup.set_status_text("Converting Faces to Meshes: " + matname + mat_step + "...[" + current_step.to_s + "/" + total_step.to_s + "]" + " #{rest}") if (rest%500==0)
		rest-=1
	
	  	polymesh=(ft[3]==true) ? ft[0].mesh(5) : ft[0].mesh(6)
		trans = ft[1]
		trans_inverse = trans.inverse
		default_mat.push (ft[0].material==nil)
		distorted_uv.push ft[2]
		mat_dir.push ft[3]

		polymesh.transform! trans
	  
	 
		xa = point_to_vector(ft[1].xaxis)
		ya = point_to_vector(ft[1].yaxis)
		za = point_to_vector(ft[1].zaxis)
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
	
	if mat.class==String
	out.puts "NamedMaterial \""+mat+"\""
	else
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
	
	i=0
	#Exporting normals
	out.puts '"normal N" ['
	for mesh in meshes
		Sketchup.set_status_text("Material being exported: " + matname + mat_step + "...[" + current_step.to_s + "/" + total_step.to_s + "]" + " - Normals " + " #{rest}") if rest%500==0
		rest -= 1
		mat_dir_tmp = mat_dir[i]
		for p in (1..mesh.count_points)
			norm = mesh.normal_at(p)
			norm.reverse! if mat_dir_tmp==false
				out.print "#{"%.4f" %(norm.x)} #{"%.4f" %(norm.y)} #{"%.4f" %(norm.z)}\n"
		end
		i += 1
	end
	out.puts ']'
	
	@exp_default_uvs=true
	no_texture_uvs=(!has_texture and @exp_default_uvs==true)
	if has_texture or no_texture_uvs
		current_step += 1
		i = 0
		#Exporting uv-coordinates
		out.puts '"float uv" ['
		for mesh in meshes
			#SU2KT.status_bar("Material being exported: " + matname + mat_step + "...[" + current_step.to_s + "/" + total_step.to_s + "]" + " - UVs " + " #{rest}") if rest%500==0
			rest -= 1

			dir=(no_texture_uvs) ? true : mat_dir[i]

			for p in (1 .. mesh.count_points)

				if default_mat[i] and @model_textures[matname]!=nil
					mat_texture=(@model_textures[matname][5]).texture
					texsize = Geom::Point3d.new(mat_texture.width, mat_texture.height, 1)
				else
					texsize = Geom::Point3d.new(1,1,1)
				end

				textsize=Geom::Point3d.new(20,20,20) if no_texture_uvs

				if distorted_uv[i]!=nil
					uvHelp=distorted_uv[i]
					#UV-Photomatch-Bugfix Stefan Jaensch 2009-08-25 (transformation applied)
					uv=uvHelp.get_front_UVQ(mesh.point_at(p).transform!(trans_inverse)) if mat_dir[i]==true
					uv=uvHelp.get_back_UVQ(mesh.point_at(p).transform!(trans_inverse)) if mat_dir[i]==false
				else
					uv = [mesh.uv_at(p,dir).x/texsize.x, mesh.uv_at(p,dir).y/texsize.y, mesh.uv_at(p,dir).z/texsize.z]
				end
					out.print "#{"%.4f" %(uv.x)} #{"%.4f" %(-uv.y+1)}\n"
			end
			i += 1
		end
		out.puts ']'
	end
	
	out.puts 'AttributeEnd'
	#Exporting Material
end



#####################################################################
#####################################################################
def export_used_materials(materials, out)
	materials.each { |mat|
		luxrender_mat = LuxrenderMaterial.new(mat)
		p_debug luxrender_mat.name
		export_mat(luxrender_mat, out)
	}
end

def export_textures(out)
	@model_textures.each { |key,value|
	export_texture(key,value[4],out)
	}
end


def export_texture(texture_name,texture_path,out)
	out.puts "\Texture \""+texture_name+"\" \"color\" \"imagemap\" \"string filename\" [\""+texture_path+ "\"]"
	out.puts "MakeNamedMaterial \"" + texture_name + "\""
	out.puts "\"string type\" [\"matte\"]"
	out.puts "\"texture Kd\" [\""+texture_name+"\"]"
end
#####################################################################
#####################################################################
def export_mat(mat, out)
	p_debug "export_mat"
	out.puts "# Material '" + mat.name + "'"
	case mat.type
		when "matte"
			out.puts "MakeNamedMaterial \"" + mat.name + "\""
			p_debug "mat.name " + mat.name
			out.puts  "\"string type\" [\"matte\"]"
			out.puts  "\"color Kd\" [#{"%.6f" %(mat.color.red.to_f/255)} #{"%.6f" %(mat.color.green.to_f/255)} #{"%.6f" %(mat.color.blue.to_f/255)}]"
		when "glass"
			out.puts "MakeNamedMaterial \"" + mat.name + "\""
			p_debug "mat.name " + mat.name
#   "bool architectural" ["true"]
			out.puts  "\"string type\" [\"glass\"]"
			out.puts  "\"color Kt\" [#{"%.6f" %(mat.color.red.to_f/255)} #{"%.6f" %(mat.color.green.to_f/255)} #{"%.6f" %(mat.color.blue.to_f/255)}]"
			out.puts "\"float index\" [1.520000]"
		when "light"
			out.puts "Texture \"" + mat.name + ":light:L\" \"color\" \"blackbody\"
				\"float temperature\" [6500.000000]"
	end
	out.puts("\n")
end

def write_textures
	@copy_textures=true #TODO add in settings export
	
	if (@copy_textures == true and @model_textures!={})

		if FileTest.exist? (@path_textures+@os_separator+@textures_prefix+@model_name)
		else
			Dir.mkdir(@path_textures+@os_separator+@textures_prefix+@model_name)
		end

		tw=@texturewriter
		p @texturewriter
		number=@model_textures.length
		count=1
		@model_textures.each do |key, value|
			Sketchup.set_status_text("Exporting texture "+count.to_s+"/"+number.to_s)
			if value[1].class== Sketchup::Face
				p value[1]
				return_val = tw.write value[1], value[2], (@path_textures+@os_separator+value[4])
				p 'path: '+@path_textures+@os_separator+value[4]
				p return_val
				p 'write texture1'
			else
				tw.write value[1], (@path_textures+@os_separator+value[4])
				p 'write texture2'
			end
			count+=1
		end

		status='ok' #TODO

		if status
		stext = "SU2LUX: " + (count-1).to_s + " textures and model"
		else
			stext = "An error occured when exporting textures. Model"
		end
		@texturewriter=nil
		@model_textures=nil
	else
		stext = "Model"
	end

	return stext

end


end
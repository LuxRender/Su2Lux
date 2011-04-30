class LuxrenderExport
	attr_reader :count_tri
	##
	#
	##
	def initialize(export_file_path,os_separator)
		@lrs=LuxrenderSettings.new
		@export_file_path=export_file_path
		@model_name=File.basename(@export_file_path)
		@model_name=@model_name.split(".")[0]
		@os_separator=os_separator

		@path_textures=File.dirname(@export_file_path)
	end # END initialize

	def reset
		@materials = {}
		@fm_materials = {}
		@count_faces = 0
		@clay=false
		@exp_default_uvs = false
		@scale = 0.0254
		@count_tri = 0
		@model_textures={}
	#	@textures_prefix = "TX_"
		# @lrs=LuxrenderSettings.new
		@lrs.fleximage_xresolution = Sketchup.active_model.active_view.vpwidth unless @lrs.fleximage_xresolution
		@lrs.fleximage_yresolution = Sketchup.active_model.active_view.vpheight unless @lrs.fleximage_yresolution
	end #END reset
		
	##
	#
	##
	def export_global_settings(out)
		out.puts "# Lux Render Scene File"
		out.puts "# Exported by SU2LUX 0.1-devel"
		out.puts "# Global Information"
	end # END export_global_settings

		# -----------Extract the camera parameters of the current view ------------------------------------

	##
	#
	##
	def export_camera(view, out)
		# @lrs=LuxrenderSettings.new

		user_camera = view.camera
		user_eye = user_camera.eye
		user_target=user_camera.target
		user_up=user_camera.up

		out_user_target = "%12.6f" %(user_target.x.to_m.to_f) + " " + "%12.6f" %(user_target.y.to_m.to_f) + " " + "%12.6f" %(user_target.z.to_m.to_f)
		out_user_up = "%12.6f" %(user_up.x) + " " + "%12.6f" %(user_up.y) + " " + "%12.6f" %(user_up.z)

		out.puts "LookAt"
		out.puts "%12.6f" %(user_eye.x.to_m.to_f) + " " + "%12.6f" %(user_eye.y.to_m.to_f) + " " + "%12.6f" %(user_eye.z.to_m.to_f)
		out.puts out_user_target
		out.puts out_user_up
		out.print "\n"

		camera_scale = 1.0
		if Sketchup.active_model.active_view.camera.perspective?
			camera_type = 'perspective'
		else
			camera_type = 'orthographic'
		end
		if @lrs.camera_type != "environment" && @lrs.camera_type != camera_type
			@lrs.camera_type = camera_type
		end
		out.puts "Camera \"#{@lrs.camera_type}\""
		case @lrs.camera_type
			when "perspective"
				fov = compute_fov(@lrs.fleximage_xresolution, @lrs.fleximage_yresolution)
				out.puts "	\"float fov\" [%.6f" %(fov) + "]"
			when "orthographic"
				camera_scale = @lrs.camera_scale
				# out.puts "Camera \"#{@lrs.camera_type}\""
				# No more scale parameter exporting due to Lux complainig for it
				# out.puts "	\"float scale\" [%.6f" %(@lrs.camera_scale) + "]"
			when "environment"
				# out.puts "Camera \"#{@lrs.camera_type}\""
		end
		
		if (@lrs.use_clipping)
			out.puts "\t\"float hither\" [" + "%.6f" %(@lrs.hither) + "]"
			out.puts "\t\"float yon\" [" + "%.6f" %(@lrs.yon) + "]"
		end
		
		
		if (@lrs.use_dof_bokeh)
			out.puts "\t\"float lensradius\" [%.6f" %(@lrs.lensradius.to_f) + "]"
			case @lrs.focus_type
				when "autofocus"
					autofocus = @lrs.autofocus ? "true" : "false"
					out.puts "\t\"bool autofocus\" [\"" + autofocus + "\"]"
				when "manual"
					out.puts "\t\"float focaldistance\" [%.6f" %(@lrs.focaldistance.to_f) + "]"
			end
			out.puts "\t\"string distribution\" [\"" + @lrs.distribution + "\"]"
			out.puts "\t\"integer power\" [#{@lrs.power.to_i}]"
			out.puts "\t\"integer blades\" [#{@lrs.blades.to_i}]"
		end
		
		if (@lrs.use_architectural)
			if (@lrs.use_ratio)
				out.puts "\t\"float frameaspectratio\" [" + "%.6f" %(@lrs.frameaspectratio) + "]"
			end
		end
		
		if (@lrs.use_motion_blur)
			out.puts "\t\"float shutteropen\" [%.6f" %(@lrs.shutteropen) + "]"
			out.puts "\t\"float shutterclose\" [%.6f" %(@lrs.shutterclose) + "]"
			out.puts "\t\"string shutterdistribution\" [\"" + @lrs.shutterdistribution + "\"]"
		end
		sw = compute_screen_window
		out.puts	"\t\"float screenwindow\" [" + "%.6f" %(sw[0]) + " " + "%.6f" %(sw[1]) + " " + "%.6f" %(sw[2]) + " " + "%.6f" %(sw[3]) +"]\n"
		# out.puts "	\"float hither\" [%.6f" %(@lrs.hither) + "]"
		# out.puts "	\"float yon\" [%.6f" %(@lrs.yon) + "]"
		
		#TODO  depends aspect_ratio and resolution 
		#http://www.luxrender.net/wiki/index.php?title=Scene_file_format#Common_Camera_Parameters
				
		out.print "\n"
	end # END export_camera

	##
	#
	##
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
	end # END compute_fov

	##
	#
	##
	def compute_screen_window
		cam_shiftX = @lrs.shiftX.to_f
		cam_shiftY = @lrs.shiftY.to_f
		ratio = @lrs.fleximage_xresolution.to_f / @lrs.fleximage_yresolution.to_f
		inv_ratio = 1.0 / ratio
		if (ratio > 1.0)
			screen_window = [2 * cam_shiftX - ratio, 2 * cam_shiftX + ratio, 2 * cam_shiftY - 1.0, 2 * cam_shiftY + 1.0]
		else
			screen_window = [2 * cam_shiftX - 1.0, 2 * cam_shiftX + 1.0, 2 * cam_shiftY - inv_ratio, 2 * cam_shiftY + inv_ratio]
		end
	end # END compute_screen_window

	##
	#
	##
	def export_film(out)
		out.puts "Film \"fleximage\""
		out.puts "\t\"integer xresolution\" [#{@lrs.fleximage_xresolution.to_i}]"
		out.puts "\t\"integer yresolution\" [#{@lrs.fleximage_yresolution.to_i}]"
		out.puts "\t\"integer haltspp\" [#{@lrs.fleximage_haltspp.to_i}]"
		out.puts "\t\"integer halttime\" [#{@lrs.fleximage_halttime.to_i}]"
		out.puts "\t\"integer filterquality\" [#{@lrs.fleximage_filterquality.to_i}]"
		pre_alpha = @lrs.fleximage_premultiplyalpha ? "true" : "false"
		out.puts "\t\"bool premultiplyalpha\" [\"#{pre_alpha}\"]\n"
		out.puts "\t\"integer displayinterval\" [#{@lrs.fleximage_displayinterval.to_i}]"
		out.puts "\t\"integer writeinterval\" [#{@lrs.fleximage_writeinterval.to_i}]"
		out.puts "\t\"string ldr_clamp_method\" [\"#{@lrs.fleximage_ldr_clamp_method}\"]"
		out.puts "\t\"string tonemapkernel\" [\"#{@lrs.fleximage_tonemapkernel}\"]"
		case @lrs.fleximage_tonemapkernel
			when "reinahrd"
			when "linear"
			when "contrast"
			when "maxwhite"
		end
		exr = @lrs.fleximage_write_exr ? "true" : "false"
		out.puts "\t\"bool write_exr\" [\"#{exr}\"]\n"
		if (@lrs.fleximage_write_exr)
		end
		png = @lrs.fleximage_write_png ? "true" : "false"
		out.puts "\t\"bool write_png\" [\"#{png}\"]\n"
		if (@lrs.fleximage_write_png)
		end
		tga = @lrs.fleximage_write_tga ? "true" : "false"
		out.puts "\t\"bool write_tga\" [\"#{tga}\"]\n"
		if (@lrs.fleximage_write_tga)
		end
		flm = @lrs.fleximage_write_resume_flm ? "true" : "false"
		out.puts "\t\"bool write_resume_flm\" [\"#{flm}\"]\n"
		flm = @lrs.fleximage_restart_resume_flm ? "true" : "false"
		out.puts "\t\"bool restart_resume_flm\" [\"#{flm}\"]\n"
		out.puts "\t\"string filename\" [\"#{@lrs.fleximage_filename}\"]"
		out.puts "\t\"integer reject_warmup\" [#{@lrs.fleximage_reject_warmup.to_i}]"
		dbg = @lrs.fleximage_debug ? "true" : "false"
		out.puts "\t\"bool debug\" [\"#{dbg}\"]\n"
		out.puts "\t\"float colorspace_white\" [#{"%.6f" %(@lrs.fleximage_colorspace_white_x)} #{"%.6f" %(@lrs.fleximage_colorspace_white_y)}]\n"
		out.puts "\t\"float colorspace_red\" [#{"%.6f" %(@lrs.fleximage_colorspace_red_x)} #{"%.6f" %(@lrs.fleximage_colorspace_red_y)}]\n"
		out.puts "\t\"float colorspace_green\" [#{"%.6f" %(@lrs.fleximage_colorspace_green_x)} #{"%.6f" %(@lrs.fleximage_colorspace_green_y)}]\n"
		out.puts "\t\"float colorspace_blue\" [#{"%.6f" %(@lrs.fleximage_colorspace_blue_x)} #{"%.6f" %(@lrs.fleximage_colorspace_blue_y)}]\n"
		out.puts "\t\"float gamma\" [#{"%.6f" %(@lrs.fleximage_gamma)}]\n"
		out.puts "\t\"integer outlierrejection_k\" [#{@lrs.fleximage_outlierrejection_k.to_i}]"
		
		flm = @lrs.useparamkeys ? "true" : "false"
		out.puts "\t\"bool useparamkeys\" [\"#{flm}\"]\n"

		# out.puts '
		# "integer halttime" [0]
		# "bool premultiplyalpha" ["false"]
		# "string tonemapkernel" ["reinhard"]
		# "float reinhard_prescale" [1.000000]
		# "float reinhard_postscale" [1.200000]
		# "float reinhard_burn" [6.000000]
		# "integer displayinterval" [4]
		# "integer writeinterval" [10]
		# "string ldr_clamp_method" ["lum"]
		# "bool write_exr" ["false"]
		# "bool write_png" ["true"]
		# "string write_png_channels" ["RGB"]
		# "bool write_png_16bit" ["false"]
		# "bool write_png_gamutclamp" ["true"]
		# "bool write_tga" ["false"]
		# "string filename" ["exported_image"]
		# "bool write_resume_flm" ["false"]
		# "bool restart_resume_flm" ["true"]
		# "integer reject_warmup" [128]
		# "bool debug" ["true"]
		# "float colorspace_white" [0.314275 0.329411]
		# "float colorspace_red" [0.630000 0.340000]
		# "float colorspace_green" [0.310000 0.595000]
		# "float colorspace_blue" [0.155000 0.070000]
		# "float gamma" [2.200000]'
	end # END export_film

	##
	#
	##
	def export_render_settings(out)
		out.puts export_surface_integrator
		out.puts export_filter
		out.puts export_sampler
		out.puts export_volume_integrator
		out.puts export_accelerator
		out.puts "\n"
	end # END export_render_settings

	##
	#
	##
	def export_filter
		filter = "\n"
		filter += "PixelFilter \"#{@lrs.pixelfilter_type}\"\n"
		case @lrs.pixelfilter_type
			when "box"
				if (@lrs.pixelfilter_show_advanced)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_box_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_box_ywidth)}]\n"
				end
			when "gaussian"
				if (@lrs.pixelfilter_show_advanced)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_gaussian_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_gaussian_ywidth)}]\n"
					filter += "\t\"float alpha\" [#{"%.6f" %(@lrs.pixelfilter_gaussian_alpha)}]\n"
				end
			when "mitchell"
				if (@lrs.pixelfilter_show_advanced)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_mitchell_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_mitchell_ywidth)}]\n"
					case @lrs.pixelfilter_mitchell_optmode
						when "slider"
							sharpness = @lrs.pixelfilter_mitchell_sharpness
							filter += "\t\"float B\" [#{"%.6f" %(sharpness)}]\n"
							filter += "\t\"float C\" [#{"%.6f" %(sharpness)}]\n"
						when "manual"
							filter += "\t\"float B\" [#{"%.6f" %(@lrs.pixelfilter_mitchell_B)}]\n"
							filter += "\t\"float C\" [#{"%.6f" %(@lrs.pixelfilter_mitchell_C)}]\n"
						when "preset"
							# to be implemented following LuxBlend
					end
					supersample = @lrs.pixelfilter_mitchell_supersample ? "true" : "false"
					filter += "\t\"bool supersample\" [\"" + supersample + "\"]\n"
				else
					sharpness = @lrs.pixelfilter_mitchell_sharpness
					filter += "\t\"float B\" [#{"%.6f" %(sharpness)}]\n"
					filter += "\t\"float C\" [#{"%.6f" %(sharpness)}]\n"
					width = 1.5
					filter += "\t\"float xwidth\" [#{"%.6f" %(width)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(width)}]\n"
					filter += "\t\"bool supersample\" [\"true\"]\n"
				end
			when "sinc"
				if (@lrs.pixelfilter_show_advanced)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_sinc_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_sinc_ywidth)}]\n"
					filter += "\t\"float tau\" [#{"%.6f" %(@lrs.pixelfilter_sinc_tau)}]\n"
				end
			when "triangle"
				if (@lrs.pixelfilter_show_advanced)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_triangle_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_triangle_ywidth)}]\n"
				end
		end
		return filter
	end #END export_filter
	
	##
	#
	##
	def export_sampler
		sampler = "\n"
		sampler += "Sampler \"#{@lrs.sampler_type}\"\n"
		case @lrs.sampler_type
			when "metropolis"
				if (@lrs.sampler_show_advanced)
					sampler += "\t\"float largemutationprob\" [#{"%.6f" %(@lrs.sampler_metropolis_lmprob)}]\n"
					sampler += "\t\"integer maxconsecrejects\" [#{@lrs.sampler_metropolis_maxrejects.to_i}]\n"
					usevariance = @lrs.sampler_metropolis_usevariance ? "true" : "false"
					sampler += "\t\"bool usevariance\" [\"#{usevariance}\"]\n"
				else
					sampler += "\t\"float largemutationprob\" [#{"%.6f" %(1 - @lrs.sampler_metropolis_strength)}]\n"
				end
			when "lowdiscrepancy"
				sampler += "\t\"string pixelsampler\" [\"#{@lrs.sampler_lowdisc_pixelsampler}\"]\n"
				sampler += "\t\"integer pixelsamples\" [#{@lrs.sampler_lowdisc_pixelsamples.to_i}]\n"
			when "random"
				sampler += "\t\"string pixelsampler\" [\"#{@lrs.sampler_lowdisc_pixelsampler}\"]\n"
				sampler += "\t\"integer pixelsamples\" [#{@lrs.sampler_lowdisc_pixelsamples.to_i}]\n"
			when erpt
				sampler += "\t\"integer cheinlength\" [#{@lrs.sampler_erpt_chainlength.to_i}]\n"
		end
		return sampler
	end #END export_sampler

	##
	#
	##
	def export_surface_integrator
		integrator = "\n"
		integrator += "SurfaceIntegrator \"#{@lrs.sintegrator_type}\"\n"
		case @lrs.sintegrator_type
			# "bidirectional"
			when "bidirectional"
				if (@lrs.sintegrator_show_advanced)
					integrator += "\t\"integer eyedepth\" [#{@lrs.sintegrator_bidir_eyedepth}]\n"
					integrator += "\t\"integer lightdepth\" [#{@lrs.sintegrator_bidir_lightdepth}]\n"
					integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_bidir_strategy}\"]\n"
					integrator += "\t\"float eyerrthreshold\" [#{"%.6f" %(@lrs.sintegrator_bidir_eyethreshold)}]\n"
					integrator += "\t\"float lightrrthreshold\" [#{"%.6f" %(@lrs.sintegrator_bidir_lightthreshold)}]\n"
				else
					integrator += "\t\"integer eyedepth\" [#{@lrs.sintegrator_bidir_bounces.to_i}]\n"
					integrator += "\t\"integer lightdepth\" [#{@lrs.sintegrator_bidir_bounces.to_i}]\n"
				end
			# 'path'
			when 'path'
				if (@lrs.sintegrator_show_advanced)
					integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_path_maxdepth}]\n"
					environment = @lrs.sintegrator_path_include_environment ? "true" : "false"
					integrator += "\t\"bool includeenvironment\" [\"#{environment}\"]\n"
					integrator += "\t\"string rrstrategy\" [\"#{@lrs.sintegrator_path_rrstrategy}\"]\n"
					if (@lrs.sintegrator_path_rrstrategy == "probability")
						integrator += "\t\"float rrcontinueprob\" [#{"%.6f" %(@lrs.sintegrator_path_rrcontinueprob)}]\n"
					end
					integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_path_strategy}\"]\n"
					integrator += "\t\"integer shadowraycount\" [#{@lrs.sintegrator_path_shadow_ray_count}]\n"
				else
					integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_path_bounces}]\n"
					environment = @lrs.sintegrator_path_include_environment ? "true" : "false"
					integrator += "\t\"bool includeenvironment\" [\"#{environment}\"]\n"
				end
			# "distributedpath"
			when "distributedpath"
				bool_value = @lrs.sintegrator_distributedpath_directsampleall ? "true" : "false"
				integrator += "\t\"bool directsampleall\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer directsamples\" [#{@lrs.sintegrator_distributedpath_directsamples.to_i}]\n"
				bool_value = @lrs.sintegrator_distributedpath_directdiffuse ? "true" : "false"
				integrator += "\t\"bool directdiffuse\" [\"#{bool_value}\"]\n"
				bool_value = @lrs.sintegrator_distributedpath_directglossy ? "true" : "false"
				integrator += "\t\"bool directglossy\" [\"#{bool_value}\"]\n"
				bool_value = @lrs.sintegrator_distributedpath_indirectsampleall ? "true" : "false"
				integrator += "\t\"bool indirectsampleall\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer indirectsamples\" [#{@lrs.sintegrator_distributedpath_indirectsamples.to_i}]\n"
				bool_value = @lrs.sintegrator_distributedpath_indirectdiffuse ? "true" : "false"
				integrator += "\t\"bool indirectdiffuse\" [\"#{bool_value}\"]\n"
				bool_value = @lrs.sintegrator_distributedpath_indirectglossy ? "true" : "false"
				integrator += "\t\"bool indirectglossy\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer diffusereflectdepth\" [#{@lrs.sintegrator_distributedpath_diffusereflectdepth.to_i}]\n"
				integrator += "\t\"integer diffusereflectsamples\" [#{@lrs.sintegrator_distributedpath_diffusereflectsamples.to_i}]\n"
				integrator += "\t\"integer diffuserefractdepth\" [#{@lrs.sintegrator_distributedpath_diffuserefractdepth.to_i}]\n"
				integrator += "\t\"integer diffuserefractsamples\" [#{@lrs.sintegrator_distributedpath_diffuserefractsamples.to_i}]\n"
				integrator += "\t\"integer glossyreflectdepth\" [#{@lrs.sintegrator_distributedpath_glossyreflectdepth.to_i}]\n"
				integrator += "\t\"integer glossyreflectsamples\" [#{@lrs.sintegrator_distributedpath_glossyreflectsamples.to_i}]\n"
				integrator += "\t\"integer glossyrefractdepth\" [#{@lrs.sintegrator_distributedpath_glossyrefractdepth.to_i}]\n"
				integrator += "\t\"integer glossyrefractsamples\" [#{@lrs.sintegrator_distributedpath_glossyrefractsamples.to_i}]\n"
				integrator += "\t\"integer specularreflectdepth\" [#{@lrs.sintegrator_distributedpath_specularreflectdepth.to_i}]\n"
				integrator += "\t\"integer specularrefractdepth\" [#{@lrs.sintegrator_distributedpath_specularrefractdepth.to_i}]\n"
				integrator += "\t\"string strategy\" [\"#{@lrs.sintegrator_distributedpath_strategy}\"]\n"
				if (@lrs.sintegrator_distributedpath_reject)
					bool_value = @lrs.sintegrator_distributedpath_diffusereflectreject ? "true" : "false"
					integrator += "\t\"bool diffusereflectreject\" [\"#{bool_value}\"]\n"
					integrator += "\t\"float diffusereflectreject_threshold\" [#{"%.6f" %(@lrs.sintegrator_distributedpath_diffusereflectreject_threshold)}]\n"
					bool_value = @lrs.sintegrator_distributedpath_diffuserefractreject ? "true" : "false"
					integrator += "\t\"bool diffuserefractreject\" [\"#{bool_value}\"]\n"
					integrator += "\t\"float diffuserefractreject_threshold\" [#{"%.6f" %(@lrs.sintegrator_distributedpath_diffuserefractreject_threshold)}]\n"
					bool_value = @lrs.sintegrator_distributedpath_glossyreflectreject ? "true" : "false"
					integrator += "\t\"bool glossyreflectreject\" [\"#{bool_value}\"]\n"
					integrator += "\t\"float glossyreflectreject_threshold\" [#{"%.6f" %(@lrs.sintegrator_distributedpath_glossyreflectreject_threshold)}]\n"
					bool_value = @lrs.sintegrator_distributedpath_glossyrefractreject ? "true" : "false"
					integrator += "\t\"bool glossyrefractreject\" [\"#{bool_value}\"]\n"
					integrator += "\t\"float glossyrefractreject_threshold\" [#{"%.6f" %(@lrs.sintegrator_distributedpath_glossyrefractreject_threshold)}]\n"
				end

			# "directlighting"
			when "directlighting"
				if (@lrs.sintegrator_show_advanced)
					integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_direct_maxdepth}]\n"
				else
					integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_direct_bounces}]\n"
					integrator += "\t\"integer shadowraycount\" [#{@lrs.sintegrator_direct_shadow_ray_count}]\n"
					integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_direct_strategy}\"]\n"
				end
			# "exphotonmap"
			when "exphotonmap"
				integrator += "\t\"integer directphotons\" [#{@lrs.sintegrator_exphoton_directphotons}]\n"
				integrator += "\t\"integer causticphotons\" [#{@lrs.sintegrator_exphoton_causticphotons}]\n"
				finalgather = @lrs.sintegrator_exphoton_finalgather ? "true" : "false"
				integrator += "\t\"bool finalgather\" [\"#{finalgather}\"]\n"
				if (@lrs.sintegrator_exphoton_finalgather)
					integrator += "\t\"integer finalgathersamples\" [#{@lrs.sintegrator_exphoton_finalgathersamples}]\n"
					integrator += "\t\"string rrstrategy\" [\"#{@lrs.sintegrator_exphoton_rrstrategy}\"]\n"
					if (@lrs.sintegrator_exphoton_rrstrategy)
						integrator += "\t\"float rrcontinueprob\" [#{"%.6f" %(@lrs.sintegrator_exphoton_rrcontinueprob)}]\n"
					end
					integrator += "\t\"float gatherangle\" [#{"%.6f" %(@lrs.sintegrator_exphoton_gatherangle)}]\n"
				end
				integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_exphoton_maxdepth}]\n"
				integrator += "\t\"integer maxphotondepth\" [#{@lrs.sintegrator_exphoton_maxphotondepth}]\n"
				integrator += "\t\"integer nphotonsused\" [#{@lrs.sintegrator_exphoton_nphotonsused}]\n"
				integrator += "\t\"integer shadowraycount\" [#{@lrs.sintegrator_exphoton_shadow_ray_count}]\n"
				integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_exphoton_strategy}\"]\n"
				integrator += "\t\"string renderingmode\" [\"#{@lrs.sintegrator_exphoton_rendermode}\"]\n"
				if (@lrs.sintegrator_show_advanced)
					dbg = @lrs.sintegrator_exphoton_dbg_enable_direct ? "true" : "false"
					integrator += "\t\"bool dbg_enabledirect\" [\"#{dbg}\"]\n"
					dbg = @lrs.sintegrator_exphoton_dbg_enable_indircaustic ? "true" : "false"
					integrator += "\t\"bool dbg_enableindircaustic\" [\"#{dbg}\"]\n"
					dbg = @lrs.sintegrator_exphoton_dbg_enable_indirdiffuse ? "true" : "false"
					integrator += "\t\"bool dbg_enableindirdiffuse\" [\"#{dbg}\"]\n"
					dbg = @lrs.sintegrator_exphoton_dbg_enable_indirspecular ? "true" : "false"
					integrator += "\t\"bool dbg_enableindirspecular\" [\"#{dbg}\"]\n"
					dbg = @lrs.sintegrator_exphoton_dbg_enable_radiancemap ? "true" : "false"
					integrator += "\t\"bool dbg_enableradiancemap\" [\"#{dbg}\"]\n"
				end
			# "igi"
			when "igi"
				integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_igi_maxdepth}]\n"
				if (@lrs.sintegrator_show_advanced)
					integrator += "\t\"integer nsets\" [#{@lrs.sintegrator_igi_nsets}]\n"
					integrator += "\t\"integer nlights\" [#{@lrs.sintegrator_igi_nlights}]\n"
					integrator += "\t\"float mindist\" [#{"%.6f" %(@lrs.sintegrator_igi_mindist)}]\n"
				end
		end
		return integrator
		
	end #END export_surface_integrator
	
	##
	#
	##
	def export_accelerator
		accel = "\n"
		accel += "Accelerator \"#{@lrs.accelerator_type}\"\n"
		case @lrs.accelerator_type
			when "kdtree", "tabreckdtree"
				accel += "\t\"integer intersectcost\" [#{@lrs.kdtree_intersection_cost.to_i}]\n"
				accel += "\t\"integer traversalcost\" [#{@lrs.kdtree_traversal_cost.to_i}]\n"
				accel += "\t\"float emptybonus\" [#{"%.6f" %(@lrs.kdtree_empty_bonus)}]\n"
				accel += "\t\"integer maxprims\" [#{@lrs.kdtree_max_prims.to_i}]\n"
				accel += "\t\"integer maxdepth\" [#{@lrs.kdtree_max_depth.to_i}]\n"
			when "grid"
				refine = @lrs.grid_refine_immediately ? "true": "false"
				accel += "\t\"bool refineimmediately\" [\"#{refine}\"]\n"
			when "bvh"
			when "qbvh"
				accel += "\t\"integer maxprimsperleaf\" [#{@lrs.qbvh_max_prims_per_leaf.to_i}]\n"
				accel += "\t\"integer skipfactor\" [#{@lrs.qbvh_skip_factor.to_i}]\n"
		end
		return accel
	end
	##
	#
	##
	def export_volume_integrator
		volume = "\n"
		volume += "VolumeIntegrator \"#{@lrs.volume_integrator_type}\"\n"
		case @lrs.volume_integrator_type
			when "single"  
				volume += "\t\"float stepsize\" [#{"%.6f" %(@lrs.volume_integrator_stepsize)}]\n"
			when "emission"
				volume += "\t\"float stepsize\" [#{"%.6f" %(@lrs.volume_integrator_stepsize)}]\n"
		end
		return volume
	end
	##
	#
	##
	def export_light(out)
		sun_direction = Sketchup.active_model.shadow_info['SunDirection']
		out.puts "AttributeBegin"
		case @lrs.environment_light_type
			when 'sunsky'
				out.puts "\tLightGroup \"#{@lrs.environment_sky_lightgroup}\""
				out.puts "\tLightSource \"sky\""
				out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_sky_gain)}]"
				out.puts "\t\"float turbidity\" [#{"%.6f" %(@lrs.environment_sky_turbidity)}]"
				out.puts "\t\"vector sundir\" [#{"%.6f" %(sun_direction.x)} #{"%.6f" %(sun_direction.y)} #{"%.6f" %(sun_direction.z)}]"
				out.puts "\tLightGroup \"#{@lrs.environment_sun_lightgroup}\""
				out.puts "\tLightSource \"sun\""
				out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_sun_gain)}]"
				out.puts "\t\"float relsize\" [#{"%.6f" %(@lrs.environment_sun_relsize)}]"
				out.puts "\t\"float turbidity\" [#{"%.6f" %(@lrs.environment_sun_turbidity)}]"
				out.puts "\t\"vector sundir\" [#{"%.6f" %(sun_direction.x)} #{"%.6f" %(sun_direction.y)} #{"%.6f" %(sun_direction.z)}]"
			when 'infinite'
				out.puts "\tLightGroup \"#{@lrs.environment_infinite_lightgroup}\""
				out.puts "\tLightSource \"infinite\""
				out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_infinite_gain)}]"
				if ( ! @lrs.environment_infinite_map.strip.empty?)
					out.puts "\t\"float gamma\" [#{"%.6f" %(@lrs.environment_infinite_gamma)}]"
					out.puts "\t\"string mapping\" [\"" + @lrs.environment_infinite_map_type + "\"]"
					out.puts "\t\"string mapname\" [\"" + @lrs.environment_infinite_map + "\"]"
				end
				if (@lrs.use_environment_infinite_sun)
					out.puts "\tLightGroup \"#{@lrs.environment_sun_lightgroup}\""
					out.puts "\tLightSource \"sun\""
					out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_sun_gain)}]"
					out.puts "\t\"float relsize\" [#{"%.6f" %(@lrs.environment_sun_relsize)}]"
					out.puts "\t\"float turbidity\" [#{"%.6f" %(@lrs.environment_sun_turbidity)}]"
					out.puts "\t\"vector sundir\" [#{"%.6f" %(sun_direction.x)} #{"%.6f" %(sun_direction.y)} #{"%.6f" %(sun_direction.z)}]"
				end
		end
		out.puts "AttributeEnd"
	end # END export_light

	##
	#
	##
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
	end # END export_mesh

	##
	#
	##
	def export_faces(out)
		@materials.each{|mat,value|
			if (value!=nil and value!=[])
				export_face(out,mat,false)
				@materials[mat]=nil
			end}
		@materials={}
	end # END export_faces

	##
	#
	##
	def export_fm_faces(out)
		@fm_materials.each{|mat,value|
			if (value!=nil and value!=[])
				export_face(out,mat,true)
				@fm_materials[mat]=nil
			end}
		@fm_materials={}
	end # END export_fm_faces

	##
	#
	##
	def point_to_vector(p)
		Geom::Vector3d.new(p.x,p.y,p.z)
	end # END point_to_vector

	##
	#
	##
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
			has_texture=true if matname!=SU2LUX::FRONT_FACE_MATERIAL
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
			default_mat.push(ft[0].material==nil)
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
	end # END export_face

	##
	#
	##
	def export_used_materials(materials, out)
		materials.each { |mat|
			luxrender_mat = LuxrenderMaterial.new(mat)
			SU2LUX.dbg_p luxrender_mat.name
			export_mat(luxrender_mat, out)
		}
	end # END export_used_materials

	##
	#
	##
	def export_textures(out)
		@model_textures.each { |key,value|
		export_texture(key,value[4],out)
		}
	end # END export_textures

	##
	#
	##
	def export_texture(texture_name,texture_path,out)
		out.puts "\Texture \""+texture_name+"\" \"color\" \"imagemap\" \"string filename\" [\""+texture_path+ "\"]"
		out.puts "MakeNamedMaterial \"" + texture_name + "\""
		out.puts "\"string type\" [\"matte\"]"
		out.puts "\"texture Kd\" [\""+texture_name+"\"]"
	end # END export_texture

	##
	#
	##
	def export_mat(mat, out)
		SU2LUX.dbg_p "export_mat"
		out.puts "# Material '" + mat.name + "'"
		case mat.type
			when "matte"
				out.puts "MakeNamedMaterial \"" + mat.name + "\""
				SU2LUX.dbg_p "mat.name " + mat.name
				out.puts  "\"string type\" [\"matte\"]"
				out.puts  "\"color Kd\" [#{"%.6f" %(mat.color.red.to_f/255)} #{"%.6f" %(mat.color.green.to_f/255)} #{"%.6f" %(mat.color.blue.to_f/255)}]"
			when "glass"
				out.puts "MakeNamedMaterial \"" + mat.name + "\""
				SU2LUX.dbg_p "mat.name " + mat.name
	#   "bool architectural" ["true"]
				out.puts  "\"string type\" [\"glass\"]"
				out.puts  "\"color Kt\" [#{"%.6f" %(mat.color.red.to_f/255)} #{"%.6f" %(mat.color.green.to_f/255)} #{"%.6f" %(mat.color.blue.to_f/255)}]"
				out.puts "\"float index\" [1.520000]"
			when "light"
				out.puts "Texture \"" + mat.name + ":light:L\" \"color\" \"blackbody\"
					\"float temperature\" [6500.000000]"
		end
		out.puts("\n")
	end # END export_mat

	##
	#
	##
	def write_textures
		@copy_textures=true #TODO add in settings export
		
		if (@copy_textures == true and @model_textures!={})

			if FileTest.exist?(@path_textures+@os_separator+SU2LUX::PREFIX_TEXTURES+@model_name)
			else
				Dir.mkdir(@path_textures+@os_separator+SU2LUX::PREFIX_TEXTURES+@model_name)
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

	end # END write_textures

end # END class LuxrenderEXport
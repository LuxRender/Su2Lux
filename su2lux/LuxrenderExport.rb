class LuxrenderExport
	attr_reader :count_tri
	attr_reader :used_materials
    
	def initialize(export_file_path,os_separator)
		@lrs=LuxrenderSettings.new
		@export_file_path=export_file_path
		@model_name=File.basename(@export_file_path)
		@model_name=@model_name.split(".")[0]
        @instance_name = 0
		@os_separator=os_separator
		@has_portals = false
        @mat_step = 0 # monitors export progress
        @current_step = 0
        @total_step = 0
        @texexport = "skp"
        @texfolder = ""
        
        @currentluxmat = nil
        @currentmatname = ""
        @currenttexname = ""
        @currentfilename = ""
        
	end # END initialize

	def reset
		@has_portals = false
		@materials = {}
		@fm_materials = {}
		@count_faces = 0
		@clay=false
		@exp_default_uvs = false
		@scale = 0.0254
		@count_tri = 0
		@model_textures={}
        @instance_name = 0
		@lrs.fleximage_xresolution = Sketchup.active_model.active_view.vpwidth unless @lrs.fleximage_xresolution
		@lrs.fleximage_yresolution = Sketchup.active_model.active_view.vpheight unless @lrs.fleximage_yresolution
	end #END reset

	def export_global_settings(out)
		out.puts "# LuxRender Scene File"
		out.puts "# Exported by SU2LUX #{SU2LUX::SU2LUX_VERSION}"
		out.puts "# Global Information"
	end # END export_global_settings

	def export_camera(view, out)
		user_camera = view.camera
		user_eye = user_camera.eye
		user_target=user_camera.target
		user_up=user_camera.up

		out_user_target = "%12.6f" %(user_target.x.to_m.to_f) + " " + "%12.6f" %(user_target.y.to_m.to_f) + " " + "%12.6f" %(user_target.z.to_m.to_f)
		out_user_up = "%12.6f" %(user_up.x) + " " + "%12.6f" %(user_up.y) + " " + "%12.6f" %(user_up.z)
		out.puts " LookAt"
		out.puts "%12.6f" %(user_eye.x.to_m.to_f) + " " + "%12.6f" %(user_eye.y.to_m.to_f) + " " + "%12.6f" %(user_eye.z.to_m.to_f)
		out.puts out_user_target
		out.puts out_user_up
		out.print "\n"

		camera_scale = 1.0
        
		out.puts "Camera \"#{@lrs.camera_type}\""
		case @lrs.camera_type
			when "perspective"
				fov = compute_fov(@lrs.fleximage_xresolution, @lrs.fleximage_yresolution)
				out.puts "	\"float fov\" [%.6f" %(fov) + "]"
			when "orthographic"
                # scale is taken into account in screenwindow declaration
			when "environment"
				# out.puts "Camera \"#{@lrs.camera_type}\""
		end
		
		if (@lrs.use_clipping)
			out.puts "\t\"float hither\" [" + "%.6f" %(@lrs.hither) + "]"
			out.puts "\t\"float yon\" [" + "%.6f" %(@lrs.yon) + "]"
		end
		
		
		if (@lrs.use_dof_bokeh)
            radiusfromaperture = 0.0005 * @lrs.focal_length.to_f / @lrs.aperture.to_f
			out.puts "\t\"float lensradius\" [%.6f" %(radiusfromaperture) + "]"
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
		out.print "\n"
	end # END export_camera

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

	def compute_screen_window
        cam_shiftX = 0.0
		cam_shiftY = 0.0
        # if lens shift is on
        if (@lrs.use_architectural)
            cam_shiftX = @lrs.shiftX.to_f
            cam_shiftY = @lrs.shiftY.to_f
        end
		ratio = @lrs.fleximage_xresolution.to_f / @lrs.fleximage_yresolution.to_f
		inv_ratio = 1.0 / ratio
        
        # todo 2014: 2d camera logic
        # get variables necessary for two point perspective offset calculation
        camtarget = Sketchup.active_model.active_view.camera.target
        skp_view_height = Sketchup.active_model.active_view.vpheight
        skp_view_width = Sketchup.active_model.active_view.vpwidth
        target_x = Sketchup.active_model.active_view.screen_coords(camtarget)[0]
        target_y = Sketchup.active_model.active_view.screen_coords(camtarget)[1]
        target_fraction_x_skp = (skp_view_width / ( skp_view_height * ratio)) * ( (0.5 * skp_view_width - target_x) / skp_view_width)
        target_fraction_y_skp = 0.5 - target_y / skp_view_height
        offsetx = 2 * target_fraction_x_skp
        offsety = -2 * target_fraction_y_skp
        puts "CALCULATED X, Y OFFSET:"
        puts target_fraction_x_skp
        puts target_fraction_y_skp

        # todo 2014: check portrait aspect ratio offset
        # ...
        # ...
        
        if (@lrs.camera_type=='orthographic')
            imageheight = Sketchup.active_model.active_view.camera.height.to_m
            imagewidth = ratio * imageheight
            screen_window = [-0.5*imagewidth, 0.5*imagewidth, -0.5*imageheight, 0.5*imageheight] # lens shift not used here
        else # perspective or environment
        if (ratio > 1.0)
            screen_window = [2 * cam_shiftX - ratio + offsetx, 2 * cam_shiftX + ratio + offsetx, 2 * cam_shiftY - 1.0 + offsety, 2 * cam_shiftY + 1.0 + offsety]
            #screen_window = [2 * cam_shiftX - ratio, 2 * cam_shiftX + ratio, 2 * cam_shiftY - 1.0, 2 * cam_shiftY + 1.0]
            else
                screen_window = [2 * cam_shiftX - 1.0, 2 * cam_shiftX + 1.0, 2 * cam_shiftY - inv_ratio, 2 * cam_shiftY + inv_ratio]
            end
        end
	end # END compute_screen_window

	def export_film(out,file_basename)
		out.puts "Film \"fleximage\""
		percent = @lrs.fleximage_resolution_percent.to_i / 100.0
		xres = @lrs.fleximage_xresolution.to_i * percent
		yres = @lrs.fleximage_yresolution.to_i * percent
		out.puts "\t\"integer xresolution\" [#{xres.to_i}]"
		out.puts "\t\"integer yresolution\" [#{yres.to_i}]"
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
			when "reinhard"
				out.puts "\t\"float reinhard_prescale\" [#{"%.6f" %(@lrs.fleximage_reinhard_prescale)}]\n"
				out.puts "\t\"float reinhard_postscale\" [#{"%.6f" %(@lrs.fleximage_reinhard_postscale)}]\n"
				out.puts "\t\"float reinhard_burn\" [#{"%.6f" %(@lrs.fleximage_reinhard_burn)}]\n"
			when "linear"
				if (@lrs.fleximage_linear_use_preset)
					out.puts "\t\"float linear_sensitivity\" [#{"%.6f" %(@lrs.fleximage_linear_iso)}]\n"
					if (@lrs.fleximage_linear_use_half_stop == true)
						fstop = @lrs.fleximage_linear_hf_stopT
					else
						fstop = @lrs.fleximage_linear_hf_stopF
					end
					out.puts "\t\"float linear_fstop\" [#{"%.6f" %(fstop)}]\n"

					case @lrs.fleximage_linear_camera_type
						when "photo"
							exposure_preset = @lrs.fleximage_linear_photo_exposure
						when "cinema"
							exposure_preset = @lrs.fleximage_linear_cinema_exposure
					end
					exposure = get_exposure(@lrs.fleximage_linear_camera_type, exposure_preset, @lrs.fleximage_linear_cinema_fps)
					out.puts "\t\"float linear_exposure\" [#{"%.6f" %(exposure)}]\n"
				else
					out.puts "\t\"float linear_sensitivity\" [#{"%.6f" %(@lrs.fleximage_linear_sensitivity)}]\n"
					out.puts "\t\"float linear_exposure\" [#{"%.6f" %(@lrs.fleximage_linear_exposure)}]\n"
					out.puts "\t\"float linear_fstop\" [#{"%.6f" %(@lrs.fleximage_linear_fstop)}]\n"
				end
			when "contrast"
				out.puts "\t\"float contrast_ywa\" [#{"%.6f" %(@lrs.fleximage_contrast_ywa)}]\n"
			when "maxwhite"
		end
		exr = @lrs.fleximage_write_exr ? "true" : "false"
		out.puts "\t\"bool write_exr\" [\"#{exr}\"]\n"
		if (@lrs.fleximage_write_exr)
			out.puts "\t\"string write_exr_channels\" [\"#{@lrs.fleximage_write_exr_channels}\"]"
			bits = @lrs.fleximage_write_exr_halftype ? "true" : "false"
			out.puts "\t\"bool write_exr_halftype\" [\"#{bits}\"]\n"
			out.puts "\t\"string write_exr_compressiontype\" [\"#{@lrs.fleximage_write_exr_compressiontype}\"]"
			if (@lrs.fleximage_write_exr_applyimaging)
				gamut = @lrs.fleximage_write_exr_gamutclamp ? "true" : "false"
				out.puts "\t\"bool write_exr_gamutclamp\" [\"#{gamut}\"]\n"
			end
			if (@lrs.fleximage_write_exr_ZBuf)
				out.puts "\t\"string write_exr_zbuf_normalizationtype\" [\"#{@lrs.fleximage_write_exr_zbuf_normalizationtype}\"]"
			end
		end
		png = @lrs.fleximage_write_png ? "true" : "false"
		out.puts "\t\"bool write_png\" [\"#{png}\"]\n"
		if (@lrs.fleximage_write_png)
			out.puts "\t\"string write_png_channels\" [\"#{@lrs.fleximage_write_png_channels}\"]"
			bits = @lrs.fleximage_write_png_16bit ? "true" : "false"
			out.puts "\t\"bool write_png_16bit\" [\"#{bits}\"]\n"
			gamut = @lrs.fleximage_write_png_gamutclamp ? "true" : "false"
			out.puts "\t\"bool write_png_gamutclamp\" [\"#{gamut}\"]\n"
			if (@lrs.fleximage_write_png_ZBuf)
				out.puts "\t\"string write_png_zbuf_normalizationtype\" [\"#{@lrs.fleximage_write_png_zbuf_normalizationtype}\"]"
			end
		end
		tga = @lrs.fleximage_write_tga ? "true" : "false"
		out.puts "\t\"bool write_tga\" [\"#{tga}\"]\n"
		if (@lrs.fleximage_write_tga)
			out.puts "\t\"string write_tga_channels\" [\"#{@lrs.fleximage_write_tga_channels}\"]"
			gamut = @lrs.fleximage_write_tga_gamutclamp ? "true" : "false"
			out.puts "\t\"bool write_exr_gamutclamp\" [\"#{gamut}\"]\n"
			if (@lrs.fleximage_write_tga_ZBuf)
				out.puts "\t\"string write_tga_zbuf_normalizationtype\" [\"#{@lrs.fleximage_write_tga_zbuf_normalizationtype}\"]"
			end
		end
		flm = @lrs.fleximage_write_resume_flm ? "true" : "false"
		out.puts "\t\"bool write_resume_flm\" [\"#{flm}\"]\n"
		flm = @lrs.fleximage_restart_resume_flm ? "true" : "false"
		out.puts "\t\"bool restart_resume_flm\" [\"#{flm}\"]\n"
		out.puts "\t\"string filename\" [\"#{file_basename}\"]"
        dbg = @lrs.fleximage_debug ? "true" : "false"
		out.puts "\t\"bool debug\" [\"#{dbg}\"]\n"
		if (@lrs.fleximage_use_preset)
		SU2LUX.dbg_p @lrs.fleximage_colorspace_preset
			case @lrs.fleximage_colorspace_preset
				when "sRGB - HDTV (ITU-R BT.709-5)"
					cspacewhiteX = 0.314275
					cspacewhiteY = 0.329411 # sRGB
					cspaceredX = 0.63
					cspaceredY = 0.34
					cspacegreenX = 0.31
					cspacegreenY = 0.595
					cspaceblueX = 0.155
					cspaceblueY = 0.07
				when "ROMM RGB"
					cspacewhiteX = 0.346
					cspacewhiteY = 0.359 # D50
					cspaceredX = 0.7347
					cspaceredY = 0.2653
					cspacegreenX = 0.1596
					cspacegreenY = 0.8404
					cspaceblueX = 0.0366
					cspaceblueY = 0.0001
				when "Adobe RGB 98"
					cspacewhiteX = 0.313
					cspacewhiteY = 0.329 # D65
					cspaceredX = 0.64
					cspaceredY = 0.34
					cspacegreenX = 0.21
					cspacegreenY = 0.71
					cspaceblueX = 0.15
					cspaceblueY = 0.06
				when "Apple RGB"
					cspacewhiteX = 0.313
					cspacewhiteY = 0.329 # D65
					cspaceredX = 0.625
					cspaceredY = 0.34
					cspacegreenX = 0.28
					cspacegreenY = 0.595
					cspaceblueX = 0.155
					cspaceblueY = 0.07
				when "NTSC (FCC 1953, ITU-R BT.470-2 System M)"
					cspacewhiteX = 0.310
					cspacewhiteY = 0.316 # C
					cspaceredX = 0.67
					cspaceredY = 0.33
					cspacegreenX = 0.21
					cspacegreenY = 0.71
					cspaceblueX = 0.14
					cspaceblueY = 0.08
				when "NTSC (FCC 1953, ITU-R BT.470-2 System M)"
					cspacewhiteX = 0.313
					cspacewhiteY = 0.329 # D65
					cspaceredX = 0.63
					cspaceredY = 0.34
					cspacegreenX = 0.31
					cspacegreenY = 0.595
					cspaceblueX = 0.155
					cspaceblueY = 0.07
				when "PAL/SECAM (EBU 3213, ITU-R BT.470-6)"
					cspacewhiteX = 0.313
					cspacewhiteY = 0.329 # D65
					cspaceredX = 0.64
					cspaceredY = 0.33
					cspacegreenX = 0.29
					cspacegreenY = 0.60
					cspaceblueX = 0.15
					cspaceblueY = 0.06
				when "CIE (1931) E"
					cspacewhiteX = 0.333
					cspacewhiteY = 0.333 # E
					cspaceredX = 0.7347
					cspaceredY = 0.2653
					cspacegreenX = 0.2738
					cspacegreenY = 0.7174
					cspaceblueX = 0.1666
					cspaceblueY = 0.0089
			end
			if (@lrs.fleximage_use_colorspace_gamma)
				gamma = @lrs.fleximage_gamma
			else
				gamma = @lrs.fleximage_colorspace_gamma
			end
			if ( ! @lrs.fleximage_use_colorspace_whitepoint)
				if (@lrs.fleximage_use_colorspace_whitepoint_preset)
					if (((@lrs.fleximage_colorspace_wp_preset)).include?("E - "))
						cspacewhiteX = 0.333
						cspacewhiteY = 0.333
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("D50 - "))
						cspacewhiteX = 0.346
						cspacewhiteY = 0.359
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("D55 - "))
						cspacewhiteX = 0.332
						cspacewhiteY = 0.347
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("D65 - "))
						cspacewhiteX = 0.313
						cspacewhiteY = 0.329
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("D75 - "))
						cspacewhiteX = 0.299
						cspacewhiteY = 0.315
					elsif (((@lrs.fleximage_colorspace_wp_preset)).include?("A - "))
						cspacewhiteX = 0.448
						cspacewhiteY = 0.407
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("B - "))
						cspacewhiteX = 0.348
						cspacewhiteY = 0.352
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("C - "))
						cspacewhiteX = 0.310
						cspacewhiteY = 0.316
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("9300"))
						cspacewhiteX = 0.285
						cspacewhiteY = 0.293
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("F2 - "))
						cspacewhiteX = 0.372
						cspacewhiteY = 0.375
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("F7 - "))
						cspacewhiteX = 0.313
						cspacewhiteY = 0.329
					elsif ((@lrs.fleximage_colorspace_wp_preset).include?("F11 - "))
						cspacewhiteX = 0.381
						cspacewhiteY = 0.377
					end
				else
					cspacewhiteX = @lrs.fleximage_colorspace_preset_white_x
					cspacewhiteY = @lrs.fleximage_colorspace_preset_white_y
				end
			end
			out.puts "\t\"float colorspace_white\" [#{"%.6f" %(cspacewhiteX)} #{"%.6f" %(cspacewhiteY)}]\n"
			out.puts "\t\"float colorspace_red\" [#{"%.6f" %(cspaceredX)} #{"%.6f" %(cspaceredY)}]\n"
			out.puts "\t\"float colorspace_green\" [#{"%.6f" %(cspacegreenX)} #{"%.6f" %(cspacegreenY)}]\n"
			out.puts "\t\"float colorspace_blue\" [#{"%.6f" %(cspaceblueX)} #{"%.6f" %(cspaceblueY)}]\n"
			out.puts "\t\"float gamma\" [#{"%.6f" %(gamma)}]\n"
		else
			out.puts "\t\"float colorspace_white\" [#{"%.6f" %(@lrs.fleximage_colorspace_white_x)} #{"%.6f" %(@lrs.fleximage_colorspace_white_y)}]\n"
			out.puts "\t\"float colorspace_red\" [#{"%.6f" %(@lrs.fleximage_colorspace_red_x)} #{"%.6f" %(@lrs.fleximage_colorspace_red_y)}]\n"
			out.puts "\t\"float colorspace_green\" [#{"%.6f" %(@lrs.fleximage_colorspace_green_x)} #{"%.6f" %(@lrs.fleximage_colorspace_green_y)}]\n"
			out.puts "\t\"float colorspace_blue\" [#{"%.6f" %(@lrs.fleximage_colorspace_blue_x)} #{"%.6f" %(@lrs.fleximage_colorspace_blue_y)}]\n"
			out.puts "\t\"float gamma\" [#{"%.6f" %(@lrs.fleximage_gamma)}]\n"
		end
		out.puts "\t\"integer outlierrejection_k\" [#{@lrs.fleximage_outlierrejection_k.to_i}]"
		
		# flm = @lrs.useparamkeys ? "true" : "false"
		# out.puts "\t\"bool useparamkeys\" [\"#{flm}\"]\n"
	end # END export_film

	def get_exposure(type, shutterStr, fpsStr)
		if (type == 'photo')
			fps = 1
		else
			fps = fpsStr.split(" ")[0].to_f  # assuming fps are in form 'n FPS'
		end

		if (shutterStr == '1')
			exp = 1.0
		elsif (type == 'photo')
			exp = 1.0 / shutterStr[/(?!.*?\/).*/].to_f  # assuming still camera shutterspeed is in form '1/n'
		elsif (type == 'cinema')
			exp = (1.0 / fps) * (1 - shutterStr.split("-")[1].to_f/360) # assuming motion camera shutterspeed is in form 'n-degree'
		end
		return exp
	end

	def export_render_settings(out)
		out.puts export_surface_integrator
		out.puts export_filter
		out.puts export_sampler
		out.puts export_volume_integrator
		out.puts export_accelerator
		out.puts "\n"
	end # END export_render_settings

	def export_filter
		filter = "\n"
		filter += "PixelFilter \"#{@lrs.pixelfilter_type}\"\n"
		case @lrs.pixelfilter_type
			when "box"
				if (@lrs.pixelfilter_show_advanced_box)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_box_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_box_ywidth)}]\n"
				end
			when "gaussian"
				if (@lrs.pixelfilter_show_advanced_gaussian)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_gaussian_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_gaussian_ywidth)}]\n"
					filter += "\t\"float alpha\" [#{"%.6f" %(@lrs.pixelfilter_gaussian_alpha)}]\n"
				end
			when "mitchell"
				if (@lrs.pixelfilter_show_advanced_mitchell)
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
				if (@lrs.pixelfilter_show_advanced_sinc)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_sinc_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_sinc_ywidth)}]\n"
					filter += "\t\"float tau\" [#{"%.6f" %(@lrs.pixelfilter_sinc_tau)}]\n"
				end
			when "triangle"
				if (@lrs.pixelfilter_show_advanced_triangle)
					filter += "\t\"float xwidth\" [#{"%.6f" %(@lrs.pixelfilter_triangle_xwidth)}]\n"
					filter += "\t\"float ywidth\" [#{"%.6f" %(@lrs.pixelfilter_triangle_ywidth)}]\n"
				end
		end
		return filter
	end #END export_filter

	def export_sampler
		sampler = "\n"
		sampler += "Sampler \"#{@lrs.sampler_type}\"\n"
        usevariance = @lrs.sampler_metropolis_usevariance ? "true" : "false"
        noiseaware = @lrs.sampler_noiseaware ? "true" : "false"
		case @lrs.sampler_type
			when "metropolis"
                sampler += "\t\"float largemutationprob\" [#{"%.6f" %(@lrs.sampler_metropolis_largemutationprob)}]\n"
                sampler += "\t\"integer maxconsecrejects\" [#{@lrs.sampler_metropolis_maxconsecrejects.to_i}]\n"
                sampler += "\t\"bool usevariance\" [\"#{usevariance}\"]\n"
                sampler += "\t\"bool noiseaware\" [\"#{noiseaware}\"]\n"
			when "lowdiscrepancy"
				sampler += "\t\"string pixelsampler\" [\"#{@lrs.sampler_lowdisc_pixelsampler}\"]\n"
				sampler += "\t\"integer pixelsamples\" [#{@lrs.sampler_lowdisc_pixelsamples.to_i}]\n"
                sampler += "\t\"bool noiseaware\" [\"#{noiseaware}\"]\n"
			when "random"
				sampler += "\t\"string pixelsampler\" [\"#{@lrs.sampler_random_pixelsampler}\"]\n"
				sampler += "\t\"integer pixelsamples\" [#{@lrs.sampler_random_pixelsamples.to_i}]\n"
                sampler += "\t\"bool noiseaware\" [\"#{noiseaware}\"]\n"
			when "erpt"
                sampler += "\t\"integer chainlength\" [#{@lrs.sampler_erpt_chainlength.to_i}]\n"
            when "sobol"
                sampler += "\n"
                sampler += "\t\"bool noiseaware\" [\"#{noiseaware}\"]\n"
		end
		return sampler
	end #END export_sampler

	def export_surface_integrator
		integrator = "\n"
		integrator += "SurfaceIntegrator \"#{@lrs.sintegrator_type}\"\n"
		case @lrs.sintegrator_type
			# "bidirectional"
			when "bidirectional"
				if (@lrs.sintegrator_bidir_show_advanced)
					integrator += "\t\"integer eyedepth\" [#{@lrs.sintegrator_bidir_eyedepth}]\n"
					integrator += "\t\"integer lightdepth\" [#{@lrs.sintegrator_bidir_lightdepth}]\n"
					integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_bidir_strategy}\"]\n"
					integrator += "\t\"float eyerrthreshold\" [#{"%.6f" %(@lrs.sintegrator_bidir_eyerrthreshold)}]\n"
					integrator += "\t\"float lightrrthreshold\" [#{"%.6f" %(@lrs.sintegrator_bidir_lightthreshold)}]\n"
				else
					integrator += "\t\"integer eyedepth\" [#{@lrs.sintegrator_bidir_bounces.to_i}]\n"
					integrator += "\t\"integer lightdepth\" [#{@lrs.sintegrator_bidir_bounces.to_i}]\n"
				end
			# 'path'
			when "path"
				if (@lrs.sintegrator_path_show_advanced)
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
				integrator += "\t\"string strategy\" [\"#{@lrs.sintegrator_distributedpath_strategy}\"]\n"
				bool_value = @lrs.sintegrator_distributedpath_directsampleall ? "true" : "false"
				integrator += "\t\"bool directsampleall\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer directsamples\" [#{@lrs.sintegrator_distributedpath_directsamples.to_i}]\n"
				bool_value = @lrs.sintegrator_distributedpath_indirectsampleall ? "true" : "false"
				integrator += "\t\"bool indirectsampleall\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer indirectsamples\" [#{@lrs.sintegrator_distributedpath_indirectsamples.to_i}]\n"
				integrator += "\t\"integer diffusereflectdepth\" [#{@lrs.sintegrator_distributedpath_diffusereflectdepth.to_i}]\n"
				integrator += "\t\"integer diffusereflectsamples\" [#{@lrs.sintegrator_distributedpath_diffusereflectsamples.to_i}]\n"
				integrator += "\t\"integer diffuserefractdepth\" [#{@lrs.sintegrator_distributedpath_diffuserefractdepth.to_i}]\n"
				integrator += "\t\"integer diffuserefractsamples\" [#{@lrs.sintegrator_distributedpath_diffuserefractsamples.to_i}]\n"
				bool_value = @lrs.sintegrator_distributedpath_directdiffuse ? "true" : "false"
				integrator += "\t\"bool directdiffuse\" [\"#{bool_value}\"]\n"
				bool_value = @lrs.sintegrator_distributedpath_indirectdiffuse ? "true" : "false"
				integrator += "\t\"bool indirectdiffuse\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer glossyreflectdepth\" [#{@lrs.sintegrator_distributedpath_glossyreflectdepth.to_i}]\n"
				integrator += "\t\"integer glossyreflectsamples\" [#{@lrs.sintegrator_distributedpath_glossyreflectsamples.to_i}]\n"
				integrator += "\t\"integer glossyrefractdepth\" [#{@lrs.sintegrator_distributedpath_glossyrefractdepth.to_i}]\n"
				integrator += "\t\"integer glossyrefractsamples\" [#{@lrs.sintegrator_distributedpath_glossyrefractsamples.to_i}]\n"
				bool_value = @lrs.sintegrator_distributedpath_directglossy ? "true" : "false"
				integrator += "\t\"bool directglossy\" [\"#{bool_value}\"]\n"
				bool_value = @lrs.sintegrator_distributedpath_indirectglossy ? "true" : "false"
				integrator += "\t\"bool indirectglossy\" [\"#{bool_value}\"]\n"
				integrator += "\t\"integer specularreflectdepth\" [#{@lrs.sintegrator_distributedpath_specularreflectdepth.to_i}]\n"
				integrator += "\t\"integer specularrefractdepth\" [#{@lrs.sintegrator_distributedpath_specularrefractdepth.to_i}]\n"
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
				if (@lrs.sintegrator_direct_show_advanced)
					integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_direct_maxdepth}]\n"
					integrator += "\t\"integer shadowraycount\" [#{@lrs.sintegrator_direct_shadow_ray_count}]\n"
					integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_direct_strategy}\"]\n"
				else
					integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_direct_bounces}]\n"
				end
			# "exphotonmap"
			when "exphotonmap"
				integrator += "\t\"integer directphotons\" [#{@lrs.sintegrator_exphoton_directphotons}]\n"
				integrator += "\t\"integer indirectphotons\" [#{@lrs.sintegrator_exphoton_indirectphotons}]\n"
				integrator += "\t\"integer causticphotons\" [#{@lrs.sintegrator_exphoton_causticphotons}]\n"
				finalgather = @lrs.sintegrator_exphoton_finalgather ? "true" : "false"
				integrator += "\t\"bool finalgather\" [\"#{finalgather}\"]\n"
				if (@lrs.sintegrator_exphoton_finalgather)
					integrator += "\t\"integer finalgathersamples\" [#{@lrs.sintegrator_exphoton_finalgathersamples}]\n"
					integrator += "\t\"string rrstrategy\" [\"#{@lrs.sintegrator_exphoton_rrstrategy}\"]\n"
					if (@lrs.sintegrator_exphoton_rrstrategy.match("probability"))
						integrator += "\t\"float rrcontinueprob\" [#{"%.6f" %(@lrs.sintegrator_exphoton_rrcontinueprob)}]\n"
					end
					integrator += "\t\"float gatherangle\" [#{"%.6f" %(@lrs.sintegrator_exphoton_gatherangle)}]\n"
				end
				integrator += "\t\"integer maxdepth\" [#{@lrs.sintegrator_exphoton_maxdepth}]\n"
				integrator += "\t\"integer maxphotondepth\" [#{@lrs.sintegrator_exphoton_maxphotondepth}]\n"
				integrator += "\t\"float maxphotondist\" [#{"%.6f" %(@lrs.sintegrator_exphoton_maxphotondist)}]\n"
				integrator += "\t\"integer nphotonsused\" [#{@lrs.sintegrator_exphoton_nphotonsused}]\n"
				integrator += "\t\"integer shadowraycount\" [#{@lrs.sintegrator_exphoton_shadow_ray_count}]\n"
				integrator += "\t\"string lightstrategy\" [\"#{@lrs.sintegrator_exphoton_strategy}\"]\n"
				integrator += "\t\"string renderingmode\" [\"#{@lrs.sintegrator_exphoton_renderingmode}\"]\n"
				if (@lrs.sintegrator_exphoton_show_advanced)
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
				if (@lrs.sintegrator_igi_show_advanced)
					integrator += "\t\"integer nsets\" [#{@lrs.sintegrator_igi_nsets}]\n"
					integrator += "\t\"integer nlights\" [#{@lrs.sintegrator_igi_nlights}]\n"
					integrator += "\t\"float mindist\" [#{"%.6f" %(@lrs.sintegrator_igi_mindist)}]\n"
				end
		end
		return integrator
		
	end #END export_surface_integrator

	def export_accelerator
		accel = "\n"
		accel += "Accelerator \"#{@lrs.accelerator_type}\"\n"
		case @lrs.accelerator_type
			when "kdtree", "tabreckdtree"
				accel += "\t\"integer intersectcost\" [#{@lrs.kdtree_intersectcost.to_i}]\n"
				accel += "\t\"integer traversalcost\" [#{@lrs.kdtree_traversalcost.to_i}]\n"
				accel += "\t\"float emptybonus\" [#{"%.6f" %(@lrs.kdtree_emptybonus)}]\n"
				accel += "\t\"integer maxprims\" [#{@lrs.kdtree_maxprims.to_i}]\n"
				accel += "\t\"integer maxdepth\" [#{@lrs.kdtree_maxdepth.to_i}]\n"
			when "grid"
				refine = @lrs.grid_refineimmediately ? "true": "false"
				accel += "\t\"bool refineimmediately\" [\"#{refine}\"]\n"
			when "bvh"
			when "qbvh"
				accel += "\t\"integer maxprimsperleaf\" [#{@lrs.qbvh_maxprimsperleaf.to_i}]\n"
				accel += "\t\"integer skipfactor\" [#{@lrs.qbvh_skip_factor.to_i}]\n"
		end
		return accel
	end

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

	def export_light(out)
		sun_direction = Sketchup.active_model.shadow_info['SunDirection']
		out.puts "TransformBegin"
		case @lrs.environment_light_type
            when 'sunsky'
                out.puts "\tLightGroup \"#{@lrs.environment_sky_lightgroup}\""
			when 'infinite'
				if ( ! @lrs.environment_infinite_mapname.strip.empty?)
					out.puts "\tRotate #{@lrs.environment_infinite_rotatex} 1 0 0" 
					out.puts "\tRotate #{@lrs.environment_infinite_rotatey} 0 1 0"
					out.puts "\tRotate #{@lrs.environment_infinite_rotatez} 0 0 1"
				end
				out.puts "\tLightGroup \"#{@lrs.environment_infinite_lightgroup}\""
		end
		out.puts "AttributeBegin"
		case @lrs.environment_light_type
			when 'sunsky'
                if (@lrs.environment_use_sky)
                    out.puts "\tLightSource \"sky\""
                    out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_sky_gain)}]"
                    out.puts "\t\"float turbidity\" [#{"%.6f" %(@lrs.environment_sky_turbidity)}]"
                    out.puts "\t\"vector sundir\" [#{"%.6f" %(sun_direction.x)} #{"%.6f" %(sun_direction.y)} #{"%.6f" %(sun_direction.z)}]"
                    out.puts "\tPortalInstance \"Portal_Shape\"" if @has_portals == true
                    out.puts "AttributeEnd" + "\n"
                    
                    out.puts "AttributeBegin"
                end
                if (@lrs.environment_use_sun)
                    out.puts "\tLightGroup \"#{@lrs.environment_sun_lightgroup}\""
                    out.puts "\tLightSource \"sun\""
                    out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_sun_gain)}]"
                    out.puts "\t\"float relsize\" [#{"%.6f" %(@lrs.environment_sun_relsize)}]"
                    out.puts "\t\"float turbidity\" [#{"%.6f" %(@lrs.environment_sun_turbidity)}]"
                    out.puts "\t\"vector sundir\" [#{"%.6f" %(sun_direction.x)} #{"%.6f" %(sun_direction.y)} #{"%.6f" %(sun_direction.z)}]"
                    out.puts "\tPortalInstance \"Portal_Shape\"" if @has_portals == true
                end
			when 'infinite'
				out.puts "\tLightSource \"infinitesample\""
				out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_infinite_gain)}]"
				if ( ! @lrs.environment_infinite_mapname.strip.empty?)
					out.puts "\t\"float gamma\" [#{"%.6f" %(@lrs.environment_infinite_gamma)}]"
					out.puts "\t\"string mapping\" [\"" + @lrs.environment_infinite_mapping + "\"]"
					out.puts "\t\"string mapname\" [\"" + @lrs.environment_infinite_mapname + "\"]"
				else
					out.puts "\t\"color L\" [#{"%.6f" %(@lrs.environment_infinite_L_R)} #{"%.6f" %(@lrs.environment_infinite_L_G)} #{"%.6f" %(@lrs.environment_infinite_L_B)}]"
				end
					
				if (@lrs.use_environment_infinite_sun)
					out.puts "\tLightGroup \"#{@lrs.environment_infinite_sun_lightgroup}\""
					out.puts "\tLightSource \"sun\""
					out.puts "\t\"float gain\" [#{"%.6f" %(@lrs.environment_infinite_sun_gain)}]"
					out.puts "\t\"float relsize\" [#{"%.6f" %(@lrs.environment_infinite_sun_relsize)}]"
					out.puts "\t\"float turbidity\" [#{"%.6f" %(@lrs.environment_infinite_sun_turbidity)}]"
					out.puts "\t\"vector sundir\" [#{"%.6f" %(sun_direction.x)} #{"%.6f" %(sun_direction.y)} #{"%.6f" %(sun_direction.z)}]"
					out.puts "\tPortalInstance \"Portal_Shape\"" if @has_portals == true
				end
		end
		out.puts "AttributeEnd"
		out.puts "TransformEnd"
	end # END export_light

	def export_mesh(out)
		mc=LuxrenderMeshCollector.new(@model_name,@os_separator,true)
		mc.collect_faces(Sketchup.active_model.entities, Geom::Transformation.new)
		@materials=mc.materials
		@fm_materials=mc.fm_materials # face me component materials
		# @used_materials = @materials.merge(@fm_materials)
		@model_textures=mc.model_textures
        puts "@model_textures length:"
        puts @model_textures.length
		@texturewriter=mc.texturewriter
		@count_faces=mc.count_faces
		@current_mat_step = 1
		p 'export faces'
		export_faces(out,[])
		p 'export fmfaces'
		export_fm_faces(out,[])
        
        # the instances we deferred also need to be exported
        mc.deferred_instances.each { | key , value |
            p "key: #{key} -> #{value.length}"
            imc=LuxrenderMeshCollector.new(@model_name,@os_separator,false) #do not defer a second time
            definition  = Sketchup.active_model.definitions.select { | d | d.class == Sketchup::ComponentDefinition && d.name.eql?(key) }
            if ! definition.empty?
                p "Executing collect_faces for: #{definition[0].name} ->  #{@instance_name}"
                imc.collect_faces(definition[0].entities, Geom::Transformation.new)
                keep_materials = 	@materials
                keep_fm_materials = @fm_materials
                keep_textures = @model_textures
                @materials=imc.materials
                @fm_materials=imc.fm_materials
                @model_textures=imc.model_textures
                @texturewriter=imc.texturewriter
                @count_faces=imc.count_faces
                @current_mat_step = 1
                ## keep totals alive
                @materials = @materials.merge(keep_materials)
                @fm_materials = @fm_materials.merge(keep_fm_materials)
                @model_textures = @model_textures.merge(keep_textures)
                export_faces(out,value)
                export_fm_faces(out,value)
            end
        }
	end # END export_mesh

	def export_preview_material(preview_path,generated_lxm_file,currentmaterialname,currentmaterial,texture_path,luxmat)
		puts "\n"
        puts "running preview export function"
		# puts preview_path,generated_lxm_file,currentmaterialname,currentmaterial,texture_path,luxmat
		
		# prepare texture paths
        outputfolder = "LuxRender_luxdata/textures"
        
		# check for textures folder in temporary location, create if missing
		outputfolder_temp= preview_path+"/LuxRender_luxdata"
		Dir.mkdir(outputfolder_temp) unless File.exists?(outputfolder_temp)
		outputfolder_temp= outputfolder_temp+"/textures"
		Dir.mkdir(outputfolder_temp) unless File.exists?(outputfolder_temp)
		
		# create temporary group and face, apply current material
		luxmat_group = Sketchup.active_model.entities.add_group
		pt1 = [-3,-3,-3]
		pt2 = [-3, -3, -4]
		pt3 = [-3, -4, -3]
		luxmat_face = luxmat_group.entities.add_face(pt1, pt2, pt3)
		puts "assigning material #{currentmaterial.name} to temporary face"
		luxmat_face.material = currentmaterial
		luxmat_group.material = currentmaterial
		
		# create MeshCollector, store used material's textures
		mcpre=LuxrenderMeshCollector.new(outputfolder,@os_separator,false)
		mcpre.collect_faces(luxmat_group, Geom::Transformation.new) # this includes adding texture to meshcollector
		@model_textures=mcpre.model_textures
		@texturewriter=mcpre.texturewriter
        puts "number of files in texturewriter: " + @texturewriter.length.to_s
		@materials=mcpre.materials
		
		# get SketchUp material texture
		if (currentmaterial.texture)
			texturefilename = currentmaterial.texture.filename
			trimmedfilename = texturefilename.gsub("\\", "")
			trimmedfilename = trimmedfilename.gsub("/", "")
			if (texturefilename == trimmedfilename) # texture is built-in texture
				puts "exporting SketchUp texture to preview texture folder"
                imageexport = @texturewriter.write_all(preview_path+texture_path+"/", false)
                if (!imageexport) # catch missing file extension
                    @texturewriter.write(luxmat_face, true, preview_path+texture_path+"/" + luxmat_face.material.name + ".jpg")
                end
			else # texture is loaded from file
				texture_name=mcpre.get_texture_name(currentmaterialname,currentmaterial)
				puts "copying material preview texture from:", texturefilename
				outputpath = preview_path+texture_path+"/"+File.basename(texture_name)  # last part was File.basename(texturefilename)
				texturefilename = sanitize_path(texturefilename)
				FileUtils.copy_file(texturefilename, outputpath)
			end
		end
		
		# write data to file
		export_mat(luxmat, generated_lxm_file, nil, nil)
		
		# delete temporary group
		Sketchup.active_model.entities.erase_entities luxmat_group
		puts "end of preview export function"
	end

	def export_faces(out,is_instance)
        puts "export_faces"
		@materials.each{|matname,value|
			if (value!=nil and value!=[])
                #puts "@materials values:"
                #puts value[0][0]
                #puts value[0][1]
                #puts value[0][2]
                #puts value[0][3]
                #puts value[0][4]
                #puts value[0][5]
                #puts value[0][6]
				export_face(out,value[0][4],false,is_instance,matname,value[0][6])
				@materials[matname]=nil
			end}
		@materials={}
	end # END export_faces

	def export_fm_faces(out,is_instance)
        puts "export_fm_faces"
		@fm_materials.each{|matname,value|
			if (value!=nil and value!=[])
                #puts "fm_materials values:"
                #puts value[0][0]
                #puts value[0][1]
                #puts value[0][2]
                #puts value[0][3]
                #puts value[0][4]
                #puts value[0][5]
                #puts value[0][6]
				export_face(out,value[0][4],true,is_instance,matname,value[0][5])
				@fm_materials[matname]=nil
			end}
		@fm_materials={}
	end # END export_fm_faces

	def point_to_vector(p)
		Geom::Vector3d.new(p.x,p.y,p.z)
	end # END point_to_vector

	def export_face(out,mat,fm_mat,is_instance,matname,distorted)
        p 'export face' # this function runs once for each material
        @currenttexname = @currenttexname_prefixed = matname.delete("[<>]")
        @currentmatname = matname.delete("[<>]")
        skpmatname = mat.name
        puts "skpmatname is " + skpmatname
        puts out,mat,fm_mat,is_instance,matname,distorted
		meshes = []
		polycount = 0
		pointcount = 0
		mirrored=[]
		mat_dir=[]
		default_mat=[]
		distorted_uv=[]
		
		if fm_mat
			export=@fm_materials[matname]
		else
			export=@materials[matname]
		end
        
        puts "ITERATING EXPORT"
        for currentface in export
            puts currentface[0].material
        end
        puts ""
        
		has_texture = false
		if mat.respond_to?(:name)
			matname = mat.display_name.delete("[<>]")
			has_texture = true if mat.texture!=nil
        #else
            #matname = mat
			# has_texture=true if matname!=SU2LUX::FRONT_FACE_MATERIAL
		 end
		
		# matname="FM_"+matname if fm_mat # todo Abel 2014: check (distorted) textures in faceme components
        
		total_mat = @materials.length + @fm_materials.length
		@mat_step = " [" + @current_mat_step.to_s + "/" + total_mat.to_s + "]"
		@current_mat_step += 1

		@total_step = 4
		if (has_texture and @clay==false) or @exp_default_uvs==true
			@total_step += 1
		end
		@current_step = 1
		@rest = export.length*@total_step
		Sketchup.set_status_text("Exporting geometry: " + matname + @mat_step + "...[" + @current_step.to_s + "/" + @total_step.to_s + "]" + " #{@rest}")
		
		for ft in export
            # this runs once per face in current material export
			Sketchup.set_status_text("Exporting geometry: " + matname + @mat_step + "...[" + @current_step.to_s + "/" + @total_step.to_s + "]" + " #{@rest}") if (@rest%500==0)
			@rest-=1
		
			polymesh=(ft[3]==true) ? ft[0].mesh(5) : ft[0].mesh(6)
			trans = ft[1]
			@trans_inverse = trans.inverse
            
            if (ft[3] == true)
                default_mat.push(ft[0].material==nil)
            else
                default_mat.push(ft[0].back_material==nil)
            end

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
		
		# startindex = 0 # commented out when integrating ply/instance export
		
		# Exporting vertices
		#has_texture = false
		@current_step += 1
        
        mateditor = SU2LUX.get_editor("material")
		luxrender_mat = mateditor.materials_skp_lux[mat]
        luxrender_name=luxrender_mat.name
		
        if is_instance.empty?
            if (luxrender_mat.type == "light") # lightgroup declaration goes before attributebegin
                out.puts "LightGroup \""+luxrender_mat.name+"\""
            end
            out.puts 'AttributeBegin'
            if(distorted)
                output_material(mat, out,luxrender_mat, @currenttexname)
            else
                output_material(mat, out,luxrender_mat, skpmatname)
            end
        else
            out.puts "ObjectBegin \"instance_#{@instance_name}\""
        end
        
        geometrytype = @lrs.geomexport()
        if ( geometrytype=="ply" ) # Write ply filename for all materials
            puts "using .ply export"
            
            ply_path_base = File.dirname(@export_file_path) + "/" +  File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::GEOMETRYFOLDER
            Dir.mkdir(ply_path_base) unless File.exists?(ply_path_base)
            ply_path_relative = File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::GEOMETRYFOLDER
            
            if mat.class==String
                ply_path=ply_path_relative + @instance_name.to_s + '_' + mat+'.ply'
            else
                ply_path=ply_path_relative + @instance_name.to_s + '_' + luxrender_name +'.ply' # mat.name was mat.display_name
            end
            output_ply_geometry((File.dirname(@export_file_path)+"/"+ply_path), meshes, mirrored, mat_dir, @rest, has_texture, matname, pointcount, polycount, default_mat, distorted_uv, (!has_texture and @exp_default_uvs==true), false)
            out.puts "Shape \"plymesh\""
            out.puts "\"string filename\" [\"#{ply_path}\"]\n"
            
        else # write lxo geometry
            output_inline_geometry(out, meshes, mirrored, mat_dir, @rest, has_texture, matname, luxrender_mat)
            puts "writing inline geometry"
            @exp_default_uvs=true
            no_texture_uvs=(!has_texture and @exp_default_uvs==true)
            if has_texture or no_texture_uvs
                output_inline_uv(out, meshes, has_texture, matname, mat_dir, default_mat, distorted_uv, (!has_texture and @exp_default_uvs==true), luxrender_mat)
            end
        end
        
        export_displacement_textures(mat, out, luxrender_mat)
        
        if luxrender_mat.type == "portal"
			out.puts "ObjectEnd"
		end
        
        if is_instance.empty?
            
            out.puts "AttributeEnd\n\n"
        else
            out.puts 'ObjectEnd'
            is_instance.each { | i_trans |
                if (luxrender_mat.type == "light") # lightgroup declaration goes before attributebegin
                    out.puts "LightGroup \""+luxrender_mat.name+"\""
                end
                out.puts "AttributeBegin #instance_#{@instance_name}"
                m=i_trans.to_a
                out.print "Transform [ #{m[0]} #{m[1]} #{m[2]} #{m[3]} #{m[4]} #{m[5]} #{m[6]} #{m[7]} #{m[8]} #{m[9]} #{m[10]} #{m[11]} #{m[12]*@scale} #{m[13]*@scale} #{m[14]*@scale} #{m[15]} ] \n"
                output_material(mat, out, luxrender_mat, @currenttexname)
                out.puts "ObjectInstance \"instance_#{@instance_name}\""
                out.puts "AttributeEnd #instance_#{@instance_name}"
            }
        end
        #Exporting Material
        @instance_name += 1
    end
        
    def output_ply_geometry(ply_path, meshes, mirrored, mat_dir, rest, has_texture, matname, pointcount, polycount, default_mat, distorted_uv, no_texture_uvs, binary)
        startindex = 0
        
        ply_file=File.new(ply_path,"w")
        ply_file << "ply\n"
        if ( binary == true)
            ply_file << "format binary_little_endian 1.0\n"
            else
            ply_file << "format ascii 1.0\n"
        end
        ply_file << "comment created by SU2Lux " << Time.new << "\n"
        ply_file << "element vertex #{pointcount}\n"
        ply_file << "property float x\n"
        ply_file << "property float y\n"
        ply_file << "property float z\n"
        ply_file << "property float nx\n"
        ply_file << "property float ny\n"
        ply_file << "property float nz\n"
        ply_file << "property float s\n"
        ply_file << "property float t\n"
        
        ply_file << "element face #{polycount}\n"
        #ply_file << "property list uint8 int32\n"
        ply_file << "property list uchar uint vertex_indices\n"
        ply_file << "end_header\n"
        
        
        i=0
        for mesh in meshes
            mat_dir_tmp = mat_dir[i]
            dir=(no_texture_uvs) ? true : mat_dir[i]
            for p in (1..mesh.count_points)
                if default_mat[i] and @model_textures[matname]!=nil
                    # puts "texsize option 1"
                    mat_texture=(@model_textures[matname][5]).texture
                    texsize = Geom::Point3d.new(mat_texture.width, mat_texture.height, 1)
                else
                    # puts "texsize option 2"
                    texsize = Geom::Point3d.new(1,1,1)
                end
                
                textsize=Geom::Point3d.new(20,20,20) if no_texture_uvs
                
                if distorted_uv[i]!=nil
                    puts "DISTORTED UV MAPPING DISCOVERED IN MESHES"
                    uvHelp=distorted_uv[i]
                    #UV-Photomatch-Bugfix Stefan Jaensch 2009-08-25 (transformation applied)
                    uv=uvHelp.get_front_UVQ(mesh.point_at(p).transform!(@trans_inverse)) if mat_dir[i]==true
                    uv=uvHelp.get_back_UVQ(mesh.point_at(p).transform!(@trans_inverse)) if mat_dir[i]==false
                else
                    uv = [mesh.uv_at(p,dir).x/texsize.x, mesh.uv_at(p,dir).y/texsize.y, mesh.uv_at(p,dir).z/texsize.z]
                end
              
                pos = mesh.point_at(p).to_a
                norm = mesh.normal_at(p)
                norm.reverse! if mat_dir_tmp==false
                if ( binary == true)
                    ply_file << [pos[0]*@scale, pos[1]*@scale, pos[2]*@scale, norm.x, norm.y, norm.z, uv.x, (-uv.y+1)].pack('e*.')
                else
                    ply_file << "#{"%.6f" %(pos[0]*@scale)} #{"%.6f" %(pos[1]*@scale)} #{"%.6f" %(pos[2]*@scale)} #{"%.4f" %(norm.x)} #{"%.4f" %(norm.y)} #{"%.4f" %(norm.z)} #{"%.4f" %(uv.x)} #{"%.4f" %(-uv.y+1)}\n"
                end
            end
            i += 1
        end
        
        for mesh in meshes
            mirrored_tmp = mirrored[i]
            mat_dir_tmp = mat_dir[i]
            for poly in mesh.polygons
                v1 = (poly[0]>=0?poly[0]:-poly[0])+startindex
                v2 = (poly[1]>=0?poly[1]:-poly[1])+startindex
                v3 = (poly[2]>=0?poly[2]:-poly[2])+startindex
                if !mirrored_tmp
                    if mat_dir_tmp==true
                        out_a = [ 3, v1-1, v2-1, v3-1 ]
                        else
                        out_a = [ 3, v1-1, v3-1, v2-1 ]
                    end
                    else
                    if mat_dir_tmp==true
                        out_a = [ 3, v2-1, v1-1, v3-1 ]
                        else
                        out_a = [ 3, v2-1, v3-1, v1-1 ]
                    end
                end		
                if ( binary == true)
                    ply_file << out_a.pack('CVVV')
                    else
                    ply_file << "3 #{out_a[1]} #{out_a[2]} #{out_a[3]} \n"
                end 	
                @count_tri = @count_tri + 1
            end
            startindex = startindex + mesh.count_points
            i+=1
        end
        ply_file.close
    end
    
    def output_inline_geometry(out, meshes, mirrored, mat_dir, rest, has_texture, matname, luxrender_mat)
        startindex = 0
        i=0
		mesh_type = 'Shape "trianglemesh" '
        mesh_begin= '"integer indices" ['
        out.puts mesh_type
        out.puts mesh_begin
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
		
		
        #Exporting vertices
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
            Sketchup.set_status_text("Material being exported: " + matname + @mat_step + "...[" + @current_step.to_s + "/" + @total_step.to_s + "]" + " - Normals " + " #{@rest}") if @rest%500==0
            @rest -= 1
            mat_dir_tmp = mat_dir[i]
            for p in (1..mesh.count_points)
                norm = mesh.normal_at(p)
                norm.reverse! if mat_dir_tmp==false
                out.print "#{"%.4f" %(norm.x)} #{"%.4f" %(norm.y)} #{"%.4f" %(norm.z)}\n"
            end
            i += 1
        end
        out.puts ']'
        
        if luxrender_mat.type == "portal"
			out.puts "ObjectEnd"
		end
        
        @exp_default_uvs=true
		no_texture_uvs=(!has_texture and @exp_default_uvs==true)
    end
    
    def output_inline_uv(out, meshes, has_texture, matname, mat_dir, default_mat, distorted_uv, no_texture_uvs, luxrender_mat)
        if has_texture
    		@current_step += 1
            
            i = 0
            #Exporting uv-coordinates
            out.puts '"float uv" ['
            for mesh in meshes
                #SU2KT.status_bar("Material being exported: " + matname + mat_step + "...[" + @current_step.to_s + "/" + @total_step.to_s + "]" + " - UVs " + " #{@rest}") if @rest%500==0
                @rest -= 1
                    
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
                        puts "DISTORTED UV MAPPING DISCOVERED"
                        uvHelp=distorted_uv[i]
                        #UV-Photomatch-Bugfix Stefan Jaensch 2009-08-25 (transformation applied)
                        uv=uvHelp.get_front_UVQ(mesh.point_at(p).transform!(@trans_inverse)) if mat_dir[i]==true
                        uv=uvHelp.get_back_UVQ(mesh.point_at(p).transform!(@trans_inverse)) if mat_dir[i]==false
                    else
                        puts "GENERATING UV COORDINATES USING uv_at FUNCTION"
                        uv = [mesh.uv_at(p,dir).x/texsize.x, mesh.uv_at(p,dir).y/texsize.y, mesh.uv_at(p,dir).z/texsize.z]
                    end
                    out.print "#{"%.4f" %(uv.x)} #{"%.4f" %(-uv.y+1)}\n"
                end
                i += 1
            end
            out.puts ']'
            # out.puts 'AttributeEnd'
        else
            saved_uvs = luxrender_mat.get_uv(1)
            if saved_uvs
                out.puts '"float uv" ['
                saved_uvs.each { |uv|
                    out.puts "#{"%.4f" %(uv.x)} #{"%.4f" %(-uv.y+1)}"
                }
                out.puts ']'
                # out.puts 'AttributeEnd'
            end
        end
    end
	
	def sanitize_path(original_path)
		if (ENV['OS'] =~ /windows/i)
			sanitized_path = original_path.unpack('U*').pack('C*') # converts string to ISO-8859-1
		else
			sanitized_path = original_path
		end
	end
	
    def output_material (mat, out,luxrender_mat, matname)
        puts "running output_material"
        case luxrender_mat.type
        when "light"
            #out.puts "LightGroup \""+luxrender_mat.name+"\""
            out.puts "AreaLightSource \"area\" \"texture L\" [\"#{luxrender_mat.name}:light:L\"]"
            out.puts "\"float power\" [#{"%.6f" %(luxrender_mat.light_power)}]"
            out.puts "\"float efficacy\" [#{"%.6f" %(luxrender_mat.light_efficacy)}]"
            out.puts "\"float gain\" [#{"%.6f" %(luxrender_mat.light_gain)}]"
        when "portal"
            out.puts "ObjectBegin \"Portal_Shape\""
            @has_portals = true
        else
            out.puts "NamedMaterial \"" + matname.delete("[<>]") + "\""
        end # end case
    end
        
    def export_displacement_textures (mat, out, luxrender_mat)
        puts "exporting displacement map"
        if luxrender_mat.use_displacement
            puts "running displacement"
            out.puts "\"string subdivscheme\" [\""+luxrender_mat.dm_scheme+"\"]"
            case luxrender_mat.dm_scheme
                when "loop"
                    out.puts "\"bool dmnormalsmooth\" [\"#{luxrender_mat.dm_normalsmooth}\"]"
                    out.puts "\"bool dmnormalsplit\" [\"#{luxrender_mat.dm_normalsplit}\"]"
                    out.puts "\"bool dmsharpboundary\" [\"#{luxrender_mat.dm_sharpboundary}\"]"
                    out.puts "\"integer nsubdivlevels\" [#{luxrender_mat.dm_subdivl}]"
                when "microdisplacement"
                    out.puts "\"integer nsubdivlevels\" [#{luxrender_mat.dm_microlevels}]"
            end
            out.puts "\"texture displacementmap\" [\""+     @currenttexname    +"::displacementmap\"]"
            out.puts "\"float dmscale\" [#{"%.6f" %(luxrender_mat.dm_scale)}]"
            out.puts "\"float dmoffset\" [#{"%.6f" %(luxrender_mat.dm_offset)}]"
        end
    end
	
	def export_used_materials(materials, out, texexport, datafolder)
        mateditor = SU2LUX.get_editor("material")
        puts "@texexport: " + texexport
        @texexport = texexport
        @texfolder = datafolder
		# mix materials should be last, so first we write normal materials
        materials.each { |mat|
            luxrender_mat = mateditor.materials_skp_lux[mat]
            if (luxrender_mat.type != "portal" && luxrender_mat.type != "mix" )
                puts "exporting material: " + mat.name
                export_mat(luxrender_mat, out, nil, nil)
            end
		}
		# now write mix materials
        materials.each { |mat|
            luxrender_mat = mateditor.materials_skp_lux[mat]
            if (luxrender_mat.type == "mix" )
                puts "exporting mix material: " + mat.name
                export_mat(luxrender_mat, out, nil, nil)
            end
		}
        @texexport = "skp" # prevent material preview function from copying textures
	end
    
	def export_distorted_materials(out, datafolder)
        mateditor = SU2LUX.get_editor("material")
        @texfolder = datafolder
        
        # step one: process @model_textures, get only distorted textures
        puts "DISTORTED TEXTURE SEARCH: processing #{@model_textures.length} textures"
        distorted_textures = []
        undistorted_textures = []
        for texture in @model_textures do
            puts "distortion to be exported for this material?"
            puts texture[1][6]
            #puts ""
            if (texture[1][6])
                distorted_textures << texture
            else
                undistorted_textures << texture
            end
        end
        puts "#{distorted_textures.length} textures found"
        
		# mix materials should be last, so first we write normal materials
        distorted_textures.each { |distmat|
            luxrender_mat = mateditor.materials_skp_lux[distmat[1][5]]
            if (luxrender_mat.type != "portal" && luxrender_mat.type != "mix" )
                puts "exporting material: " + distmat[1][4]
                export_mat(luxrender_mat, out, distmat[1][4], distmat[1][6])
            end
		}
		# now write mix materials
        distorted_textures.each { |distmat|
            luxrender_mat = mateditor.materials_skp_lux[distmat[1][5]]
            if (luxrender_mat.type == "mix" )
                puts "exporting mix material: " + distmat[1][4]
                export_mat(luxrender_mat, out, distmat[1][4], distmat[1][6])
            end
		}
        
        @texexport = "skp" # prevent material preview function from copying textures
	end
    

	def export_texture(material, mat_type, type, before, after)
        puts "running export_texture"
		# SU2LUX.dbg_p "exporting additional texture channels"
		type_str, type_str2 = self.texture_parameters_from_type(mat_type)
		preceding = ""
		following = ""
        if (mat_type=="normal")
            preceding += "Texture \"#{@currenttexname_prefixed}::#{type_str}\" \"#{type}\" \"normalmap\"" + "\n"
        else
            preceding += "Texture \"#{@currenttexname_prefixed}::#{type_str}\" \"#{type}\" \"imagemap\"" + "\n"
		end
        preceding += "\t" + "\"string wrap\" [\"#{material.send(mat_type + "_imagemap_wrap")}\"]" + "\n"
        if (mat_type=='dm')
			preceding += "\t" + "\"string channel\" [\"#{material.send(mat_type + "_imagemap_channel")}\"]" + "\n"
        end
		case material.send(mat_type + "_texturetype")
			when "sketchup"
                if (@model_textures.has_key?(material.name))
                    filename = @currentfilename
                    filename = File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::TEXTUREFOLDER + filename
				else
                    puts "export_texture: no texture file path found"
                    return [preceding, following]
                end
                preceding += "\t" + "\"string filename\" [\"#{filename}\"]" + "\n"
			when "imagemap"
                if (@texexport == "all")
                    imagemap_filename = @texfolder + "/" + File.basename(sanitize_path(material.send(mat_type + "_imagemap_filename")))
                else
                    imagemap_filename = sanitize_path(material.send(mat_type + "_imagemap_filename"))
                end
                preceding += "\t" + "\"string filename\" [\"#{imagemap_filename}\"]" + "\n"
        end
		preceding += "\t" + "\"float gamma\" [#{material.send(mat_type + "_imagemap_gamma")}]" + "\n"
		preceding += "\t" + "\"float gain\" [#{material.send(mat_type + "_imagemap_gain")}]" + "\n"
		preceding += "\t" + "\"string filtertype\" [\"#{material.send(mat_type + "_imagemap_filtertype")}\"]" + "\n"
		preceding += "\t" + "\"string mapping\" [\"#{material.send(mat_type + "_imagemap_mapping")}\"]" + "\n"
		preceding += "\t" + "\"float uscale\" [#{"%.6f" %(material.send(mat_type + "_imagemap_uscale"))}]" + "\n"
		preceding += "\t" + "\"float vscale\" [#{"%.6f" %(material.send(mat_type + "_imagemap_vscale"))}]" + "\n"
		preceding += "\t" + "\"float udelta\" [#{"%.6f" %(material.send(mat_type + "_imagemap_udelta"))}]" + "\n"
		preceding += "\t" + "\"float vdelta\" [#{"%.6f" %(material.send(mat_type + "_imagemap_vdelta"))}]" + "\n"

        if (material.send(mat_type + "_imagemap_colorize") == true)
            preceding += "Texture \"#{@currenttexname_prefixed}::#{type_str}.scale\" \"#{type}\" \"scale\" \"texture tex1\" [\"#{@currenttexname_prefixed}::#{type_str}\"] \"#{type} tex2\" [#{material.send(type_str2)}]" + "\n"
            following += "\t" + "\"texture #{type_str}\" [\"#{@currenttexname_prefixed}::#{type_str}.scale\"]" + "\n"
        else
            following += "\t" + "\"texture #{type_str}\" [\"#{@currenttexname_prefixed}::#{type_str}\"]" + "\n"
        end
        
        return [preceding, following]
	end


    def export_material_parameters(mat, pre, post)
		case mat.type
			when "null"
                pre, post = self.export_null(mat, pre, post)
			when "mix"
                pre, post = self.export_mix(mat, pre, post)
			when "matte"
                pre, post = self.export_diffuse_component(mat, pre, post)
                pre, post = self.export_sigma(mat, pre, post)
			when "carpaint"
                pre, post = self.export_carpaint_name(mat, pre, post)
                if (!mat.carpaint_name)
                    pre, post = self.export_diffuse_component(mat, pre, post)
                end
			when "velvet"
                pre, post = self.export_diffuse_component(mat, pre, post)
                pre, post = self.export_sigma(mat, pre, post)
            when "cloth"
                pre, post = self.export_cloth_base(mat, pre, post)
                pre, post = self.export_cloth_channel1(mat, pre, post)
                pre, post = self.export_cloth_channel2(mat, pre, post)
                pre, post = self.export_cloth_channel3(mat, pre, post)
                pre, post = self.export_cloth_channel3(mat, pre, post)
			when "glossy"
                pre, post = self.export_diffuse_component(mat, pre, post)
                pre, post = self.export_specular_component(mat, pre, post)
                pre, post = self.export_exponent(mat, pre, post)
                #pre, post = self.export_IOR(mat, pre, post)
                #pre, post = self.export_spec_IOR(mat, pre, post)

                
                if (mat.use_absorption)
                    pre, post = self.export_absorption_component(mat, pre, post)
                end
                multibounce = mat.multibounce ? "true": "false"
                post += "\t" + "\"bool multibounce\" [\"#{multibounce}\"]" + "\n"
			when "glass"
                pre, post = self.export_reflection_component(mat, pre, post)
                pre, post = self.export_transmission_component(mat, pre, post)
                pre, post = self.export_IOR(mat, pre, post)
                architectural = mat.use_architectural ? "true" : "false"
                post += "\t" + "\"bool architectural\" [\"#{architectural}\"]" + "\n"
                if ( ! mat.use_architectural)
                    if (mat.use_dispersive_refraction)
                        pre, post = self.export_dispersive_refraction(mat, pre, post)
                    end
                end
			when "roughglass"
                pre, post = self.export_reflection_component(mat, pre, post)
                pre, post = self.export_transmission_component(mat, pre, post)
                pre, post = self.export_IOR(mat, pre, post)
                pre, post = self.export_dispersive_refraction(mat, pre, post)
			when "metal"
                pre, post = self.export_nk(mat, pre, post)
                pre, post = self.export_exponent(mat, pre, post)
            when "metal2"
                pre, post = self.export_metal2(mat, pre, post)
                pre, post = self.export_exponent(mat, pre, post)
			when "shinymetal"
                pre, post = self.export_reflection_component(mat, pre, post)
                pre, post = self.export_specular_component(mat, pre, post)
                pre, post = self.export_exponent(mat, pre, post)
			when "mirror"
                pre, post = self.export_reflection_component(mat, pre, post)
            when "mattetranslucent"
                pre, post = self.export_reflection_component(mat, pre, post)
                pre, post = self.export_transmission_component(mat, pre, post)
                energyconserving = mat.energyconserving ? "true": "false"
                post += "\t" + "\"bool energyconserving\" [\"#{energyconserving}\"]" + "\n"
                pre, post = self.export_sigma(mat, pre, post)
			when "glossytranslucent"
                pre, post = self.export_diffuse_component(mat, pre, post)
                pre, post = self.export_transmission_component(mat, pre, post)
                pre, post = self.export_specular_component(mat, pre, post)
                pre, post = self.export_exponent(mat, pre, post)
                pre, post = self.export_IOR(mat, pre, post)
                pre, post = self.export_absorption_component(mat, pre, post)
                multibounce = mat.multibounce ? "true": "false"
                post += "\t" + "\"bool multibounce\" [\"#{multibounce}\"]" + "\n"
			when "light"
                post += self.export_mesh_light(mat)
		end
        return pre, post
    end # end export_material_parameters

	def export_mat(mat, out, distortedname, texdistorted)
        @currentluxmat = mat
        #puts "texdistorted:" + texdistorted.to_s
        if(distortedname && texdistorted)
            @currentmatname = File.basename(sanitize_path(distortedname), '.*') + SU2LUX::SUFFIX_DISTORTED_TEXTURE
            @currenttexname = File.basename(sanitize_path(distortedname), '.*')
            @currenttexname_prefixed =  SU2LUX::PREFIX_DISTORTED_TEXTURE + @currenttexname
            @currentfilename = SU2LUX::PREFIX_DISTORTED_TEXTURE + distortedname
            
        elsif(distortedname)
            @currentmatname = File.basename(sanitize_path(distortedname), '.*')
            @currentfilename = sanitize_path(@model_textures[mat.name][4])
            @currenttexname = "xx_" + File.basename(sanitize_path(@model_textures[mat.name][4]), '.*')
            @currenttexname_prefixed = "tex" + File.basename(sanitize_path(@model_textures[mat.name][4]), '.*')
        else
            @currentmatname = sanitize_path(mat.name)
            if (@model_textures.has_key?(mat.name))
                @currentfilename = sanitize_path(@model_textures[mat.name][4])
                @currenttexname = @currenttexname_prefixed = File.basename(@currentfilename, '.*')
            end
        end
        
        # export main material properties
		pre = ""
		post = ""
        pre, post = export_material_parameters(mat, pre, post)
        
        if (mat.use_thin_film_coating)
            pre, post = self.export_thin_film(mat, pre, post)
        end
		if (mat.has_bump?)
            pre, post = self.export_bump(mat, pre, post)
		end
        if (mat.has_normal?)
            pre, post = self.export_normal(mat, pre, post)
		end
        if (mat.has_displacement?)
			pre, post = self.export_displacement(mat, pre, post)
		end
        
        matnamecomment = "# Material '" + @currentmatname + "'"
		matdeclaration_statement1 = "MakeNamedMaterial \"#{@currentmatname}\"" + "\n"
		matdeclaration_statement2 = "\t" + "\"string type\" [\"#{mat.type}\"]" + "\n"
        
		if (mat.type == "light")
            out.puts matnamecomment
			out.puts post
        else
            if (mat.use_auto_alpha == true)
                puts "explorting alpha transparency"
                # export material as mix material
                out.puts "# auto-alpha material for Material '" + @currentmatname + "'" + "\n"+ "\n"
                # define null material
                out.puts "# Material 'Mix_Null'"  + "\n"
                out.puts "MakeNamedMaterial \"Mix_Null\"" + "\n"
                out.puts "\t" + "\"string type\" [\"null\"]" + "\n" + "\n"
                # define main material (with altered name) and texture
                out.puts "# Original material texture and material definition "
                out.puts pre
                out.puts "# Material 'Mix_Original'"  + "\n"
                out.puts "MakeNamedMaterial \"Mix_Original\"" + "\n"
                out.puts matdeclaration_statement2
                out.puts post
                out.puts "\n" + "\n"
                # write mix texture
                out.puts '# Generated mix texture'
                out.puts 'Texture "' + mat.name + '_automix::amount" "float" "imagemap"'
                imagemap_filename = ""
                if (mat.aa_texturetype=="sketchupalpha") ## sketchup texture
                    if (@model_textures.has_key?(mat.name))
                        imagemap_filename = @currentfilename
                        imagemap_filename = File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::TEXTUREFOLDER + imagemap_filename
                    end
               else ## image texture
                    if (@texexport == "all")
                        imagemap_filename = @texfolder + "/" + File.basename(sanitize_path(mat.send("aa_imagemap_filename")))
                    else
                        imagemap_filename = sanitize_path(mat.send("aa_imagemap_filename"))
                    end
                end
                out.puts "\t" + "\"string filename\" [\"#{imagemap_filename}\"]" + "\n"
                out.puts "\t" + "\"float gamma\" [#{mat.send("aa_imagemap_gamma")}]" + "\n"
                out.puts "\t" + "\"float gain\" [#{mat.send("aa_imagemap_gain")}]" + "\n"
                out.puts "\t" + "\"string wrap\" [\"repeat\"]"
                if (mat.aa_texturetype=="imagealpha" || mat.aa_texturetype=="sketchupalpha")
                    out.puts "\t" + "\"string channel\" [\"alpha\"]"
                else
                    out.puts "\t" + "\"string channel\" [\"mean\"]"
                end
                out.puts "\t" + "\"string filtertype\" [\"" + mat.aa_imagemap_filtertype + "\"]" + "\n"
                out.puts "\t" + "\"string mapping\" [\"uv\"]" + "\n"
                out.puts "\t" + "\"float uscale\" [" + mat.aa_imagemap_uscale.to_s + "]" + "\n"
                out.puts "\t" + "\"float vscale\" [" + mat.aa_imagemap_vscale.to_s + "]" + "\n"
                out.puts "\t" + "\"float udelta\" [" + mat.aa_imagemap_udelta.to_s + "]" + "\n"
                out.puts "\t" + "\"float vdelta\" [" + mat.aa_imagemap_vdelta.to_s + "]" + "\n" + "\n"
                # define mix material with matdeclaration_statement
                out.puts matnamecomment
                out.puts matdeclaration_statement1
                out.puts "\t" + "\"string type\" [\"mix\"]" + "\n"
                out.puts "\t" + "\"texture amount\" [\"" + mat.name +  "_automix::amount\"]" + "\n"
                out.puts "\t" + "\"string namedmaterial1\" [\"Mix_Null\"]" + "\n"
                out.puts "\t" + "\"string namedmaterial2\" [\"Mix_Original\"]" + "\n"
            else # export ordinary material
                out.puts matnamecomment
                out.puts pre if (pre != "")
                out.puts matdeclaration_statement1
                out.puts matdeclaration_statement2
                out.puts post
            end
		end
		out.puts("\n")
	end # END export_mat
 
	def write_textures
		puts ("using LuxrenderExport write_textures function")
		if (@lrs.copy_textures == true and @model_textures!={}) # if textures have been gathered
            tex_path_base = File.dirname(@export_file_path) + "/" +  File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::TEXTUREFOLDER
            Dir.mkdir(tex_path_base) unless File.exists?(tex_path_base)
            tex_path_relative = File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::TEXTUREFOLDER
            
			tw=@texturewriter
			p @texturewriter
			texnumber=@model_textures.length
			count=1
            puts "@model_textures.length: ", texnumber
			@model_textures.each do |key, value|
				Sketchup.set_status_text("Exporting texture "+count.to_s+"/"+texnumber.to_s)
                #puts ("Exporting texture "+count.to_s+"/"+texnumber.to_s)
				SU2LUX.dbg_p  "model_textures key, value:"
				SU2LUX.dbg_p  key
				SU2LUX.dbg_p  value
				if value[1].class== Sketchup::Face
                    distprefix = ""
                    if (value[6] && @lrs.exp_distorted==true)
                        distprefix = SU2LUX::PREFIX_DISTORTED_TEXTURE
                        return_val0 = tw.load value[1], value[2]
                        return_val = tw.write value[1], value[2], (tex_path_base+distprefix+value[4]) # face, face side, output path
                    else
                        puts "WRITING UNDISTORTED TEXTURE: " + tex_path_base + value[5].name.delete("[<>]") + File.extname(value[4])
                        return_val0 = tw.load value[1], value[2]
                        return_val = tw.write value[1], value[2], (tex_path_base+value[5].name.delete("[<>]")+File.extname(value[4])) # face, face side, output path
                    end
					p 'path: '+tex_path_base+value[4]
					p return_val
					p 'write texture1'
                else
					tw.write value[1], (tex_path_base+@os_separator+value[4])
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

	def export_diffuse_component(material, before, after)
		preceding = ""
		following = ""
		if ( not material.has_texture?("kd"))
			following += "\t" + "\"color Kd\" [#{material.color_tos}]" + "\n"
		else
			preceding += "Texture \"#{@currenttexname_prefixed}::Kd\" \"color\" \"imagemap\"" + "\n"
			preceding += "\t" + "\"string wrap\" [\"#{material.kd_imagemap_wrap}\"]" + "\n"
			case material.kd_texturetype
				when "sketchup"
					if (@model_textures.has_key?(material.name))
						filename = @currentfilename
                        # add texture subfolder path
                        filename = File.basename(@export_file_path, SU2LUX::SCENE_EXTENSION) + SU2LUX::SUFFIX_DATAFOLDER + SU2LUX::TEXTUREFOLDER + filename
					else
						return [before, after]
					end

					preceding += "\t" + "\"string filename\" [\"#{filename}\"]" + "\n"
				when "imagemap"
                    if (@texexport == "all")
                        imagemapfilepath = @texfolder + "/" + File.basename(sanitize_path(material.kd_imagemap_filename))
                    else
                        imagemapfilepath = sanitize_path(material.kd_imagemap_filename)
                    end
					preceding += "\t" + "\"string filename\" [\"#{imagemapfilepath}\"]" + "\n"
			end
			preceding += "\t" + "\"float gamma\" [#{material.kd_imagemap_gamma}]" + "\n"
            preceding += "\t" + "\"float uscale\" [#{"%.6f" %(material.kd_imagemap_uscale)}]" + "\n"
            preceding += "\t" + "\"float vscale\" [#{"%.6f" %(material.kd_imagemap_vscale)}]" + "\n"
			preceding += "\t" + "\"float gain\" [#{material.kd_imagemap_gain}]" + "\n"
			preceding += "\t" + "\"string filtertype\" [\"#{material.kd_imagemap_filtertype}\"]" + "\n"
            
            # color = "#{"%.6f" %(material.color[0])} #{"%.6f" %(material.color[1])} #{"%.6f" %(material.color[2])}"
			if (material.send("kd_imagemap_colorize") == true)
                preceding += "Texture \"#{@currenttexname_prefixed}::Kd.scale\" \"color\" \"scale\" \"texture tex1\" [\"#{@currenttexname_prefixed}::Kd\"] \"color tex2\" [#{material.color_tos}]" + "\n"
				following += "\t" + "\"texture Kd\" [\"#{@currenttexname_prefixed}::Kd.scale\"]" + "\n"
			else
				following += "\t" + "\"texture Kd\" [\"#{@currenttexname_prefixed}::Kd\"]" + "\n"
			end
		end
		return [before + preceding, after + following]
	end

	def export_sigma(material, before, after)
		preceding = ""
		following = ""
		if ( ! material.has_texture?("matte_sigma"))
			following += "\t" + "\"float sigma\" [#{material.matte_sigma}]" + "\n"
		else
			preceding, following = self.export_texture(material, "matte_sigma", "float", before, after)
		end
		return [before + preceding, after + following]
	end

	def export_specular_component(material, before, after)
		preceding = ""
		following = ""
        if (material.specular_scheme == "specular_scheme_preset")
            following += "\t" + "\"float index\" [#{material.specular_preset}]\n"
        elsif (material.specular_scheme == "specular_scheme_IOR")
            if ( ! material.has_texture?("spec_IOR"))
                following += "\t" + "\"float index\" [#{material.spec_IOR}]\n"
            else
                preceding, following = self.export_texture(material, "spec_IOR", "float", before, after)
            end
        else
            if ( ! material.has_texture?("ks"))
                following += "\t" + "\"color Ks\" [#{material.specular_tos}]" + "\n"
            else
                preceding, following = self.export_texture(material, "ks", "color", before, after)
            end
        end
		return [before + preceding, after + following]
	end
    
    def export_cloth_base(material, before,after)
		preceding = ""
		following = ""
        # add cloth type, u scale, v scale
        following += "\t" + "\"string presetname\" [\"#{material.cl_type}\"]" + "\n"
        following += "\t" + "\"float repeat_u\" [#{material.cl_repeatu}]" + "\n"
        following += "\t" + "\"float repeat_v\" [#{material.cl_repeatv}]" + "\n"
        
        return [before + preceding, after + following]
	end
    
    def export_cloth_channel1(material, before,after)
        preceding = ""
        following = ""
        if ( ! material.has_texture?("cl1kd"))
            following += "\t" + "\"color warp_Kd\" [#{material.channelcolor_tos('cl1kd')}]" + "\n"
        else
            preceding, following = self.export_texture(material, "cl1kd", "color", before, after)
        end
        return [before + preceding, after + following]
    end
    
    def export_cloth_channel2(material, before,after)
        preceding = ""
        following = ""
        if ( ! material.has_texture?("cl1ks"))
            following += "\t" + "\"color warp_Ks\" [#{material.channelcolor_tos('cl1ks')}]" + "\n"
        else
            preceding, following = self.export_texture(material, "cl1ks", "color", before, after)
        end
        return [before + preceding, after + following]
    end

    def export_cloth_channel3(material, before,after)
        preceding = ""
        following = ""
        
        if ( ! material.has_texture?("cl2kd"))
            following += "\t" + "\"color weft_Kd\" [#{material.channelcolor_tos('cl2kd')}]" + "\n"
        else
            preceding, following = self.export_texture(material, "cl2kd", "color", before, after)
        end
        return [before + preceding, after + following]
    end

    def export_cloth_channel4(material, before,after)
        preceding = ""
        following = ""
        if ( ! material.has_texture?("cl2kd"))
            following += "\t" + "\"color weft_Ks\" [#{material.channelcolor_tos('cl2ks')}]" + "\n"
        else
            preceding, following = self.export_texture(material, "cl2ks", "color", before, after)
        end
        return [before + preceding, after + following]
    end




	def export_null(material, before, after)
		preceding = ""
		following = ""
		#following += "\t" + "\"string type\" [\"null\"]"+ "\n\n"

		return [before + preceding, after + following]
	end
    
	def export_mix(material, before, after)
		preceding = ""
		following = ""
        mixmat1 = material.material_list1.delete("[<>]")
        mixmat2 = material.material_list2.delete("[<>]")
        case material.mx_texturetype
            when "none"
                following += "\t" + "\"string namedmaterial1\" [\"#{mixmat1}\"]" + "\n"
                following += "\t" + "\"string namedmaterial2\" [\"#{mixmat2}\"]" + "\n"
                mixamount = 1 - material.mix_uniform.to_f / 100
                mixamountstring = mixamount.to_s
                following += "\t" + "\"float amount\" [" + mixamountstring +"]" + "\n"
            when "sketchup"
                preceding, following = self.export_texture(material, 'mx', 'float', before, after)
                following += "\t" + "\"string namedmaterial1\" [\"#{mixmat1}\"]" + "\n"
                following += "\t" + "\"string namedmaterial2\" [\"#{mixmat2}\"]" + "\n"
            when "imagemap"
                preceding, following = self.export_texture(material, 'mx', 'float', before, after)
                following += "\t" + "\"string namedmaterial1\" [\"#{mixmat1}\"]" + "\n"
                following += "\t" + "\"string namedmaterial2\" [\"#{mixmat2}\"]" + "\n"
		end
		return [before + preceding, after + following]
	end

	def export_carpaint_name(material, before, after)
		preceding = ""
		following = ""
		if (material.carpaint_name)
			following += "\t" + "\"string name\" [\"#{material.carpaint_name}\"]" + "\n"
		end
		return [before + preceding, after + following]
	end

	def export_exponent(material, before, after)
		preceding = ""
		following = ""
		material.uroughness = Math.sqrt(2.0 / (material.u_exponent.to_f + 2))
		material.vroughness = Math.sqrt(2.0 / (material.v_exponent.to_f + 2))
		if ( ! material.has_texture?('u_exponent'))
			following += "\t" + "\"float uroughness\" [#{"%.6f" %(material.uroughness)}]" + "\n"
			following += "\t" + "\"float vroughness\" [#{"%.6f" %(material.vroughness)}]" + "\n"
		else
			preceding_t, following_t = self.export_texture(material, "u_exponent", "float", before, after)
			preceding, following = self.export_texture(material, "v_exponent", "float", before, after)
			preceding = preceding_t+ preceding
			following = following_t + following
		end
		return [before + preceding, after + following]
	end

	def export_IOR(material, before, after)
		preceding = ""
		following = ""
		if ( ! material.has_texture?('IOR_index'))
			following += "\t" + "\"float index\" [#{material.IOR_index}]\n"
		else
			preceding, following = self.export_texture(material, 'IOR_index', 'float', before, after)
		end
		return [before + preceding, after + following]
	end

	def export_absorption_component(material, before, after)
		preceding = ""
		following = ""
		if ( ! material.has_texture?('ka'))
			following += "\t" + "\"color Ka\" [#{"%.6f" %(material.absorption[0])} #{"%.6f" %(material.absorption[1])} #{"%.6f" %(material.absorption[2])}]" + "\n"
		else
			preceding, following = self.export_texture(material, "ka", "color", before, after)
		end
		if ( ! material.has_texture?('ka_d'))
			following += "\t" + "\"float d\" [#{"%.6f" %(material.ka_d)}]" + "\n"
		else
			preceding, following = self.export_texture(material, "d", "float", before, after)
		end
		return [before + preceding, after + following]
	end

	def export_nk(material, before, after)
		preceding = ""
		following = ""
		following += "\t" + "\"string name\" [\"#{material.nk_preset}\"]" + "\n"
		return [before + preceding, after + following]
	end
    
    def export_metal2(material, before, after)
        preceding = ""
        following = ""
        if (material.metal2_preset == "custom")
            if (material.has_texture?('km2'))
                preceding, preceding2 = self.export_texture(material, "km2", "color", before, after)
                preceding += "\n" + "Texture \"#{@currenttexname_prefixed}::Km2_fresnel\" \"fresnel\" \"fresnelcolor\"" + "\n"
                preceding += preceding2
            else
                preceding += "Texture \"#{@currenttexname_prefixed}::Km2_fresnel\" \"fresnel\" \"fresnelcolor\"" + "\n"
                preceding += "\t" + "\"color Kr\" [#{material.km2_R} #{material.km2_G} #{material.km2_B}]" + "\n" + "\n"
            end
        else # preset
            preceding += "Texture \"#{@currenttexname_prefixed}::Km2_fresnel\" \"fresnel\" \"preset\"" + "\n"
            preceding += "\"string name\" [\"" + material.metal2_preset + "\"]" + "\n" + "\n"
        end
        following += "\t" + "\"texture fresnel\" [\"#{@currenttexname_prefixed}::Km2_fresnel\"]" + "\n"
        return [before + preceding, after + following]
    end

	def export_reflection_component(material, before, after)
		preceding = ""
		following = ""
		if ( ! material.has_texture?('kr'))
			following += "\t" + "\"color Kr\" [#{"%.6f" %(material.kr_R)} #{"%.6f" %(material.kr_G)} #{"%.6f" %(material.kr_B)}]" + "\n"
		else
			preceding, following = self.export_texture(material, 'kr', 'color', before, after)
		end
		return [before + preceding, after + following]
	end

	def export_transmission_component(material, before, after)
		preceding = ""
		following = ""
		if ( ! material.has_texture?('kt'))
			following += "\t" + "\"color Kt\" [#{"%.6f" %(material.kt_R)} #{"%.6f" %(material.kt_G)} #{"%.6f" %(material.kt_B)}]" + "\n"
		else
			preceding, following = self.export_texture(material, 'kt', 'color', before, after)
		end
		return [before + preceding, after + following]
	end

	def export_thin_film(material, before, after)
        puts "exporting thin film"
		preceding = ""
		following = ""
		if ( ! material.has_texture?('film'))
			following += "\t" + "\"float film\" [#{"%.6f" %(material.film)}]" + "\n"
		else
			preceding, following = self.export_texture(material, 'film', 'float', before, after)
		end
		if ( ! material.has_texture?('filmindex'))
			following += "\t" + "\"float filmindex\" [#{"%.6f" %(material.filmindex)}]" + "\n"
		else
			preceding, following = self.export_texture(material, 'filmindex', 'float', before, after)
		end
		return [before + preceding, after + following]
	end

	def export_dispersive_refraction(material, before, after)
		preceding = ""
		following = ""
		if ( ! material.has_texture?('cauchyb'))
			following += "\t" + "\"float cauchyb\" [#{"%.6f" %(material.cauchyb)}]" + "\n"
		else
			preceding, following = self.export_texture(material, 'cauchyb', 'float', before, after)
		end
		return [before + preceding, after + following]
	end
    
	def export_bump(material, before, after)
		preceding = ""
		following = ""
        preceding, following = self.export_texture(material, "bump", "float", before, after)
		return [before + preceding, after + following]
	end
	def export_normal(material, before, after)
		preceding = ""
		following = ""
        preceding, following = self.export_texture(material, "normal", "float", before, after)
		return [before + preceding, after + following]
	end

	def export_displacement(material, before, after)
		preceding = ""
		following = ""
		if (material.has_texture?('dm'))
            puts ("material.has_texture? dm is true")
			preceding, following = self.export_texture(material, "dm", "float", before, after)
		end
		return [before + preceding, after] # following parts would be added to geometry, not to material definition
	end

	def export_mesh_light(material)
		case material.light_L
			when "blackbody"
				following = "Texture \"" + @currenttexname_prefixed + ":light:L\" \"color\" \"blackbody\" \"float temperature\" [#{material.light_temperature}]" + "\n"
		end
	end

	def texture_parameters_from_type(mat_type)
		case mat_type
			when 'kd'
				type_str = "Kd"
				if (material.color['red'].to_f != 1.0 or material.color['green'].to_f != 1.0 or material.color['blue'].to_f != 1.0)
					color = material.color_tos
				end
				type_str2 = ""
			when 'bump'
				type_str = "bumpmap"
				type_str2 = "bumpmap"
			when 'dm'
				type_str = "displacementmap"
				type_str2 = "dm_imagemap_uscale"
			when 'matte_sigma'
				type_str = "sigma"
				type_str2 = "matte_sigma"
			when 'ks'
				type_str = "Ks"
				type_str2 = "specular_tos"
			when 'ka'
				type_str = "Ka"
				type_str2 = "absorption_tos"
            when 'km2'
                type_str = "Kr"
                type_str2 = "km2_tos"
			when 'ka_d'
				type_str = "d"
				type_str2 = "ka_d"
			when 'kr'
				type_str = "Kr"
				type_str2 = "reflection_tos"
			when 'kt'
				type_str = "Kt"
				type_str2 = "transmission_tos"
            when 'normal'
				type_str = "bumpmap"
				type_str2 = "normalmap"
            when 'IOR_index'
				type_str = 'index'
				type_str2 = 'IOR_index'
            when 'spec_IOR'
				type_str = 'index'
				type_str2 = 'spec_IOR'
			when 'u_exponent'
				type_str = 'uroughness'
				type_str2 = 'uroughness'
			when 'v_exponent'
				type_str = 'vroughness'
				type_str2 = 'vroughness'
			when 'mx'
				type_str = 'amount'
				type_str2 = 'skmixstrtwo'
			when 'carpaint_name'
				type_str = 'carpaint_name'
				type_str2 = 'name'
            when 'cl1kd'
                type_str = 'warp_Kd'
                type_str2 = 'cl1kd_tos'
            when 'cl1ks'
                type_str = 'warp_Ks'
                type_str2 = 'cl1ks_tos'
            when 'cl2kd'
                type_str = 'weft_Kd'
                type_str2 = 'cl2kd_tos'
            when 'cl2ks'
                type_str = 'weft_Ks'
                type_str2 = 'cl2ks_tos'
                
			else
				type_str = type_str2 = mat_type
		end
		return [type_str, type_str2]
	end
	
end # END class LuxrenderExport

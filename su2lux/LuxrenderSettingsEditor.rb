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
# This file is part of su2lux.
#
# Authors      : Alexander Smirnov (aka Exvion)  e-mail: exvion@gmail.com
#                Mimmo Briganti (aka mimhotep)


class LuxrenderSettingsEditor

	attr_reader :settings_dialog
	alias_method :settings_editor, :settings_dialog
	##
	#
	##
	def initialize
        puts "initializing settings editor"
        puts self
		@settings_dialog = UI::WebDialog.new("LuxRender Settings Editor", true, "LuxrenderSettingsEditor", 520, 500, 10, 10, true)
        @settings_dialog.max_width = 520
		setting_html_path = Sketchup.find_support_file("settings.html" , "Plugins/"+SU2LUX::PLUGIN_FOLDER)
		@settings_dialog.set_file(setting_html_path)
        # @settings_dialog.set_on_close { @presets[@lrad["preset"].value].save} # taken from Juicyfruit version, but @presets does not exist
		@lrs=LuxrenderSettings.new
        
        @exportable_settings = ['pixelfilter_type','pixelfilter_mitchell_sharpness','pixelfilter_mitchell_optmode','pixelfilter_mitchell_xwidth','pixelfilter_mitchell_ywidth','pixelfilter_mitchell_B','pixelfilter_mitchell_C','pixelfilter_mitchell_supersample','pixelfilter_box_xwidth','pixelfilter_box_ywidth','pixelfilter_triangle_xwidth','pixelfilter_triangle_ywidth','pixelfilter_sinc_xwidth','pixelfilter_sinc_ywidth','pixelfilter_sinc_tau','pixelfilter_gaussian_xwidth','pixelfilter_gaussian_ywidth','pixelfilter_gaussian_alpha','sampler_type','sampler_random_pixelsamples','sampler_random_pixelsampler','sampler_lowdisc_pixelsamples','sampler_lowdisc_pixelsampler','sampler_noiseaware','sampler_metropolis_largemutationprob','sampler_metropolis_maxconsecrejects','sampler_metropolis_usevariance','sampler_erpt_chainlength','sintegrator_show_advanced','sintegrator_type','sintegrator_bidir_show_advanced','sintegrator_bidir_bounces','sintegrator_bidir_eyedepth','sintegrator_bidir_eyerrthreshold','sintegrator_bidir_lightdepth','sintegrator_bidir_lightthreshold','sintegrator_bidir_strategy','sintegrator_bidir_debug','sintegrator_direct_show_advanced','sintegrator_direct_bounces','sintegrator_direct_maxdepth','sintegrator_direct_shadow_ray_count','sintegrator_direct_strategy','sintegrator_distributedpath_directsampleall','sintegrator_distributedpath_directsamples','sintegrator_distributedpath_indirectsampleall','sintegrator_distributedpath_indirectsamples','sintegrator_distributedpath_diffusereflectdepth','sintegrator_distributedpath_diffusereflectsamples','sintegrator_distributedpath_diffuserefractdepth','sintegrator_distributedpath_diffuserefractsamples','sintegrator_distributedpath_directdiffuse','sintegrator_distributedpath_indirectdiffuse','sintegrator_distributedpath_glossyreflectdepth','sintegrator_distributedpath_glossyreflectsamples','sintegrator_distributedpath_glossyrefractdepth','sintegrator_distributedpath_glossyrefractsamples','sintegrator_distributedpath_directglossy','sintegrator_distributedpath_indirectglossy','sintegrator_distributedpath_specularreflectdepth','sintegrator_distributedpath_specularrefractdepth','sintegrator_distributedpath_strategy','sintegrator_distributedpath_reject','sintegrator_distributedpath_diffusereflectreject','sintegrator_distributedpath_diffusereflectreject_threshold','sintegrator_distributedpath_diffuserefractreject','sintegrator_distributedpath_diffuserefractreject_threshold','sintegrator_distributedpath_glossyreflectreject','sintegrator_distributedpath_glossyreflectreject_threshold','sintegrator_distributedpath_glossyrefractreject','sintegrator_distributedpath_glossyrefractreject_threshold','sintegrator_exphoton_show_advanced','sintegrator_exphoton_finalgather','sintegrator_exphoton_finalgathersamples','sintegrator_exphoton_gatherangle','sintegrator_exphoton_maxdepth','sintegrator_exphoton_maxphotondepth','sintegrator_exphoton_maxphotondist','sintegrator_exphoton_nphotonsused','sintegrator_exphoton_causticphotons','sintegrator_exphoton_directphotons','sintegrator_exphoton_indirectphotons','sintegrator_exphoton_radiancephotons','sintegrator_exphoton_renderingmode','sintegrator_exphoton_rrcontinueprob','sintegrator_exphoton_rrstrategy','sintegrator_exphoton_photonmapsfile','sintegrator_exphoton_shadow_ray_count','sintegrator_exphoton_strategy','sintegrator_exphoton_dbg_enable_direct','sintegrator_exphoton_dbg_enable_indircaustic','sintegrator_exphoton_dbg_enable_indirdiffuse','sintegrator_exphoton_dbg_enable_indirspecular','sintegrator_exphoton_dbg_enable_radiancemap','sintegrator_igi_show_advanced','sintegrator_igi_maxdepth','sintegrator_igi_mindist','sintegrator_igi_nsets','sintegrator_igi_nlights','sintegrator_path_show_advanced','sintegrator_path_include_environment','sintegrator_path_bounces','sintegrator_path_maxdepth','sintegrator_path_rrstrategy','sintegrator_path_rrcontinueprob','sintegrator_path_shadow_ray_count','sintegrator_path_strategy','volume_integrator_type','volume_integrator_stepsize','film_type','fleximage_premultiplyalpha','fleximage_filterquality','fleximage_ldr_clamp_method','fleximage_write_exr','fleximage_write_exr_channels','fleximage_write_exr_halftype','fleximage_write_exr_compressiontype','fleximage_write_exr_applyimaging','fleximage_write_exr_gamutclamp','fleximage_write_exr_ZBuf','fleximage_write_exr_zbuf_normalizationtype','fleximage_write_png','fleximage_write_png_channels','fleximage_write_png_16bit','fleximage_write_png_gamutclamp','fleximage_write_png_ZBuf','fleximage_write_png_zbuf_normalizationtype','fleximage_write_tga','fleximage_write_tga_channels','fleximage_write_tga_gamutclamp','fleximage_write_tga_ZBuf','fleximage_write_tga_zbuf_normalizaziontype','fleximage_write_resume_flm','fleximage_restart_resume_flm','fleximage_filename','fleximage_writeinterval','fleximage_displayinterval','fleximage_outlierrejection_k','fleximage_debug','fleximage_haltspp','fleximage_halttime','fleximage_colorspace_red_x','fleximage_colorspace_red_y','fleximage_colorspace_green_x','fleximage_colorspace_green_y','fleximage_colorspace_blue_x','fleximage_colorspace_blue_y','fleximage_colorspace_white_x','fleximage_colorspace_white_y','fleximage_tonemapkernel','fleximage_reinhard_prescale','fleximage_reinhard_postscale','fleximage_reinhard_burn','fleximage_linear_sensitivity','fleximage_linear_exposure','fleximage_linear_fstop','fleximage_linear_gamma','fleximage_contrast_ywa','fleximage_cameraresponse','fleximage_gamma','fleximage_linear_use_preset','fleximage_linear_camera_type','fleximage_linear_cinema_exposure','fleximage_linear_cinema_fps','fleximage_linear_photo_exposure','fleximage_linear_use_half_stop','fleximage_linear_hf_stopF','fleximage_linear_hf_stopT','fleximage_linear_iso','fleximage_use_preset','fleximage_use_colorspace_whitepoint','fleximage_use_colorspace_gamma','fleximage_use_colorspace_whitepoint_preset','fleximage_colorspace_wp_preset','fleximage_colorspace_gamma','fleximage_colorspace_preset_white_x','fleximage_colorspace_preset_white_y','fleximage_colorspace_preset','accelerator_type','kdtree_intersectcost','kdtree_traversalcost','kdtree_emptybonus','kdtree_maxprims','kdtree_maxdepth','qbvh_maxprimsperleaf','qbvh_skip_factor','grid_refineimmediately','useparamkeys','texexport','exp_distorted','geomexport','priority','copy_textures']
		
        puts "finished initialising settings editor"
        
		##
		#
		##
		@settings_dialog.add_action_callback("param_generate") {|dialog, params|
				SU2LUX.dbg_p "settings editor param_generate"
				pair = params.split("=")
				key = pair[0]		   
				value = pair[1]
				case key
                    when "preset"
                        puts "preset toggled"
					when "fov"
						Sketchup.active_model.active_view.camera.fov = value.to_f
					when "focal_length"
						Sketchup.active_model.active_view.camera.focal_length = value.to_f
					when "xresolution"
						@lrs.fleximage_xresolution=value.to_f
						change_aspect_ratio(@lrs.fleximage_xresolution.to_f / @lrs.fleximage_yresolution.to_f)
					when "yresolution"
						@lrs.fleximage_yresolution=value.to_f
						change_aspect_ratio(@lrs.fleximage_xresolution.to_f / @lrs.fleximage_yresolution.to_f)
					when "use_plain_color"
						method_name = "use_plain_color" + "="
						@lrs.send(method_name, value)
						case value
							when "sketchup_color"
                                SU2LUX.dbg_p "use_sketchup_color"
								color = Sketchup.active_model.rendering_options["BackgroundColor"]
								red = color.red / 255.0
								method_name = "environment_infinite_L_R" + "="
								@lrs.send(method_name, red)
								method_name = "environment_infinite_L_G" + "="
								green = color.green / 255.0
								@lrs.send(method_name, green)
								method_name = "environment_infinite_L_B" + "="
								blue = color.blue / 255.0
								@lrs.send(method_name, blue)
							when "no_color"
                                SU2LUX.dbg_p "use_no_color"
								method_name = "environment_infinite_L_R" + "="
								@lrs.send(method_name, 0.0)
								method_name = "environment_infinite_L_G" + "="
								@lrs.send(method_name, 0.0)
								method_name = "environment_infinite_L_B" + "="
								@lrs.send(method_name, 0.0)
						end
                    else # true/false toggles
						if (@lrs.respond_to?(key))
                            #puts "@lrs responding"
                            #puts key
                            #puts value.to_s.downcase
							method_name = key + "="
							if (value.to_s.downcase == "true")
								value = true
                                #puts "value will be set to true"
							end
							if (value.to_s.downcase == "false")
								value = false
                                #puts "value will be set to false"
							end
							@lrs.send(method_name, value)
						else
							# UI.messagebox "Parameter " + key + " does not exist.\n\nPlease contact developers."
							SU2LUX.dbg_p "Parameter " + key + " does not exist.\n\nPlease contact developers."
						end
				end	
		} #end action callback param_generatate

    ##
    #
    ##
    @settings_dialog.add_action_callback("overwrite_settings"){ |settingseditor, presetname|
        puts "exporting settings to existing file"
        settings_folder = SU2LUX.get_settings_folder
        settings_path = settings_folder + presetname +  ".lxp"
        outputfile = File.new(settings_path, "w") # "a" adds to file, "w" writes new file content
        @exportable_settings.each {|settingname|
            if (settingname==@exportable_settings.last)
                outputfile << settingname + "," + @lrs.send(settingname).to_s
                else
                outputfile << settingname + "," + @lrs.send(settingname).to_s + "\n"
            end
        }
        outputfile.close
    }


        ##
        #
        ##
        @settings_dialog.add_action_callback("export_settings"){ |settingseditor, params|
            puts "exporting settings to file"
            settings_folder = SU2LUX.get_settings_folder
            settings_path = UI.savepanel("Save as", settings_folder, ".lxp")
            outputfile = File.new(settings_path, "w") # "a" adds to file, "w" writes new file content
            @exportable_settings.each {|settingname|
                if (settingname==@exportable_settings.last)
                    outputfile << settingname + "," + @lrs.send(settingname).to_s
                else
                    outputfile << settingname + "," + @lrs.send(settingname).to_s + "\n"
                end
            }
            outputfile.close
            # add to dropdown
            settingsname = File.basename(settings_path,".lxp")
            addtodropdown = 'add_to_dropdown(\'' + settingsname + '\');'
            settingseditor.execute_script(addtodropdown)
            # set active
            setactivesettingsname = '$("#preset").val("' + settingsname + '");'
            settingseditor.execute_script(setactivesettingsname)
        }

        ##
        #
        ##
        @settings_dialog.add_action_callback("load_settings"){ |dialog, presetfile|
            puts "loading settings from file"
            puts presetfile
            puts ""
            if (!presetfile || presetfile==false || presetfile=="false")
                # user gets file
                settings_folder = SU2LUX.get_settings_folder
                filepath = UI.openpanel("Open LuxRender settings file (.lxp)", settings_folder, "*")
                if(filepath)
                    inputfile = File.open(filepath, "r")
                else
                    next # break
                end
            else
                # use file as defined by dropdown
                filepath = File.join(SU2LUX.get_settings_folder, File.basename(presetfile)+".lxp")
                inputfile = File.open(filepath, "r")
            end
            
            # set value in @lrs
            inputfile.each_line do |line|
                cleanline = line.gsub(/\r/,"")
                cleanline = cleanline.gsub(/\n/,"")
                property = cleanline.split(",").first
                value = cleanline.split(",").last
                @lrs.send(property+"=",value)
            end
            inputfile.close
            
            # set value in dropdown menu
            javascriptcommand = 'update_settings_dropdown("' + File.basename(filepath,".lxp") + '")'
            SU2LUX.dbg_p javascriptcommand
			dialog.execute_script(javascriptcommand)
            
            # update interface
			self.sendDataFromSketchup()
        }

        ##
        #
        ##
        @settings_dialog.add_action_callback("delete_settings"){ |dialog, presetfile|
            if (presetfile != "Custom")
                puts "delete settings file"
                puts presetfile
                puts ""
                # delete file
                filepath = File.join(SU2LUX.get_settings_folder, File.basename(presetfile)+".lxp")
                File.delete(filepath)
                # remove value from dropdown menu, set to custom instead
                removecommand = '$("#preset option:selected").remove();'
                puts dialog
                dialog.execute_script(removecommand)
                updatecommand = 'update_settings_dropdown("Custom")'
                dialog.execute_script(updatecommand)
            else
                puts "Custom settings selected, nothing to delete"
            end
        }
        
		##
		#
		##
		@settings_dialog.add_action_callback("get_view_size") { |dialog, params|
			width = (Sketchup.active_model.active_view.vpwidth)
			height = (Sketchup.active_model.active_view.vpheight)
			setValue("fleximage_xresolution", width)
			setValue("fleximage_yresolution", height)
			@lrs.fleximage_xresolution = width
			@lrs.fleximage_yresolution = height
			change_aspect_ratio(0.0)
		}

		##
		#
		##
		@settings_dialog.add_action_callback("set_image_size") { |dialog, params|
			values = params.split('x')
			width = values[0].to_i
			height = values[1].to_i
			setValue("fleximage_xresolution", width)
			setValue("fleximage_yresolution", height)
			@lrs.fleximage_xresolution = width
			@lrs.fleximage_yresolution= height
			change_aspect = values[2]
			change_aspect_ratio(width.to_f / height.to_f) if change_aspect == "true"
		}
		
		##
		#
		##
		@settings_dialog.add_action_callback("camera_change") { |dialog, cameratype|
            puts "previous camera type:"
            puts @lrs.camera_type
            @lrs.camera_type = cameratype
            if (cameratype != "environment")
                Sketchup.active_model.active_view.camera.perspective = (cameratype=='perspective')
            end
		}
		# @settings_dialog.add_action_callback("scale_view") { |dialog, params|
			# values = params.split('x')
			# width = values[0].to_i
			# height = values[1].to_i
			# setValue("xresolution", width)
			# setValue("yresolution", height)
			# @lrs.xresolution = width
			# @lrs.yresolution = height
		# }
		

        ##
        #
        ##
        @settings_dialog.add_action_callback("display_loaded_presets") {|dialog, params|
            puts "running display_loaded_presets"
            self.sendDataFromSketchup()
        }


		##
		#
		##
		@settings_dialog.add_action_callback("open_dialog") {|dialog, params|
			case params.to_s
				when "new_export_file_path"
					SU2LUX.new_export_file_path
				when "load_env_image"
					SU2LUX.load_env_image
                when "change_luxpath"
                    SU2LUX.change_luxrender_path
			end #end case
		} #end action callback open_dialog

 
        
		@settings_dialog.add_action_callback("save_to_model") {|dialog, params|
			@lrs.save_to_model
		}
		
		@settings_dialog.add_action_callback("reset_to_default") {|dialog, params|
			@lrs.reset
			self.close
			UI.start_timer(0.5, false) { self.show }
			# self.show
		}
        
        @settings_dialog.add_action_callback("load_preset_files") {|dialog, params|
            puts "LOADING SETTINGS FILES"
            settings_folder = SU2LUX.get_settings_folder
            Dir.foreach(settings_folder) do |settingsfile|
                if File.extname(settingsfile)==".lxp"
                    settingsfile2 = File.basename(settingsfile, ".lxp").to_s
                    addtodropdown = 'add_to_dropdown(\'' + settingsfile2 + '\');'
                    puts addtodropdown
                    @settings_dialog.execute_script(addtodropdown)
                end
            end
            puts "FINISHED LOADING SETTINGS FILES"
        }
        
		
	end # END initialize



	##
	#
	##
	def show
		@settings_dialog.show{sendDataFromSketchup()}
	end # END show

	##
	#set parameters in inputs of settings.html
	##
	def sendDataFromSketchup()
		@lrs.fleximage_xresolution = Sketchup.active_model.active_view.vpwidth unless @lrs.fleximage_xresolution
		@lrs.fleximage_yresolution = Sketchup.active_model.active_view.vpheight unless @lrs.fleximage_yresolution
		settings = @lrs.get_names
        puts "running sendDataFromSketchup"
		settings.each { |setting|
            #puts setting
			updateSettingValue(setting)
		}
        
        # set setting areas based on dropdown settings
        subfield_categories = ["sampler_type", "sintegrator_type", "pixelfilter_type", "accelerator_type"]
        subfield_categories.each{|fieldname|
            update_subfield = 'update_subfield("' + fieldname + '")'
            puts update_subfield
            @settings_dialog.execute_script(update_subfield)
        }
        
	end # END sendDataFromSketchup
	
	##
	#
	##
	def is_a_checkbox?(id)#much better to use objects for settings?!
		if @lrs[id] == true or @lrs[id] == false
			return id
		end
	end # END is_a_checkbox?

	##
	#
	##
	def setValue(id,value) #extend to encompass different types (textbox, anchor, slider)
		new_value=value.to_s
		case id
			
		#### -- export_file_path slash change -- ####
		when "export_file_path"
            SU2LUX.dbg_p new_value
			new_value.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
			new_value.gsub!(/\\/, '/') if new_value.include?('\\')
			cmd="$('##{id}').val('#{new_value}');" #different asignment method
			# SU2LUX.dbg_p cmd
			@settings_dialog.execute_script(cmd)
		############################

		
		########  -- checkboxes -- ##########
		when is_a_checkbox?(id)
			cmd="$('##{id}').attr('checked', #{value});" #different asignment method
			# SU2LUX.dbg_p cmd
			@settings_dialog.execute_script(cmd)
			cmd="checkbox_expander('#{id}');"
			# SU2LUX.dbg_p cmd
			@settings_dialog.execute_script(cmd)
		#############################
		when "use_plain_color"
			radio_id = @lrs.use_plain_color
			cmd = "$('##{radio_id}').attr('checked', true)"
			@settings_dialog.execute_script(cmd)
		
		######### -- other -- #############
		else
			cmd="$('##{id}').val('#{new_value}');" #syntax jquery
			# SU2LUX.dbg_p cmd
			# cmd = "document.getElementById('#{id}').value=\"#{new_value}\""
			# SU2LUX.dbg_p cmd
			@settings_dialog.execute_script(cmd)
			#Horror coding?
			if(id == "camera_type")
				cmd="$('##{id}').change();" #syntax jquery
				@settings_dialog.execute_script(cmd)
			end
		end
		#############################
		
	end # END setValue

	##
	#
	##
	def updateSettingValue(id)
		setValue(id, @lrs[id])
	end # END updateSettingValue

	##
	#
	##
	def change_aspect_ratio(aspect_ratio)
		current_camera = Sketchup.active_model.active_view.camera
		current_ratio = current_camera.aspect_ratio
		current_ratio = 1.0 if current_ratio == 0.0
		
		new_ratio = aspect_ratio
		
		if(current_ratio != new_ratio)
			current_camera.aspect_ratio = new_ratio
			new_ratio = 1.0 if new_ratio == 0.0
			scale = current_ratio / new_ratio.to_f
			if current_camera.perspective?
				fov = current_camera.fov
				current_camera.focal_length = current_camera.focal_length * scale
			end
		end
	end # END change_aspect_ratio

	##
	#
	##
	def setCheckbox(id,value)
		#TODO
	end # END setCheckbox

	def close
		@settings_dialog.close
	end #END close
	
	def visible?
		return @settings_dialog.visible?
	end #END visible?
	
end # # END class LuxrenderSettingsEditor
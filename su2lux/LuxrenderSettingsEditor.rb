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

		pref_key = "LuxrenderSettingsEditor"
		@settings_dialog = UI::WebDialog.new("Luxrender Render Settings", true, pref_key, 520, 500, 10, 10, true)
		@settings_dialog.max_width = 520
		setting_html_path = Sketchup.find_support_file("settings_basic.html" , "Plugins/"+SU2LUX::PLUGIN_FOLDER)
		@settings_dialog.set_file(setting_html_path)
		
		@lrs=LuxrenderSettings.new
		
		##
		#
		##
		@settings_dialog.add_action_callback("param_generate") {|dialog, params|
				SU2LUX.dbg_p params
				pair = params.split("=")
				key = pair[0]		   
				value = pair[1]
				case key
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
					else
						if (@lrs.respond_to?(key))
							method_name = key + "="
							if (value.to_s.downcase == "true")
								value = true
							end
							if (value.to_s.downcase == "false")
								value = false
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
		@settings_dialog.add_action_callback("camera_change") { |dialog, params|
			perspective_camera = (params == "perspective")
			Sketchup.active_model.active_view.camera.perspective = perspective_camera if params != "environment"
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
		#TODO: change variables names
		@settings_dialog.add_action_callback("preset") {|d,p|
			case p
				when '0' #<option value='0'>0 Preview - Global Illumination</option> in settings.html
					SU2LUX.dbg_p "set preset 0 Preview - Global Illumination"
					@lrs.fleximage_displayinterval = 4
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 1
					@lrs.sampler_lowdisc_pixelsampler = 'lowdiscrepancy'
					
					@lrs.sintegrator_type = 'distributedpath'
					@lrs.sintegrator_distributedpath_directsampleall = true
					@lrs.sintegrator_distributedpath_directsamples = 1
					@lrs.sintegrator_distributedpath_directdiffuse = true
					@lrs.sintegrator_distributedpath_directglossy = true
					@lrs.sintegrator_distributedpath_indirectsampleall = false
					@lrs.sintegrator_distributedpath_indirectsamples = 1
					@lrs.sintegrator_distributedpath_indirectdiffuse = true
					@lrs.sintegrator_distributedpath_indirectglossy = true
					@lrs.sintegrator_distributedpath_diffusereflectdepth = 1
					@lrs.sintegrator_distributedpath_diffusereflectsamples = 4
					@lrs.sintegrator_distributedpath_diffuserefractdepth = 4
					@lrs.sintegrator_distributedpath_diffuserefractsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectdepth = 1
					@lrs.sintegrator_distributedpath_glossyreflectsamples = 2
					@lrs.sintegrator_distributedpath_glossyrefractdepth = 4
					@lrs.sintegrator_distributedpath_glossyrefractsamples = 1
					@lrs.sintegrator_distributedpath_specularreflectdepth = 2
					@lrs.sintegrator_distributedpath_specularrefractdepth = 4
					@lrs.sintegrator_distributedpath_strategy = 'auto'
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.250 
					@lrs.pixelfilter_mitchell_xwidth = 2.0 
					@lrs.pixelfilter_mitchell_ywidth = 2.0 
					@lrs.pixelfilter_mitchell_optmode = 'slider'
				when '0b'
					SU2LUX.dbg_p 'set preset 0b Preview - Direct Lighting'
					@lrs.fleximage_displayinterval = 4
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 1
					@lrs.sampler_lowdisc_pixelsampler = 'lowdiscrepancy'
					
					@lrs.sintegrator_type = 'directlighting'
					@lrs.sintegrator_direct_maxdepth = 5

					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				
				when '0c'
					@lrs.fleximage_displayinterval = 10
					@lrs.fleximage_haltspp = 1
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 4
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'exphotonmap'
					@lrs.sintegrator_exphoton_finalgather = false
					@lrs.sintegrator_exphoton_finalgathersamples = 32
					@lrs.sintegrator_exphoton_gatherangle = 10.0
					@lrs.sintegrator_exphoton_maxdepth = 5
					@lrs.sintegrator_exphoton_maxphotondepth = 10
					@lrs.sintegrator_exphoton_maxphotondist = 0.5
					@lrs.sintegrator_exphoton_nphotonsused = 50
					@lrs.sintegrator_exphoton_causticphotons = 20000
					@lrs.sintegrator_exphoton_directphotons = 20000
					@lrs.sintegrator_exphoton_indirectphotons = 0
					@lrs.sintegrator_exphoton_renderingmode = 'directlighting'
					@lrs.sintegrator_exphoton_rrcontinueprob = 0.65
					@lrs.sintegrator_exphoton_rrstrategy = 'efficiency'
					@lrs.sintegrator_exphoton_photonmapsfile = ''
					@lrs.sintegrator_exphoton_radiancephotons = 20000
					@lrs.sintegrator_exphoton_shadow_ray_count = 1
					@lrs.sintegrator_exphoton_strategy = 'auto'

					@lrs.pixelfilter_type = 'gaussian'
				when '1'
					SU2LUX.dbg_p 'set preset 1 Final - MLT/Bidir Path Tracing (interior) (recommended)'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'metropolis'
					@lrs.sampler_metropolis_strength = 0.6
					@lrs.sampler_metropolis_largemutationprob = 0.4
					@lrs.sampler_metropolis_maxconsecrejects = 512
					@lrs.sampler_metropolis_usevariance = false
					
					@lrs.sintegrator_type = 'bidirectional'
					@lrs.sintegrator_bidir_bounces = 16
					@lrs.sintegrator_bidir_eyedepth = 16
					@lrs.sintegrator_bidir_lightdepth = 16

					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when '2'
					SU2LUX.dbg_p 'set preset 2 Final - MLT/Path Tracing (exterior)'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'metropolis'
					@lrs.sampler_metropolis_strength = 0.6
					@lrs.sampler_metropolis_largemutationprob = 0.4
					@lrs.sampler_metropolis_maxconsecrejects = 512
					@lrs.sampler_metropolis_usevariance  = false
					
					@lrs.sintegrator_type = 'path'
					@lrs.sintegrator_path_bounces = 10
					@lrs.sintegrator_path_maxdepth = 10

					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when '5'
					SU2LUX.dbg_p 'set preset 5 Progressive - Bidir Path Tracing (interior)'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 1
					@lrs.sampler_lowdisc_pixelsampler = 'lowdiscrepancy'
					
					@lrs.sintegrator_type = 'bidirectional'
					@lrs.sintegrator_bidir_bounces = 16
					@lrs.sintegrator_bidir_eyedepth = 16
					@lrs.sintegrator_bidir_lightdepth = 16

					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when '6'
					SU2LUX.dbg_p 'set preset 6 Progressive - Path Tracing (exterior)'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 1
					@lrs.sampler_lowdisc_pixelsampler = 'lowdiscrepancy'
					
					@lrs.sintegrator_type = 'path'
					@lrs.sintegrator_path_bounces = 10
					@lrs.sintegrator_path_maxdepth = 10
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when '8'
					SU2LUX.dbg_p 'set preset 8 Bucket - Bidir Path Tracing (interior)'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 64
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'bidirectional'
					@lrs.sintegrator_bidir_bounces = 8
					@lrs.sintegrator_bidir_eyedepth = 8
					@lrs.sintegrator_bidir_lightdepth = 10
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when '9'
					SU2LUX.dbg_p 'set preset 9 Bucket - Path Tracing (exterior)'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 64
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'path'
					@lrs.sintegrator_path_bounces = 8
					@lrs.sintegrator_path_maxdepth = 8
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when 'B'
					SU2LUX.dbg_p 'set preset B Anim - Distributed/GI low Q'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 1
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 16
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'distributedpath'
					@lrs.sintegrator_distributedpath_directsampleall = true
					@lrs.sintegrator_distributedpath_directsamples = 1
					@lrs.sintegrator_distributedpath_directdiffuse = true
					@lrs.sintegrator_distributedpath_directglossy = true
					@lrs.sintegrator_distributedpath_indirectsampleall = false
					@lrs.sintegrator_distributedpath_indirectsamples = 1
					@lrs.sintegrator_distributedpath_indirectdiffuse = true
					@lrs.sintegrator_distributedpath_indirectglossy = true
					@lrs.sintegrator_distributedpath_diffusereflectdepth = 2
					@lrs.sintegrator_distributedpath_diffusereflectsamples = 1
					@lrs.sintegrator_distributedpath_diffuserefractdepth = 5
					@lrs.sintegrator_distributedpath_diffuserefractsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectdepth = 2
					@lrs.sintegrator_distributedpath_glossyreflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyrefractdepth = 5
					@lrs.sintegrator_distributedpath_glossyrefractsamples = 1
					@lrs.sintegrator_distributedpath_specularreflectdepth = 2
					@lrs.sintegrator_distributedpath_specularrefractdepth = 5
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when 'C'
					SU2LUX.dbg_p 'set preset C Anim - Distributed/GI medium Q'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 1
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 64
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'distributedpath'
					@lrs.sintegrator_distributedpath_diffuserefractdepth = 5
					@lrs.sintegrator_distributedpath_indirectglossy = true
					@lrs.sintegrator_distributedpath_directsamples = 1
					@lrs.sintegrator_distributedpath_diffuserefractsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectdepth = 2
					@lrs.sintegrator_distributedpath_directsampleall = true
					@lrs.sintegrator_distributedpath_indirectdiffuse = true
					@lrs.sintegrator_distributedpath_specularreflectdepth = 3
					@lrs.sintegrator_distributedpath_diffusereflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyrefractdepth = 5
					@lrs.sintegrator_distributedpath_diffusereflectdepth = 2
					@lrs.sintegrator_distributedpath_indirectsamples = 1
					@lrs.sintegrator_distributedpath_indirectsampleall = false
					@lrs.sintegrator_distributedpath_glossyrefractsamples = 1
					@lrs.sintegrator_distributedpath_directdiffuse = true
					@lrs.sintegrator_distributedpath_directglossy = true
					@lrs.sintegrator_distributedpath_strategy = 'auto'
					@lrs.sintegrator_distributedpath_specularrefractdepth = 5
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when 'D'
					SU2LUX.dbg_p 'set preset D Anim - Distributed/GI high Q'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 1
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 256
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'distributedpath'
					@lrs.sintegrator_distributedpath_diffuserefractdepth = 5
					@lrs.sintegrator_distributedpath_indirectglossy = true
					@lrs.sintegrator_distributedpath_directsamples = 1
					@lrs.sintegrator_distributedpath_diffuserefractsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectdepth = 2
					@lrs.sintegrator_distributedpath_directsampleall = true
					@lrs.sintegrator_distributedpath_indirectdiffuse = true
					@lrs.sintegrator_distributedpath_specularreflectdepth = 3
					@lrs.sintegrator_distributedpath_diffusereflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyrefractdepth = 5
					@lrs.sintegrator_distributedpath_diffusereflectdepth = 2
					@lrs.sintegrator_distributedpath_indirectsamples = 1
					@lrs.sintegrator_distributedpath_indirectsampleall = false
					@lrs.sintegrator_distributedpath_glossyrefractsamples = 1
					@lrs.sintegrator_distributedpath_directdiffuse = true
					@lrs.sintegrator_distributedpath_directglossy = true
					@lrs.sintegrator_distributedpath_strategy = 'auto'
					@lrs.sintegrator_distributedpath_specularrefractdepth = 5
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true
				when 'E'
					SU2LUX.dbg_p 'set preset E Anim - Distributed/GI very high Q'
					@lrs.fleximage_displayinterval = 8
					@lrs.fleximage_haltspp = 1
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 512
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'distributedpath'
					@lrs.sintegrator_distributedpath_diffuserefractdepth = 5
					@lrs.sintegrator_distributedpath_indirectglossy = true
					@lrs.sintegrator_distributedpath_directsamples = 1
					@lrs.sintegrator_distributedpath_diffuserefractsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectdepth = 2
					@lrs.sintegrator_distributedpath_directsampleall = true
					@lrs.sintegrator_distributedpath_indirectdiffuse = true
					@lrs.sintegrator_distributedpath_specularreflectdepth = 3
					@lrs.sintegrator_distributedpath_diffusereflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyreflectsamples = 1
					@lrs.sintegrator_distributedpath_glossyrefractdepth = 5
					@lrs.sintegrator_distributedpath_diffusereflectdepth = 2
					@lrs.sintegrator_distributedpath_indirectsamples = 1
					@lrs.sintegrator_distributedpath_indirectsampleall = false
					@lrs.sintegrator_distributedpath_glossyrefractsamples = 1
					@lrs.sintegrator_distributedpath_directdiffuse = true
					@lrs.sintegrator_distributedpath_directglossy = true
					@lrs.sintegrator_distributedpath_strategy = 'auto'
					@lrs.sintegrator_distributedpath_specularrefractdepth = 5
					
					@lrs.pixelfilter_type = 'mitchell'
					@lrs.pixelfilter_mitchell_sharpness = 0.333333
					@lrs.pixelfilter_mitchell_xwidth = 1.5 
					@lrs.pixelfilter_mitchell_ywidth = 1.5 
					@lrs.pixelfilter_mitchell_supersample = true

				when 'F'
					@lrs.fleximage_displayinterval = 15
					@lrs.fleximage_haltspp = 0
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 16
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'exphotonmap'
					@lrs.sintegrator_exphoton_finalgather = true
					@lrs.sintegrator_exphoton_finalgathersamples = 32
					@lrs.sintegrator_exphoton_gatherangle = 10.0
					@lrs.sintegrator_exphoton_maxdepth = 5
					@lrs.sintegrator_exphoton_maxphotondepth = 10
					@lrs.sintegrator_exphoton_maxphotondist = 0.1
					@lrs.sintegrator_exphoton_nphotonsused = 50
					@lrs.sintegrator_exphoton_causticphotons = 20000
					@lrs.sintegrator_exphoton_directphotons = 200000
					@lrs.sintegrator_exphoton_indirectphotons = 200000
					@lrs.sintegrator_exphoton_radiancephotons = 200000
					@lrs.sintegrator_exphoton_renderingmode = 'directlighting'
					@lrs.sintegrator_exphoton_rrcontinueprob = 0.65
					@lrs.sintegrator_exphoton_rrstrategy = 'efficiency'
					@lrs.sintegrator_exphoton_photonmapsfile = ''
					@lrs.sintegrator_exphoton_shadow_ray_count = 1
					@lrs.sintegrator_exphoton_strategy = 'auto'
					
					@lrs.pixelfilter_type = 'gaussian'
				when 'G'
					@lrs.fleximage_displayinterval = 15
					@lrs.fleximage_haltspp = 1
					@lrs.fleximage_halttime = 0
					
					@lrs.useparamkeys = false
					@lrs.sampler_show_advanced = false
					@lrs.sintegrator_show_advanced = false
					@lrs.pixelfilter_show_advanced = false
					
					@lrs.sampler_type = 'lowdiscrepancy'
					@lrs.sampler_lowdisc_pixelsamples = 256
					@lrs.sampler_lowdisc_pixelsampler = 'hilbert'
					
					@lrs.sintegrator_type = 'exphotonmap'
					@lrs.sintegrator_exphoton_finalgather = true
					@lrs.sintegrator_exphoton_finalgathersamples = 32
					@lrs.sintegrator_exphoton_gatherangle = 10.0
					@lrs.sintegrator_exphoton_maxdepth = 5
					@lrs.sintegrator_exphoton_maxphotondepth = 10
					@lrs.sintegrator_exphoton_maxphotondist = 0.1
					@lrs.sintegrator_exphoton_nphotonsused = 50
					@lrs.sintegrator_exphoton_causticphotons = 1000000
					@lrs.sintegrator_exphoton_directphotons = 200000
					@lrs.sintegrator_exphoton_indirectphotons = 200000
					@lrs.sintegrator_exphoton_radiancephotons = 200000
					@lrs.sintegrator_exphoton_renderingmode = 'directlighting'
					@lrs.sintegrator_exphoton_rrcontinueprob = 0.65
					@lrs.sintegrator_exphoton_rrstrategy = 'efficiency'
					@lrs.sintegrator_exphoton_photonmapsfile = ''
					@lrs.sintegrator_exphoton_shadow_ray_count = 1
					@lrs.sintegrator_exphoton_strategy = 'auto'
					
					@lrs.pixelfilter_type = 'gaussian'
				end #end case
			self.sendDataFromSketchup()
		} #end action callback preset
		
		
		##
		#
		##
		@settings_dialog.add_action_callback("open_dialog") {|dialog, params|
			case params.to_s
				when "new_export_file_path"
					SU2LUX.new_export_file_path
				when "load_env_image"
					SU2LUX.load_env_image
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
		settings.each { |setting|
			updateSettingValue(setting)
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
			p radio_id
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
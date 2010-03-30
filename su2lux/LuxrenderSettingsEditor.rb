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

def initialize

	pref_key="LuxrenderSettingsEditor"
	@settings_dialog=UI::WebDialog.new("Luxrender Render Settings", true,pref_key,520,500, 10,10,true)
	@settings_dialog.max_width = 520
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
					Sketchup.active_model.active_view.camera.fov = value.to_f
				when "focal_length"
					Sketchup.active_model.active_view.camera.focal_length = value.to_f
				when "camera_scale"
					@lrs.camera_scale=value
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
				when "architectural"
					@lrs.architectural=true if value=="true"
					@lrs.architectural=false if value=="false"
				when "motion_blur"
					@lrs.motion_blur=true if value=="true"
					@lrs.motion_blur=false if value=="false"
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
				when "sintegrator_dlighting_maxdepth"
					@lrs.sintegrator_dlighting_maxdepth=value
				when "singtegrator_path_maxdepth"
					@lrs.sintegrator_path_maxdepth=value
				when "sintegrator_igi_maxdepth"
					@lrs.sintegrator_igi_maxdepth=value
				#end Integrator
				
				#Volume integrator
				when "volume_integrator_type"
					@lrs.volume_integrator_type=value
				when "volume_integrator_stepsize"
					@lrs.volume_integrator_stepsize=value
				#end Volume integrator
				
				#Film
				when "xresolution"
					SU2LUX.p_debug 'set xresolution '+value
					@lrs.xresolution=value.to_f
					change_aspect_ratio(@lrs.xresolution.to_f / @lrs.yresolution.to_f)
				when "yresolution"
					SU2LUX.p_debug 'set yresolution '+value
					@lrs.yresolution=value.to_f
					change_aspect_ratio(@lrs.xresolution.to_f / @lrs.yresolution.to_f)
				#end Film
				
				#Accelerator
				when "accelerator_type"
					@lrs.accelerator_type=value
				#tabrec
				when "intersection_cost"
					@lrs.intersection_cost=value
				when "traversal_cost"
					@lrs.traversal_cost=value
				when "empty_bonus"
					@lrs.empty_bonus=value
				when "max_prims"
					@lrs.max_prims=value
				when "max_depth"
					@lrs.max_depth=value

				#grid
				when "refine_immediately"
					@lrs.refine_immediately=value

				#qbvh
				when "max_prims_per_leaf"
					@lrs.max_prims_per_leaf=value
				when "skip_factor"
					@lrs.skip_factor=value
				#end Accelerator
			end	
	} #end action callback param_generatate
	
	@settings_dialog.add_action_callback("get_view_size") { |dialog, params|
		width = (Sketchup.active_model.active_view.vpwidth)
		height = (Sketchup.active_model.active_view.vpheight)
		setValue("xresolution", width)
		setValue("yresolution", height)
		@lrs.xresolution = width
		@lrs.yresolution = height
		change_aspect_ratio(0.0)
	}

	@settings_dialog.add_action_callback("set_image_size") { |dialog, params|
		values = params.split('x')
		width = values[0].to_i
		height = values[1].to_i
		setValue("xresolution", width)
		setValue("yresolution", height)
		@lrs.xresolution = width
		@lrs.yresolution= height
		change_aspect = values[2]
		change_aspect_ratio(width.to_f / height.to_f) if change_aspect == "true"
	}
	
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
			
			@lrs.sintegrator_type='distributedpath'
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
			
			@lrs.sintegrator_type='distributedpath'
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
			
			@lrs.sintegrator_type='distributedpath'
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
	end #end case
	self.sendDataFromSketchup()
	} #end action callback preset
	
	
	@settings_dialog.add_action_callback("open_dialog") {|dialog, params|
  case params.to_s
		when "new_export_file_path"
			SU2LUX.new_export_file_path
	end #end case
	} #end action callback open_dialog
end


def show
	@settings_dialog.show{sendDataFromSketchup()}
end

#set parameters in inputs of settings.html
def sendDataFromSketchup()
	updateSettingValue("fov")
	updateSettingValue("focal_length")
	updateSettingValue("camera_scale")
	updateSettingValue("near_far_clipping")
	@lrs.xresolution = Sketchup.active_model.active_view.vpwidth
	updateSettingValue("xresolution")
	@lrs.yresolution = Sketchup.active_model.active_view.vpheight
	updateSettingValue("yresolution")
	if Sketchup.active_model.active_view.camera.perspective?
		@lrs.camera_type = 'perspective'
	else
		@lrs.camera_type = 'orthographic'
	end
	updateSettingValue("camera_type")
	updateSettingValue("hither")
	updateSettingValue("yon")
	updateSettingValue("accelerator_type")
	updateSettingValue("sintegrator_type")
	updateSettingValue("sintegrator_dlighting_maxdepth")
	updateSettingValue("sintegrator_path_maxdepth")
	updateSettingValue("sintegrator_igi_maxdepth")
	updateSettingValue("sampler_type")
	updateSettingValue("volume_integrator_type")
	updateSettingValue("volume_integrator_stepsize")
	updateSettingValue("export_file_path")
	
	updateSettingValue("intersection_cost")
	updateSettingValue("traversal_cost")
	updateSettingValue("empty_bonus")
	updateSettingValue("max_prims")
	updateSettingValue("max_depth")

	updateSettingValue("refine_immediately")

	updateSettingValue("max_prims_per_leaf")
	updateSettingValue("skip_factor")
end 

def is_a_checkbox?(id)#much better to use objects for settings?!
  @lrs=LuxrenderSettings.new
  if @lrs[id] == true or @lrs[id] == false
    return id
  end
end

def setValue(id,value) #extend to encompass different types (textbox, anchor, slider)
	new_value=value.to_s
  case id
    
  #### -- export_file_path slash change -- ####
  when "export_file_path"
    new_value.gsub!(/\\/, '\/') #bug with sketchup not allowing \ characters
    cmd="$('##{id}').text('#{new_value}');" #different asignment method
    SU2LUX.p_debug cmd
    @settings_dialog.execute_script(cmd)
  ############################

  
  ########  -- checkboxes -- ##########
  when is_a_checkbox?(id)
    cmd="$('##{id}').attr('checked', #{value});" #different asignment method
    SU2LUX.p_debug cmd
    @settings_dialog.execute_script(cmd)
    cmd="checkbox_expander('#{id}');"
    SU2LUX.p_debug cmd
    @settings_dialog.execute_script(cmd)
  #############################
  
  
  ######### -- other -- #############
	else
		cmd="$('##{id}').val('#{new_value}');" #syntax jquery
		SU2LUX.p_debug cmd
		@settings_dialog.execute_script(cmd)
		#Horror coding?
		if(id == "camera_type")
			cmd="$('##{id}').change();" #syntax jquery
			@settings_dialog.execute_script(cmd)
		end
	end
  #############################
  
end

def updateSettingValue(id)
  @lrs=LuxrenderSettings.new
  setValue(id, @lrs[id])
end

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
end

def setCheckbox(id,value)
	#TODO
end

end #end class LuxrenderSettingsEditor
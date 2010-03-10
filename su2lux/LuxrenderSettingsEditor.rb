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
				when "yresolution"
					SU2LUX.p_debug 'set yresolution '+value
					@lrs.yresolution=value.to_f
				#end Film
				
				#Accelerator
				when "accelerator_type"
					@lrs.accelerator_type=value
				#end Accelerator
			end	
	}
	
	

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
def SendDataFromSketchup()
	setValue("fov",@lrs.fov)
	setValue("camera_scale",@lrs.camera_scale)
	setValue("xresolution",@lrs.xresolution)
	setValue("yresolution",@lrs.yresolution)
	setValue("camera_type",@lrs.camera_type)
	setValue("hither",@lrs.hither)
	setValue("yon",@lrs.yon)
	setValue("accelerator_type",@lrs.accelerator_type)
	setValue("sintegrator_type",@lrs.sintegrator_type)
	setValue("sintegrator_dlighting_maxdepth",@lrs.sintegrator_dlighting_maxdepth)
	setValue("sintegrator_path_maxdepth",@lrs.sintegrator_path_maxdepth)
	setValue("sintegrator_igi_maxdepth",@lrs.sintegrator_igi_maxdepth)
	setValue("sampler_type",@lrs.sampler_type)
	setValue("volume_integrator_type",@lrs.volume_integrator_type)
	setValue("volume_integrator_stepsize",@lrs.volume_integrator_stepsize)
end 

def setValue(id,value)
	new_value=value.to_s
	cmd="$('##{id}').val('#{new_value}');" #syntax jquery
	SU2LUX.p_debug cmd
	@settings_dialog.execute_script(cmd)
end

def setCheckbox(id,value)
	#TODO
end

end #end class LuxrenderSettingsEditor
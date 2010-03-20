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
#                 Luke Frisken (aka lfrisken)

class LuxrenderSettings


@@settings=
{
#'name_option'=>'default_value'
#####################################################################
###### - Camera	-														######
#####################################################################
	'camera_type'=>'perspective',
	'fov'=>35, # not currently in use
	'camera_scale'=>7.31,
	'near_far_clipping'=>false,
	'dof_bokeh'=>false,
	'architectural'=>false,
	'motion_blur'=>false,
	'hither'=>0.1,
	'yon'=>100,  
	#end Camera
#####################################################################
#####################################################################

	#Environment 
	'environment_light_type'=>'infinite',
	#end Environment

	#Sampler
	'sampler_showadvanced'=>false,
	'sampler_type'=>'lowdiscrepancy',
	'sampler_lowdisc_pixelsamples'=>1,
	'sampler_lowdisc_pixelsampler'=>'lowdiscrepancy',
	'sampler_metro_strength'=>0.6,
	'sampler_metro_lmprob'=>0.4,
	'sampler_metro_maxrejects'=>512,
	'sampler_metro_usevariance'=>false,
	#end Sampler
  
	#Integrator
	'sintegrator_showadvanced'=>false,
	'sintegrator_type'=>'distributedpath',
	'sintegrator_distributedpath_directsampleall'=>true,
	'sintegrator_distributedpath_directsamples'=>1,
	'sintegrator_distributedpath_directdiffuse'=>true,
	'sintegrator_distributedpath_directglossy'=>true,
	'sintegrator_distributedpath_indirectsampleall'=>false,
	'sintegrator_distributedpath_indirectsamples'=>1,
	'sintegrator_distributedpath_indirectdiffuse'=>true,
	'sintegrator_distributedpath_indirectglossy'=>true,
	'sintegrator_distributedpath_diffusereflectdepth'=>1,
	'sintegrator_distributedpath_diffusereflectsamples'=>4,
	'sintegrator_distributedpath_diffuserefractdepth'=>4,
	'sintegrator_distributedpath_diffuserefractsamples'=>1,
	'sintegrator_distributedpath_glossyreflectdepth'=>1,
	'sintegrator_distributedpath_glossyreflectsamples'=>2,
	'sintegrator_distributedpath_glossyrefractdepth'=>4,
	'sintegrator_distributedpath_glossyrefractsamples'=>1,
	'sintegrator_distributedpath_specularreflectdepth'=>2,
	'sintegrator_distributedpath_specularrefractdepth'=>4,
	'sintegrator_distributedpath_causticsonglossy'=>true,
	'sintegrator_distributedpath_causticsondiffuse'=>false,
	'sintegrator_distributedpath_strategy'=>'auto',
	
	'sintegrator_dlighting_maxdepth'=>5,
	
	'sintegrator_bidir_bounces'=>16,
	'sintegrator_bidir_eyedepth'=>16,
	'singtegrator_bidir_lightdepth'=>16,
	'sintegrator_bidir_strategy'=>'auto',
	
	'sintegrator_path_maxdepth'=>10,
	'singtegrator_path_ienvironment'=>true,

	'singtegrator_path_strategy'=>'auto',
	'sintegrator_path_rrstrategy'=>'efficiency',
	'sintegrator_path_rrcontinueprob'=>0.65,
	
	'sintegrator_igi_maxdepth'=>5,
	#end Integrator
  
	#Volume Integrator
	'volume_integrator_type'=>"emission",
	'volume_integrator_stepsize'=>1.00,
	#end VolumeIntegrator
  
	#Filter
	'pixelfilter_showadvanced'=>false,
	'pixelfilter_type'=>'mitchell',
	'pixelfilter_mitchell_sharp'=>0.250, 
	'pixelfilter_mitchell_xwidth'=>2.0, 
	'pixelfilter_mitchell_ywidth'=>2.0,
	'pixelfilter_mitchell_optmode'=>'slider',
	#end Filter
  
	#Film
#####################################################################
###### - Film	-												######
#####################################################################
	'film_type'=>"fleximage",
	'xresolution'=> Sketchup.active_model.active_view.vpwidth,#800
	'yresolution'=> Sketchup.active_model.active_view.vpheight,#600
	'film_displayinterval'=>4,
	'haltspp'=>0,
	'halttime'=>0,
	#end Film
  
#####################################################################
###### - Accelerator	-														######
#####################################################################
	'accelerator_type'=> "tabreckdtree",
	#tabreckdtree  properties
	'intersectcost'=> 80,
	'traversalcost'=> 1,
	'emptybonus'=> 0.5,
	'maxprims'=> 1,
	'maxdepth'=> -1,
	#bvh properties
	#qbvh properties
	'maxprimsperleaf'=> 4,
	#grid properties
	'refineimmediately'=> false,
	#end Accelerator
#####################################################################
#####################################################################
  
	#Other
	'useparamkeys'=>false,
	'export_file_path'=>""
}


def LuxrenderSettings::ui_refreshable?(id)
  ui_refreshable_settings = [
    'export_file_path'
  ]
  if ui_refreshable_settings.include?(id)
    return id
  else
    return "not_ui_refreshable"
  end
end

def initialize
	singleton_class = (class << self; self; end)
	@model=Sketchup.active_model
	@view=@model.active_view
	@dict="luxrender_settings"
	singleton_class.module_eval do
    
    define_method("[]") do |key| 
      value = @@settings[key]
      return @model.get_attribute(@dict,key,value)
    end
    
    @@settings.each do |key, value|
      
      ######## -- get any attribute -- #######
      define_method(key) { @model.get_attribute(@dict,key,value) }
      ############################

      case key
        
        ###### -- set ui_refreshable -- #######
      when LuxrenderSettings::ui_refreshable?(key)
        define_method("#{key}=") do |new_value|
          settings_editor = SU2LUX.get_editor("settings")
          @model.set_attribute(@dict,key,new_value)
          settings_editor.updateSettingValue(key)
        end
        ###########################
      
      
        ######## -- set other -- ##########
      else
        define_method("#{key}=") { |new_value| @model.set_attribute(@dict,key,new_value) }
        ###########################
      end #end case
    end #end settings.each
	end #end module_eval
end #end initialize


end #end class LuxrenderSettings
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
  
#####################################################################
###### - Accelerator	-														######
#####################################################################
	@@accelerator_type = "tabreckdtree"
	#tabreckdtree  properties
	@@intersectcost = 80
	@@traversalcost = 1
	@@emptybonus = 0.5
	@@maxprims = 1
	@@maxdepth = -1
	#bvh properties
	#qbvh properties
	@@maxprimsperleaf = 4
	#grid properties
	@@refineimmediately = false
	#end Accelerator
#####################################################################
#####################################################################
  
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

#  @@accelerator_type="grid"
#  @@refineimmediately=false

  @@export_file_path = ""
  
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

#####################################################################
###### - Accelerator	-														######
#####################################################################
def accelerator_type
	@model.get_attribute(@dict, 'accelerator_type', @@accelerator_type)
end

def accelerator_type=(value)
	@model.set_attribute(@dict, 'accelerator_type', value)
end

def refineimmediately
	@model.get_attribute(@dict, 'refineimmediately', @@refineimmediately)
end

def refineimmediately=(value)
	@model.set_attribute(@dict, 'refineimmediately', value)
end

#tabreckdtree
def intersectcost
	@model.get_attribute(@dict, 'intersectcost', @@intersectcost)
end

def intersectcost=(value)
	@model.set_attribute(@dict, 'intersectcost', value)
end

def traversalcost
	@model.get_attribute(@dict, 'traversalcost', @@traversalcost)
end

def traversalcost=(value)
	@model.set_attribute(@dict, 'traversalcost', value)
end

def emptybonus
	@model.get_attribute(@dict, 'emptybonus', @@emptybonus)
end

def emptybonus=(value)
	@model.set_attribute(@dict, 'emptybonus', value)
end

def maxprims
	@model.get_attribute(@dict, 'maxprims', @@maxprims)
end

def maxprims=(value)
	@model.set_attribute(@dict, 'maxprims', value)
end

def maxdepth
	@model.get_attribute(@dict, 'maxdepth', @@maxdepth)
end

def maxdepth=(value)
	@model.set_attribute(@dict, 'maxdepth', value)
end
#end tabreckdtree

#qvbh
def maxprimsperleaf
	@model.get_attribute(@dict, 'maxprimsperleaf', @@maxprimsperleaf)
end

def maxprimsperleaf=(value)
	@model.set_attribute(@dict, 'maxprimsperleaf', value)
end
#end qvbh
#####################################################################
###### - END Accelerator	-												######
#####################################################################
  
#Other
def useparamkeys
	@model.get_attribute(@dict,'useparamkeys',@@useparamkeys)
end

def useparamkeys=(value)
	@model.set_attribute(@dict,'useparamkeys',value)
end
#end Other
  
#Export Path Settings
def export_file_path
  @model.get_attribute(@dict, 'export_file_path', @@export_file_path)
end

def export_file_path=(value)
  @model.set_attribute(@dict, 'export_file_path', value)
end
#end Export Path Settings

end #end class LuxrenderSettings
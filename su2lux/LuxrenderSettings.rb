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

	attr_reader :dict
	alias_method :dictionary_name, :dict
	
	@@settings=
	{
	#'name_option'=>'default_value'
	##
	# Settings
	###
        #'preset' => '1',
    
	##
	# Camera
	###
		'camera_type' => 'perspective',
		'hither'=> 0.1,
		'yon' => 100,  
		'shutteropen' => 0.0,
		'shutterclose' => 1.0,
		'shutterdistribution' => 'uniform',
		'lensradius' => 0.006250,
        'aperture' => 2.8,
		'focaldistance' => 1.0,
		'frameaspectratio' => 1.333333,
		'autofocus' => true,
		'fov' => format("%.2f", Sketchup.active_model.active_view.camera.fov), # camera angle, not currently in use
		'distribution' => 'uniform',
		'power' => 1,
		'blades' => 6,
    
		'camera_scale' => 7.31, #seems to work only in Blender
		'use_clipping' => false, #GUI
		'use_dof_bokeh'=>false, #GUI
		'focus_type' => 'autofocus', #GUI
		'use_architectural'=>false, #GUI
		'shiftX' => 0.0, #GUI
		'shiftY' => 0.0, #GUI
		'use_ratio' => false, #GUI
		'use_motion_blur'=>false, #GUI
		'focal_length' => format("%.5f", Sketchup.active_model.active_view.camera.focal_length), #GUI
	# END Camera

	##
	#Environment
	##
		'environment_light_type'=> 'sunsky',
		'environment_infinite_lightgroup' => 'infinite light',
		'environment_infinite_L_R' => Sketchup.active_model.rendering_options["BackgroundColor"].red / 255.0, #environment color red component
		'environment_infinite_L_G' => Sketchup.active_model.rendering_options["BackgroundColor"].green / 255.0, #environment color green component
		'environment_infinite_L_B' => Sketchup.active_model.rendering_options["BackgroundColor"].blue / 255.0, #environment color green component
		'environment_infinite_gain' => 1.0,
		'environment_infinite_mapping' => 'latlong',
		'environment_infinite_mapname' => '',
		'environment_infinite_rotatex' => 0,
		'environment_infinite_rotatey' => 0,
		'environment_infinite_rotatez' => 0,
		'environment_infinite_gamma' => 1.0,
		'environment_sky_lightgroup' => 'sky',
		'environment_sky_gain' => 1.0,
		'environment_sky_turbidity' => 2.2,
		'environment_sun_lightgroup' => 'sun',
		'environment_sun_gain' => 1.0,
		'environment_sun_relsize' => 1.0,
		'environment_sun_turbidity' => 2.2,
        'environment_use_sun' => true,
        'environment_use_sky' => true,

		'use_environment_infinite_sun' => false, #GUI
		'use_plain_color' => 'sketchup_color', #GUI
		'environment_infinite_sun_lightgroup' => 'sun', #for full GUI
		'environment_infinite_sun_gain' => 1.0, #for full GUI
		'environment_infinite_sun_relsize' => 1.0, #for full GUI
		'environment_infinite_sun_turbidity' => 2.2, #for full GUI
	#END Environment

	##
	# Filter
	##
		'pixelfilter_show_advanced' => false, #GUI
		'pixelfilter_show_advanced_box' => false, #GUI
		'pixelfilter_show_advanced_gaussian' => false, #GUI
		'pixelfilter_show_advanced_mitchell' => false, #GUI
		'pixelfilter_show_advanced_sinc' => false, #GUI
		'pixelfilter_show_advanced_triangle' => false, #GUI
		'pixelfilter_type' => 'mitchell',
		'pixelfilter_mitchell_sharpness' => 0.333333, #Basic GUI
		'pixelfilter_mitchell_optmode' => 'manual', #TODO: change to slider ##unused in Sketchup
		'pixelfilter_mitchell_xwidth' => 2.0, 
		'pixelfilter_mitchell_ywidth' => 2.0,
		'pixelfilter_mitchell_B' => 0.333333,
		'pixelfilter_mitchell_C' => 0.333333,
		'pixelfilter_mitchell_supersample' => false,
		'pixelfilter_box_xwidth' => 0.5, 
		'pixelfilter_box_ywidth' => 0.5,
		'pixelfilter_triangle_xwidth' => 2.0, 
		'pixelfilter_triangle_ywidth' => 2.0,
		'pixelfilter_sinc_xwidth' => 2.0, 
		'pixelfilter_sinc_ywidth' => 2.0,
		'pixelfilter_sinc_tau' => 2.0,
		'pixelfilter_gaussian_xwidth' => 2.0, 
		'pixelfilter_gaussian_ywidth' => 2.0,
		'pixelfilter_gaussian_alpha' => 2.0,
	# END Filter
	
	##
	#Sampler
	##
		'sampler_show_advanced'=>false,
		'sampler_type'=>'metropolis',
		'sampler_random_pixelsamples' => 4,
		'sampler_random_pixelsampler' => 'vegas',
		'sampler_lowdisc_pixelsamples' => 4,
		'sampler_lowdisc_pixelsampler' => 'vegas',
        'sampler_metropolis_strength' => 0.6, #Basic GUI
        'sampler_noiseaware' => true,
		'sampler_metropolis_largemutationprob' => 0.4,
		'sampler_metropolis_maxconsecrejects' => 512,
		'sampler_metropolis_usevariance'=> false,
		'sampler_erpt_chainlength' => 2000,
	# END Sampler
		
	##
	#Integrator
	##
		'sintegrator_show_advanced' => true, #GUI
		'sintegrator_type' => 'bidirectional',
		'sintegrator_bidir_show_advanced' => false, #GUI
		'sintegrator_bidir_bounces' => 16, #Basic GUI
		'sintegrator_bidir_eyedepth' => 8,
		'sintegrator_bidir_eyerrthreshold' => 0.0,
		'sintegrator_bidir_lightdepth' => 8,
		'sintegrator_bidir_lightthreshold' => 0.0,
		'sintegrator_bidir_strategy' => 'auto',
		'sintegrator_bidir_debug' => 'false',
		'sintegrator_direct_show_advanced' => false,
		'sintegrator_direct_bounces' => 5, #Basic GUI
		'sintegrator_direct_maxdepth' => 5,
		'sintegrator_direct_shadow_ray_count' => 1,
		'sintegrator_direct_strategy' => 'auto',
		'sintegrator_distributedpath_directsampleall' => true,
		'sintegrator_distributedpath_directsamples' => 1,
		'sintegrator_distributedpath_indirectsampleall' => false,
		'sintegrator_distributedpath_indirectsamples' => 1,
		'sintegrator_distributedpath_diffusereflectdepth' => 3,
		'sintegrator_distributedpath_diffusereflectsamples' => 1,
		'sintegrator_distributedpath_diffuserefractdepth' => 5,
		'sintegrator_distributedpath_diffuserefractsamples' => 1,
		'sintegrator_distributedpath_directdiffuse' => true,
		'sintegrator_distributedpath_indirectdiffuse' => true,
		'sintegrator_distributedpath_glossyreflectdepth' => 2,
		'sintegrator_distributedpath_glossyreflectsamples' => 1,
		'sintegrator_distributedpath_glossyrefractdepth' => 5,
		'sintegrator_distributedpath_glossyrefractsamples' => 1,
		'sintegrator_distributedpath_directglossy' => true,
		'sintegrator_distributedpath_indirectglossy' => true,
		'sintegrator_distributedpath_specularreflectdepth' => 2,
		'sintegrator_distributedpath_specularrefractdepth' => 5,
		'sintegrator_distributedpath_strategy' => 'auto',
		'sintegrator_distributedpath_reject' => false, #GUI
		'sintegrator_distributedpath_diffusereflectreject' => false,
		'sintegrator_distributedpath_diffusereflectreject_threshold' => 10.0,
		'sintegrator_distributedpath_diffuserefractreject' => false,
		'sintegrator_distributedpath_diffuserefractreject_threshold' => 10.0,
		'sintegrator_distributedpath_glossyreflectreject' => false,
		'sintegrator_distributedpath_glossyreflectreject_threshold' => 10.0,
		'sintegrator_distributedpath_glossyrefractreject' => false,
		'sintegrator_distributedpath_glossyrefractreject_threshold' => 10.0,
		
		'sintegrator_exphoton_show_advanced' => false,
		'sintegrator_exphoton_finalgather' => true,
		'sintegrator_exphoton_finalgathersamples' => 32,
		'sintegrator_exphoton_gatherangle' => 10.0,
		'sintegrator_exphoton_maxdepth' => 5,
		'sintegrator_exphoton_maxphotondepth' => 10,
		'sintegrator_exphoton_maxphotondist' => 0.5,
		'sintegrator_exphoton_nphotonsused' => 50,
		'sintegrator_exphoton_causticphotons' => 20000,
		'sintegrator_exphoton_directphotons' => 200000,
		'sintegrator_exphoton_indirectphotons' => 1000000,
		'sintegrator_exphoton_radiancephotons' => 200000,
		'sintegrator_exphoton_renderingmode' => 'directlighting',
		'sintegrator_exphoton_rrcontinueprob' => 0.65,
		'sintegrator_exphoton_rrstrategy' => 'efficiency',
		'sintegrator_exphoton_photonmapsfile' => '',
		'sintegrator_exphoton_shadow_ray_count' => 1,
		'sintegrator_exphoton_strategy' => 'auto',
		'sintegrator_exphoton_dbg_enable_direct' => true,
		'sintegrator_exphoton_dbg_enable_indircaustic' => true,
		'sintegrator_exphoton_dbg_enable_indirdiffuse' => true,
		'sintegrator_exphoton_dbg_enable_indirspecular' => true,
		'sintegrator_exphoton_dbg_enable_radiancemap' => false,

		'sintegrator_igi_show_advanced' => false,
		'sintegrator_igi_maxdepth' => 5,
		'sintegrator_igi_mindist' => 0.1,
		'sintegrator_igi_nsets' => 4,
		'sintegrator_igi_nlights' => 64,

		'sintegrator_path_show_advanced' => false,
		'sintegrator_path_include_environment' => true,
		'sintegrator_path_bounces' => 10, #Basic GUI
		'sintegrator_path_maxdepth' => 10,
		'sintegrator_path_rrstrategy' => 'efficiency',
		'sintegrator_path_rrcontinueprob' => 0.65,
		'sintegrator_path_shadow_ray_count' => 1,
		'sintegrator_path_strategy' => 'auto',
	# END Integrator
		
	##
	# Volume Integrator
	##
		'volume_integrator_type' => "emission",
		'volume_integrator_stepsize' => 1.0,
	# END VolumeIntegrator
		
	##
	# Film
	##
		'film_type' => "fleximage",
		'fleximage_premultiplyalpha' => false,
		'fleximage_xresolution' => nil,
		'fleximage_yresolution' => nil,
		'fleximage_resolution_percent' => 100, #GUI
		'fleximage_filterquality' => 4,
		'fleximage_ldr_clamp_method' => "lum",
		'fleximage_write_exr' => false,
		'fleximage_write_exr_channels' => "RGB",
		'fleximage_write_exr_halftype' => true,
		'fleximage_write_exr_compressiontype' => "PIZ (lossless)",
		'fleximage_write_exr_applyimaging' => true,
		'fleximage_write_exr_gamutclamp' => true,
		'fleximage_write_exr_ZBuf' => false,
		'fleximage_write_exr_zbuf_normalizationtype' => "None",
		'fleximage_write_png' => true,
		'fleximage_write_png_channels' => "RGB",
		'fleximage_write_png_16bit' => false,
		'fleximage_write_png_gamutclamp' => true,
		'fleximage_write_png_ZBuf' => false,
		'fleximage_write_png_zbuf_normalizationtype' => "Min/Max",
		'fleximage_write_tga' => false,
		'fleximage_write_tga_channels' => "RGB",
		'fleximage_write_tga_gamutclamp' => true,
		'fleximage_write_tga_ZBuf' => false,
		'fleximage_write_tga_zbuf_normalizaziontype' => "Min/Max",
		'fleximage_write_resume_flm' => false,
		'fleximage_restart_resume_flm' => false,
		'fleximage_filename' => "SU2LUX_rendered_image",
		'fleximage_writeinterval' => 180,
		'fleximage_displayinterval' => 20,
		'fleximage_outlierrejection_k' => 0,
		'fleximage_debug' => false,
		'fleximage_haltspp' => -1,
		'fleximage_halttime' => -1,
		'fleximage_colorspace_red_x' => 0.63, #GUI
		'fleximage_colorspace_red_y' => 0.34, #GUI
		'fleximage_colorspace_green_x' => 0.31, #GUI
		'fleximage_colorspace_green_y' => 0.595, #GUI
		'fleximage_colorspace_blue_x' => 0.155, #GUI
		'fleximage_colorspace_blue_y' => 0.07, #GUI
		'fleximage_colorspace_white_x' => 0.314275, #GUI
		'fleximage_colorspace_white_y' => 0.329411, #GUI
		'fleximage_tonemapkernel' => 'reinhard',
		'fleximage_reinhard_prescale' => 1.0,
		'fleximage_reinhard_postscale' => 1.0,
		'fleximage_reinhard_burn' => 6.0,
		'fleximage_linear_sensitivity' => 50.0,
		'fleximage_linear_exposure' => 1.0,
		'fleximage_linear_fstop' => 2.8,
		'fleximage_linear_gamma' => 1.0,
		'fleximage_contrast_ywa' => 1.0,
		'fleximage_cameraresponse' => "",
		'fleximage_gamma' => 2.2,
		#added for GUI
		'fleximage_linear_use_preset' => false,
		'fleximage_linear_camera_type' => "photo",
		'fleximage_linear_cinema_exposure' => "180-deg",
		'fleximage_linear_cinema_fps' => "25 FPS",
		'fleximage_linear_photo_exposure' => "1/125",
		'fleximage_linear_use_half_stop' => "false",
		'fleximage_linear_hf_stopF' => 2.8,
		'fleximage_linear_hf_stopT' => 3.3,
		'fleximage_linear_iso' => "100",
		'fleximage_use_preset' => true,
		'fleximage_use_colorspace_whitepoint' => true,
		'fleximage_use_colorspace_gamma' => true,
		'fleximage_use_colorspace_whitepoint_preset' => true,
		'fleximage_colorspace_wp_preset' => "D65 - daylight, 6504",
		'fleximage_colorspace_gamma' => 2.2,
		'fleximage_colorspace_preset_white_x' => 0.314275,
		'fleximage_colorspace_preset_white_y' => 0.329411,
		'fleximage_colorspace_preset' => 'sRGB - HDTV (ITU-R BT.709-5)',
		
		
		# 'saveexr' => false,
	# END Film
		
	##
	# Accelerator
	##
		'accelerator_type' => "tabreckdtree",
		#tabreckdtree  properties
		'kdtree_intersectcost' => 80,
		'kdtree_traversalcost' => 1,
		'kdtree_emptybonus' => 0.5,
		'kdtree_maxprims' => 1,
		'kdtree_maxdepth' => -1,
		#bvh properties
		#qbvh properties
		'qbvh_maxprimsperleaf' => 4,
		'qbvh_skip_factor' => 1,
		#grid properties
		'grid_refineimmediately' => false,
	# END Accelerator
    
    
    ##
    # Color Swatches
    ##
    'swatch_list' => ['diffuse_swatch','specular_swatch','reflection_swatch','metal2_swatch','transmission_swatch','absorption_swatch','cl1kd_swatch','cl1ks_swatch','cl2kd_swatch','cl2ks_swatch'],
    'diffuse_swatch' => ['kd_R','kd_G','kd_B'],
    'specular_swatch'=> ['ks_R','ks_G','ks_B'],
    'reflection_swatch' => ['kr_R','kr_G','kr_B'],
    'transmission_swatch' => ['kt_R','kt_G','kt_B'],
    'absorption_swatch' => ['ka_R','ka_G','ka_B'],
    'metal2_swatch' => ['km2_R','km2_G','km2_B'],
    'cl1kd_swatch' => ['cl1kd_R','cl1kd_G','cl1kd_B'],
    'cl1ks_swatch' => ['cl1ks_R','cl1ks_G','cl1ks_B'],
    'cl2kd_swatch' => ['cl2kd_R','cl2kd_G','cl2kd_B'],
    'cl2ks_swatch' => ['cl2ks_R','cl2ks_G','cl2ks_B'],
    
    
	##
	# Other
	##
		'useparamkeys' => false,
        'texexport' => "skp",
		'exp_distorted' => true, # export distorted textures
		'export_file_path' => "",
        'export_luxrender_path' => "",
        'geomexport' => 'ply',
		'priority' => 'low',
        'copy_textures' => true,
        'colorpicker' => "diffuse_swatch",
        'preview_size' => 140,
        'preview_time' => 2,
	}

	##
	#
	##
	def LuxrenderSettings::ui_refreshable?(id)
		ui_refreshable_settings = [
            'export_file_path',
            'export_luxrender_path',
			'environment_infinite_mapname'
		]
		if ui_refreshable_settings.include?(id)
			return id
		else
			return "not_ui_refreshable"
		end
	end # END LuxrenderSettings::ui_refreshable?

	##
	#
	##
	def initialize
        puts "initializing LuxRender settings"
		singleton_class = (class << self; self; end)
		@model=Sketchup.active_model
		@view=@model.active_view
		@dict="luxrender_settings"
		singleton_class.module_eval do

			define_method("[]") do |key| 
				value = @@settings[key]
				return LuxrenderAttributeDictionary.get_attribute(@dict, key, value)
			end
			
			@@settings.each do |key, value|
				######## -- get any attribute -- #######
				define_method(key) { LuxrenderAttributeDictionary.get_attribute(@dict, key, value) }

				case key
					when LuxrenderSettings::ui_refreshable?(key)# set ui_refreshable
						define_method("#{key}=") do |new_value|
						settings_editor = SU2LUX.get_editor("settings")
						LuxrenderAttributeDictionary.set_attribute(@dict, key, new_value)
						settings_editor.updateSettingValue(key) if settings_editor
					end
					else # set other
						define_method("#{key}=") { |new_value| LuxrenderAttributeDictionary.set_attribute(@dict, key, new_value) }
				end #end case
			end #end settings.each
		end #end module_eval
        puts "done initializing LuxRender settings"
	end #end initialize

	def reset
            puts "resetting settings editor"
			@@settings.each do |key, value|
				LuxrenderAttributeDictionary.set_attribute(@dict, key, value)
			end
			LuxrenderAttributeDictionary.set_attribute(@dict, 'fov', format("%.2f", Sketchup.active_model.active_view.camera.fov))
			LuxrenderAttributeDictionary.set_attribute(@dict, 'focal_length', format("%.2f", Sketchup.active_model.active_view.camera.focal_length))
			LuxrenderAttributeDictionary.set_attribute(@dict, 'fleximage_xresolution', Sketchup.active_model.active_view.vpwidth)
			LuxrenderAttributeDictionary.set_attribute(@dict, 'fleximage_yresolution', Sketchup.active_model.active_view.vpheight)
	end #END reset
	
	def load_from_model
		return LuxrenderAttributeDictionary.load_from_model(@dict)
	end #END load_from_model
	
	def save_to_model
        puts "saving settings to sketchup file"
		Sketchup.active_model.start_operation "SU2LUX settings saved" # start undo operation block
		LuxrenderAttributeDictionary.save_to_model(@dict)
		Sketchup.active_model.commit_operation # end undo operation block
	end #END load_from_model
	
	def get_names
		settings = []
		@@settings.each { |key, value|
			settings.push(key)
		}
		return settings
	end #END get_names
	
end # END class LuxrenderSettings
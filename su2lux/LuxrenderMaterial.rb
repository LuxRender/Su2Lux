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

class LuxrenderMaterial

	attr_reader :dict, :mat
	alias_method :dictionary_name, :dict
	
	@@settings=
	{
		'type' => "matte",
		'kd_imagemap_Sketchup_filename' => '',

		'kd_R' => 0.64,
		'kd_G' => 0.64,
		'kd_B' => 0.64,

		'ks_R' => 0.5,
		'ks_G' => 0.5,
		'ks_B' => 0.5,

		'ka_R' => 0.0,
		'ka_G' => 0.0,
		'ka_B' => 0.0,

		'kr_R' => 1.0,
		'kr_G' => 1.0,
		'kr_B' => 1.0,

		'kt_R' => 1.0,
		'kt_G' => 1.0,
		'kt_B' => 1.0,

		'exponent' => 50,
		'uroughness' => 0.1,
		'vroughness' => 0.1,

		'matte_sigma' => 0.0,
		'ka_d' => 0.0,
		'IOR_index' => 1.5,
		'multibounce' => false,
		'cauchyb' => 0.004,
		'film' => 200,
		'film_index' => 1.5,
		'nk_preset' => '',
		'energyconserving' => true,
		'bumpmap' => 0.0001,

		'light_L' => 'blackbody',
		'light_temperature' => 6500.0,
		'light_power' => 100.0,
		'light_efficacy' => 17.0,
		'light_gain' => 1.0,
		#GUI
		'use_diffuse_texture' => false,
		'use_sigma_texture' => false,
		'use_uroughness_texture' => false,
		'use_specular_texture' => false,
		'use_absorption_texture' => false,
		'use_absorption_depth_texture' => false,
		'use_reflection_texture' => false,
		'use_transmission_texture' => false,
		'use_architectural' => false,
		'use_IOR_texture' => false,
		'use_dispersive_refraction_texture' => false,
		'use_film_texture' => false,
		'use_film_index_texture' => false,
		'use_absorption' => false,
		'use_dispersive_refraction' => false,
		'use_thin_film_coating' => false,
		'use_bump' => false,
		'use_bump_texture' => false,
	}

	##
	#
	##
	def lux_image_texture(material, name, texture, type)
		material_prefix = material
		material_prefix += "_" if ( ! material.empty?)
		key_prefix = material_prefix + "#{name}"
		key = "#{key_prefix}_#{texture}_"
		@@settings[key_prefix + "_texturetype"] = "none"
		@@settings[key + "wrap"] = "repeat"
		@@settings[key + "channel"] = "mean" if (type == "float")
		@@settings[key + "filename"] = ""
		@@settings[key + "gamma"] = 2.2
		@@settings[key + "gain"] = 1.0
		@@settings[key + "filtertype"] = "bilinear"
		@@settings[key + "mapping"] = "uv"
		@@settings[key + "uscale"] = 1.0
		@@settings[key + "vscale"] = -1.0
		@@settings[key + "udelta"] = 0.0
		@@settings[key + "vdelta"] = 1.0
		@@settings[key + "maxanisotropy"] = 8.0
		@@settings[key + "discardmipmaps"] = 0
	end
	
	##
	#
	##
	def LuxrenderMaterial::ui_refreshable?(id)
		ui_refreshable_settings = [
			"kd_imagemap_filename",
			"matte_sigma_imagemap_filename",
			"ks_imagemap_filename",
			"uroughness_imagemap_filename",
			"vroughness_imagemap_filename",
			"ka_imagemap_filename",
			"ka_d_imagemap_filename",
			"kr_imagemap_filename",
			"kt_imagemap_filename",
		]
		if ui_refreshable_settings.include?(id)
			return id
		else
			return "not_ui_refreshable"
		end
	end # END LuxrenderMaterial::ui_refreshable?

	##
	#
	##
	def initialize(su_material)
		@mat = su_material
		
		lux_image_texture("", "kd", "imagemap", "color")
		lux_image_texture("matte", "sigma", "imagemap", "float")
		lux_image_texture("", "ks", "imagemap", "color")
		lux_image_texture("", "ka", "imagemap", "color")
		lux_image_texture("", "uroughness", "imagemap", "float")
		lux_image_texture("", "vroughness", "imagemap", "float")
		lux_image_texture("", "ka_d", "imagemap", "float")
		lux_image_texture("", "IOR_index", "imagemap", "float")
		lux_image_texture("", "kr", "imagemap", "color")
		lux_image_texture("", "kt", "imagemap", "color")
		# lux_image_texture("", "IOR", "imagemap", "float")
		lux_image_texture("", "cauchyb", "imagemap", "float")
		lux_image_texture("", "film_thickness", "imagemap", "float")
		lux_image_texture("", "film_index", "imagemap", "float")
		lux_image_texture("", "bump", "imagemap", "float")
		
		singleton_class = (class << self; self; end)
		@model=Sketchup.active_model
		@view=@model.active_view
		# @dict="luxrender_materials"
		# TEST
		@dict = mat.name
		singleton_class.module_eval do

			define_method("[]") do |key| 
				value = @@settings[key]
				return LuxrenderAttributeDictionary.get_attribute(@dict, key, value)
			end
			
			@@settings.each do |key, value|
				######## -- get any attribute -- #######
				define_method(key) { LuxrenderAttributeDictionary.get_attribute(@dict, key, value) }

				case key
					when LuxrenderMaterial::ui_refreshable?(key)# set ui_refreshable
						define_method("#{key}=") do |new_value|
						LuxrenderAttributeDictionary.set_attribute(@dict, key, new_value)
						settings_editor = SU2LUX.get_editor("material")
						settings_editor.updateSettingValue(key) if settings_editor
					end
					else # set other
						define_method("#{key}=") { |new_value| LuxrenderAttributeDictionary.set_attribute(@dict, key, new_value) }
				end #end case
			end #end settings.each
		end #end module_eval
	end #end initialize

	##
	#
	##
	def reset
			@@settings.each do |key, value|
				LuxrenderAttributeDictionary.set_attribute(@dict, key, value)
			end
	end #END reset
	
	##
	#
	##
	def load_from_model
		return LuxrenderAttributeDictionary.load_from_model(@dict)
	end #END load_from_model
	
	##
	#
	##
	def save_to_model
		Sketchup.active_model.start_operation "SU2LUX Material settings saved"
		LuxrenderAttributeDictionary.save_to_model(@dict)
		Sketchup.active_model.commit_operation
	end #END save_to_model
	
	##
	#
	##
	def get_names
		settings = []
		@@settings.each { |key, value|
			settings.push(key)
		}
		return settings
	end #END get_names
	
	##
	#
	##
	def name
		return mat.display_name.delete("[<>]")  #replaces <> characters with *
		# return mat.display_name.gsub(/[<>]/, '*')  #replaces <> characters with *
	end
  
	##
	#
	##
	def original_name
		return mat.name
	end
	
	##
	#
	##
	def color
		color = [self.kd_R, self.kd_G, self.kd_B]
	end

	##
	#
	##
	def color=(su_mat_color)
		scale = 1/255.0
		self.kd_R = format("%.6f", su_mat_color.red.to_f * scale)
		self.kd_G = format("%.6f", su_mat_color.green.to_f * scale)
		self.kd_B = format("%.6f", su_mat_color.blue.to_f * scale)
	end
	
	##
	#
	##
	def RGB_color
		scale = 255
		rgb = []
		for c in self.color
			rgb.push((c.to_f * scale).to_i)
		end
		return rgb
	end

	##
	#
	##
	def specular
		specular = [self.ks_R, self.ks_G, self.ks_B]
	end

	##
	#
	##
	def specular=(color)
		self.ks_R = format("%.6f", color[0])
		self.ks_G = format("%.6f", color[1])
		self.ks_B = format("%.6f", color[2])
	end
	
	##
	#
	##
	def absorption
		specular = [self.ka_R, self.ka_G, self.ka_B]
	end
	
	##
	#
	##
	def reflection
		reflection = [self.kr_R, self.kr_G, self.kr_B]
	end

	##
	#
	##
	def transmission
		transmission = [self.kt_R, self.kt_G, self.kt_B]
	end

	private :lux_image_texture
	
end # END class LuxrenderMaterial
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
		'matte_kd_R' => 0.64,
		'matte_kd_G' => 0.64,
		'matte_kd_B' => 0.64,
		'matte_sigma' => 0.0,
		# 'glossy_kd_R' => 0.5,
		# 'glossy_kd_G' => 0.5,
		# 'glossy_kd_B' => 0.5,
		'glossy_ks_R' => 0.5,
		'glossy_ks_G' => 0.5,
		'glossy_ks_B' => 0.5,
		'glossy_ka_R' => 0.0,
		'glossy_ka_G' => 0.0,
		'glossy_ka_B' => 0.0,
		'glossy_uroughness' => 0.1,
		'glossy_vroughness' => 0.1,
		'ka_d' => 0.0,
		'glossy_index' => 0.0,
		'multibounce' => false,
		#GUI
		'use_diffuse_texture' => false,
		'use_sigma_texture' => false,
		'use_specular_texture' => false,
		'use_absorption_texture' => false,
		'use_absorption_depth_texture' => false,
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
		lux_image_texture("glossy", "index", "imagemap", "float")
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

	def reset
			@@settings.each do |key, value|
				LuxrenderAttributeDictionary.set_attribute(@dict, key, value)
			end
	end #END reset
	
	# def load_from_model
		# return LuxrenderAttributeDictionary.load_from_model(@dict)
	# end #END load_from_model
	
	# def save_to_model
		# Sketchup.active_model.start_operation "SU2LUX settings saved"
		# LuxrenderAttributeDictionary.save_to_model(@dict)
		# Sketchup.active_model.commit_operation
	# end #END load_from_model
	
	def get_names
		settings = []
		@@settings.each { |key, value|
			settings.push(key)
		}
		return settings
	end #END get_names
	
	def name
		return mat.display_name.gsub(/[<>]/, '*')  #replaces <> characters with *
	end
  
	def original_name
		return mat.name
	end
	
	def color
		color = [self.matte_kd_R, self.matte_kd_G, self.matte_kd_B]
	end

	def color=(su_mat_color)
		scale = 1/255.0
		self.matte_kd_R = format("%.6f", su_mat_color.red.to_f * scale)
		self.matte_kd_G = format("%.6f", su_mat_color.green.to_f * scale)
		self.matte_kd_B = format("%.6f", su_mat_color.blue.to_f * scale)
	end
	
	def RGB_color
		scale = 255
		rgb = [(self.color[0] * scale), (self.color[1] * scale), (self.color[2] * scale)]
	end
	
	def color2
		mat.color
	end


	private :lux_image_texture
	
end # END class LuxrenderMaterial
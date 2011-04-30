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

class LuxrenderMaterialEditor

	attr_writer :current
	
	def initialize
		@material_editor_dialog = UI::WebDialog.new("Luxrender Material Editor", true, "LuxrenderMaterialEditor", 500, 500, 900, 400, true)
		material_editor_dialog_path = Sketchup.find_support_file("materialeditor.html", "Plugins/su2lux")
		@material_editor_dialog.max_width = 800
		@material_editor_dialog.set_file(material_editor_dialog_path)

		# @lm = LuxrenderMaterial.new(Sketchup.active_model.materials.current.name)
		
		@material_editor_dialog.add_action_callback('param_generate') {|dialog, params|
			# Get the data from the Webdialog.
			parameters = string_to_hash(params)
			material = Sketchup.active_model.materials.current
			# lux_material = LuxrenderMaterial.new(material)
			# lux_material = self.find(material.name)
			lux_material = @current
			parameters.each{ |k, v|
				if (lux_material.respond_to?(k))
					method_name = k + "="
					lux_material.send(method_name, v)
					case
						when k.match(/matte_kd_/)
							red = lux_material.color[0]
							green = lux_material.color[1]
							blue = lux_material.color[2]
							p lux_material.RGB_color.to_a.to_s
							material.color = lux_material.RGB_color
					end
				end
			}
		}
				
		@material_editor_dialog.add_action_callback("open_dialog") {|dialog, params|
			data = params.to_s
			material = Sketchup.active_model.materials.current
			# lux_material = LuxrenderMaterial.new(material)
			lux_material = @current
			SU2LUX.load_image("Open image", lux_material, data)
		} #end action callback open_dialog
		
		@material_editor_dialog.add_action_callback('material_changed') { |dialog, material_name|
			materials = Sketchup.active_model.materials
			@current = self.find(material_name)
			materials.current = materials[material_name] if ( ! @current.nil?)
			# updateSettingValue("type")
			self.sendDataFromSketchup()
		}
		
		@material_editor_dialog.add_action_callback('type_changed') { |dialog, material_type|
			# material = Sketchup.active_model.materials.current
			# lux_material = LuxrenderMaterial.new(material)
			# lux_material.type = material_type
			# UI.start_timer(0.2, false) { self.sendDataFromSketchup() }
		}
		
		@material_editor_dialog.add_action_callback("reset_to_default") {|dialog, params|
			materials = Sketchup.active_model.materials
			for mat in materials
				luxmat = self.find(mat.name)
				luxmat.reset
			end
			self.close
			UI.start_timer(0.5, false) { self.show }
			# self.show
		}

		@material_editor_dialog.add_action_callback("save_to_model") {|dialog, params|
			materials = Sketchup.active_model.materials
			for mat in materials
				luxmat = self.find(mat.name)
				luxmat.save_to_model
			end
		}
		
		# @material_editor_dialog.add_action_callback('param_generate') {|dialog, params|
				# #p 'param_generate'
				# SU2LUX.dbg_p params
				# # Get the data from the Webdialog.
				# parameters = string_to_hash(params)
				# # Prepare the data
				# material_type=parameters['material_type']
				# #p material_type
				# material_name=parameters['material_name']
				# #p material_name
				# #p "su_material"
				# luxmat=self.find(material_name)
				# luxmat.type=material_type
		# }
		
		# @material_editor_dialog.add_action_callback('set_material_list') {
			# self.set_material_list()
		# }
		
		# @material_editor_dialog.add_action_callback('select_material'){|dialog, matname|
			# SU2LUX.dbg_p "matname_2"+matname
			# luxrender_material=self.find(matname)
			# SU2LUX.dbg_p "type="+luxrender_material.type
			# cmd="$(\"#material_type option[value='"+luxrender_material.type+"']\").attr(\"selected\",\"selected\");"
			# SU2LUX.dbg_p cmd
			# @material_editor_dialog.execute_script(cmd)
		# }
	end # end initialize

	##
	# Takes a string like "key1=value1,key2=value2" and creates an hash.
	##
	def string_to_hash(string)
		hash = {}
		datapairs = string.split('|')
		datapairs.each { |datapair|
			data = datapair.split('=')
			hash[data[0]] = data[1]
		}
		return hash
	end

	##
	#
	##	
	def find(name) 
		# display_names = materials.collect {|m| m.display_name}
		# names=materials.collect {|m| m.name}
		# index=names.index(display_name)
		# mat=index ? materials[names[index]] : nil  #get the SU material
		materials=Sketchup.active_model.materials
		mat = materials[name]
		if mat
			return LuxrenderMaterial.new(mat)
		else
			return nil
		end
	end 

	##
	#
	##	
	def show
		# @material_editor_dialog.show{}
		@material_editor_dialog.show{refresh()}
	end

	##
	#
	##
	def refresh()
		set_material_list()
		#set current material in editor
		materials = Sketchup.active_model.materials
		for mat in materials
			luxmat = LuxrenderMaterial.new(mat)
			# TODO: set up all the parameters
			luxmat.color = mat.color
			if mat.texture
				texture_name = mat.texture.filename
				texture_name.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
				texture_name.gsub!(/\\/, '/') if texture_name.include?('\\')
				luxmat.kd_imagemap_Sketchup_filename = texture_name
				luxmat.kd_texturetype = 'sketchup'
				luxmat.use_diffuse_texture = true
			end
		end
		current = materials.current
		if (current.nil?)
			current = materials[0]
			materials.current = current
		end
		luxmat = self.find(current.name)
		self.set_current(luxmat.name)
		@current = luxmat
		self.sendDataFromSketchup()
	end
	
	##
	#
	##
	def set_current(name)
		# cmd = "$(#material_name).attr('selected', 'selected'"
		p "call to set_current"
		cmd = "$('#material_name option:contains(#{name})').attr('selected', true)"
		@material_editor_dialog.execute_script(cmd)
	end
	
	# ##
	# #
	# ##	
	# def refreshMaterialsList()

		# #cmd="clearMaterialList()"
		# #@material_editor_dialog.execute_script(cmd)
		# mat_list=Sketchup.active_model.materials.collect {|m| m.name}
		# mat_list.sort!
		# id="material_name"
		# mat_list.each {|mat_name|
		# #cmd="createMapOption(\"#{id}\",\"#{mat_name}\",\"#{mat_name}\")"
		# # cmd="createMapOption(\"#{id}\",\"wwwww\",\"wwww\")"
		# # SU2LUX.dbg_p cmd
		# # @material_editor_dialog.execute_script(cmd)
	# }
	# end

	##
	#
	##	
	def set_material_list() 
		cmd = "$('#material_name').empty()"
		@material_editor_dialog.execute_script(cmd)	
		cmd = "$('#material_name').append( $('"
		materials = Sketchup.active_model.materials.sort
		for mat in materials
			luxrender_mat = LuxrenderMaterial.new(mat)
			cmd = cmd + "<option value=\"#{luxrender_mat.original_name}\">#{luxrender_mat.name}</option>"
		end
		cmd = cmd + "'));"	
		@material_editor_dialog.execute_script(cmd)	
	end
		
	##
	#
	##	
	# def refresh_material_list() 
		# materials=Sketchup.active_model.materials.count
		# mat_list.sort!
		# cmd = "$('#material_name').empty()"
		# @material_editor_dialog.execute_script(cmd)	
		# cmd = "$('#material_name').append( $('"
		# materials = Sketchup.active_model.materials.sort
		# for mat in materials
			# luxrender_mat = LuxrenderMaterial.new(mat)
			# cmd = cmd + "<option value=\"#{luxrender_mat.original_name}\">#{luxrender_mat.name}</option>"
		# end
		# cmd = cmd + "'));"	
		# @material_editor_dialog.execute_script(cmd)	
	# end
		
	# ##
	# #
	# ##	
	# def setmaterialtype()
		# SU2LUX.dbg_p "set material type"
	# end

	##
	#set parameters in inputs of settings.html
	##
	def sendDataFromSketchup()
		# material = Sketchup.active_model.materials.current
		# lux_material = self.find(material.name)
		lux_material = @current
		settings = lux_material.get_names
		# current_settings = settings.select{ |k, v| k.include?(lux_material.type) }
		# current_settings = settings
		settings.each { |setting|
			updateSettingValue(setting)
		}
		# setting = "type"
		# setValue(setting, lux_material[setting])
		# updateSettingValue(setting)
	end # END sendDataFromSketchup
	
	##
	#
	##
	def is_a_checkbox?(id)#much better to use objects for settings?!
		# material = Sketchup.active_model.materials.current
		# lux_material = LuxrenderMaterial.new(material)
		lux_material = @current
		if lux_material[id] == true or lux_material[id] == false
			return id
		end
	end # END is_a_checkbox?

	##
	#
	##
	def setValue(id, value) #extend to encompass different types (textbox, anchor, slider)
		new_value=value.to_s
		case id
			when is_a_checkbox?(id)
				self.fire_event("##{id}", "attr", "checked=#{value}")
				cmd="checkbox_expander('#{id}');"
				@material_editor_dialog.execute_script(cmd)
				cmd = "$('##{id}').next('div.collapse').find('select').change();"
				@material_editor_dialog.execute_script(cmd)
			# #############################
			# when "use_plain_color"
				# radio_id = @lrs.use_plain_color
				# cmd = "$('##{radio_id}').attr('checked', true)"
				# @material_editor_dialog.execute_script(cmd)
			
			######### -- other -- #############
			else
				self.fire_event("##{id}", "val", new_value)
				# cmd="$('##{id}').val('#{new_value}');"
				# @material_editor_dialog.execute_script(cmd)
			end
			#############################
	end # END setValue

	##
	#
	##
	def updateSettingValue(id)
		# material = Sketchup.active_model.materials.current
		# lux_material = LuxrenderMaterial.new(material)
		lux_material = @current
		setValue(id, lux_material[id])
	end # END updateSettingValue

	def fire_event(object, event, parameters)
		cmd = ""
		case event
			when "change"
				cmd = "$('#{object}').#{event}();"
			when "val"
				cmd = "$('#{object}').val('#{parameters}');"
			when "attr"
				params = string_to_hash(parameters)
				params.each{ |key, value|
					cmd += "$('#{object}').attr('#{key}', #{value});"
				}
		end
		@material_editor_dialog.execute_script(cmd)
	end

	def close
		@material_editor_dialog.close
	end
	
	def visible?
		return @material_editor_dialog.visible?
	end
	
end #end class LuxrenderMaterialEditor
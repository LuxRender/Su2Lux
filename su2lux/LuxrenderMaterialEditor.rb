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

	attr_accessor :current, :matname_changed, :materials_skp_lux
    attr_reader :material_editor_dialog
	
	def initialize
		@lrs = LuxrenderSettings.new
		@materials_skp_lux = Hash.new
		@matname_changed = false
		@material_editor_dialog = UI::WebDialog.new("LuxRender Material Editor", true, "LuxrenderMaterialEditor", 500, 700, 900, 100, true)
		material_editor_dialog_path = Sketchup.find_support_file("materialeditor.html", "Plugins/su2lux")
		@material_editor_dialog.max_width = 800
		@material_editor_dialog.set_file(material_editor_dialog_path)
        
        @color_picker = UI::WebDialog.new("Color Picker", false, "ColorPicker", 200, 220, 200, 350, true)
        color_picker_path = Sketchup.find_support_file("colorpicker.html", "Plugins/su2lux")
        @color_picker.set_file(color_picker_path)
		@texture_editor_data = {}
		
		@material_editor_dialog.add_action_callback('param_generate') {|dialog, params|
            SU2LUX.dbg_p ("callback: param_generate")
			parameters = string_to_hash(params) # converts data passed by webdialog to hash
			material = Sketchup.active_model.materials.current
			lux_material = @current
			parameters.each{ |k, v|
				if (lux_material.respond_to?(k))
					method_name = k + "="
					if (v.to_s.downcase == "true")
						v = true
					end
					if (v.to_s.downcase == "false")
						v = false
					end
					lux_material.send(method_name, v)
					case
						when (k.match(/^kd_.$/) and !material.texture) # changing diffuse color, updating SketchUp material colour accordingly
                            # puts "lux_material.color: ", lux_material.color # debugging
							red = lux_material['kd_R'].to_f * 255.0
                            green = lux_material['kd_G'].to_f * 255.0
                            blue = lux_material['kd_B'].to_f * 255.0
                            # puts red, green, blue
                            convertedcolor = Sketchup::Color.new(red.to_i, green.to_i, blue.to_i)
                            puts convertedcolor
                            material.color = convertedcolor
                            # todo: update color swatch
                            @lrs.diffuse_swatch[0]
                            @lrs.diffuse_swatch[1]
                            @lrs.diffuse_swatch[2]
                            update_swatches()
					end
				end
			}
		}
				
		@material_editor_dialog.add_action_callback("open_dialog") {|dialog, params|
            SU2LUX.dbg_p ("callback: open_dialog")
			data = params.to_s
			material = Sketchup.active_model.materials.current
			lux_material = @current
			SU2LUX.load_image("Open image", lux_material, data, '')
		} #end action callback open_dialog
        
		@material_editor_dialog.add_action_callback("material_changed") { |dialog, material_name|
            puts ("callback: material_changed")
            puts material_name
            materials = Sketchup.active_model.materials
            puts ("current material: " + materials.current.name)
			# material_name_8859_1 = sanitize_path(material_name)
			
			existingluxmat = "none"
			@materials_skp_lux.values.each {|value| 
				# puts "checking material name ", value.name
				if value.name == material_name.delete("[<>]")
					existingluxmat = value
				end
			}
			
			if existingluxmat == "none"
				puts "LuxRender material not found, creating new material"
				@current = self.find(material_name) ### use only this line if testing fails
			else
				puts "reusing LuxRender material"
				@current = existingluxmat
			end
			
			SU2LUX.dbg_p "new active material: #{materials.current.name}"
			if (material_name != materials.current.name)
				materials.current = materials[material_name] if ( ! @current.nil?)
			end
			
			# reload existing material preview image
			puts "attempting to reload image"
			load_preview_image()
		}
        
        @material_editor_dialog.add_action_callback('open_color_picker') { |dialog, param|
            SU2LUX.dbg_p "creating color picker window"
            #puts param
            @lrs.colorpicker=param
            @color_picker.show
        }
        
        @color_picker.add_action_callback('pass_color') { |dialog, passedcolor|
            passedcolor="000000" if passedcolor.length != 7 # color picker may return NaN when mouse is dragged outside window
            SU2LUX.dbg_p "passed color received"
			@colorpicker_triggered = true
            puts "picked color is ", passedcolor
            colorswatch = @lrs.colorpicker
			rvalue = (passedcolor[1, 2].to_i(16).to_f*1000000/255.0).round/1000000.0 # ruby 1.8 doesn't support round(6)
            gvalue = (passedcolor[3, 2].to_i(16).to_f*1000000/255.0).round/1000000.0
            bvalue = (passedcolor[5, 2].to_i(16).to_f*1000000/255.0).round/1000000.0
            if ((@lrs.colorpicker=="diffuse_swatch" or @lrs.colorpicker=="transmission_swatch")  and !Sketchup.active_model.materials.current.texture)
                Sketchup.active_model.materials.current.color = [rvalue,gvalue,bvalue] # material observer will update kd_R,G,B values
                # # @current.RGB_swatch = Sketchup.active_model.materials.current.color
            end
            #puts "updating swatch:", colorswatch
            colorvars = []
            case colorswatch
            when "diffuse_swatch"
                puts "updating diffuse swatch"
                @current.kd_R = rvalue
                @current.kd_G = gvalue
                @current.kd_B = bvalue
            when "absorption_swatch"
                @current.ka_R = rvalue
                @current.ka_G = gvalue
                @current.ka_B = bvalue
            when "reflection_swatch"
                @current.kr_R = rvalue
                @current.kr_G = gvalue
                @current.kr_B = bvalue
            when "transmission_swatch"
                @current.kt_R = rvalue
                @current.kt_G = gvalue
                @current.kt_B = bvalue
            end
            updateSettingValue(@lrs.send(colorswatch)[0])
            updateSettingValue(@lrs.send(colorswatch)[1])
            updateSettingValue(@lrs.send(colorswatch)[2])
            
            update_swatches()
            #@material_editor_dialog.execute_script('flowtest()')
        }
        
		@material_editor_dialog.add_action_callback('start_refresh') { |dialog, param|
            SU2LUX.dbg_p "refresh called through javascript"
			refresh()
		}
		
		@material_editor_dialog.add_action_callback('active_mat_type') { |dialog, param| # shows the appropriate material editor panels for current material type
            SU2LUX.dbg_p ("callback: active_mat_type")
			@materialtype = @current.type # @materialtype = LuxrenderAttributeDictionary.get_attribute(@materials_skp_lux.index(@current).name, 'type', 'default')
			javascriptcommand = "$('#type').nextAll('.' + '" + @materialtype + "').show();"
            SU2LUX.dbg_p javascriptcommand
			dialog.execute_script(javascriptcommand)
		}
		
		@material_editor_dialog.add_action_callback('type_changed') { |dialog, material_type|
            SU2LUX.dbg_p ("callback: type changed")
			print "current material: ", material_type, "\n"
            @current.send("type=", material_type)
            # update_swatches()
		}
		
		@material_editor_dialog.add_action_callback('get_diffuse_color') {|dialog, param|
            SU2LUX.dbg_p ("callback: get_diffuse_color")
			lux_material = @current
			lux_material.specular = lux_material.color
			updateSettingValue("ks_R")
			updateSettingValue("ks_G")
			updateSettingValue("ks_B")
		}
		
		@material_editor_dialog.add_action_callback("reset_to_default") {|dialog, params|
            puts ("callback: reset_to_default")
			materials = Sketchup.active_model.materials
			for mat in materials
				luxmat = self.find(mat.name)
				luxmat.reset
			end
			self.close
			UI.start_timer(0.5, false) { self.show }
		}
        
		@material_editor_dialog.add_action_callback("update_material_preview") {|dialog, params|
            puts ("callback: update_material_preview")
			
			# prepare file paths
			os = OSSpecific.new
            preview_path = os.get_variables["material_preview_path"]
            path_separator = os.get_variables["path_separator"]
		
            active_material = @materials_skp_lux.index(@current) ## was Sketchup.active_model.materials.current  
			active_material_name = active_material.name.delete("[<>]") # following LuxrenderMaterial.rb convention ## was Sketchup.active_model.materials.
			active_material_name_converted = sanitize_path(active_material_name)
            
			# generate preview lxm file and export bitmap images
			lxm_path = preview_path+active_material_name+".lxm"
			lxm_path_8859_1 = sanitize_path(lxm_path)
			base_file = preview_path + "ansi.txt"
			FileUtils.copy_file(base_file,lxm_path_8859_1)
			generated_lxm_file = File.new(lxm_path_8859_1,"a")
			
			texture_subfolder = "/LuxRender/textures"
			previewExport=LuxrenderExport.new(preview_path,path_separator) # preview path should define where preview files will be stored
			previewExport.export_preview_material(preview_path,generated_lxm_file,active_material_name_converted,active_material,texture_subfolder,@current)
			generated_lxm_file.close
												
			# previewExport.write_textures # old
			puts "finished texture output for material preview"
			
			# generate preview lxs file
			lxs_path = preview_path+active_material_name+".lxs"
			lxs_path_8859_1 = sanitize_path(lxs_path)
			
			base_file_2 = preview_path + "ansi.txt"
			FileUtils.copy_file(base_file_2,lxs_path_8859_1)
			generated_lxs_file = File.new(lxs_path_8859_1,"a")
            
			lxs_section_1 = File.readlines(preview_path+"preview.lxs01")
            lxs_section_2 = File.readlines(preview_path+"preview.lxs02")
            lxs_section_3 = File.readlines(preview_path+"preview.lxs03")
            generated_lxs_file.puts (lxs_section_1)
            generated_lxs_file.puts ("  \"string filename\" \[\""+active_material_name_converted+"\"]")
            generated_lxs_file.puts ("WorldBegin")          
			generated_lxs_file.puts ("Include \""+active_material_name_converted+".lxm\"")
            generated_lxs_file.puts (lxs_section_2)
            previewExport.output_material (active_material, generated_lxs_file, @current) # writes "NamedMaterial #active_material_name.." or light definition
            generated_lxs_file.puts (lxs_section_3)
            previewExport.export_displacement_textures (active_material, generated_lxs_file, @current)
            generated_lxs_file.puts ("AttributeEnd")
            generated_lxs_file.puts ("WorldEnd")
			generated_lxs_file.close
            
			# start rendering preview using luxconsole
			@preview_lxs = preview_path+active_material_name_converted+".lxs" 
			@filename = preview_path+active_material_name_converted+".png"
			luxconsole_path = SU2LUX.get_luxrender_console_path()
			@preview_renderingtime = 2  # seconds (todo: make user configurable?)  
			@time_out = @preview_renderingtime + 10
			@retry_interval = 0.5
			@luxconsole_options = " "
			pipe = IO.popen(luxconsole_path + @luxconsole_options + "\"" + @preview_lxs + "\"","r") # start rendering
            puts (luxconsole_path + @luxconsole_options + "\"" + @preview_lxs + "\"")
			
			# wait for rendering to get ready, then update image
			@times_waited = 0.0
			@d = UI.start_timer(@preview_renderingtime+1, false){ 		# sets timer one second longer than rendering time
				file_exists = File.file? @filename
				while (!file_exists && (@times_waited < @time_out)) 	# if no image is found, wait for file to be rendered
					print("no image found, timing out in ", @time_out-@times_waited, " seconds\n")
					file_exists = File.file? @filename
					sleep 0.2
					@times_waited += 0.2
				end	
				while (file_exists && ((Time.now()-File.mtime(@filename)) > @preview_renderingtime) && (@times_waited < @time_out)) 
					puts("old preview found, waiting for update...")				# if an old image is found, wait for update
					sleep 1
					@times_waited += 1
				end	
				if (@times_waited > (@time_out))						# if the waiting has surpassed the time out limit, give up
					puts("preview is taking too long, aborting")
					# UI.messagebox("The preview rendering process is taking longer than expected.")
				end
				if (@times_waited <= @time_out && (Time.now()-File.mtime(@filename)) < (@preview_renderingtime+@time_out))
					puts("updating preview")
					# the file name on the following line includes ?timestamp, forcing the image to be refreshed as the link has changed
					cmd = 'document.getElementById("preview_image").src = "' + @filename.gsub('\\', '\\\\\\\\')  + '\?' + File.mtime(@filename).to_s + '"' 
					@material_editor_dialog.execute_script(cmd)
				end
			}
		}
        
		@material_editor_dialog.add_action_callback("save_to_model") {|dialog, params|
            puts ("callback: save_to_model")
			materials = Sketchup.active_model.materials
			for mat in materials
				luxmat = self.find(mat.name)
				luxmat.save_to_model
			end
		}
		
		@material_editor_dialog.add_action_callback("show_continued") {|dialog, params|
			# todo: make this run only when the material dialog hasn't been initialised
			@material_editor_dialog.execute_script('startactivemattype()')
		}
		
		@material_editor_dialog.add_action_callback("texture_editor") {|dialog, params|
            puts ("callback: texture_editor")
			lux_material = @current
			data = params.to_s
			method_name = data + '_texturetype'
			texture_type = lux_material.send(method_name)
			
			prefix = data + '_' + texture_type + '_'
			@texture_editor_data['texturetype'] = lux_material.send(method_name)
			['wrap', 'channel', 'filename', 'gamma', 'gain', 'filtertype', 'mapping', 'uscale',
			 'vscale', 'udelta', 'vdelta', 'maxanisotropy', 'discardmipmaps'].each {|par|
				@texture_editor_data[texture_type + '_' + par] = lux_material.send(prefix + par) if(lux_material.respond_to?(prefix+par))
			}
			@texture_editor = LuxrenderTextureEditor.new(@texture_editor_data, data)
			@texture_editor.show()
		}
	end # end initialize
	
	def load_preview_image()
		puts "running load_preview_image function"			
		os = OSSpecific.new
		filename = os.get_variables["material_preview_path"] + @current.name.delete("[<>]") + ".png"
		filename = filename.gsub('\\', '/')
		if (File.exists?(filename))
			puts "preview image exists, loading"
			cmd = 'document.getElementById("preview_image").src = "' + filename + '"'
		else
			puts "file doesn't exist, showing default image"
			cmd = 'document.getElementById("preview_image").src = "empty_preview.png"'
		end
		@material_editor_dialog.execute_script(cmd)
	end
	
	
	def sanitize_path(original_path)
		if (ENV['OS'] =~ /windows/i)
			sanitized_path = original_path.unpack('U*').pack('C*') # converts string to ISO-8859-1
		else
			sanitized_path = original_path
		end
	end
    
    def update_swatches() # sets the right color for current material's material editor swatches
        puts "updating swatches"
		swatches = @lrs.swatch_list
        swatches.each do |swatch|
            colorswatch = @lrs.send(swatch) # returns ['k#_R','k#_G','k#_B']
            rchannel = "%.2x" % ((@current.send(colorswatch[0]).to_f)*255).to_i
            gchannel = "%.2x" % ((@current.send(colorswatch[1]).to_f)*255).to_i
            bchannel = "%.2x" % ((@current.send(colorswatch[2]).to_f)*255).to_i
            swatchcolor = "#" + rchannel + gchannel + bchannel
            changecolorswatch = "$('#" + swatch + "').css('background-color', '" + swatchcolor + "');"
            @material_editor_dialog.execute_script(changecolorswatch)
        end
    end
    
    
    
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
		mat = Sketchup.active_model.materials[name]
		if mat
			return LuxrenderMaterial.new(mat)
		else
            puts "no material found for name ", name
			return nil
		end
	end 

	##
	#
	##	
	def show
        SU2LUX.dbg_p "running show function"
		@material_editor_dialog.show{}
        #refresh()
        # SU2LUX.dbg_p "finished running show function"
	end	
	
	##
	#
	##	
	def hide
		@material_editor_dialog.close{}
	end
    
	
	##
	#
	##
	def refresh()
		SU2LUX.dbg_p "running refresh function"
		materials = Sketchup.active_model.materials
        
		## check if LuxRender materials exist, if not, create them
		for mat in materials
			if !@materials_skp_lux.include?(mat) # test if LuxRender material has been created, if not, create one
				luxmat = find(mat.name) # creates LuxRender material
				@materials_skp_lux[mat] = luxmat  	#  add materials to hash contained processed materials
				puts "adding material #{mat.name} to material hash, creating LuxRender material"
				luxmat.color = mat.color
				if mat.texture
					puts "setting texture information"
					texture_name = mat.texture.filename
					texture_name.gsub!(/\\\\/, '/') #bug with sketchup not allowing \ characters
					texture_name.gsub!(/\\/, '/') if texture_name.include?('\\')
					luxmat.kd_imagemap_Sketchup_filename = texture_name
					luxmat.kd_texturetype = 'sketchup'
					luxmat.use_diffuse_texture = true
				end
				#puts luxmat.type
                   
			else
				puts "material #{mat.name} found in material hash, skipping LuxRender material creation"
			end
		end
		
		## set @current
		if @materials_skp_lux.include?(materials.current)
			@current = @materials_skp_lux[materials.current]
			puts "current material has been set"
		else
			@current = @materials_skp_lux.values[0]
			puts "setting material[0] as current material"
		end
		
		## update material editor contents
		set_material_list()
##listmat		
			set_material_list1()
##listmat		
		sendDataFromSketchup()
		load_preview_image		
		set_current(@current.name)
        
        # for all textures, show the Load button if texture type is image map
        cmd = 'show_load_buttons()'
        @material_editor_dialog.execute_script(cmd)
	end
	
	##
	#
	##
	def set_current(passedname)
		SU2LUX.dbg_p "call to set_current: #{passedname}"
        if (@current) # prevent update_swatches function from running before a luxmaterial has been created
            update_swatches()
        end
        # todo: improve cmd to prevent issues when material names overlap (like brick, brick2)
		cmd = "$('#material_name option:contains(#{passedname})').attr('selected', true)" 
        puts cmd
		@material_editor_dialog.execute_script(cmd)
	end
	
	##
	#
	##	
	def set_material_list()
        puts "updating material dropdown list in LuxRender Material Editor"
		cmd = "$('#material_name').empty()"
		@material_editor_dialog.execute_script(cmd)	
		cmd = "$('#material_name').append( $('"
		# puts "material list command: ", cmd
		materials = Sketchup.active_model.materials.sort
		for mat in materials
			luxrender_mat = @materials_skp_lux[mat]
			# puts "adding luxrender material to material list: ", luxrender_mat
			cmd = cmd + "<option value=\"#{luxrender_mat.original_name}\">#{luxrender_mat.name}</option>"
		end
		cmd = cmd + "'));"
		@material_editor_dialog.execute_script(cmd)		
	end
##listmat
	def set_material_list1()
		arr = [1, 2]
		for item in arr
	      puts "updating material dropdown list in LuxRender Material Editor"
			cmd = "$('#material_list"+item.to_s+"').empty()"
			@material_editor_dialog.execute_script(cmd)	
			cmd = "$('#material_list"+item.to_s+"').append( $('"
			# puts "material list command: ", cmd
			materials = Sketchup.active_model.materials.sort
			for mat in materials
				luxrender_mat = @materials_skp_lux[mat]
				# puts "adding luxrender material to material list: ", luxrender_mat
				cmd = cmd + "<option value=\"#{luxrender_mat.name}\">#{luxrender_mat.name}</option>"
			end
		cmd = cmd + "<option value="">none</option>"	
		cmd = cmd + "'));"
		@material_editor_dialog.execute_script(cmd)
		end	
	end
##listmat
	##
	#set parameters in inputs of settings.html
	##
	def sendDataFromSketchup()
        SU2LUX.dbg_p "running sendDataFromSketchup for "
		puts @current.name
		materialproperties = @current.get_names # returns all settings from LuxrenderMaterial @@settings
		materialproperties.each { |setting| updateSettingValue(setting)	}
		# SU2LUX.dbg_p "just ran sendDataFromSketchup@LuxrenderMaterialEditor"
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
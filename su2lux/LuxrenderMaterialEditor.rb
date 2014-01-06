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
		@material_editor_dialog = UI::WebDialog.new("LuxRender Material Editor", true, "LuxrenderMaterialEditor", 424, 700, 900, 100, true)
		material_editor_dialog_path = Sketchup.find_support_file("materialeditor.html", "Plugins/su2lux")
		@material_editor_dialog.max_width = 800
		@material_editor_dialog.set_file(material_editor_dialog_path)
        @collectedmixmaterials = []
        @collectedmixmaterials_i = 0
        
        @color_picker = UI::WebDialog.new("Color Picker", false, "ColorPicker", 200, 220, 200, 350, true)
        color_picker_path = Sketchup.find_support_file("colorpicker.html", "Plugins/su2lux")
        @color_picker.set_file(color_picker_path)
		@texture_editor_data = {}
        
        @numberofluxmaterials = 0
		
		@material_editor_dialog.add_action_callback('param_generate') {|dialog, params|
            SU2LUX.dbg_p ("callback: param_generate")
			parameters = string_to_hash(params) # converts data passed by webdialog to hash
			material = Sketchup.active_model.materials.current
			lux_material = @current
			parameters.each{ |k, v|
				if (lux_material.respond_to?(k))
                    puts k
                    puts v
                    puts "lux_material responding"
                    puts @current
					method_name = k + "="
					if (v.to_s.downcase == "true")
						v = true
					end
					if (v.to_s.downcase == "false")
						v = false
					end
					lux_material.send(method_name, v) # updates values in material
					case
						when (k.match(/^kd_.$/) and !material.texture) # changing diffuse color, updating SketchUp material colour accordingly
                            puts "updating color"
                            # puts "lux_material.color: ", lux_material.color # debugging
							red = (lux_material['kd_R'].to_f * 255.0).to_i
                            green = (lux_material['kd_G'].to_f * 255.0).to_i
                            blue = (lux_material['kd_B'].to_f * 255.0).to_i
                            material.color = Sketchup::Color.new(red, green, blue)
                        when (k.match(/_R/) || k.match (/_G/) || k.match (/_B/))
                            puts "some other color channel"
                            update_swatches()
					end
				end
                if (v == "imagemap")
                        puts "updating text"
                        textype = k.dup
                        textype.slice!("_texturetype")
                        update_texture_name(lux_material, textype)
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
            materials = Sketchup.active_model.materials
            puts ("callback: material_changed, changing from material " + materials.current.name + " to " + material_name)
			
			existingluxmat = "none"
			@materials_skp_lux.values.each {|value| 
				# puts "checking material name ", value.name
				if value.name == material_name.delete("[<>]")
					existingluxmat = value
				end
			}
			
			if existingluxmat == "none"
				puts "LuxRender material not found, creating new material"
                #UI.messagebox ("about to run .find for material " + material_name)
				@current = self.find(material_name) ### use only this line if testing fails
			else
				puts "reusing LuxRender material"
				@current = existingluxmat
			end
			
			if (material_name != materials.current.name)
				materials.current = materials[material_name] if ( ! @current.nil?)
			end
			
			# reload existing material preview image
			puts "attempting to reload image"
			load_preview_image()
            puts @current.name
            settexturefields(@current.name)
		}
        
        def settexturefields(skpmatname) # shows and hides texture load buttons, based on material properties
            puts "updating texture fields"
            luxmat = getluxmatfromskpname(skpmatname)
            channels = luxmat.texturechannels
            #puts channels
            for channelname in channels
                textypename = channelname + "_texturetype" # for example "kd_texturetype"
                cmd = "$('#" + textypename + "').nextAll('span').hide();"
                @material_editor_dialog.execute_script(cmd)
                cmd = "$('#" + textypename + "').nextAll('div').hide();"
                @material_editor_dialog.execute_script(cmd)
                activetexturetype = luxmat.send(textypename)
                cmd = "$('#" + textypename + "').nextAll('." + activetexturetype + "').show()";
                #puts cmd
                @material_editor_dialog.execute_script(cmd)
                
                # set colorize checkboxes
                colorizename = channelname + "_imagemap_colorize" # for example kd_imagemap_colorize
                colorizeon = (@current.send(colorizename))? "true":"false"
                cmd = "$('." + colorizename + "\').attr('checked', " + colorizeon + ");"
                #puts cmd
                @material_editor_dialog.execute_script(cmd)
            end
        end
        
        
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
                when "specular_swatch"
                    puts "updating specular swatch"
                    @current.ks_R = rvalue
                    @current.ks_G = gvalue
                    @current.ks_B = bvalue
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
                when "cl1kd_swatch"
                    @current.cl1kd_R = rvalue
                    @current.cl1kd_G = gvalue
                    @current.cl1kd_B = bvalue
                when "cl1ks_swatch"
                    @current.cl1ks_R = rvalue
                    @current.cl1ks_G = gvalue
                    @current.cl1ks_B = bvalue
                when "cl2kd_swatch"
                    @current.cl2kd_R = rvalue
                    @current.cl2kd_G = gvalue
                    @current.cl2kd_B = bvalue
                when "cl2ks_swatch"
                    @current.cl2ks_R = rvalue
                    @current.cl2ks_G = gvalue
                    @current.cl2ks_B = bvalue     
            end
            updateSettingValue(@lrs.send(colorswatch)[0])
            updateSettingValue(@lrs.send(colorswatch)[1])
            updateSettingValue(@lrs.send(colorswatch)[2])
            update_swatches()
        }
        
		@material_editor_dialog.add_action_callback('start_refresh') { |dialog, param|
            SU2LUX.dbg_p "refresh called through javascript"
			refresh()
		}

		@material_editor_dialog.add_action_callback('active_mat_type') { |dialog, param| # shows the appropriate material editor panels for current material type
            SU2LUX.dbg_p ("callback: active_mat_type")
			@materialtype = @current.type
			javascriptcommand = "$('#type').nextAll('.' + '" + @materialtype + "').show();"
            SU2LUX.dbg_p javascriptcommand
			dialog.execute_script(javascriptcommand)
		}
		
		@material_editor_dialog.add_action_callback('type_changed') { |dialog, material_type|
            SU2LUX.dbg_p ("callback: type changed")
			print "current material: ", material_type, "\n"
            update_texture_names(@current)
            if (material_type=="mix") # check if mix materials have been set
                if (@current.material_list1 == '')
                    matname0 = Sketchup.active_model.materials[0].name.delete("[<>]")
                    puts "COMPARING NAMES:"
                    puts matname0
                    puts @current.name
                    if (@current.name != matname0)
                        @current.material_list1 = matname0
                        @current.material_list2 = matname0
                    else
                        @current.material_list1 = Sketchup.active_model.materials[1].name.delete("[<>]")
                        @current.material_list2 = Sketchup.active_model.materials[1].name.delete("[<>]")
                    end
                    cmd = "$('#material_list1 option').filter(function(){return ($(this).text() == '" + @current.material_list1 + "');}).attr('selected', true);"
                    @material_editor_dialog.execute_script(cmd)
                    cmd = "$('#material_list2 option').filter(function(){return ($(this).text() == '" + @current.material_list2 + "');}).attr('selected', true);"
                    @material_editor_dialog.execute_script(cmd)
                end
            end
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
			luxmat = getluxmatfromskpname(Sketchup.active_model.materials.current.name)
            # copy settings to be saved
            kdr, kdg, kdb = [luxmat.kd_R, luxmat.kd_G, luxmat.kd_B]
            mattype = luxmat.type
            textype = "none"
            #if (luxmat.has_texture?('kd'))
            if luxmat.respond_to?(:kd_texturetype)
                puts "TEXTURE"
                textype = luxmat.kd_texturetype
            else
                PUTS "NO TEXTURE"
            end
            # reset material
            luxmat.reset
            
            # paste settings to be saved
            luxmat.kd_R = kdr
            luxmat.kd_G = kdg
            luxmat.kd_B = kdb
            luxmat.type = mattype
            
            # use jquery to set dropdown to right texture type, after that, set texture_name
            puts "TEXTYPE: " + textype
            if textype == "sketchup"
                cmd = '$("#kd_texturetype").val(\'' + textype + '\')'
                luxmat.kd_texturetype = textype
                @material_editor_dialog.execute_script(cmd)
            end
            
            # refresh material editor
            refresh
		}
        
		@material_editor_dialog.add_action_callback("update_material_preview") {|dialog, params|
            puts ("callback: update_material_preview")
			
			# prepare file paths
			os = OSSpecific.new
            preview_path = os.get_variables["material_preview_path"]
            path_separator = os.get_variables["path_separator"]
		
            settingseditor = LuxrenderSettings.new
            previewtime = settingseditor.preview_time
            
            active_material = @materials_skp_lux.index(@current) ## was Sketchup.active_model.materials.current  
			active_material_name = active_material.name.delete("[<>]") # following LuxrenderMaterial.rb convention ## was Sketchup.active_model.materials.
			active_material_name_converted = sanitize_path(active_material_name)
            
			# generate preview lxm file and export bitmap images
			lxm_path = preview_path+active_material_name+".lxm"
			lxm_path_8859_1 = sanitize_path(lxm_path)
			base_file = preview_path + "ansi.txt"
			FileUtils.copy_file(base_file,lxm_path_8859_1)
			generated_lxm_file = File.new(lxm_path_8859_1,"a")
			
			texture_subfolder = "LuxRender_luxdata/textures"
			previewExport=LuxrenderExport.new(preview_path,path_separator) # preview path should define where preview files will be stored
            
            collect_mix_materials(@current) # check if the current material is a mix material; if so, recursively gather submaterials
            puts "collected materials:"
            puts @collectedmixmaterials
            for prmat in @collectedmixmaterials
                active_material = @materials_skp_lux.index(prmat)
                active_material_name = active_material.name.delete("[<>]") # following LuxrenderMaterial.rb convention
                active_material_name_converted = sanitize_path(active_material_name)
                previewExport.export_preview_material(preview_path,generated_lxm_file,active_material_name_converted,active_material,texture_subfolder,prmat)
            end
            @collectedmixmaterials = []
            @collectedmixmaterials_i = 0
            
			generated_lxm_file.close
			puts "finished texture output for material preview"
			
			# generate preview lxs file
			lxs_path = preview_path+Sketchup.active_model.title+"_"+active_material_name+".lxs"
			lxs_path_8859_1 = sanitize_path(lxs_path)
			
			base_file_2 = preview_path + "ansi.txt"
			FileUtils.copy_file(base_file_2,lxs_path_8859_1)
			generated_lxs_file = File.new(lxs_path_8859_1,"a")
            
			lxs_section_1 = File.readlines(preview_path+"preview.lxs01")
            lxs_section_2 = File.readlines(preview_path+"preview.lxs02")
            lxs_section_3 = File.readlines(preview_path+"preview.lxs03")
            generated_lxs_file.puts (lxs_section_1)
            
            generated_lxs_file.puts("\t\"integer xresolution\" [" + settingseditor.preview_size.to_s + "]")
            generated_lxs_file.puts("\t\"integer yresolution\" [" + settingseditor.preview_size.to_s + "]")
            generated_lxs_file.puts("\t\"integer halttime\" [" + settingseditor.preview_time.to_s + "]")
            generated_lxs_file.puts ("\t\"string filename\" \[\""+Sketchup.active_model.title+"_"+active_material_name_converted+"\"]")
            generated_lxs_file.puts ("")
            generated_lxs_file.puts ("WorldBegin")          
			generated_lxs_file.puts ("Include \""+active_material_name_converted+".lxm\"")
            generated_lxs_file.puts (lxs_section_2)
            previewExport.output_material (active_material, generated_lxs_file, @current, active_material.name) # writes "NamedMaterial #active_material_name.." or light definition
            generated_lxs_file.puts (lxs_section_3)
            previewExport.export_displacement_textures (active_material, generated_lxs_file, @current)
            generated_lxs_file.puts ("AttributeEnd")
            generated_lxs_file.puts ("WorldEnd")
			generated_lxs_file.close
            
			# start rendering preview using luxconsole
			@preview_lxs = preview_path+Sketchup.active_model.title+"_"+active_material_name_converted+".lxs"
			@filename = preview_path+Sketchup.active_model.title+"_"+active_material_name_converted+".png"
			luxconsole_path = SU2LUX.get_luxrender_console_path()
			@time_out = previewtime.to_f + 5
			@retry_interval = 0.5
			@luxconsole_options = " -x "
			pipe = IO.popen(luxconsole_path + @luxconsole_options + "\"" + @preview_lxs + "\"","r") # start rendering
            puts (luxconsole_path + @luxconsole_options + "\"" + @preview_lxs + "\"")
			
			# wait for rendering to get ready, then update image
			@times_waited = 0.0
			@d = UI.start_timer(previewtime.to_f+1, false){ 		# sets timer one second longer than rendering time
				file_exists = File.file? @filename
				while (!file_exists && (@times_waited < @time_out)) 	# if no image is found, wait for file to be rendered
					print("no image found, timing out in ", @time_out-@times_waited, " seconds\n")
					file_exists = File.file? @filename
					sleep 0.2
					@times_waited += 0.2
				end	
				while (file_exists && ((Time.now()-File.mtime(@filename)) > previewtime.to_f) && (@times_waited < @time_out))
					puts("old preview found, waiting for update...")				# if an old image is found, wait for update
					sleep 1
					@times_waited += 1
				end	
				if (@times_waited > (@time_out))						# if the waiting has surpassed the time out limit, give up
					puts("preview is taking too long, aborting")
					# UI.messagebox("The preview rendering process is taking longer than expected.")
				end
				if (@times_waited <= @time_out && (Time.now()-File.mtime(@filename)) < (previewtime.to_f+@time_out))
					puts("updating preview")
					# the file name on the following line includes ?timestamp, forcing the image to be refreshed as the link has changed
                    filename = @filename.gsub('\\', '\\\\\\\\')
                    filename.gsub!(/\#/, '	%23')
                    puts ('loading file ' + filename)
					cmd = 'document.getElementById("preview_image").src = "' + filename + '\?' + File.mtime(@filename).to_s + '"'
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
        
        @material_editor_dialog.add_action_callback("previewsize") {|dialog, params|
            puts "setting preview size to " + params
            @lrs.preview_size = params
            # update image size in interface
            setdivheightcmd = 'setpreviewheight(' + @lrs.preview_size + ')'
            #puts setdivheightcmd
            @material_editor_dialog.execute_script(setdivheightcmd)
        }
        
        @material_editor_dialog.add_action_callback("previewtime") {|dialog, params|
            puts "setting preview time to " + params
            @lrs.preview_time = params
            
        }
		
		@material_editor_dialog.add_action_callback("show_continued") {|dialog, params|
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
				@texture_editor_data[texture_type + '_' + par] = lux_material.send(prefix + par) if (lux_material.respond_to?(prefix+par))
			}
            
            @texture_editor = LuxrenderTextureEditor.new(@texture_editor_data, data)

            puts "sending data to texture editor:"
            puts @texture_editor_data
            puts data
            
			@texture_editor.show()
		}
	end # end initialize
    
    def collect_mix_materials(active_material)
        if (@collectedmixmaterials_i > 4) # 4 levels of recursion is considered maximum sensible amount
            puts "recursive mix material detected, aborting"
        elsif (active_material.type=="mix")
            @collectedmixmaterials_i = @collectedmixmaterials_i + 1
            submaterial1 = getluxmatfromskpname(active_material.material_list1)
            submaterial2 = getluxmatfromskpname(active_material.material_list2)
            collect_mix_materials(submaterial1)
            collect_mix_materials(submaterial2)
            @collectedmixmaterials << active_material
        else
            @collectedmixmaterials << active_material
        end
    end
    
    def getluxmatfromskpname(passedmatname)
        for mat in @materials_skp_lux.values
            if (mat.name == passedmatname)
                return mat
            elsif (mat.original_name == passedmatname)
                return mat
            end
        end
        return nil
    end
	
	def load_preview_image()
		puts "running load_preview_image function"			
		os = OSSpecific.new
		filename = os.get_variables["material_preview_path"] + Sketchup.active_model.title + "_" + @current.name.delete("[<>]") + ".png"
		filename = filename.gsub('\\', '/')
		if (File.exists?(filename))
			puts "preview image exists, loading " + filename
            filename.gsub!(/\#/, '	%23')
            cmd = 'document.getElementById("preview_image").src = "' + filename + '"'
		else
			puts "file doesn't exist, showing default image"
			cmd = 'document.getElementById("preview_image").src = "empty_preview.png"'
		end
		@material_editor_dialog.execute_script(cmd)
	end
	
    def showhideIOR()
        if @current.use_architectural == false
            cmd = '$("#IOR_interface").show()'
        else
            cmd = '$("#IOR_interface").hide()'
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
        if (getluxmatfromskpname(name))
            return getluxmatfromskpname(name)
        elsif (mat)
            @numberofluxmaterials += 1
            newluxmat = LuxrenderMaterial.new(mat)
            @materials_skp_lux[mat] = newluxmat
            return newluxmat
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
        #UI.messagebox (Sketchup.active_model.materials.length)
		materials = Sketchup.active_model.materials
        
		## check if LuxRender materials exist, if not, create them
		for mat in materials
			if !@materials_skp_lux.include?(mat) # test if LuxRender material has been created, if not, create one
				#UI.messagebox(mat)
                luxmat = find(mat.name) # creates LuxRender material
				puts "adding material #{mat.name} to material hash, creating LuxRender material"
                @materials_skp_lux[mat]=luxmat
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
		set_material_lists
		sendDataFromSketchup()
		load_preview_image		
		set_current(@current.name)
        update_texture_names(@current)
        puts "RUNNING REFRESH, ABOUT TO RUN settexturefields FOR MATERIAL " + @current.name
        settexturefields(@current.name)
        
        # set preview section height
        setdivheightcmd = 'setpreviewheight(' + @lrs.preview_size.to_s + ',' + @lrs.preview_time.to_s + ')'
        puts setdivheightcmd
        @material_editor_dialog.execute_script(setdivheightcmd)
        
	end
    
    ##
    #
    ##
    
    def update_texture_names(luxmat)
        for textype in luxmat.texturechannels
            update_texture_name(luxmat,textype)
        end
    end
    
    def update_texture_name(luxmat, textype)
        filepath = File.basename(luxmat.send(textype+'_imagemap_filename'))
        cmd = 'show_load_buttons(\'' + textype + '\',\'' + filepath + '\')'
        #puts cmd
        @material_editor_dialog.execute_script(cmd)
    end
    
    
    ##
    #
    ##
    def set_material_lists()
        set_material_list("material_name")  # main material list
        set_material_list("material_list1") # mix material 1
        set_material_list("material_list2") # mix material 2
    end
    
	
	##
	#
	##
	def set_current(passedname)
		SU2LUX.dbg_p "call to set_current: #{passedname}"
        if (@current) # prevent update_swatches function from running before a luxmaterial has been created
            update_swatches()
        end
        passedname = passedname.delete("[<>]")
        # show right material in material editor dropdown menu
        puts "setting active material in SU2LUX material editor dropdown"
        cmd = "$('#material_name option').filter(function(){return ($(this).text() == \"#{passedname}\");}).attr('selected', true);"
        #puts cmd
		@material_editor_dialog.execute_script(cmd)
	end
	
    ##
	#
	##
	def set_material_list(dropdownname)
        puts "updating material dropdown list in LuxRender Material Editor, " + dropdownname
		cmd = "$('#" + dropdownname + "').empty()"
		@material_editor_dialog.execute_script(cmd)
		cmd = "$('#" + dropdownname +"').append( $('"
		# puts "material list command: ", cmd
		materials = Sketchup.active_model.materials.sort
        #puts "whole material list (@materials_skp_lux):"
        #puts @materials_skp_lux
		for mat in materials
            #puts "set_material_list running"
            #puts mat.name
			luxrender_mat = @materials_skp_lux[mat]
            #puts luxrender_mat
			# puts "adding luxrender material to material list: ", luxrender_mat
			cmd = cmd + "<option value=\"#{luxrender_mat.original_name}\">#{luxrender_mat.name}</option>"
		end
		cmd = cmd + "'));"
		@material_editor_dialog.execute_script(cmd)
	end
    
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
	def is_a_checkbox?(id) #much better to use objects for settings?!
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
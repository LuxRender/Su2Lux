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
# Authors      : Abel Groenewolt

class LuxrenderProceduralTexturesEditor

	attr_reader :procedural_textures_dialog, :activeProcTex
	##
	#
	##
	def initialize(matEditor, lrs)
		@textureDictionary = LuxrenderAttributeDictionary.new(Sketchup.active_model)
		@textureCollection = {} # hash containing texture names and objects
        puts "initializing procedural textures editor"
        filename = File.basename(Sketchup.active_model.path)
		@activeProcTex = nil
        if (filename == "")
            windowname = "LuxRender Procedural Textures Editor"
        else
            windowname = "LuxRender Procedural Textures - " + filename
        end
		
		@procedural_textures_dialog = UI::WebDialog.new(windowname, true, "LuxrenderProceduralTexturesEditor", 450, 600, 10, 10, true)
        @procedural_textures_dialog.max_width = 700
		setting_html_path = Sketchup.find_support_file("procedural_textures_dialog.html" , "Plugins/"+SU2LUX::PLUGIN_FOLDER)
		@procedural_textures_dialog.set_file(setting_html_path)
        @lrs = lrs
		@material_editor = matEditor
		
		#puts "material editor (created or found):"
		#puts @material_editor
		
        puts "finished initializing procedural textures editor"
       
	   # callbacks for javascript functions
	   
	   ##
	   #	create a new procedural texture
	   ##
	   	@procedural_textures_dialog.add_action_callback("create_procedural_texture") { |dialog, texType|
			puts "creating procedural texture"
			puts texType
			
			# todo: query for texture name
			generatedName = ""
			nameFree = false
			texNumber = 0
			while(nameFree == false)
				texNumber += 1
				generatedName = "procTex_" + texNumber.to_s
				if(@textureCollection[generatedName] == nil)
					nameFree = true
				end
			end
			
			texName = UI.inputbox(["volume name"], [generatedName], "Enter new volume name")
			if(texName != false)		
				# create volume object, or warn user of duplicate name
				texName = texName[0]
				if(@textureCollection[texName] == nil)
					puts "creating texture with name " + texName

					newTexture = LuxrenderProceduralTexture.new(true, self, @lrs, texType, texName)
					
					# call javascript function that adds new name to texture list and sets that name in dropdown
					@procedural_textures_dialog.execute_script('addToTextureList("' + texName + '")')
					
					# add this to all dropdown dialogs in the material editor
					channel = newTexture.getChannelType()
					@material_editor.material_editor_dialog.execute_script('addToProcTextList("' + texName + '","' + channel + '")')
					
					# update channel list in procedural texture editor (color, float, fresnel)
					updateChannelList(texType)
					
					# show parameters in interface
					puts "updating interface"
					@procedural_textures_dialog.execute_script("$('#textypedropdownarea').show()")
					@procedural_textures_dialog.execute_script("$('#texturechanneldropdownarea').show()")
					@procedural_textures_dialog.execute_script("$('#texture_types').val('" + texType + "')")
					
										
					@procedural_textures_dialog.execute_script("$('.parameter_container').hide()")
					showTexParams = "$(\".#{texType}\").show()"
					@procedural_textures_dialog.execute_script(showTexParams)
					
					# update parameters
					updateParams(texName,texType)
				else
					UI.messagebox("Texture name exists already, please choose a different name")
				end
			end		
		}
		
		##
		#	display active texture parameters
		##
		@procedural_textures_dialog.add_action_callback('show_procedural_texture') {|dialog, texName|
			puts "callback: show_procedural_texture"
			
			# get texture library, get texture type
			#activeTextureLib = @textureDictionary.returnDictionary(texName)
			#texType = activeTextureLib["textureType"]
			
			# set active texture
			@activeProcTex = @textureCollection[texName]
			texType = @activeProcTex.getTexType()
			
			# update texture type dropdown
			puts "setting texture type dropdown"
			updateChannelList(texType)			
			@procedural_textures_dialog.execute_script('$("#texture_types").val("' + texType + '")')
			
			# show relevant parameter section in html
			hideFields = "$('.parameter_container').hide()";
			@procedural_textures_dialog.execute_script(hideFields)
			showField =	"$(\".#{texType}\").show()"
			puts showField
			@procedural_textures_dialog.execute_script(showField)
						
			# update parameters for relevant texture type
			puts "setting parameters"
			updateParams(texName, texType)	
			
			# update channel type dropdown items
			updateChannelList(texType)
			
			# set active channel type
			puts "setting channel type dropdown"
			channelType = @activeProcTex.getChannelType()	
			@procedural_textures_dialog.execute_script('$("#procTexChannel").val("' + channelType + '")') 
		}
		
		##
		#	pass on changed parameter from interface to dictionary
		##
		@procedural_textures_dialog.add_action_callback('set_param') {|dialog, paramString|
            SU2LUX.dbg_p "callback: set_param"
			puts paramString # noisesize|0.4
			puts paramString
			
			params = paramString.split('|')
			@activeProcTex.setValue(params[0],params[1])
			
			# remove and add texture in material editor dropdowns if type changes from float to color or vice versa
			if(params[0] == "procTexChannel")
				@material_editor.material_editor_dialog.execute_script('removeFromProcTextList("' + @activeProcTex.name + '")')
				@material_editor.material_editor_dialog.execute_script('addToProcTextList("' + @activeProcTex.name + '","' + params[0] + '")')
			end
		}
		
		##
		#	update texture type: update texture type in dictionary and get values from dictionary
		##
		@procedural_textures_dialog.add_action_callback('update_texType') {|dialog, paramString|
            SU2LUX.dbg_p "callback: update_texType"
			
			puts paramString # procTex_9|textureTypeName|cloud|float
			
			params = paramString.split('|')
			texObject = @textureCollection[params[0]]
			puts "texObject is " + texObject.to_s
			
			# store texture type in material
			puts "storing material type: " + params[2]
			texObject.setValue("textureType",params[2])
			puts "getTexType " + texObject.getTexType()
			
			# show texture type _dropdown, _channel type dropdown, texture name bar + contents
			@procedural_textures_dialog.execute_script('displayTextureInterface("' + params[2] + '")')
			
			# store channel type and update channel list
			puts "storing channel type"
			setChannel = texObject.setTexChannel()
			updateChannelList(params[2])
			
			# update parameters in procedural texture interface
			puts "updating parameters in interface"
			updateParams(params[0],params[2])
			
			# remove and add texture in material editor dropdowns
			@material_editor.material_editor_dialog.execute_script('removeFromProcTextList("' + params[0] + '")')
			@material_editor.material_editor_dialog.execute_script('addToProcTextList("' + params[0] + '","' + setChannel + '")')
		}
		
		@procedural_textures_dialog.add_action_callback('show_texData') {|dialog, paramString|
			puts "procedural texture interface loaded, call received by ruby"
			
			# add all procedural textures to list
			puts "adding textures to texture dropdown list"
			for texName in @lrs.proceduralTextureNames
				@procedural_textures_dialog.execute_script('addToTextureList("' + texName + '")')
			end
			
			puts "getting texture"
			# get procedural texture object to display: 
			if (@lrs.proceduralTextureNames.count > 0)
				activeTexture = @textureDictionary.returnDictionary(@activeProcTex.name)
				activeTexType = activeTexture["textureType"]
				
				puts "activeTexture has textureType " + activeTexType

				# set texture name dropdown
				cmd1 = 'setTextureNameDropdown("' + @activeProcTex.name + '")'
				@procedural_textures_dialog.execute_script(cmd1)	
				
				# show right texture parameter section
				cmd2 = 'displayTextureInterface("' + activeTexType + '")'
				@procedural_textures_dialog.execute_script(cmd2)
				
				# add channel types to list
				updateChannelList(activeTexType)				
				
				# select right channel type (float, color)
				channelType = activeTexture["procTexChannel"]
				@procedural_textures_dialog.execute_script('$("#procTexChannel").val("' + channelType + '")') 
			
				# set parameters 
				updateParams(@activeProcTex.name, activeTexType)
	
			end
					
		}
    
	end # END initialize

	def updateGUI()
		puts "updating procedural texture interface"
		puts @activeProcTex.name
		puts @activeProcTex.getTexType()
		puts @activeProcTex.getChannelType()
	
		# set active texture in texture list
		@procedural_textures_dialog.execute_script("$('#textures_in_model').val('" + @activeProcTex.name + "')")
		
		# set texture type 
		texType = @activeProcTex.getTexType()
		@procedural_textures_dialog.execute_script("$('#texture_types').val('" + texType + "')")
		
		# set channels
		channelType = @activeProcTex.getChannelType()
		@procedural_textures_dialog.execute_script('$("#procTexChannel").val("' + channelType + '")') 
		
		# show parameters
		@procedural_textures_dialog.execute_script('displayTextureInterface("' + texType + '")')
		
		# load parameters?
		updateParams(@activeProcTex.name, texType)
	end
	
	
	##
	#	update channel list in interface (float, color, fresnel)
	##
	
	def updateChannelList(texType)
		# remove all items from dropdown
		@procedural_textures_dialog.execute_script('$("#procTexChannel").empty()');
		# get available channel types for new type
		availableChannels = LuxrenderProceduralTexture.getTexChannels(texType)
		# add these channel types
		availableChannels.each do |channelName|
			cmd = '$("#procTexChannel").append( $("<option></option>").val("' + channelName + '").html("' + channelName + '"))'
			@procedural_textures_dialog.execute_script(cmd)
		end
	end
	
	##
	#	update parameters in interface
	##
	
	def updateParams(texName,texType)
		# get values for ordinary parameters
		textureObject = @textureCollection[texName]
		varValues = textureObject.getValues()
		puts "updateParams: ordinary parameters"
		varValues.each do |varList|
			# update parameter in interface using jQuery command
			divId = varList[0]
			cmd = '$("#' + divId + '").val("' + varList[2].to_s + '")'
			puts cmd
			@procedural_textures_dialog.execute_script(cmd)
		end
		# get values for transformation parameters
		puts "updateParams: transformation parameters"
		transValues = textureObject.getTranformationValues()
		transValues.each do |varList|
			cmd = '$("#' + varList[0] + '").val("' + varList[1].to_s + '")'
			puts cmd
			@procedural_textures_dialog.execute_script(cmd)
		end
		
	end
	
	def getTextureDictionary()
		return @textureDictionary
	end
		
	def getTextureCollection()
		return @textureCollection
	end
	
	def getTextureObject(objectName)
		return @textureCollection[objectName]
	end
	
	def showProcTexDialog
		@procedural_textures_dialog.show{} # note: code inserted in the show block will run when the dialog is initialized
		puts "number of textures in model: " + @lrs.proceduralTextureNames.count.to_s
		# note: interface should be updated by code that is called when the procedural texture editor is loaded
	end
	
	def addTexture(name, texObject)
		@textureCollection[name] = texObject
	end
	
	def setActiveTexture(passedProcTex)
		@activeProcTex = passedProcTex
	end

	def close
		@procedural_textures_dialog.close
	end #END close
	
	def visible?
		return @procedural_textures_dialog.visible?
	end #END visible?
	

	
end # # END class LuxrenderSceneSettingsEditor
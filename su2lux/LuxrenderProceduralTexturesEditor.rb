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

	attr_reader :procedural_textures_dialog
	##
	#
	##
	def initialize
		@textureDictionary = LuxrenderAttributeDictionary.new(Sketchup.active_model)
		@textureCollection = {} # hash containing texture names and objects
        puts "initializing procedural textures editor"
        @scene_id = Sketchup.active_model.definitions.entityID
        filename = File.basename(Sketchup.active_model.path)
        if (filename == "")
            windowname = "LuxRender Procedural Textures Editor"
        else
            windowname = "LuxRender Procedural Textures - " + filename
        end
		
		@procedural_textures_dialog = UI::WebDialog.new(windowname, true, "LuxrenderProceduralTexturesEditor", 450, 600, 10, 10, true)
        @procedural_textures_dialog.max_width = 700
		setting_html_path = Sketchup.find_support_file("procedural_textures_dialog.html" , "Plugins/"+SU2LUX::PLUGIN_FOLDER)
		@procedural_textures_dialog.set_file(setting_html_path)
        @lrs=SU2LUX.get_lrs(@scene_id)
		@scene_id = Sketchup.active_model.definitions.entityID
		@material_editor = SU2LUX.get_editor(@scene_id,"material")
		
        puts "finished initializing procedural textures editor"
       
	   # callbacks for javascript functions
	   
	   ##
	   #	create a new procedural texture
	   ##
	   	@procedural_textures_dialog.add_action_callback("create_procedural_texture") { |dialog, texType|
			puts "creating procedural texture"
			newTexture = LuxrenderProceduralTexture.new(true, texType)
			texName = newTexture.name
			# call javascript function that adds new name to texture list and sets that name in dropdown
			@procedural_textures_dialog.execute_script('addToTextureList("' + texName + '")')
			# also add add this to all dropdown dialogs in the material editor
			channel = LuxrenderProceduralTexture.getChannelType(texName)
			@material_editor.material_editor_dialog.execute_script('addToProcTextList("' + texName + '","' + channel + '")')
			# update channel list
			updateChannelList(texType)
			# update parameters
			updateParams(texName,texType)
			
		}
		
		##
		#	display active texture parameters
		##
		@procedural_textures_dialog.add_action_callback('show_procedural_texture') {|dialog, texName|
			puts "callback: show_procedural_texture"
			
			# update texture type dropdown
			puts "setting texture type dropdown"
			
			# get texture object, get texture type
			activeTexture = @textureDictionary.returnDictionary(texName)
			texType = activeTexture["textureType"]
			
			# update texture channel list
			updateChannelList(texType)			
			@procedural_textures_dialog.execute_script('$("#texture_types").val("' + texType + '")')
			
			# show relevant parameter section in html
			hideFields = "$('.texfield').hide()";
			@procedural_textures_dialog.execute_script(hideFields)
			showField =	"$(\"##{texType}\").show()"
			@procedural_textures_dialog.execute_script(showField)
			
			# update parameters for relevant texture type
			puts "setting parameters"
			updateParams(texName, texType)	
			
			# update channel type dropdown items
			updateChannelList(texType)
						
			# set active channel type
			puts "setting channel type dropdown"
			channelType = activeTexture["procTexChannel"]			
			@procedural_textures_dialog.execute_script('$("#procTexChannel").val("' + channelType + '")') 
		}
		
		##
		#	pass on changed parameter from interface to dictionary
		##
		@procedural_textures_dialog.add_action_callback('set_param') {|dialog, paramString|
            SU2LUX.dbg_p "callback: set_param"
			puts paramString # procMat_0|brick_procTexChannel|float
			params = paramString.split('|')
			paramNameList = params[1].split('_')
			# removed #textype_ prefix
			if paramNameList.size > 3
				paramName = paramNameList[2] + '_' + paramNameList[3] # deal with blender_voronoi_minkowsky_exp
			else
				paramName = paramNameList.last
			end
			LuxrenderProceduralTexture.setParameter(params[0],paramName,params[2])
			
			# remove and add texture in material editor dropdowns
			if(paramName == "procTexChannel")
				@material_editor.material_editor_dialog.execute_script('removeFromProcTextList("' + params[0] + '")')
				@material_editor.material_editor_dialog.execute_script('addToProcTextList("' + params[0] + '","' + params[2] + '")')
			end
		}
		
		##
		#	update texture type: update texture type in dictionary and get values from dictionary
		##
		@procedural_textures_dialog.add_action_callback('update_texType') {|dialog, paramString|
            SU2LUX.dbg_p "callback: update_texType"
			puts paramString # procMat_9|textureTypeName|cloud|float
			params = paramString.split('|')
			
			# store texture type in material
			puts "storing material type"
			LuxrenderProceduralTexture.setParameter(params[0],params[1],params[2])
			
			# show texture type _dropdown, _channel type dropdown, texture name bar + contents
			puts "showing stuff in interface"
			@procedural_textures_dialog.execute_script('displayTextureInterface("' + params[2] + '")')
			
			# update parameters in procedural texture interface
			puts "updating parameters in interface"
			updateParams(params[0],params[2])
						
			# store channel type and update channel list
			puts "storing channel type"
			setChannel = LuxrenderProceduralTexture.setTexChannel(params[0])
			updateChannelList(params[2])
			
			# remove and add texture in material editor dropdowns
			@material_editor.material_editor_dialog.execute_script('removeFromProcTextList("' + params[0] + '")')
			@material_editor.material_editor_dialog.execute_script('addToProcTextList("' + params[0] + '","' + setChannel + '")')
		}
		
		@procedural_textures_dialog.add_action_callback('show_texData') {|dialog, paramString|
			puts "procedural texture interface loaded, call received by ruby"
			
			# add all procedural textures to list # note: this code may not be functional
			puts "adding textures to texture dropdown list"
			for i in 0..@lrs.nrProceduralTextures-1
				texName = "procMat_" + i.to_s
				cmd = 'addToTextureList("' + texName + '")'
				@procedural_textures_dialog.execute_script(cmd)
			end
			
			puts "getting texture"
			# get procedural texture object to display: 
			if (@lrs.nrProceduralTextures > 0)
				activeTexture = @textureDictionary.returnDictionary("procMat_0")
				
				#activeTexType = LuxrenderProceduralTexture.getParamValue(activeTexture.name, "textureType")
				activeTexType = activeTexture["textureType"]
				
				puts "activeTexture has textureType " + activeTexType

				# set texture name dropdown
				cmd1 = 'setTextureNameDropdown("procMat_0")'
				@procedural_textures_dialog.execute_script(cmd1)	
				
				# show right texture parameter section
				cmd2 = 'displayTextureInterface("' + activeTexType + '")'
				@procedural_textures_dialog.execute_script(cmd2)
				
				# add channel types to list
				updateChannelList(activeTexType)
				
				# select right channel type
				channelType = activeTexture["procTexChannel"]
				@procedural_textures_dialog.execute_script('$("#procTexChannel").val("' + channelType + '")') 
			
				# set parameters 
				updateParams("procMat_0", activeTexType)
	
			end
					
		}
    
	end # END initialize

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
		# get values for all parameters
		# todo: get texture object
		textureObject = @textureCollection[texName]
		varValues = textureObject.getValues()
		varValues.each do |varList|
			# update parameter in interface using jQuery command
			divId = texType + "_" + varList[0]
			cmd = '$("#' + divId + '").val("' + varList[2].to_s + '")'
			puts cmd
			@procedural_textures_dialog.execute_script(cmd)
		end
	end
	
	def getTextureDictionary()
		return @textureDictionary
	end
	
 	##
	#
	##
	def showProcTexDialog
		@procedural_textures_dialog.show{} # note: code inserted in the show block will run when the dialog is initialized
		puts "number of textures in model: " + @lrs.nrProceduralTextures.to_s
		# note: interface will be updated by code that is called when the procedural texture editor is loaded
	end
	
	def addTexture(name, texObject)
		@textureCollection[name] = texObject
	end

	def close
		@procedural_textures_dialog.close
	end #END close
	
	def visible?
		return @procedural_textures_dialog.visible?
	end #END visible?
	

	
end # # END class LuxrenderSceneSettingsEditor
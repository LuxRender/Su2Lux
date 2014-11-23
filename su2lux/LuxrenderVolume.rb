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
# This file is part of SU2LUX.
#
# Author:      Abel Groenewolt (aka pistepilvi)

class LuxrenderVolume

	attr_reader :name
	
	@@volumeParamDicts =
	{
		# texture types, data format: [texture parameter name, parameter type, default value]
		'clear' => {"volumeType"=>["string","clear"],"fresnel"=>["float",1.0],"vol_absorption_swatch"=>["color",[0.01,0.01,0.01]],"absorption_scale"=>["float",1.0]},
		'homogeneous' => {"volumeType"=>["string","homogeneous"],"fresnel"=>["float",1.0],"vol_absorption_swatch"=>["color",[0.0,0.0,0.0]],"absorption_scale"=>["float",1.0],"vol_scattering_swatch"=>["color",[0.0,0.0,0.0]],"scattering_scale"=>["float",1.0],"g"=>["float",[0.0,0.0,0.0]]},
		'heterogeneous' => {"volumeType"=>["string","heterogeneous"],"fresnel"=>["float",1.0],"vol_absorption_swatch"=>["color",[0.0,0.0,0.0]],"absorption_scale"=>["float",1.0],"vol_scattering_swatch"=>["color",[0.0,0.0,0.0]],"scattering_scale"=>["float",1.0],"g"=>["float",[0.0,0.0,0.0]],"stepsize"=>["float",1.0]}		
	}
		
	def initialize(createNew, passedName, passedParameter = "") # passedParameter is volume type: clear, homogeneous, heterogeneous
	
		# get texture editor and procedural texture editor
        @scene_id = Sketchup.active_model.definitions.entityID
		@lrs = SU2LUX.get_lrs(@scene_id)
		@volumeEditor = SU2LUX.get_editor(@scene_id,"volume")
		@materialEditor = SU2LUX.get_editor(@scene_id,"material")
		
		# store name, create attribute dictionary to store parameters in
		@name = passedName
		@attributeDictionary = @volumeEditor.getVolumeDictionary()
		
		if createNew == true # create new object from scratch
			if (passedParameter != "")
				@volumeType = passedParam
			else
				@volumeType = "clear"
			end

			# todo: check if name exists; if so, either modify it or abort
			
			# add texture to volume editor and @lrs (the latter in order to be able to reconstruct volumes when opening a file)
			@volumeEditor.addVolume(passedName, self) # add texture to collection in current texture editor
			volumeNameList = @lrs.volumeNames
			volumeNameList << @name
			@lrs.volumeNames = volumeNameList # was = [@name]

			# write name and volume type name to attribute dictionary #
			@attributeDictionary.set_attribute(@name, "volumeType", @volumeType)
			@attributeDictionary.set_attribute(@name, "name", @name)
		
		else # create object based on existing data in attribute dictionary
			@volumeEditor.addVolume(passedName, self) # add texture to collection in current texture editor
			puts "getting dictionary object"
			@attributeDictionary.load_from_model(@name)
			@volumeType = @attributeDictionary.get_attribute(@name, "volumeType")
		end
		dropdown_add_interior = "$('#volume_interior').append( $('<option></option>').val('" + @name + "').html('" + @name + "'))"
		dropdown_add_exterior = "$('#volume_exterior').append( $('<option></option>').val('" + @name + "').html('" + @name + "'))"
		@materialEditor.material_editor_dialog.execute_script(dropdown_add_interior)
		@materialEditor.material_editor_dialog.execute_script(dropdown_add_exterior)
	end
	
	##
	#	class methods
	##

		
	def self.getVolumeType(texName)
		thisDict = LuxrenderAttributeDictionary.returnDictionary(texName)
		thisTexName = thisDict["volumeType"]
		return thisTexName
	end
	
	##
	#	instance methods
	##

	def setValue(property, value)
		@attributeDictionary.set_attribute(@name, property, value)
	end
	
	def getValue(property)
		texType = @attributeDictionary.get_attribute(@name, "volumeType")
		return @attributeDictionary.get_attribute(@name, property, @@volumeParamDicts[texType][property][1]) # returns default value if no value is found in this object's dictionary
	end
	
	def getValueHash()
		passedVariableLists = Hash.new
		texType = @attributeDictionary.get_attribute(@name, "volumeType")
		@@volumeParamDicts[texType].each do |key, value|
			# get value from dictionary, or use default value if no value has been stored
			varValue = @attributeDictionary.get_attribute(@name, key, value[1])
			passedVariableLists[key] = [value[0], varValue]
		end
		return passedVariableLists
	end
	
	def getFormattedValues()
		unformattedValues = getValues()
		formattedValuesHash = Hash.new
		unformattedValues.each do |paramSet|
		# deal with vector parameters
			formattedString = ""
			texParamName = paramSet[0]
			if (texParamName[0..6] == "vector_")
				texParamName.slice! "vector_"
			end
			typeString = paramSet[1].to_s + " " + texParamName
			# deal with square brackets: if first character is '[', remove first and last character and replace ', ' with ' '
			if paramSet[2].to_s[0] == '['
				paramSet[2] = paramSet[2].to_s
				paramSet[2] = paramSet[2][1, paramSet[2].length - 2]
				paramSet[2] = paramSet[2].gsub!(', ' , ' ')
			end

			# add formatted strings to array
			if (paramSet[1] == "string" || paramSet[1] == "bool")
				formattedString = typeString +  " \"" + paramSet[2].to_s + "\""
			else
				formattedString = typeString + " " + paramSet[2].to_s
			end
			formattedValuesHash[paramSet[0]] = formattedString
			
		end
		puts "returning values in hash:"
		puts formattedValuesHash
		return formattedValuesHash
	end
	
end
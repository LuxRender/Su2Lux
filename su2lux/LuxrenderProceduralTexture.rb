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

class LuxrenderProceduralTexture

	attr_reader :name
	
	@@textureTypes = 
	{
		"add" => ["color","float"],
		"band" => ["color","float","fresnel"],
		"bilerp" => ["color","float","fresnel"],
		"blackbody" => ["color"],
		"brick" => ["color","float"],
		#"cauchy" => ["fresnel"],
		"checkerboard" => ["float"],
		"cloud" => ["float"],
		"colordepth" => ["color"],
		#"constant" => ["float","color","fresnel"],
		"dots" => ["float"],
		#"equalenergy" => ["color"],
		"fbm" => ["float"],
		"fresnelcolor" => ["fresnel"],
		"fresnelname" => ["fresnel"],
		"gaussian" => ["color"],
		"harlequin" => ["color"],
		#"lampspectrum" => ["color"],
		"marble" => ["color"],
		"mix" => ["float","color","fresnel"],
		#"multimix" => ["float","color","fresnel"],
		"normalmap" => ["float"],
		"scale" => ["float","color","fresnel"],
		#"sellmeier" => ["fresnel"],
		"subtract" => ["float","color"],
		"tabulateddata" => ["color"],
		"uv" => ["color"],
		#"uvmask" => ["float"],
		"windy" => ["float"],
		"wrinkled" => ["float"],
		#"blender_blend" => ["float"],
		"blender_clouds" => ["float"],
		"blender_distortednoise" => ["float"],
		"blender_noise" => ["float"],
		"blender_magic" => ["float"],
		"blender_marble" => ["float"],
		"blender_musgrave" => ["float"],
		"blender_stucci" => ["float"],
		"blender_wood" => ["float"],
		"blender_voronoi" => ["float"]
	}  
	
	@@textureParameters =
	{
		# texture types, data format: [texture parameter name, parameter type, default value]
		'add' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["tex1","color",[1.0,1.0,1.0]],["tex2","color",[1.0,1.0,1.0]]],
		'band' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["tex1","color",[1.0,1.0,1.0]],["tex2","color",[0.0,0.0,0.0]],["tex3","color",[1.0,1.0,1.0]],["tex4","color",[0.0,0.0,0.0]],["tex5","color",[1.0,1.0,1.0]],["tex6","color",[0.0,0.0,0.0]],["tex7","color",[1.0,1.0,1.0]],["tex8","color",[0.0,0.0,0.0]],["offsets","arrayf",""],["amount","texf",""]],
		'bilerp' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["v00","color",[0.8,0.8,0.8]],["v01","color",[0.0,0.0,0.0]],["v10","color",[0.8,0.8,0.8]],["v11","color",[0.0,0.0,0.0]]],
		'blackbody' =>  [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["temperature","float",6500.0]],
		'brick' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["brickwidth","float",0.3],
		["brickheight","float",0.1],["brickdepth","float",0.15],["mortarsize","float",0.01],["brickbevel","float",0.0],["brickrun","float",0.75],["brickbond","string","stacked"],["bricktex","color",[0.4,0.2,0.2]],["mortartex","color",[0.2,0.2,0.2]],["brickmodtex","float",1.0]],
		'checkerboard' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["dimension","integer",2],["aamode","string","none"],["tex1","float",1.0],["tex2","float",0.0]],
		'cloud' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["radius","float",0.5],["noisescale","float",0.5],["turbulence","float",0.01],["sharpness","float",6.0],["noiseoffset","float",0.0],["omega","float",0.75],["variability","float",0.9],["baseflatness","float",0.8],["spheresize","float",0.15],["spheres","integer",0],["octaves","integer",1]],
		'colordepth' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["depth","float",1.0],["Kt","color",[0.0,0.0,0.0]]],
		'densitygrid' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["density","floats",""],["nx","integer",1],["ny","integer",1],["nz","integer",1],["wrap","string","repeat"]],
		'dots' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["inside","color",[1.0,1.0,1.0]],["outside","color",[0.0,0.0,0.0]]],
		'exponential' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["origin","point",[0.0,0.0,0.0]],["updir","vector",[0.0,0.0,1.0]],["decay","float",1.0]],
		'fbm' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["roughness","float",0.8],["octaves","integer",8]],
		'fresnelname' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["filename","string",""],["name","string","aluminium"]],
		'fresnelcolor' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["Kr","color",[0.5,0.5,0.5]]],
		'gaussian' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["energy","float",1.0],["wavelength","float",550.0],["width","float",50.0]],
		'harlequin' => [],
		'imagemap' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["filename","string",""],["wrap","string",""],["filtertype","string","bilinear"],["maxanisotropy","float",8.0],["trilinear","boolean",false],["channel","string","mean"],["gamma","float",2.2],["gain","float",1.0]],
		'marble' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["octaves","integer",8],["roughness","float",0.5],["scale","float",1.0],["variation","float",0.2]],
		'mix' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["tex1","color",[0.0,0.0,0.0]],["tex2","color",[1.0,1.0,1.0]],["scale","float",1.0],["variation","float",0.2]],
		'normalmap' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["filename","string",""],["wrap","string",""],["filtertype","string","bilinear"],["maxanisotropy","float",8.0],["trilinear","boolean",false],["channel","string","mean"],["gamma","float",1.0],["gain","float",1.0]],
		'scale' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["value","color",[1.0,1.0,1.0]],["tex1","color",[1.0,1.0,1.0]],["tex2","color",[1.0,1.0,1.0]]],
		'subtract' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["tex1","color",[1.0,1.0,1.0]],["tex2","color",[1.0,1.0,1.0]]],
		'tabulateddata' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["filename","string",""]],
		'windy' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],],
		'wrinkled' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["octaves","integer",8],["roughness","float",0.5]],
		'blender_clouds' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["noisetype","string","soft_noise"],["noisebasis","string","blender_original"],["noisesize","float",0.25],["noisedepth","integer",2],["bright","float",1.0],["contrast","float",1.0]],
		'blender_distortednoise' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["type","string","blender_original"],["noisebasis","string","blender_original"],["noisesize","float",0.25],["distamount","float",1.0],["noisedepth","integer",2],["bright","float",1.0],["contrast","float",1.0]],
		'blender_noise' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"]],
		'blender_magic' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"]],
		'blender_marble' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["noisesize","float",0.25],["noisedepth","integer",2],["turbulence","float",5.0],["type","string","soft"],["noisetype","string","hard_noise"],["noisebasis","string","sin"],["noisebasis2","string","blender_original"],["bright","float",1.0],["contrast","float",1.0]],
		'blender_musgrave' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["h","float",1.0],["lacu","float",2.0],["octs","float",2.0],["gain","float",1.0],["offset","float",1.0],["noisesize","float",0.25],["outscale","float",1.0],["type","string","multifractal"],["noisebasis","string","blender_original"],["bright","float",1.0],["contrast","float",1.0]],
		'blender_stucci' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["type","string","plastic"],["noisetype","string","soft_noise"],["noisebasis","string","blender_original"],["turbulence","float",5.0],["bright","float",1.0],["contrast","float",1.0]],
		'blender_wood' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["type","string","bands"],["noisetype","string","soft_noise"],["noisebasis","string","blender_original"],["noisebasis2","string","sin"],["noisesize","float",0.25],["turbulence","float",5.0],["bright","float",1.0],["contrast","float",1.0]],
		'blender_voronoi' => [["vectortranslate","vector",[0.0,0.0,0.0]],["vectorrotate","vector",[0.0,0.0,0.0]],["vectorscale","vector",[1.0,1.0,1.0]],["coordinates","string","global"],["distmetric","string","actual_distance"],["minkowsky_exp","float",2.5],["noisesize","float",0.25],["nabla","float",0.025],["w1","float",1.0],["w2","float",0.0],["w3","float",0.0],["w4","float",0.0],["bright","float",1.0],["contrast","float",1.0]]
	}
	
	##
	#
	##
	def initialize(createNew, procEditor, lrs, passedParam) # passedParam is texture type: marble, checkerboard, ...
		@lrs = lrs
		@procTexEditor = procEditor
		
		# create attribute dictionary
		@attributeDictionary = @procTexEditor.getTextureDictionary()
		
		if createNew == true # create new object from scratch
			textureType = passedParam
		
			# create name based on number of stored procedural materials in scene
			@name = "procTex_" + @lrs.nrProceduralTextures.to_s
			@procTexEditor.addTexture(name, self) # add texture to collection in current texture editor
			
			# update number of procedural materials in the scene
			@lrs.nrProceduralTextures += 1

			# write texture type name to attribute dictionary # marble, checkerboard, ...
			@attributeDictionary.set_attribute(@name, "textureType", textureType)
			@attributeDictionary.set_attribute(@name, "name", @name)
			
			# write texture type (by default first type in the list) # color, float, fresnel
			@attributeDictionary.set_attribute(@name, "procTexChannel", @@textureTypes[textureType][0])
			
			# for all textureType parameters, write values to attribute dictionary
			propertyList = @@textureParameters[passedParam]
			propertyList.each do |propertySet| 
				@attributeDictionary.set_attribute(@name, propertySet[0], propertySet[2])
			end
		
		else # create object based on existing data in attribute dictionary
			objectNr = passedParam
			
			# set @name and @attributeDictionary
			@name = "procTex_" + objectNr.to_s
			@procTexEditor.addTexture(name, self) # add texture to collection in current texture editor
			@attributeDictionary.set_attribute(@name, "name", @name)
			puts "getting dictionary object"
			@attributeDictionary.load_from_model(@name)
		end
	end

	def setValue(property, value)
		@attributeDictionary.set_attribute(@name, property, value)
	end
	
	def printValues()
		@@textureParameters[getTexType()].each do |propertySet|
			puts propertySet
		end	
	end	
	
	def getValues()
		passedVariableLists = []
		texType = getTexType()
		puts texType
		@@textureParameters[texType].each do |propertySet|
			puts propertySet
			# get value from dictionary, or use default value if no value has been stored
			varValue = @attributeDictionary.get_attribute(name, propertySet[0].to_s, propertySet[2])
			passedVariableLists << [propertySet[0],propertySet[1],varValue]
		end	
		puts "passedVariableList:"
		puts passedVariableLists
		return passedVariableLists
	end
	
	def getFormattedValues()
		unformattedValues = getValues()
		formattedValues = []
		unformattedValues.each do |paramSet|
			puts paramSet
			# deal with vector parameters
			texParamName = paramSet[0]
			if (texParamName[0..5] == "vector")
				texParamName.slice! "vector"
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
				formattedValues << [typeString, "\"" + paramSet[2] + "\""]
			else
				formattedValues << [typeString, paramSet[2]]
			end
		end
		puts "returning values:"
		puts formattedValues
		return formattedValues
	end
	
	def self.getTexChannels(texType)
		return @@textureTypes[texType]
	end
	
	def self.getChannelType(texName)
		thisDict = LuxrenderAttributeDictionary.returnDictionary(texName)
		thisTexType = thisDict["procTexChannel"]
		return thisTexType
	end
	
	def self.setTexChannel(texName) # returns float, fresnel or color
		thisDict = LuxrenderAttributeDictionary.returnDictionary(texName) # gets dictionary for this texture object
		thisTexName = thisDict["textureType"] # gets the texture type of this texture
		thisDict["procTexChannel"] = @@textureTypes[thisTexName][0]  # sets the texture channel to the first one that is listed
		puts "running setTexChannel, returning " + thisDict["procTexChannel"] # returns the texture channel
		return thisDict["procTexChannel"]
	end
	
	def setTexChannel()
		thisDict = LuxrenderAttributeDictionary.returnDictionary(name)
		thisTexName = thisDict["textureType"]
		thisDict["procTexChannel"] = @@textureTypes[thisTexName][0] 
		return thisDict["procTexChannel"]
	end
	

	def getTexType()
		thisDict = LuxrenderAttributeDictionary.returnDictionary(name)
		thisTexName = thisDict["textureType"]
		return thisTexName
	end
	
	def getChannelType()
		thisDict = LuxrenderAttributeDictionary.returnDictionary(name)
		thisTexType = thisDict["procTexChannel"]
		return thisTexType
	end
	
	
	def self.getTexType(texName)
		thisDict = LuxrenderAttributeDictionary.returnDictionary(texName)
		thisTexName = thisDict["textureType"]
		return thisTexName
	end
	
end
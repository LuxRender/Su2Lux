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

def initialize
	@material_editor_dialog=UI::WebDialog.new("Luxrender Material Editor", true, "LuxrenderMaterialEditor",500, 500,900,400,true)
	material_editor_dialog_path = Sketchup.find_support_file "materialeditor.html" ,"Plugins/su2lux"
	@material_editor_dialog.max_width = 800
	@material_editor_dialog.set_file(material_editor_dialog_path)
	
	@material_editor_dialog.add_action_callback('param_generate') {|dialog, params|
			#p 'param_generate'
			SU2LUX.p_debug params
			# Get the data from the Webdialog.
			parameters = string_to_hash(params)
			# Prepare the data
			material_type=parameters['material_type']
			#p material_type
			material_name=parameters['material_name']
			#p material_name
			#p "su_material"
			luxmat=self.find(material_name)
			luxmat.type=material_type
	}
	
	@material_editor_dialog.add_action_callback('set_material_list') {
	self.setmateriallist()
	}
	
	@material_editor_dialog.add_action_callback('select_material'){|dialog, matname|
	SU2LUX.p_debug "matname_2"+matname
	luxrender_material=self.find(matname)
	SU2LUX.p_debug "type="+luxrender_material.type
	cmd="$(\"#material_type option[value='"+luxrender_material.type+"']\").attr(\"selected\",\"selected\");"
	SU2LUX.p_debug cmd
	@material_editor_dialog.execute_script(cmd)
	}
end

# Takes a string like "key1=value1,key2=value2" and creates an hash.
def string_to_hash(string)
	hash = {}
	datapairs = string.split('|')
	datapairs.each { |datapair|
	  data = datapair.split('=')
	  hash[data[0]] = data[1]
	}
	return hash
end
	
def find(display_name) 
	materials=Sketchup.active_model.materials
	display_names = materials.collect {|m| m.display_name}
	names=materials.collect {|m| m.name}
	index=display_names.index(display_name)
	mat=index ? materials[names[index]] : nil  #get the SU material
	if mat
		return LuxrenderMaterial.new(mat)
	else
		return nil
	end
end 

	
def show
	@material_editor_dialog.show{refreshMaterialsList()}
end

   
def refreshMaterialsList()

	#cmd="clearMaterialList()"
	#@material_editor_dialog.execute_script(cmd)
	mat_list=Sketchup.active_model.materials.collect {|m| m.name}
	mat_list.sort!
	id="material_name"
	mat_list.each {|mat_name|
	#cmd="createMapOption(\"#{id}\",\"#{mat_name}\",\"#{mat_name}\")"
	cmd="createMapOption(\"#{id}\",\"wwwww\",\"wwww\")"
	SU2LUX.p_debug cmd
	@material_editor_dialog.execute_script(cmd)
}
end

def setmateriallist() 
	cmd="$('#material_name').append( $('"
	for mat in Sketchup.active_model.materials
		luxrender_mat=LuxrenderMaterial.new(mat)
		cmd=cmd+"<option value=\"#{luxrender_mat.name}\">#{luxrender_mat.name}</option>"
	end
	cmd=cmd+"'));"	
	#p cmd
	@material_editor_dialog.execute_script(cmd)	
end
  
def setmaterialtype()
	SU2LUX.p_debug "set material type"
end
end #end class LuxrenderMaterialEditor
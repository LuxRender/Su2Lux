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

class LuxrenderMaterial
	@@dict="luxrender_materials"
	@@type="matte"
  
	attr_reader :mat
def initialize(su_material)
	@mat=su_material
	#materials=Sketchup.active_model.materials
	#names = materials.collect {|m| m.display_name}
	#puts names
	#index=names.index(name)
	#puts index
	#@su_material=index ? materials[names[index]] : nil  #get the SU material
	#@su_material.set_attribute(@@dict,'type','matte')
	#@mat=materials.at 0
	#@mat=su_material
	#dicts=@mat.attribute_dictionaries if @mat
	#return if not dicts
end

def name
	return mat.display_name.gsub(/[<>]/, '*')  #replaces <> characters with *
end
  
def type
	t=@mat.get_attribute(@@dict,'type',@@type)  #check if the type has been set
	
	if not t
	  if @mat.alpha<1.0
		return "glass"
	  else
		return @@type
	  end
	else
	  return t
	end
end

def type=(value)
	@mat.set_attribute(@@dict,'type',value)
end

def color
	mat.color
end

def color=(value)
	mat.color=(value)
end

end #end class LuxrenderMaterial
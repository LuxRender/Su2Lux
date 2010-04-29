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


class LuxrenderSettingsEditor

def initialize

	pref_key="LuxrenderSettingsEditor"
	@settings_dialog=UI::WebDialog.new("Luxrender Render Settings", true,pref_key,520,500, 10,10,true)
	@settings_dialog.max_width = 520
	setting_html_path = Sketchup.find_support_file "test.html" ,"Plugins/su2lux"
	@settings_dialog.set_file(setting_html_path)
  @lrsd = AttributeDic.spawn($lrsd_name)
  @lrad = AttributeDic.spawn($lrad_name)
  
	@settings_dialog.add_action_callback("change_setting") {|dialog, params|
			SU2LUX.p_debug params
			pair=params.split("=")
			id=js_to_rb_path(pair[0])		   
			value=js_to_rb_path(pair[1])
      
      if AttributeDic::is_path?(value)
        if !@lrsd.include?(value) and !@lrad.include?(value)
          raise "non existant path/object (not in dictionary): #{value}"
        end
      end
      
      obj = @lrsd[id]
      
      obj.value = value
      if obj.respond_to?("call_block")
        if obj.call_block?()
          obj.call_block(self)
        end
      end
      puts value
	} #end action callback setting_change
	
  @settings_dialog.add_action_callback("call_function"){ |dialog, params|
    SU2LUX.p_debug params
    id = js_to_rb_path(params)
    
    if @lrad.include?(id)
      if @lrad[id].class == HTML_button
        @lrad[id].call_block(self, [])
      else
        raise "ruby attribute: #{id} is not a function"
      end
    else
      raise "ruby function: #{id} does not exist"
    end
  }
	
	@settings_dialog.add_action_callback("camera_change") { |dialog, params|
		perspective_camera = (params == "perspective")
		Sketchup.active_model.active_view.camera.perspective = perspective_camera if params != "environment"
	}
	# @settings_dialog.add_action_callback("scale_view") { |dialog, params|
		# values = params.split('x')
		# width = values[0].to_i
		# height = values[1].to_i
		# setValue("xresolution", width)
		# setValue("yresolution", height)
		# @lrs.xresolution = width
		# @lrs.yresolution = height
	# }
	

	@settings_dialog.add_action_callback("preset") {|d,p|
	case p
		when '0' #<option value='0'>0 Preview - Global Illumination</option> in settings.html
			puts "preset selected"
		when '0b'
			puts "preset selected"
		when '1'
			puts "preset selected"
		when '2'
			puts "preset selected"
	end #end case
	self.sendDataFromSketchup()
	} #end action callback preset
	
	
	@settings_dialog.add_action_callback("open_dialog") {|dialog, params|
  case params.to_s
		when "new_export_file_path"
			SU2LUX.new_export_file_path
	end #end case
	} #end action callback open_dialog
  
  self.add_preset()
end #end initialize


def show
	@settings_dialog.show{updateAllSettings()}
end

def visible?
  @settings_dialog.visible?
end

#set parameters in inputs of settings.html
def updateAllSettings()
  @lrsd.each_obj do |obj|
    if obj.respond_to?("html_update_cmds")
      updateSettingValue(obj)
    end
  end
  
  #custom settings list - could store this list in @lrad, and avoid the need to have it here
  #these settings can be saved along with the rest as system settings (perhaps in system settings group)
  self.updateSettingValue(@lrad["export_file_path"])
  
  @settings_dialog.execute_script("init_collapse();")
end 

def updateSettingValue(obj)
  cmds = obj.html_update_cmds
  for cmd in cmds
    #SU2LUX.p_debug cmd
    @settings_dialog.execute_script(cmd)
  end
end

def add_preset()
  @settings_dialog.execute_script("add_preset('yummy', 'yummy');")
end

def update_aspect_ratio()
  xres = @lrsd["film->xresolution"]
  yres = @lrsd["film->yresolution"]
  self.change_aspect_ratio(xres.value.to_i.to_f / yres.value.to_i.to_f)
end

def change_aspect_ratio(aspect_ratio)
	current_camera = Sketchup.active_model.active_view.camera
	current_ratio = current_camera.aspect_ratio
	current_ratio = 1.0 if current_ratio == 0.0
	
	new_ratio = aspect_ratio
	
	if(current_ratio != new_ratio)
		current_camera.aspect_ratio = new_ratio
		new_ratio = 1.0 if new_ratio == 0.0
		scale = current_ratio / new_ratio.to_f
		if current_camera.perspective?
			fov = current_camera.fov
			current_camera.focal_length = current_camera.focal_length * scale
		end
	end
end

def setCheckbox(id,value)
	#TODO
end

end #end class LuxrenderSettingsEditor
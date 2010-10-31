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
  @lrsd = AttributeDic.spawn($lrsd_name)
  @lrad = AttributeDic.spawn($lrad_name)
  
  self.create_html_dialog
  
	pref_key="LuxrenderSettingsEditor"
	@settings_dialog=UI::WebDialog.new("Luxrender Render Settings", true,pref_key,520,500, 10,10,true)
	@settings_dialog.max_width = 520
	setting_html_path = Sketchup.find_support_file "settings.html" ,"Plugins/su2lux"
	@settings_dialog.set_file(setting_html_path)
  
  self.init_presets()
  
	@settings_dialog.add_action_callback("change_setting") {|dialog, params|
			SU2LUX.p_debug params
			pair=params.split("=")
			id=js_to_rb_path(pair[0]) #not using the path thing, 
			#because not required for ruby (it 
			#accepts either format, and only the 
			#js_path works for displaying with 
			#javascript  
			value=js_to_rb_path(pair[1])
      
      if AttributeDic::is_path?(value)
        if !@lrsd.include?(value) and !@lrad.include?(value)
          raise "non existant path/object (not in dictionary): #{value}"
        end
      end
      
      obj = @lrsd[id]
      
      obj.value = value
      if obj.respond_to?("call_block")
        if obj.has_call_block?()
          obj.call_block(self)
        end
      end
      #puts value
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
	

	@settings_dialog.add_action_callback("new_preset") {|dialog, params|
    SU2LUX.p_debug params
    preset_name = params
    self.new_preset(preset_name)
    #save_preset_file()
	} #end action callback preset
	
	@settings_dialog.add_action_callback("su_select_preset") {|dialog, params|
    puts "JS CALLED SELECT: " + params
    preset_name = params
    self.su_select_preset(preset_name)
	} #end action callback preset
  
	@settings_dialog.add_action_callback("open_dialog") {|dialog, params|
  case params.to_s
		when "new_export_file_path"
			SU2LUX.new_export_file_path
	end #end case
	} #end action callback open_dialog
end #end initialize


def show
	@settings_dialog.show{updateAllSettings(); updatePresets()}
end

def visible?
  @settings_dialog.visible?
end

def updatePresets() #should be renamed or stuff changed to show_presets
  self.show_presets() #lshows presets already loaded from files
  puts "UPDTING: " + self.get_current_preset()
  puts "updating"
  self.js_select_preset(self.get_current_preset()) #set the current preset
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

def update_camera_type()
  #todo: add block stuff to luxchoice class to enable
  #callbacks
end

def fov_dic_2_su()
  current_camera = Sketchup.active_model.active_view.camera
  current_camera.fov = @lrsd["camera->camera_type->perspective->fov"].to_f
end

def fov_su_2_dic()
  current_camera = Sketchup.active_model.active_view.camera
  @lrsd["camera->camera_type->perspective->fov"] = current_camera.fov.to_f
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

def create_html_dialog
  ############## -- HTML SETTINGS EDITOR -- ###################
  presets_panel = HTML_block_panel.new("presets_panel")
    preset_table = HTML_outer_custom_element.new() do |this|
      html_str = "\n"
      html_str += "<table style=\"position:relative; margin-left:auto; margin-right:auto\">"
      
      html_str += "\n"
      html_str += "<tr>"
      for e in this.elements
        html_str += e.html
      end
      html_str += "\n"
      html_str += "</tr>"
      html_str += "\n"
      html_str += "</table>"
      html_str
    end
    
      preset_select = LuxSelection.new("preset_select", [], "Select Preset")
    preset_table.add_element!(preset_select)
    
      new_preset_button = HTML_button.new("new_preset", "New") do |env, args|
        @settings_dialog.execute_script("new_preset();") #calls js code, which then calls ruby code, providing the name of preset
      end
    preset_table.add_element!(new_preset_button)
    

  presets_panel.add_element!(preset_table)
  
  render_panel = HTML_block_panel.new("settings_panel")
    
    sampler_collapse = HTML_block_collapse.new("Sampler")
      sampler_collapse.add_LuxObject!(@lrsd["sampler"])
    
    pixelfilter_collapse = HTML_block_collapse.new("Pixel_Filter", [], "Pixel Filter")
      pixelfilter_collapse.add_LuxObject!(@lrsd["pixelfilter"])
      
    surfaceintegrator_collapse = HTML_block_collapse.new("Surface_Integrator", [], "Surface Integrator")
      surfaceintegrator_collapse.add_LuxObject!(@lrsd["surfaceintegrator"])
      
    
      
  render_panel.add_element!(sampler_collapse)
  render_panel.add_element!(surfaceintegrator_collapse)
  render_panel.add_element!(pixelfilter_collapse)
  ######################################
  
  
  ########## -- Camera/Environment Panel -- ##########
  camera_environment_panel = HTML_block_panel.new("camera_environment_panel")
    camera_collapse = HTML_block_collapse.new("Camera")
      camera_collapse.add_LuxObject!(@lrsd["camera"])
      
  camera_environment_panel.add_element!(camera_collapse)
  ######################################
  
  
  ######### -- Output Panel -- ##############
  output_panel = HTML_block_panel.new("output_panel")  
  
    film_collapse = HTML_block_collapse.new("Film")
        film_collapse.add_LuxObject!(@lrsd["film"])
        
        res_table = HTML_table.new("res_half_double")
          res_table.start_row!()
            res_double = HTML_button.new("res_double", "Double") do |env, args| 
              #env is the settings editor or the material editor
              @lrsd = AttributeDic.spawn($lrsd_name)
              xres = @lrsd["film->xresolution"]
              yres = @lrsd["film->yresolution"]
              
              xres.value = xres.value * 2
              yres.value = yres.value * 2
              
              env.updateSettingValue(@lrsd["film->xresolution"])
              env.updateSettingValue(@lrsd["film->yresolution"])
            end
            res_table.add_element!(res_double)
            
            res_half = HTML_button.new("res_half", "Half") do |env, args|
              @lrsd = AttributeDic.spawn($lrsd_name)
              xres = @lrsd["film->xresolution"]
              yres = @lrsd["film->yresolution"]
              
              xres.value = xres.value / 2
              yres.value = yres.value / 2
              
              env.updateSettingValue(@lrsd["film->xresolution"])
              env.updateSettingValue(@lrsd["film->yresolution"])
            end
            res_table.add_element!(res_half)
          res_table.end_row!()
        film_collapse.add_element!(res_table)
          
        res_table = HTML_table.new("res_presets")
          res_table.start_row!()
            res_table.add_element!(res_preset_button(800, 600))
            res_table.add_element!(res_preset_button(1024, 768))
          res_table.end_row!()
          res_table.start_row!()
            res_table.add_element!(res_preset_button(1280, 1024))
            res_table.add_element!(res_preset_button(1440, 900))
          res_table.end_row!()
        film_collapse.add_element!(res_table)
        
        view_size_table = HTML_table.new("view_size_table")
          view_size_table.start_row!()
            get_view_size_button = HTML_button.new("get_view_size", "Current View") do |env, args|
              @lrsd = AttributeDic.spawn($lrsd_name)
              xres = @lrsd["film->xresolution"]
              yres = @lrsd["film->yresolution"]
              
              xres.value = Sketchup.active_model.active_view.vpwidth
              yres.value = Sketchup.active_model.active_view.vpheight
              
              env.updateSettingValue(@lrsd["film->xresolution"])
              env.updateSettingValue(@lrsd["film->yresolution"])
              env.change_aspect_ratio(0.0)
            end
            view_size_table.add_element!(get_view_size_button)
          view_size_table.end_row!()
        film_collapse.add_element!(view_size_table)
        
  output_panel.add_element!(film_collapse)
  ##################################
  
  
  ########### -- System Settings Panel -- ###########
  system_panel = HTML_block_panel.new("system_settings_panel")
    system_settings_collapse = HTML_block_collapse.new("System_Settings", [], "System Settings")
      system_table = HTML_table.new("system_table")
      system_table.start_row!()
        export_file_path_tag = HTML_custom_element.new("export_file_path_tag", "<b>Export File Path: </b><a id=\"export_file_path\"></a>")
        system_table.add_element!(export_file_path_tag)
        
        export_file_path_button = HTML_button.new("export_file_path_button", "Browse") do |env, args|
          SU2LUX.new_export_file_path()
        end
        system_table.add_element!(export_file_path_button)
      system_table.end_row!()
    system_settings_collapse.add_element!(system_table)
    
    accelerator_collapse = HTML_block_collapse.new("Accelerator")
      accelerator_collapse.add_LuxObject!(@lrsd["accelerator"])
  
  
  system_panel.add_element!(system_settings_collapse)
  system_panel.add_element!(accelerator_collapse)
 ###########################################
 
 
 ##################################################
  settings_html_main = HTML_block_main.new("SettingsPage")
  settings_html_main.add_element!(presets_panel)
  settings_html_main.add_element!(camera_environment_panel)
  settings_html_main.add_element!(output_panel)
  settings_html_main.add_element!(render_panel)
  settings_html_main.add_element!(system_panel)
  
  open(SU2LUX.file_path("settings.html"), "w") {|out| out.puts settings_html_main.html}
  ##################################################
end

def save_preset_file()
  
end

def js_select_preset(name)
  if @presets.include?(name)
    puts "SELECTING: " + name
    @settings_dialog.execute_script("js_select_preset('#{name}');")
  end
end

def su_select_preset(name)
   if @presets.include?(name)
    @lrad["preset"].value = name
    @presets[name].load
    self.updateAllSettings()
  end
end

def find_preset_files()
  ret_arr = []
  preset_dir = SU2LUX.plugin_dir + "su2lux/presets"
  Dir.foreach(preset_dir) {|f| ret_arr.push(f) if f != "." and f != ".." and f.include?(".txt")}
  return ret_arr
end

def new_preset(name)
  puts "preset_name:" + name.to_s
  if not @presets.include? name#checking whether to overwrite
    pres = Preset.new(name)
    pres.save
    @presets[name] = pres
  else#overwritng old preset
    puts "OVERWRITING!!!!!"
    @presets[name].save
  end
  @lrad["preset"].value = name
  js_select_preset(name)
end

def set_current_preset(name)
  #self.su_select_preset(name)
  @lrad["preset"].value = name
end

def get_current_preset()
  return @lrad["preset"].value
end


def remove_preset(name)
end

def load_preset_dic()
  preset_names = find_preset_files() 
  @presets = {} #setup a new hash to store preset objects in.
  for name in preset_names
    puts "found: " + name
    name = name.gsub(/[.]txt/, "") #remove .txt from the end
    puts "PRESET NAME: " + name
    pres = Preset.new(name)
    @presets[name] = pres
  end
end


def load_current_preset()
  #preset = @lrad["preset"]
  #find presets in the preset folder
  #puts "Loading Current Preset: " + @lrad["preset"].value
  @presets[@lrad["preset"].value].load
end

def init_presets()
  preset = Attribute.new("preset")
  @lrad.add_root("preset", preset)
  self.load_preset_dic()
  if @lrad["preset"].value != "" #ensure that the selected preset is reloaded properly
    puts "FOUND PRESET SETTING: "
    puts @lrad["preset"].value
    if not @presets.include?(@lrad["preset"].value)
      puts "Preset: #{@lrad["preset"].value} not found in file"
      self.set_current_preset("default")
    end
  else
    self.set_current_preset("default")
    self.load_current_preset()
  end
end


def show_presets()
  #puts presets loaded from files into the ui
  @presets.each_key do |name|
    @settings_dialog.execute_script("set_preset_selector('#{name}')")#add the preset to the selector in the ui
  end
end

def load_default_preset()
end


end #end class LuxrenderSettingsEditor

class Preset
  def initialize(name)
    @file_name = SU2LUX.plugin_dir + "su2lux/presets/" + name.to_s + ".txt"
    @lrsd = AttributeDic.spawn($lrsd_name)
    @loaded = false
  end
  def save
    File.open(@file_name, "w") do |file|
      file.puts "#this is a presets file of  --settings--\n\n"
      file.puts @lrsd.export_dic_str
    end
    puts "SAVED!"
  end
  def load
    @loaded = true
    puts "LOADING PRESET: #{@file_name}"
    File.open(@file_name, "r") do |file|
      puts "IMPORTING"
      file.each_line do |line|
        if line.chomp != "" and not line.include?('#')
          #puts line.chomp
          @lrsd.import_dic_line(line)
        end      
      end
    end
  end
  def loaded?
    return @loaded
  end
end

require "su2lux\\LuxrenderTypes.rb"
require "su2lux\\LuxrenderHTMLTypes.rb"
require "su2lux\\LuxrenderAttributeDictionaries.rb"

#5pm
#7 rows back in the middle


@lrsd = AttributeDic.spawn($lrsd_name)
@lrad = AttributeDic.spawn($lrad_name)

########## -- SU2LUX Attributes -- ###########
export_file_path = Attribute.new('export_file_path', 'rb_file_path', '')
@lrad.add_root("export_file_path", export_file_path)

########## -- Camera Settings -- ###########
def camera_settings()
camera = LuxObject.new('camera', [], 'Camera')#name, because exporting requires capitals

camera_type = LuxSelection.new('camera_type')
  camera_type.create_choice!('perspective', LuxFloat.new('fov', 35))
  camera_type.create_choice!('orthographic', LuxFloat.new('scale', 7.31))
  camera_type.create_choice!('environment')

camera.add_element!(camera_type)

camera.add_element!(LuxBool.new('near_far_clipping', false))
camera.add_element!(LuxBool.new('dof_bokeh', false))
camera.add_element!(LuxBool.new('architectural', false))
camera.add_element!(LuxBool.new('motion_blur', false))
camera.add_element!(LuxFloat.new('hither', 0.1))
camera.add_element!(LuxFloat.new('yon', 100.0))
camera.add_element!(LuxBool.new('autofocus', false))
@lrsd.add_root("camera", camera)
end
#end camera
############################################


########## -- Film Settings -- #############
def film_settings()
film = LuxObject.new("film", [], 'Film')

film_type = LuxSelection.new('film_type')
  film_type.create_choice!('fleximage')

film.add_element!(film_type)

#film.add_element!(LuxInt.new('xresolution', Sketchup.active_model.active_view.vpwidth))
#film.add_element!(LuxInt.new('yresolution', Sketchup.active_model.active_view.vpheight))
xres = LuxInt.new('xresolution', Sketchup.active_model.active_view.vpwidth/2)
yres = LuxInt.new('yresolution', Sketchup.active_model.active_view.vpheight/2)

film.add_element!(xres)
film.add_element!(yres)

film.add_element!(LuxInt.new('displayinterval', 4))
film.add_element!(LuxInt.new('haltspp'))
film.add_element!(LuxInt.new('halttime'))

@lrsd.add_root("film", film)
end
############################################


######## -- Sampler -- #####################
def sampler_settings()
sampler = LuxObject.new('sampler', [], 'Sampler')

sampler_type = LuxSelection.new('sampler_type')
# lowdicrepancy & random #
  pixelsamples = LuxInt.new('pixelsamples', 4)
  pixelsamplerselection = LuxSelection.new('pixelsamplerselection')
    pixelsamplerselection.create_choice!('linear')
    pixelsamplerselection.create_choice!('tile')
    pixelsamplerselection.create_choice!('random')
    pixelsamplerselection.create_choice!('vegas')
    pixelsamplerselection.create_choice!('lowdiscrepancy')
    pixelsamplerselection.create_choice!('hilbert')
    pixelsamplerselection.select!('vegas')#set as default
  pixelsampler = LuxString.new('pixelsampler', pixelsamplerselection) #very cool!
  sampler_type.create_choice!('lowdiscrepancy', [pixelsamples, pixelsampler])
  sampler_type.create_choice!('random', [pixelsamples.deep_copy(), pixelsampler.deep_copy()])
# erpt #
  chainlength = LuxInt.new('chainlength', 100000)
  
  sampler_type.create_choice!('erpt', chainlength)
# metropolis #
  sampler_type.create_choice!('metropolis')

sampler.add_element!(sampler_type)

@lrsd.add_root("sampler", sampler)
end
############################################


########## -- SurfaceIntegrator -- #########
def surfaceintegrator_settings()
surfint = LuxObject.new('surfaceintegrator', [], 'SurfaceIntegrator')

int_type = LuxSelection.new('integrator_type')
  bidir = LuxChoice.new('bidirectional')
    bidir.add_child!(LuxInt.new('eyedepth', 8))
    bidir.add_child!(LuxInt.new('lightdepth', 8))
  direct = LuxChoice.new('directlighting')
    direct.add_child!(LuxFloat.new('maxdepth', 5))
  exphoton = LuxChoice.new('exphotonmap')
  path = LuxChoice.new('path')
    path.add_child!(LuxInt.new('maxdepth', 16))
    path.add_child!(LuxBool.new('includeenvironment', true))
  distrpath = LuxChoice.new('distributedpath')
  igi = LuxChoice.new('igi')
int_type.add_choice!(bidir)
int_type.add_choice!(direct)
int_type.add_choice!(exphoton)
int_type.add_choice!(path)
int_type.add_choice!(distrpath)
int_type.add_choice!(igi)

surfint.add_element!(int_type)
@lrsd.add_root("surfaceintegrator", surfint)
end
#####################################################


######## -- VolumeIntegrator -- ####################

########## -- Accelerator -- #######################
def accelerator_settings()
accel = LuxObject.new('accelerator', [], 'Accelerator')

accel_type = LuxSelection.new('accelerator_type')
  tabreckdtree = LuxChoice.new('tabreckdtree')
    tabreckdtree.add_child!(LuxInt.new('intersectcost', 80))
    tabreckdtree.add_child!(LuxInt.new('traversalcost', 1))
    tabreckdtree.add_child!(LuxFloat.new('emptybonus', 0.5))
    tabreckdtree.add_child!(LuxInt.new('maxprims', 1))
    tabreckdtree.add_child!(LuxInt.new('maxdepth', -1))
  grid = LuxChoice.new('grid', LuxBool.new('refineimmediately', false))
  qbvh = LuxChoice.new('qbvh', LuxInt.new('maxprimsperleaf', 4))
  bvh = LuxChoice.new('bvh')
accel_type.add_choice!(tabreckdtree)
accel_type.add_choice!(grid)
accel_type.add_choice!(qbvh)
accel_type.add_choice!(bvh)

accel.add_element!(accel_type)
@lrsd.add_root("accelerator", accel)
end
####################################################

#### -- initialize settings -- ####
surfaceintegrator_settings()
sampler_settings()
film_settings()
camera_settings()
accelerator_settings()
## -- end initialize settings -- ##


#@lrsd["camera"]["camera_type"].select!("environment")
#@lrsd["sampler"]["sampler_type"]["random"]["pixelsampler"].value.select!("vegas")


#@lrsd.each_value {|value| print value.export + "\n"}

############## -- HTML SETTINGS EDITOR -- ###################
settings_panel = HTML_block_panel.new("settings_panel")

  camera_collapse = HTML_block_collapse.new("Camera")
    camera_collapse.add_LuxObject!(@lrsd["camera"])
    
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
        
        
  sampler_collapse = HTML_block_collapse.new("Sampler")
    sampler_collapse.add_LuxObject!(@lrsd["sampler"])
    
  surfaceintegrator_collapse = HTML_block_collapse.new("Surface_Integrator", [], "Surface Integrator")
    surfaceintegrator_collapse.add_LuxObject!(@lrsd["surfaceintegrator"])
    
  accelerator_collapse = HTML_block_collapse.new("Accelerator")
    accelerator_collapse.add_LuxObject!(@lrsd["accelerator"])
    
settings_panel.add_element!(camera_collapse)
settings_panel.add_element!(film_collapse)
settings_panel.add_element!(sampler_collapse)
settings_panel.add_element!(surfaceintegrator_collapse)
settings_panel.add_element!(accelerator_collapse)


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

system_panel.add_element!(system_settings_collapse)


settings_html_main = HTML_block_main.new("SettingsPage")
settings_html_main.add_element!(settings_panel)
settings_html_main.add_element!(system_panel)

File.open("C:\\Program Files\\Google\\Google SketchUp 7\\Plugins\\su2lux\\test.html", "w") {|out| out.puts settings_html_main.html}

##################################################


############# -- Sketchup Attributes Testing -- ###################

#puts "Somethings" + @lrsd["accelerator"]["accelerator_type"]["tabreckdtree"].attribute_key

#it should be very easy to set up and save presets using this method.
def explore(obj)
  if obj.respond_to?("each")
    obj.each do |element|
      if element.respond_to?("attribute_key")
        if  element.respond_to?("value")
          puts element.attribute_key + " = " + element.value.to_s
        end
        explore(element)
      end
    end
  end
  return
end

#File.open("test.lxs", "w") do |out|
#  @lrsd.each_root do |p|
#    out.puts p.export + "\n"
#    #explore(p)
#    out.puts "\n\n"
#  end
#end

#~ File.open("D:\\preset_file_rb", "w") do |file|
  #~ file.puts "#this is a presets file of  --settings--\n\n"
  #~ @lrsd.strdic.each_key do |key|
    #~ val = @lrsd.strdic[key]
    #~ if not AttributeDic.is_path?(val.to_s)
      #~ file.puts "#{key} = #{val}"
    #~ end
  #~ end
  #~ file.puts "\n\n"
  #~ @lrsd.strdic.each_key do |key|
    #~ val = @lrsd.strdic[key]
    #~ if AttributeDic.is_path?(val.to_s)
      #~ file.puts "#{key} = #{val}"
    #~ end
  #~ end
#~ end

#~ File.open("D:\\preset_file_su", "w") do |file|
  #~ file.puts "#this is a presets file of  --settings--\n\n"
  #~ @lrsd.strdic.each_key do |key|
    #~ val = @lrsd.sustrdic[key]
    #~ if not AttributeDic.is_path?(val.to_s)
      #~ file.puts "#{key} = #{val}"
    #~ end
  #~ end
  #~ file.puts "\n\n"
  #~ @lrsd.strdic.each_key do |key|
    #~ val = @lrsd.sustrdic[key]
    #~ if AttributeDic.is_path?(val.to_s)
      #~ file.puts "#{key} = #{val}"
    #~ end
  #~ end
#~ end
#
puts "files written:
#   - preset_file_su
#   - preset_file_rb
#   - test.lxs
#   - test.html"

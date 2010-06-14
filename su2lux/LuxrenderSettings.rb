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


require "su2lux/LuxrenderTypes.rb"
require "su2lux/LuxrenderHTMLTypes.rb"
require "su2lux/LuxrenderAttributeDictionaries.rb"

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

camera_type = LuxSelection.new('camera_type', [], 'Camera Type')
  fov = LuxFloat.new('fov', 35) do |this, env|
    env.fov_dic_2_su()
  end
  camera_type.create_choice!('perspective', fov)
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

film_type = LuxSelection.new('film_type', [], 'Film Type')
  film_type.create_choice!('fleximage')

film.add_element!(film_type)

#probably not the best way to do this!
xres = LuxInt.new('xresolution', Sketchup.active_model.active_view.vpwidth/2) do |this, env|
  env.update_aspect_ratio()
end

yres = LuxInt.new('yresolution', Sketchup.active_model.active_view.vpheight/2) do |this, env|
  env.update_aspect_ratio()
end


film.add_element!(xres)
film.add_element!(yres)


film.add_element!(LuxFloat.new('gamma', 2.2))
film.add_element!(LuxBool.new('premultiplyalpha', false))

film.add_element!(LuxBool.new('write_exr', false))
film.add_element!(LuxBool.new('write_png', true))
film.add_element!(LuxBool.new('write_tga', false))
film.add_element!(LuxString.new('filename', 'luxout', 'image filename'))

film.add_element!(LuxInt.new('displayinterval', 4))
film.add_element!(LuxInt.new('writeinterval', 60))
film.add_element!(LuxInt.new('haltspp', 0))
film.add_element!(LuxInt.new('halttime', 0))

tonemapkernelselection = LuxSelection.new('tonemapkernelselection', [], 'tonemap')
  reinhard = LuxChoice.new('reinhard')
    reinhard.add_child!(LuxFloat.new('reinhard_prescale', 1.0))
    reinhard.add_child!(LuxFloat.new('reinhard_prostscale', 1.0))
    reinhard.add_child!(LuxFloat.new('reinhard_burn', 1.0))
  linear = LuxChoice.new('linear')
    linear.add_child!(LuxFloat.new('linear_sensitivitiy', 50.0))
    linear.add_child!(LuxFloat.new('linear_exposure', 1.0))
    linear.add_child!(LuxFloat.new('linear_fstop', 2.8))
    linear.add_child!(LuxFloat.new('linear_gamma', 1.0))
  contrast = LuxChoice.new('contrast')
    contrast.add_child!(LuxFloat.new('contrast_ywa', 1.0))
  maxwhite = LuxChoice.new('maxwhite')
  tonemapkernelselection.add_choice!(reinhard)
  tonemapkernelselection.add_choice!(linear)
  tonemapkernelselection.add_choice!(contrast)
  tonemapkernelselection.add_choice!(maxwhite)
  tonemapkernelselection.select!('reinhard')
film.add_element!(LuxString.new('tonemapkernel', tonemapkernelselection))


@lrsd.add_root("film", film)
end
############################################


######## -- Sampler -- #####################
def sampler_settings()
sampler = LuxObject.new('sampler', [], 'Sampler')

sampler_type = LuxSelection.new('sampler_type', [], 'Sampler Type')
# lowdicrepancy & random #
  pixelsamples = LuxInt.new('pixelsamples', 4)
  pixelsamplerselection = LuxSelection.new('pixelsamplerselection', [], 'Pixel Sampler Type')
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

int_type = LuxSelection.new('integrator_type', [], 'Integrator Type')
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

accel_type = LuxSelection.new('accelerator_type', [], 'Accelerator Type')
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

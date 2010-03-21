require "LuxrenderTypes.rb"

@properties = {}

########## -- Camera Settings -- ###########
camera = LuxObject.new('Camera')

camera_type = LuxSelection.new('camera_type')
  camera_type.create_choice!('perspictive', LuxFloat.new('fov', 35))
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
@properties["Camera"] = camera
#end camera
############################################


########## -- Film Settings -- #############
film = LuxObject.new("Film")

film_type = LuxSelection.new('film_type')
  film_type.create_choice!('fleximage')

film.add_element!(film_type)

#film.add_element!(LuxInt.new('xresolution', Sketchup.active_model.active_view.vpwidth))
#film.add_element!(LuxInt.new('yresolution', Sketchup.active_model.active_view.vpheight))
film.add_element!(LuxInt.new('xresolution', 800))
film.add_element!(LuxInt.new('yresolution', 600))

film.add_element!(LuxInt.new('displayinterval', 4))
film.add_element!(LuxInt.new('haltspp'))
film.add_element!(LuxInt.new('halttime'))

@properties["Film"] = film
############################################


######## -- Sampler -- #####################
sampler = LuxObject.new('Sampler')

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
  sampler_type.create_choice!('random', [pixelsamples, pixelsampler])
# erpt #
  chainlength = LuxInt.new('chainlength', 100000)
  
  sampler_type.create_choice!('erpt', chainlength)
# metropolis #
  sampler_type.create_choice!('metropolis', chainlength)

sampler.add_element!(sampler_type)

@properties["Sampler"] = sampler

############################################
#@properties["Camera"]["camera_type"].select!("environment")
#@properties["Sampler"]["sampler_type"]["random"]["pixelsampler"].value.select!("vegas")


@properties.each_value {|value| print value.export + "\n"}
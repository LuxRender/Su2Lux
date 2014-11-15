     # Create an entry in the Extension list that loads a script called
     # core.rb.
     require 'sketchup.rb'
     require 'extensions.rb'

     su2lux_extension = SketchupExtension.new('SU2LUX', 'su2lux/su2lux.rb')
     su2lux_extension.version = '0.44'
     su2lux_extension.description = 'Exporter to LuxRender'
     Sketchup.register_extension(su2lux_extension, true)
##### -- ui generation specific -- #########

class HTML_block
  attr_reader :id
  attr_accessor :elements
  def initialize(id, elements=[])
    @id = id
    if elements.is_a?(Array) == false #allow simple creation of choice with one child
      elements = [elements]
    end
    @elements = elements
  end
  def add_element!(element)
    @elements.push(element)
  end
  def add_LuxObject!(object)
    for element in object.elements
      @elements.push(element)
    end
  end
end #end HTML_block

class HTML_block_main < HTML_block
  def create_panel!(id, elements=[])
    @elements.push(HTML_block_panel.new(id, elements))
  end
  def html
    #### TOP ####
    html_str  = <<-eos 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

<html>
<head>
<title>testing</title>

<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="su2lux_test.js"></script>

<link href="settings.css" type="text/css" rel="stylesheet">

</head>
<body>
    eos
    
    #### ELEMENTS ####
    for e in @elements
      html_str << "\n" + e.html
    end
    
    #### BOTTOM ####
    html_str << "\n" + "</body>"
    html_str << "\n" + "</html>"
    
    return html_str
  end
end #end HTML_block_main


class HTML_block_collapse < HTML_block
  attr_reader :name
  def initialize(id, elements=[], name=id)
    @id = id
    @name = name
    if elements.is_a?(Array) == false #allow simple creation of choice with one child
      elements = [elements]
    end
    @elements = elements
    @collapsed = true
  end
  def html
    

    #### HEADER ####
    html_str = "\n"
    html_str << "<p class=\"header\">#{@name}</p>"
    
      #### COLLAPSE DIV ####
      html_str << "\n"
      html_str << "<div class=\"collapse\">"
      
        #### TABLE ####
        html_str << "\n"
        html_str << "<table style=\"position:relative; margin-left:auto; margin-right:auto\">"
        
          #### PROPERTIES ####
          for e in @elements
            if e.class != HTML_table #a bit of a hack to get buttons on the end
              #### TABLE ROW ####
              html_str << "\n"
              html_str << "<tr>"
                
                #### CHILD HTML ####
                html_str << "\n" + e.html
              #### END TABLE ROW ####
              html_str << "\n"
              html_str << "</tr>"
              html_str << "\n"
            end
          end
          
        #### END TABLE ####
        html_str << "\n"
        html_str << "</table>"
        
        for e in @elements
          if e.class == HTML_table
            #### TABLE ####
            html_str << "\n"
            html_str << "<table style=\"position:relative; margin-left:auto; margin-right:auto\">"
            
            html_str << "\n"
            html_str << "<tr>"
              
            #### CHILD HTML ####
            html_str << "\n" + e.html
            
            #### END TABLE ROW ####
            html_str << "\n"
            html_str << "</tr>"
            html_str << "\n"
            
            #### END TABLE ####
            html_str << "\n"
            html_str << "</table>"
          end
        end
        
      #### END COLLAPSE DIV ####
      html_str << "\n"
      html_str << "</div>"

    return html_str
  end
  def collapsed?
    return @collapsed
  end
  def collapse
    @collapsed = true
  end
  def expand
    @collapsed = false
  end
end #end HTML_block_collapse

class HTML_block_panel < HTML_block
  def html
    #### DIV ####
    html_str = "\n"
    html_str << "<div id=\"#{@id}\" class=\"panel\">"
    
    #### ELEMENTS ####
    for e in @elements
      html_str << "\n" + e.html
    end
    
    #### END DIV ####
    html_str << "\n"
    html_str << "</div>"
    
    return html_str
  end
end #end HTML_block_panel

class HTML_custom_element
  attr_reader :id, :name
  def initialize(id, custom_html="", name=id)
    @id = id
    @name = name
    @custom_html=custom_html
  end
  def html
    html_str = "\n<td>\n" + @custom_html + "\n</td>"
    return html_str
  end
end #end HTML_custom_element

class HTML_table
  attr_reader :id, :name
  def initialize(id, name=id)
    @id = id
    @name = name
    @table = []
    @row = []
  end
  def start_row!()
    if @row != [] 
      @table.push(@row)
      @row = []
    end
  end
  def end_row!()
    if @row != [] 
      @table.push(@row) 
      @row = []
    end
  end
  def add_element!(el)
    @row.push(el)
  end
  def html
    @table.push(@row) if @row != []  
    #add last row (which hasn't been pushed yet if the user has forgotten to put an end row)
    html_str = "\n"
    html_str += "<td>"
    
    html_str += "\n"
    html_str += "<table>"
    
    for row in @table
      html_str += "\n"
      html_str += "<tr>"
      
      for el in row
        html_str += el.html
      end
      
      html_str += "\n"
      html_str += "</tr>"
    end
    
    html_str += "\n"
    html_str += "</table>"
    
    html_str += "\n"
    html_str += "</td>"
    return html_str
  end
end

class HTML_button
  #IMPORTANT: this class uses @lrad for storage, and reference (see initialize method)
  attr_reader :id, :name
  def initialize(id, name=id, &block)
    @id = id
    @name = name
    @block = block
    
    @lrad = AttributeDic.spawn($lrad_name) unless @lrad
    @lrad.add_root(@id, self)
  end
  def attribute_init(parent)
    self.value = @id
  end
  def attribute_key
    return @id
  end
  def value
    return "HTML_button"
  end
  def value=(v)
    @lrad = AttributeDic.spawn($lrad_name) unless @lrad
    @lrad.map_object_value(self, v)
  end
  def call_block(env=nil, *args)
    args = nil if not args
    @block.call(env, args)
  end
  def html
    html_str = "\n<td>"
    html_str += "<input type=\"button\" id=\"#{rb_to_js_path(self.attribute_key)}\" value =\"#{@name}\" style=\"width:100%\">\n  </td>"
    return html_str
  end
end #end HTML_custom_element

def res_preset_button(x, y)
  button = HTML_button.new("res_#{x}x#{y}", "#{x}x#{y}") do |env, args|
    @lrsd = AttributeDic.spawn($lrsd_name)
    @lrad = AttributeDic.spawn($lrad_name)
    xres = @lrsd["film->xresolution"]
    yres = @lrsd["film->yresolution"]
    
    xres.value = x
    yres.value = y
    
    env.updateSettingValue(@lrsd["film->xresolution"])
    env.updateSettingValue(@lrsd["film->yresolution"])
    env.change_aspect_ratio(xres.value.to_i.to_f / yres.value.to_i.to_f)
  end
  return button
end

class HTML_from_file
  def initialize()
  end
  def html
  end
end #end HTML_from_file
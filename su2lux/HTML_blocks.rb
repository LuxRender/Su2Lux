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
end #end HTML_block

class HTML_block_main < HTML_block
  def add_element!(panel)
    @elements.push(panel)
  end
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
  end
  def html
    #### HEADER ####
    html_str = "\n"
    html_str << "<p class=\"header\">#{@name}</p>"
    
      #### COLLAPSE DIV ####
      html_str << "\n"
      html_str << "<div class=\"collapse\">"
      
        #### PROPERTIES ####
        for e in @elements
          html_str << "\n" + e.html
        end
      
      #### END COLLAPSE DIV ####
      html_str << "\n"
      html_str << "</div>"
    
    return html_str
  end
end #end HTML_block_collapse

class HTML_block_panel < HTML_block
  def html
    #### DIV ####
    html_str = "\n"
    html_str << "<div id=\"#{@id}\">"
    
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
  def initialize(property)
  end
end #end HTML_custom_element



class HTML_from_file
  def initialize()
  end
  def html
  end
end #end HTML_from_file
######## -- Basic Types -- ############
class LuxType
  attr_reader :type_str, :id, :name
  def export#todo: add another argument with tab level or use a singleton
    #of the form:
    #"bool directsampleall" ["true"]
    #"float eyerrthreshold" [0.000000]
    return "\"#{@type_str} #{@id}\" [#{@value.to_s}]"
  end
end #end LuxType

class LuxNumber < LuxType
  attr_accessor :value
  def html
    #### TEXT INPUT ####
    html_str = "#{@name}: <input type='text' id=\"#{@id}\" size=\"2\">"
	
	return html_str
  end
  #type conversion
  def to_f
    @value.to_f
  end
  def to_i
    @value.to_i
  end
  def to_s
    @value.to_s
  end
end #end LuxNumber

class LuxInt < LuxNumber
  def initialize(id, value=0, name=id)
    @id = id
    @name = name
    @value = value.to_i #add check if integer or number, convert if other number.
    @type_str = 'integer'
  end
end #end LuxInt

class LuxFloat  < LuxNumber
  def initialize(id, value=0.0, name=id)
    @id = id
    @name = name
    @value = value.to_f
    @type_str = 'float'
  end
end #end LuxFloat

class LuxBool < LuxType
  attr_accessor :value
  def initialize(id, value=true, name=id)
    @id = id
    @name = name
    @value = value #todo: add check for boolean
    @type_str = 'bool'
  end
  def export
    return "\"#{@type_str} #{@id}\" [\"#{@value.to_s}\"]"
  end
  def html
    #### CHECKBOX INPUT ####
    html_str = "<input type=\"checkbox\" id=\"#{@id}\" value=\"#{@value}\">#{@name}"
    
    return html_str
  end
  #type conversion
  def to_s
    @value.to_s
  end
  def to_i
    if @value == true
      return 1
    else
      return 0
    end
  end
end #end LuxBool

class LuxVector < LuxType
  attr_accessor :x, :y, :z
  def initialize(id, vector_array=[0,0,0], name=id )
    @id = id
    @name = name
    @x = vector_array[0]
    @y = vector_array[1]
    @z = vector_array[2]
    @type_str = 'vector'
  end
  def export
    #of the form:
    #"vector sundir" [-0.423824071310226 -0.772439983723215 0.472979521886207]
    return "\"#{@type_str} #{@id}\" [#{@x.to_s} #{@y.to_s} #{@z.to_s}]"
  end
  #type conversion
  def to_s
    return "[#{@x}, #{@y}, #{@z}]"
  end
  def to_a
    return [@x, @y, @z]
  end
end #end LuxVector

class LuxPoint < LuxVector
end

class LuxNormal < LuxPoint
end



class LuxColor < LuxType
  attr_accessor :value
end #end LuxColor

class LuxString < LuxType
  attr_accessor :value
  def initialize(id, value="", name=id)
    @id = id
    @name = name
    @value = value
    @type_str = 'string'
  end
  def export
    return "\"#{@type_str} #{@id}\" [\"#{@value.to_s}\"]"
  end
  def to_s
    @value.to_s
  end
end #end LuxString

###### -- groupings -- ######
class LuxObject
  attr_reader :id, :elements
  def initialize(id, elements=[])
    @id = id
    if elements.is_a?(Array) == false #allow simple creation of choice with one child
      elements = [elements]
    end
    @elements = elements #array of elements
  end
  def export
    export_str = @id
    for e in @elements
      export_str << " " << e.export << "\n"#watch out for spaces with lux importing
    end
    return export_str
  end
  def [](element_id)
    for element in @elements
      return element if element.id == element_id
    end
  end
  def add_element!(new_element)
    @elements.push(new_element)
  end
end #end LuxObject

######## -- Settings/export Secific -- #########
# generate types with ui updating properties?

class LuxSelection
  #usefull for value in lightgroup and lightsource and many others
  attr_reader :id, :choices, :name
  attr_accessor :selection, :children
  def initialize(id, choices=[], name=id, default_choice=0)
    @id = id
    @name = name
    @choices = choices
    @selection = choices[default_choice]
  end
  
  def add_choice!(choice)
    if choice.is_a? LuxChoice
      @choices.push(choice)
    else
     #raise error if choice not LuxChoice object
    end
  end
  
  def create_choice!(id, children=[])
    @choices.push(LuxChoice.new(id, children))
    if not @selection
      @selection = choices[0]
    end
  end 
  
  def export
    export_str = @selection.export + "\t\t"#todo: proper formatting
    return export_str
  end
  
  def html
    #### LABEL ####
    html_str = "\n"
    html_str << "<span class=\"label\">#{@name} type:</span>"
    
    #### SELECT ####
    html_str << "\n"
    html_str << "<select id=\"#{@id}\">"
    
    #### OPTIONS ####
    for choice in @choices
      html_str << "\n" + choice.html
    end
    
    #### END SELECT ####
    html_str << "\n"
    html_str << "</select>"
  
    for choice in @choices
      #### DIV ####
      html_str << "\n"
      html_str << "<div id=\"#{choice.id}\" class=\"collapse\">"
      
      for child in choice.children
        #### PROPERTY ####
        html_str << "\n"
        html_str << child.html
      end
      
      #### END DIV ####
      html_str << "\n"
      html_str << "</div>"
    end
    return html_str
  end
  
  #type conversion
  def to_s
    @selection
  end
  
  def to_a
    @choices
  end
  
  #accessibility
  def [](choice_id)
    for choice in @choices
      return choice if choice.id == choice_id
    end
  end
  def select!(new_selection_id)
    for c in @choices
      if c.id == new_selection_id
        @selection = c
        return
      end
    end
    #raise some kind of error if no new selection was made
  end
end #end LuxSelection

class LuxChoice
  attr_reader :id, :name
  attr_accessor :children
  def initialize(id, children=[], name=id)
    @id = id
    @name = name
    if children.is_a?(Array) == false #allow simple creation of choice with one child
      children = [children]
    end
    @children = children #array
  end
  
  def add_child!(child)
    @children.push(child)
  end
  
  def export
    export_str = "\"#{@id.to_s}\""
    for child in children
      export_str += "\n " + child.export
    end
    return export_str
  end
  
  def html
    #### OPTION ####
    html_str = "<option value=\"#{@id}\">#{@name}</option>"
    
    return html_str
  end

  def [](child_id)
    for child in @children
      return child if child.id == child_id
    end
  end
  def to_s
    return @id
  end
end #end LuxChoice

class Attribute
end #end Attribut


##### -- export tools -- ##############
#this really belongs in Exporter.rb
class Tbcnt
  #keeps track of tabs when exporting to html or lxs
end
######## -- Material Specific -- ########

####### -- experimentation area -- #######
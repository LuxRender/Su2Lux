######## -- Basic Types -- ############
class LuxType
  attr_reader :type_str, :name
  def export(luxtype_object)#todo: add another argument with tab level or use a singleton
    obj = luxtype_object
    #of the form:
    #"bool directsampleall" ["true"]
    #"float eyerrthreshold" [0.000000]
    return "\"#{obj.type_str} #{obj.name}\" [#{obj.value.to_s}]"
  end
end

class LuxNumber < LuxType
  attr_accessor :value
  def export(luxnumber_object)
    super(luxnumber_object)
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
end

class LuxInt < LuxNumber
  def initialize(name, value=0)
    @name = name
    @value = value.to_i #add check if integer or number, convert if other number.
    @type_str = "integer"
  end
  def export
    super(self)
  end
end

class LuxFloat  < LuxNumber
  def initialize(name, value=0.0)
    @name = name
    @value = value.to_f
    @type_str = "float"
  end
  def export
    super(self)
  end
end

class LuxBool < LuxType
  attr_accessor :value
  def initialize(name, value)
    @name = name
    @value = value #todo: add check for boolean
    @type_str = "bool"
  end
  def export
    return "\"#{@type_str} #{@name}\" [\"#{@value.to_s}\"]"
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
end

class LuxVector < LuxType
  attr_accessor :x, :y, :z
  def initialize(name , vector_array)
    @name = name
    @x = vector_array[0]
    @y = vector_array[1]
    @z = vector_array[2]
    @type_str = "vector"
  end
  def export
    #of the form:
    #"vector sundir" [-0.423824071310226 -0.772439983723215 0.472979521886207]
    return "\"#{@type_str} #{@name}\" [#{@x.to_s} #{@y.to_s} #{@z.to_s}]"
  end
  #type conversion
  def to_s
    return "[#{@x}, #{@y}, #{@z}]"
  end
  def to_a
    return [@x, @y, @z]
  end
end

class LuxColor < LuxType
  attr_accessor :value
end

class LuxString < LuxType
  attr_accessor :value
end

###### -- groupings -- ######
class LuxObject
  attr_reader :name, :elements
  def initialize(name, *elements)
    @name = name
    @elements = elements #array of elements
  end
  def export
    export_str = @name
    for e in @elements
      export_str += " " + e.export #watch out for spaces with lux importing
    end
    return export_str
  end
end

######## -- Settings/export Secific -- #########
# generate types with ui updating properties?

class LuxSelection
  #usefull for value in lightgroup and lightsource and many others
  attr_reader :name, :choices
  attr_accessor :selection, :children
  def initialize(name, choices=[],default_choice=0)
    @name = name
    @choices = choices
    @selection = choices[default_choice]
  end
  def add_choice(choice)
    @choices.push(choice)
  end
  def create_choice(name, children=[])
    @choices.push(LuxChoice.new(name, children))
    if not @selection
      @selection = choices[0]
    end
  end
  def export
    export_str = ""
    for choice in choices
      export_str += " " + choice.export + "\n\t\t"#todo: proper formatting
    end
    return export_str
  end
  #type conversion
  def to_s
    @selection
  end
  def to_a
    @choices
  end
  #accessibility
  def select(new_selection)
    if @choices.include?(new_selection)
      @selection = new_selection
    else
      #raise some kind of error
    end
  end
end

class LuxChoice
  attr_reader :name
  attr_accessor :children
  def initialize(name, children=[])
    @name = name
    if children.is_a?(Array) == false #allow simple creation of choice with one child
      children = [children]
    end
    @children = children #array
  end
  def add_child(child)
    @children.push(child)
  end
  def export
    export_str = "\"#{@name.to_s}\""
    for child in children
      export_str += " " + child.export
    end
    return export_str
  end
  def to_s
    return @name
  end
end

class Attribute
end


######## -- Material Specific -- ########

####### -- experimentation area -- #######

prop1 = LuxFloat.new('xwidth', 2)
prop2 = LuxFloat.new('ywidth', 2)

sel_menu = LuxSelection.new('Selection')
sel_menu.create_choice('mitchell', [prop1, prop2])

obj = LuxObject.new('PixelFilter', sel_menu)

print obj.export
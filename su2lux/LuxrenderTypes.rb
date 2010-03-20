######## -- Basic Types -- ############
class LuxType
  attr_reader :type_str, :name
  def export(luxtype_object)
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
end

class LuxInt < LuxNumber
  def initialize(name, value=0)
    @name = name
    @value = n.to_i #add check if integer or number, convert if other number.
    @type_str = "integer"
  end
  def export
    super(self)
  end
end

class LuxFloat  < LuxNumber
  def initialize(name, value=0.0)
    @name = name
    @value = n.to_f
    @type_str = "float"
  end
  def export
    super(self)
  end
end

class LuxBool < LuxType
  def initialize(name, value)
    @name = name
    @value = value #todo: add check for boolean
    @type_str = "bool"
  end
  def export
    super(self)
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
  def export()
    #of the form:
    #"vector sundir" [-0.423824071310226 -0.772439983723215 0.472979521886207]
    return "\"#{@type_str} #{@name}\" [#{@x.to_s} #{@y.to_s} #{@z.to_s}]"
  end
end

class LuxColor < LuxType
  attr_accessor :value
end

class LuxString < LuxType
  attr_accessor :value
end


######## -- Settings Secific -- #########
# generate types with ui updating properties?

class LuxSelection
  #usefull for lightgroup and lightsource and many others
end

######## -- Material Specific -- ########


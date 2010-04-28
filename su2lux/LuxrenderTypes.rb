require "su2lux\\LuxrenderAttributeDictionaries.rb"

######## -- Basic Types -- ############
class LuxType
  attr_reader :type_str, :id, :name
  attr_accessor :parent
  def initialize(id, name=id, parent=nil)
    @id = id
    @parent = parent
    @name = name
  end
  def attribute_init(parent) #see LuxNumber for explanation
    @parent = parent
  end
  
  def attribute_key
    if @parent
      if @parent.respond_to?("attribute_key")
         return @parent.attribute_key + "->" + @id.to_s
      else
        return @parent.id.to_s + "->" + @id.to_s
      end
    else
      return @id
    end
  end
  
  def export#todo: add another argument with tab level or use a singleton
    #of the form:
    #"bool directsampleall" ["true"]
    #"float eyerrthreshold" [0.000000]
    return "\"#{@type_str} #{@id}\" [#{self.value.to_s}]"
  end
  def html 
    #needs fixing - needs a way to convert object types
    #into strings to recognise (use path as the string)
    if self.value.is_a? LuxSelection
      return self.value.html
    end
  end
  
  def html_update_cmds(key=self.attribute_key, val=self.value)#will probably turn into fully fledged thing (unless other design idea pops up!)
    if val.is_a? LuxSelection
      puts self.parent.attribute_key
      key = val.attribute_key
      val = val.value.attribute_key
      val = "'#{val}'"
      cmd = ["$('##{rb_to_js_path(key)}').val(#{rb_to_js_path(val.to_s)});"]
      puts cmd
      return cmd
    end
    cmd = ["$('##{rb_to_js_path(key)}').val(#{rb_to_js_path(val.to_s)});"]
    #puts cmd
    return cmd
  end
  
  def to_s
    return @id.to_s
  end
end #end LuxType

class LuxNumber < LuxType
  def initialize(id, value, name=id, parent=nil)
    super(id, name, parent)
    @init_value = value
  end
  def attribute_init(parent) 
    """allows value to be set after parent has been found so 
    that the attribute dictionary key can be complete.
    """
    @parent = parent
    if @init_value.is_a? LuxSelection
      @init_value.attribute_init
    end
    self.value = @init_value
  end
 def deep_copy()
    if @init_value.class == LuxSelection
      new_copy = self.class.new(@id,@init_value.deep_copy(),@name)
    else
      new_copy = self.class.new(@id,@init_value, @name)
    end
    return new_copy
  end
  
  def value=(v)
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    #will have to think of a way to make it work for materials as well
    @lrsd.map_object_value(self, v)
    #puts @lrsd[self.attribute_key]
    #puts self.attribute_key
  end

  def html
    #### TEXT INPUT ####
    html_str = ""
    html_str += "<td align=\"left\">#{@name}:</td>\n" 
    html_str += "<td align=\"right\"><input type='text' id=\"#{rb_to_js_path(self.attribute_key)}\" size=\"2\"></td>"
  return html_str
  end
  #type conversion
  def to_f
    self.value.to_f
  end
  def to_i
    self.value.to_i
  end
  def to_s
    self.value.to_s
  end
end #end LuxNumber

class LuxInt < LuxNumber
  def initialize(id, value=0, name=id, parent=nil)
    value = value.to_i #add check if integer or number, convert if other number.
    super(id, value, name, parent)
    @type_str = 'integer'
  end
  def value
    @lrsd = AttributeDic.spawn($lrsd_name) #unless @lrsd
    return @lrsd.str_value(self).to_i
  end
end #end LuxInt

class LuxFloat  < LuxNumber
  def initialize(id, value=0.0, name=id, parent=nil)
    value = value.to_f
    super(id, value, name, parent)
    @type_str = 'float'
  end
  def value
    lrsd = AttributeDic.spawn($lrsd_name)
    return lrsd.str_value(self).to_f
  end
end #end LuxFloat

class LuxBool < LuxType
  attr_accessor :value
  def initialize(id, value=true, name=id, parent=nil)
    value = value #todo: add check for boolean
    super(id, name, parent)
    @init_value = value
    @type_str = 'bool'
  end
  def attribute_init(parent)
    @parent = parent
    self.value = @init_value
  end

  def bool?(value)
    if value.to_s == "true" or value.to_s == "false"
      return true
    else
      return false
    end
  end
  def value=(v)
    if bool?(v)
      @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
      @lrsd.map_object_value(self, v)
    else
      raise "Value not a boolean"
    end
  end
  
  def value
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    value = @lrsd.str_value(self) #keeps yielding nil! singleton not working
    if value == "true"
      return true
    end
    if value == "false"
      return false
    end
    raise "Error with getting boolean"
  end
  
  def export
    return "\"#{@type_str} #{@id}\" [\"#{self.value.to_s}\"]"
  end
  def html
    #### CHECKBOX INPUT ####
    html_str = ""
    html_str += "<td align=\"left\">#{@name}:</td>\n" 
    html_str += "<td align=\"right\"><input type=\"checkbox\" id=\"#{rb_to_js_path(self.attribute_key)}\" value=\"#{@value}\"></td>"
    return html_str
  end
  def html_update_cmds(key=self.attribute_key, val=self.value)#will probably turn into fully fledged thing (unless other design idea pops up!)
    cmds = []
    cmds.push("$('##{rb_to_js_path(key)}').attr('checked', #{val});")
    #SU2LUX.p_debug cmds[0]
    cmds.push("checkbox_expander('#{id}');")
    #SU2LUX.p_debug cmds[1]
    return cmds
  end
  #type conversion
  def to_s
    self.value.to_s
  end
  def to_i
    if self.value == true
      return 1
    else
      return 0
    end
  end
end #end LuxBool

class LuxVector < LuxType
  attr_accessor :x, :y, :z
  def initialize(id, vector_array=[0,0,0], name=id, parent=nil)
    super(id, name, parent)
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
  def initialize(id, value="", name=id, parent=nil)
    super(id, name, parent)
    @init_value = value
    @type_str = 'string'
  end
  def attribute_init(p)
    @parent = p
    @init_value.attribute_init(self)
    self.value = @init_value
    if self.value.respond_to?("attribute_key")
      #puts self.value.attribute_key
    end
  end
  def deep_copy()
    if @init_value.class == LuxSelection
      new_copy = self.class.new(@id,@init_value.deep_copy(),@name)
    else
      new_copy = self.class.new(@id,self.value.dup, @name)
    end
    return new_copy
  end
  
  def value=(v)
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    #will have to think of a way to make it work for materials as well
    @lrsd.map_object_value(self, v)
    #puts @lrsd[self.attribute_key]
    #puts self.attribute_key
  end
  
  def value
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    return @lrsd.obj_value(@lrsd.str_value(self))
  end

  def export
    if self.value.is_a? LuxSelection
      return "\"#{@type_str} #{@id}\" [\"#{self.value.value.id}\"]"
    else
      return "\"#{@type_str} #{@id}\" [\"#{self.value}\"]"
    end
  end
  def to_s
#    if self.value.is_a? LuxSelection
#      return self.value.value.id
#    else
#      return self.value
#    end
    return self.value
  end
end #end LuxString

###### -- groupings -- ######
class LuxObject
  attr_reader :id, :elements, :name
  attr_accessor :parent
  def initialize(id, elements=[], name=id, parent=nil)
    puts name
    @id = id
    @name = name
    if elements.is_a?(Array) == false #allow simple creation of choice with one child
      elements = [elements]
    end
    @elements = elements #array of elements
    @parent = parent
  end
  def attribute_init(p)
    #only happens when the object's parent calles attribute_init (which is in turn
    #called by the parent at the top of the pyramid.
    @parent = p
    for element in @elements
      element.attribute_init(self)
    end
  end
  def value
    return @elements[0]
  end
  def export
    export_str = @name
    for e in @elements
      export_str += " " + e.export + "\n"#watch out for spaces with lux importing
    end
    return export_str
  end

  def [](element_id)
    for element in @elements
      return element if element.id == element_id
    end
  end
  def each
    if block_given?
      for element in @elements
        yield element
      end
    else
      raise "no block given"
    end
  end

  def add_element!(new_element)
    @elements.push(new_element)
    #make sure LuxSelection is at the top of the tree before working
    #out the attribute_keys and assigning variables
  end
  
  def to_s
    return @id
  end
end #end LuxObject

######## -- Settings/export Secific -- #########
# generate types with ui updating properties?

class LuxSelection
  #usefull for value in lightgroup and lightsource and many others
  attr_reader :id, :choices, :name, :value
  attr_accessor :selection, :children, :parent
  def initialize(id, choices=[], name=id, default_choice=0, parent=nil)
    @id = id
    @name = name
    @choices = choices
    @default_choice = default_choice
    @init_selection = choices[default_choice]
    @parent = parent
  end
  def attribute_init(p)
    #only happens when the selection's parent calles attribute_init (which is in turn
    #called by the parent at the top of the pyramid.
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    @parent = p
    for choice in @choices
      choice.attribute_init(self)
    end
    self.selection = @init_selection
    #puts "self: #{@lrsd.obj_value(self.attribute_key).class} selection: #{@lrsd.obj_value(@init_selection.attribute_key).class}"
  end
  def attribute_key
    #todo: return selection id as value for attribute_key
    if @parent
      if @parent.respond_to?("attribute_key")
         return @parent.attribute_key + "->" + @id.to_s
      else
        return @parent.id.to_s + "->" + @id.to_s
      end
    else
      return @id
    end
  end
  def deep_copy()
    new_copy = LuxSelection.new(@id, choices=[], @name, @default_choice)
    for choice in @choices
      new_copy.add_choice!(choice.deep_copy())
    end
    return new_copy
  end
  def selection=(choice)
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    @lrsd.map_object_value(self, choice)
  end
  def selection
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    if self.id == "accelerator_type"
      #puts "Selection: #{@lrsd.str_value(self).nil? ? "nil" : @lrsd.str_value(self)}"
    end
    return @lrsd.obj_value(@lrsd.str_value(self))
  end
  def value=(v)#expose a common interface for recursive stuff
    self.selection = v
  end
  def value
    return self.selection
  end

  def add_choice!(choice)
    if choice.is_a? LuxChoice
      #make sure LuxSelection is at the top of the tree before working
      #out the attribute_keys and assigning variables
      @choices.push(choice)
      @init_selection = @choices[0] if @init_selection.nil?
    else
     #raise error if choice not LuxChoice object
    end
  end
  
  def create_choice!(id, children=[])
    choice = LuxChoice.new(id, children, parent=self)
    #make sure Selection is at the top of the
    #tree before creating attribute_key
    @choices.push(choice)
    #@choices.each {|c| puts c}
    #puts self.selection
    @init_selection = @choices[0] #if @init_selection.nil?
  end 
  
  def export
    #puts "Error ID: #{self.id}"
    export_str = self.selection.export + "\t\t"#todo: proper formatting
    return export_str
  end
  
  def html
    #### TABLE COLUMN ####
    html_str = "\n"
    html_str << "<td>"
    
    #puts self.attribute_key
    #### LABEL ####
    html_str << "\n"
    html_str << "<span class=\"label\">#{@name}:</span>"
    
    #### SELECT ####
    html_str << "\n"
    if @choices.length > 0
      html_str << "<select class=\"select_collapse\" id=\"#{rb_to_js_path(self.attribute_key)}\">"
    else
      html_str << "<select id=\"#{rb_to_js_path(self.attribute_key)}\">"
    end
    
    #### OPTIONS ####
    for choice in @choices
      html_str << "\n" + choice.html
    end
    
    #### END SELECT ####
    html_str << "\n"
    html_str << "</select>"
    
    for choice in @choices
      #puts "  choice: #{choice}"
        #### DIV ####
        html_str << "\n"
        html_str << "<div id=\"#{rb_to_js_path(choice.attribute_key)}\" class=\"collapse\">"
        
        for child in choice.children
          #### EMBEDDED CHILD TABLE ####
          html_str << "\n"
          html_str << "<table>"
          html_str << "\n"
          html_str << "<tr>"
          #puts "    child: #{child.class}"
          #### PROPERTY ####
          html_str << "\n"
          html_str << child.html
          #### END EMBEDDED CHILD TABLE ####
          html_str << "\n"
          html_str << "</tr>"
          html_str << "\n"
          html_str << "</table>"
        end
        
        #### END DIV ####
        html_str << "\n"
        html_str << "</div>"
    end
    
    #### END TABLE  COLUMN ####
    html_str << "\n"
    html_str << "</td>"
    
    return html_str
  end
  def html_update_cmds(key=self.attribute_key, val=self.value)
    return ["$('##{rb_to_js_path(key)}').val('#{rb_to_js_path(val.attribute_key)}');"]
  end
  
  
  #type conversion
  def to_s
    self.attribute_key
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
  def each
    if block_given?
      for choice in @choices
        yield choice
      end
    else
      raise "no block given"
    end
  end

  def select!(new_selection_id) #not really consistent yet
    for c in @choices
      if c.id == new_selection_id
        self.selection = c
        return
      end
    end
    raise "unable to select: #{new_selection_id}"
  end
end #end LuxSelection

class LuxChoice
  attr_reader :id, :name
  attr_accessor :children, :parent
  def initialize(id, children=[], name=id, parent=nil)
    @id = id
    @name = name
    if children.is_a?(Array) == false #allow simple creation of choice with one child
      children = [children]
    end
    @children = children #array
    @parent = parent
  end
  def attribute_init(p)
    #only happens when the choice's parent calles attribute_init (which is in turn
    #called by the parent at the top of the pyramid.
    @lrsd = AttributeDic.spawn($lrsd_name) unless @lrsd
    @parent = p
    for child in @children
      child.attribute_init(self)
    end
    @lrsd.add_obj_reference(self)
  end
  def attribute_key
    if @parent
      if @parent.respond_to?("attribute_key")
         return @parent.attribute_key + "->" + @id.to_s
      else
        return @parent.id.to_s + "->" + @id.to_s
      end
    else
      return @id
    end
  end
  def deep_copy()
    new_copy = LuxChoice.new(@id, [], @name)
    for child in @children #todo: implement deep copy for all types of children!!!!!!!
      new_copy.add_child!(child.deep_copy())
    end
    return new_copy
  end

  def add_child!(child)
    #make sure that this is at the top of the pyramid before working out the
    #attribute_key for the child
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
    html_str = "<option value=\"#{rb_to_js_path(self.attribute_key)}\">#{@id}</option>"
    #todo: @name is being interfered with somewhere
    
    return html_str
  end

  def [](child_id)
    for child in @children
      return child if child.id == child_id
    end
  end
  def each
    if block_given?
      for child in @children
        yield child
      end
    else
      raise "no block given"
    end
  end

  def to_s
    return self.attribute_key
  end
end #end LuxChoice

class Attribute
  attr_reader :type_str, :id, :name
  def initialize(id, type_str='string', val="", name=id)
    @id = id
    self.value = val
    @name = name
    @type_str = type_str
    @parent = nil
  end
  def attribute_init(parent) #see LuxNumber for explanation
    @parent = parent
  end
  def attribute_key
    if @parent
      if @parent.respond_to?("attribute_key")
         return @parent.attribute_key + "->" + @id.to_s
      else
        return @parent.id.to_s + "->" + @id.to_s
      end
    else
      return @id
    end
  end
  def value=(val)
    @lrad = AttributeDic.spawn($lrad_name) unless @lrad
    @lrad.map_object_value(self, val)
  end
  def value
    @lrad = AttributeDic.spawn($lrad_name) unless @lrad
    val = @lrad.str_value(self)
    return cast(val, @type_str)
  end
  def html_update_cmds(key=self.attribute_key, val=self.value)#will probably turn into fully fledged thing (unless other design idea pops up!)
    if @type_str == 'rb_file_path'
      return ["$('##{rb_to_js_path(key)}').text('#{rb_to_js_file_path(val)}');"]
    else
      return ["$('##{rb_to_js_path(key)}').text('#{val}');"]
    end
  end
  def to_s
    self.attribute_key
  end
end #end Attribute

class SettingAttribute < Attribute
  def initialize(setting, name=nil)
    @id = setting.id
    @setting_ref = setting
    if name
      @name = name
    else
      @name = setting.name
    end
    @type_str = setting.type_str
    @parent = nil
  end
  def value=(val)
    @setting_ref.value=val
  end
  def value
    return @setting_ref.value
  end
  def html
    return @setting_ref.html
  end
end


##### -- export tools -- ##############
#this really belongs in Exporter.rb
#class Tbcnt
  ##keeps track of tabs when exporting to html or lxs
#end
def rb_to_js_path(path)
  return path.gsub(/>/, "-")
end

def js_to_rb_path(path)
  return path.gsub(/--/, "->")
end

def rb_to_js_file_path(path)
  return path.gsub(/\\/, "/")
end

def js_to_rb_file_path(path)
  return path.gsub(/\//, "\\")
end

######## -- Material Specific -- ########

####### -- Experimentation area -- #######

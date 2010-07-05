$lrsd_name = 'luxrender_settings'
$lrad_name = 'luxrender_attributes'


def cast(obj, newtype)
  case newtype
    when 'integer'
      return obj.to_i
    when 'string'
      return obj.to_s
    when 'float'
      return obj.to_f
    else
      return obj
  end
end

class SuAttributeDic
  def initialize(name)
    model = Sketchup.active_model
    @name = name
    @attribute_dictionary = model.attribute_dictionary(@name, true)
  end
  def []=(key, value)
    model = Sketchup.active_model
    model.set_attribute(@name, key, value)
  end
  def [](key)
    model = Sketchup.active_model
    return model.get_attribute(@name, key, nil)
  end
  def each
    @attribute_dictionary.each {|key, val| yield key, val}
  end
  def include_key?(find_key)
    self.each do |key, val|
      if find_key == key
        return true
      end
    end
    return false
  end
  def include?(key)
    return include_key?(key)
  end
end

#add the ability to have dicionaries that only sync/save periodically or when sketchup closes or when someone presses save on the settings or save on sketchup
#(this is why the two classes are seperated)

class AttributeDic  #a binding between 
  private_class_method :new #stuff to manage different dictionaries 
  @@attrdic = nil
  @@attrdics = {}
  attr_accessor :dic
  
  def AttributeDic::is_path?(path)
    if path.is_a? String
      return path =~ /->/ ? true : false
      
    else
      return false
    end
  end
  
  def initialize(name)
    @strdic = {} #main storage as strings
    @sustrdic = SuAttributeDic.new(name)
    @objdic = {} #references to objects
    @objtree = {} #object tree for tree construction
  end
  
  def AttributeDic::spawn(name=nil)
    #@@attrdics = {} unless @@attrdics
    return @@attrdic unless name #very important, settings will always
    #use the last accessed dictionary.
    if not @@attrdics.include?(name)
      @@attrdics[name] = new(name)
    end
    @@attrdic = @@attrdics[name]
    return @@attrdic
  end
  
  def include_path?(path)
    if AttributeDic::is_path?(path.to_s)
      return @strdic.include?(path.to_s)
    else
      raise "input is not a valid path"
    end
  end
  
  def value(key)
  end
  def map_attribute_key(attribute_key, value)
    if self.include_path? attribute_key
      @strdic[attribute_key] = value.to_s
      @objdic[attribute_key].value = value
    else
      raise "invalid or non existant object:" + attribute_key.to_s
    end
  end
  
  def map_object_value(obj, value)
    if self.compat_object(obj)
      key = obj.attribute_key
      @strdic[key] = value.to_s
      if @sustrdic.include?(key) and not @objdic[key] #will not exist on first call of this function
        #little trick to test whether value is already saved in sketchup document
        #and to use that value, instead of resetting it.
        @objdic[key] = obj
        obj.value = @sustrdic[key]
      else
        @sustrdic[key] = value.to_s
      end
      @objdic[key] = obj
    else
      raise "invalid obj type"
    end
  end
  
  def compat_object(obj)
    if obj.respond_to?("attribute_key") and obj.respond_to?("value")
      return true
    else
      return false
    end
  end
  
  def add_root(key, obj)
    obj.attribute_init(nil, self)
    @objtree[key] = obj
  end
  
  def root(key)
    return @objtree[key]
  end
  
  def []=(key, value)
    if AttributeDic::is_path?(key)
      @objdic[key].value = value
    else
      if self.compat_object(key)
        self.map_object_value(key, value)
      else
        if key.is_a? String
          if value.respond_to?("attribute_key")
            self.add_root(key, value)
          else
            raise "invalid value type: #{value.class}"
          end
        else
          raise "invalid key type: #{key.class}"
        end
      end
    end
  end
  
  def [](key)
    """This function only returns an object,
    who's value can be accessed with value
    
    the object is accessed using a key
    """
    if @objtree.include?(key)
      return @objtree[key]
    end
    
    if AttributeDic::is_path?(key)
      #puts "yay!!!" if key == "sampler->sampler_type" 
      if @objdic.include?(key)
        return @objdic[key]
      else
        raise "input is not a valid path: #{key}"
      end
    end
    
    if key.respond_to?("attribute_key") and key.respond_to?("value")
      return @objdic[key.attribute_key]
    else
      raise "input is not a valid path: #{key}"
    end
  end
  def str_value(key)
    if key.respond_to?("attribute_key") and key.respond_to?("value")
      value = @sustrdic[key.attribute_key]#@strdic[key.attribute_key]
      if key.respond_to?("type_str")
        converted_value = cast(value, key.type_str)
        return converted_value
      else
        return value
      end
    else
      raise "input is not a valid object"
    end
  end
  def obj_value(key)
    return @objdic[key] if AttributeDic::is_path?(key)
    if key.respond_to?("attribute_key") and key.respond_to?("value")
      return @objdic[key.attribute_key].value
    else
      raise "input is not a valid object: #{key}"
    end
  end
  def get_obj_from_obj(obj)
    if obj.respond_to?("attribute_key") and obj.respond_to?("value")
      @objdic.each_key {|v| puts v if v =~ /Accelerator->accelerator_type->tabreckdtree\Z/}#(@strdic[obj.attribute_key])
      return @objdic[@strdic[obj.attribute_key]]
    else
      raise "input is not a valid object"
    end
  end
  def add_obj_reference(obj)
    @objdic[obj.attribute_key] = obj
  end
  def each
    @objtree.each {|e| yield e}
  end
  def each_root
    @objtree.each_value {|v| yield v}
  end
  def each_obj
    @objdic.each_value {|o| yield o}
  end
  def each_obj_reference_key
    @objdic.each_key {|o| yield o}
  end
  def objdic
    @objdic
  end
  def strdic
    @strdic
  end
  def sustrdic
    @sustrdic
  end
  def include?(key)
    return @objdic.include?(key)
  end
  def export_dic_str
    file_str = ""
    arr1 = []
    arr2 = []
    @strdic.each_key do |key|
      val = @sustrdic[key]
      if not AttributeDic.is_path?(val.to_s)
        arr1.push "#{key}=#{val}\n"
      else
        arr2.push "#{key}=#{val}\n" 
      end
    end
    
    arr1.each {|line| file_str += line}
    file_str += "\n\n"
    arr2.each {|line| file_str += line}
    #puts file_str
    return file_str
  end
  def import_dic_str(file_str)
    self.clear
    file_str.each_line do |line|
      pair = line.split("=")
      id = pair[0]
      val = pair[1]
      @sustrdic[id] = val
    end
  end
  def import_dic_line(line)
    line.chomp!
    self.clear
    pair = line.split("=")
    id = pair[0]
    val = pair[1]
    @sustrdic[id] = val
  end
  def clear
  end
  def each_sustr
    @strdic.each_key do |key|
      yield @sustrdic[key]
    end
  end
  
end
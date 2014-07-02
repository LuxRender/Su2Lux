class LuxrenderAttributeDictionary

    #private_class_method :new

	#list of all possible dictionaries in use
	#@@dictionaries = {} # class variable
	#@@dictionary = {}   # the current working dictionary (class variable)

	##
	#
	##
	def initialize(model)
        @dictionaries = {}
        @dictionary = {}
        @model = model
	end #END initialize
	
	##
	#
	##
	def get_attribute(name, key, default)
		dictionary = self.choose(name)
		if ( dictionary.key? key)
			return dictionary[key]
		else
			return default
		end
	end # END get_attribute
	
	##
	#
	##
	def set_attribute(name, key, value)
        #puts "setting attribute, storing in SketchUp file"
        #puts "values:"
        #puts name
        #puts key
        #puts value
        #puts ""
		@model.start_operation("SU2LUX settings update", true, false, true)
		
		dictionary = self.choose(name)
		dictionary[key] = value
		@dictionaries[name] = dictionary
        @model.set_attribute(name, key, value) # store to model's attribute dictionary
		
		@model.commit_operation()
	end #END set_attribute
	
	##
	#
	##
	def choose(name)
		if (name.nil? or name.strip.empty?)
			return @dictionary
		end
		if ( ! @dictionaries.key? name)
			@dictionaries[name] = {}
		end
		@dictionary = @dictionaries[name]
		return @dictionary
	end #END choose
    
	def save_to_model(name)
        puts "attributedictionary running save_to_model for: " + name.to_s
		@dictionary = self.choose(name)
		if (self.modified?(name))
            puts "modified"
			@dictionary.each { |key, value|
                # puts key.to_s + " " + value.to_s
				@model.set_attribute(name, key, value)
			}
        else
            puts "not modified"
		end
	end #END save_to_model
    
	def load_from_model(name)
        #puts "running load_from model:"
		@dictionary = self.choose(name) # self is #<LuxrenderAttributeDictionary:.....>
		model_dictionary = @model.attribute_dictionary(name)
		if (model_dictionary)
            #puts "number of attribute dictionary items:"
            #puts model_dictionary.length
			@model.start_operation("SU2LUX load model data", true, false, true)
			model_dictionary.each { |key, value|
				puts "load_from_model updating attributes"
				self.set_attribute(name, key, value) # set, because we're taking values from the model's attribute dictionary
                                                     # and setting them in the (temporary) LuxRender attribute dictionary
			}
			@model.commit_operation()
			
			return true
		else
            #puts "dictionary does not exist"
			return false
		end
	end #END load_from_model
	
	def modified?(name)
		@dictionary = self.choose(name)
		@dictionary.each { |key, value|
			if (@model.get_attribute(name, key) != value)
                puts key.to_s + " has changed"
				return true;
			end
		}
		return false
	end #END modified?
	
	def list_dictionaries()
		puts @dictionaries.length
		keys = @dictionaries.keys
		keys.each{|k|
		puts "\n\n#{k}\n\n"
			puts @dictionaries[k].each{|kk,vv| puts "#{kk}=>#{vv}"}
		}
	end
	
	def list_properties()
		puts @dictionary.length
		theproperties = @dictionary.keys
		theproperties.each{|kk,vv|
			puts "#{kk} #{vv}"
		}
	end
	
end #END class Luxrender_Attribute_dictionary
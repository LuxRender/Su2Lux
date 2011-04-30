class LuxrenderAttributeDictionary

	private_class_method :new

	#list of all possible dictionaries in use
	@@dictionaries = {}
	#the current dictionary
	@@dictionary = {}

	##
	#
	##
	def initialize(name)
	end #END initialize
	
	##
	#
	##
	def LuxrenderAttributeDictionary::get_attribute(name, key, default)
		@@dictionary = self.choose(name)
		if ( ! @@dictionary[key].nil?)
			return @@dictionary[key]
		else
			return default
		end
	end # END get_attribute
	
	##
	#
	##
	def LuxrenderAttributeDictionary::set_attribute(name, key, value)
		@@dictionary = self.choose(name)
		@@dictionary[key] = value
	end #END set_attribute
	
	##
	#
	##
	private
	def LuxrenderAttributeDictionary::choose(name)
		if (name.nil? or name.strip.empty?)
			return @@dictionary
		end
		if (@@dictionaries[name].nil?)
			@@dictionaries[name] = @@dictionary
		else
			@@dictionary = @@dictionaries[name]
		end
		return @@dictionary
	end #END choose
	
	def LuxrenderAttributeDictionary::save_to_model(name)
		@@dictionary = self.choose(name)
		if (self.modified?(name))
			model = Sketchup.active_model
			@@dictionary.each { |key, value|
				model.set_attribute(name, key, value)
			}
		end
	end #END save_to_model
	
	def LuxrenderAttributeDictionary::load_from_model(name)
		@@dictionary = self.choose(name)
		model_dictionary = Sketchup.active_model.attribute_dictionary(name)
		if (model_dictionary)
			model_dictionary.each { |key, value|
				self.set_attribute(name, key, value)
			}
			return true
		else
			return false
		end
	end #END load_from_model
	
	def LuxrenderAttributeDictionary::modified?(name)
		model = Sketchup.active_model
		@@dictionary = self.choose(name)
		@@dictionary.each { |key, value|
			if (model.get_attribute(name, key) != value)
				return true;
			end
		}
		return false
	end #END modified?
	
end #END class Luxrender_Attribute_dictionary
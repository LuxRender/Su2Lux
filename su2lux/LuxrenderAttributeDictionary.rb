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
	end #END my_sel
	
end #END class Luxrender_Attribute_dictionary
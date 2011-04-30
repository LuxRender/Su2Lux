class OSSpecific

	attr_reader :variables
	alias_method :get_variables, :variables
	
	##
	#
	##
	def initialize
		@variables = {
			"default_save_folder" => ENV["USERPROFILE"],
			"luxrender_filename" => "luxrender.exe",
			"path_separator" => "\\"
		}
	end
	
	##
	#
	##
	def search_multiple_installations
		return nil
	end

end
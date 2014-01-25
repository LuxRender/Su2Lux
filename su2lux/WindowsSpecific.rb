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
            "file_appendix" => "/Contents/MacOS/luxrender",
            "luxconsole_filename" => "luxconsole.exe",
			"path_separator" => "\\",
			"material_preview_path" => ENV['APPDATA']+"\\"+"LuxRender\\",
            "settings_path" => ENV['APPDATA']+"\\"+"LuxRender\\LuxRender_settings_presets\\"
		}
	end
	
	##
	#
	##
	def search_multiple_installations
		return nil
	end

end
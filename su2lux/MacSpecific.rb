class OSSpecific

	attr_reader :variables
	alias_method :get_variables, :variables
	
	##
	#
	##
	def initialize
		@variables = {
			"default_save_folder" => File.expand_path("~"),
			"luxrender_filename" => "Luxrender.app/Contents/MacOS/Luxrender",
			"path_separator" => "/"
		}
	end
	
	##
	#
	##
	def search_multiple_installations
		luxrender_folder = []
		if (SU2LUX.get_os == :mac)
			start_folder = "/Applications"
			#start_folder = "C:\\Program Files"
			applications = Dir.entries(start_folder)
			applications.each { |app|
				luxrender_folder.push app if app =~ /luxrender/i
			}
			if luxrender_folder.length > 1
				paths = luxrender_folder.join("|")
				input = UI.inputbox(["folder"], [luxrender_folder[0]], [paths], "Choose Luxrender folder")
				luxrender_folder = input[0] if input
			elsif luxrender_folder.length == 1
				luxrender_folder = luxrender_folder[0]
			else
				return nil
			end
		end
		if luxrender_folder.empty?
			folder = nil
		else
			folder = start_folder + @variables["path_separator"] + luxrender_folder
		end
		return folder
	end # END search_multiple_installations

end
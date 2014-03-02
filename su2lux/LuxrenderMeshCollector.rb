class LuxrenderMeshCollector

	attr_reader :count_faces, :materials, :fm_materials, :model_textures, :texturewriter, :deferred_instances

	##
	#
	##
	def initialize(model_name, os_separator, instances)
		@model_name = model_name
		@os_separator = os_separator
		@parent_mat = []
		@fm_comp = []
		@materials = {}
		@fm_materials = {}
		@count_faces = 0
		@model_textures = {}
		@texturewriter = Sketchup.create_texture_writer
        @instance_counter_cache = Hash.new
        @deduplicate = instances
        @deferred_instances = Hash.new
        model_id = Sketchup.active_model.definitions.entityID
        @lrs = SU2LUX.get_lrs(model_id)
	end # END initialize
    
    #####################################################################
    ## method returns true if graph contains no further instances.
    ## These can safely be instanciated
    #####################################################################
    def instance_is_leaf(object)
        if !( object == Sketchup::ComponentInstance || object == Sketchup::Group )
            return true
        end
        object.definition.entities.each { | child |
            if child.class == Sketchup::ComponentInstance
                #UI.messagebox("Definition: #{object.definition.name} contains instances")
                return false
            end
            if child.class == Sketchup::Group
                child.entities.each { | grandchild |
                    if ! instance_is_leaf(grandchild)
                        return false
                        #UI.messagebox("Group failed on ")
                    end
                }
            end
        }
        #UI.messagebox("Component: #{object.definition.name} is a leaf node")
        return true
    end
    
    #####################################################################
    
    #####################################################################
    def instances_copies(object)
        if ! @instance_counter_cache.key?(object.definition.name)
            @instance_counter_cache[object.definition.name] = object.definition.instances.length
        end
        return @instance_counter_cache[object.definition.name]
    end  
    
	##
	# sort faces by material
	##
	def collect_faces(object, trans)
        
        # check what kind of input we are dealing with
		if object.class == Sketchup::ComponentInstance
			entity_list=object.definition.entities
		elsif object.class == Sketchup::Group
			entity_list=object.entities
		else
			entity_list=object
		end

		# display progress on status bar
		text=""
		text="Component: " + object.definition.name if object.class == Sketchup::ComponentInstance
		text="Group" if object.class == Sketchup::Group
		Sketchup.set_status_text "Collecting Faces - Level #{@parent_mat.size} - #{text}"

		for e in entity_list
            # groups will recursively call collect_faces method through get_inside, storing their textures in the process
			if (e.class == Sketchup::Group and e.layer.visible?)
				get_inside(e,trans,false)
			end
			if (e.class == Sketchup::ComponentInstance and e.layer.visible? and e.visible?)
                # if advanced behavior is off do old behaviour
                # else only if instance has only 1 copy and instance does not contain instances do old behaviour
                if ( @deduplicate == false || ( instances_copies(e) == 1 ||  ( !instance_is_leaf(e) ) ) )
                    get_inside(e,trans,e.definition.behavior.always_face_camera?) # e,trans, fm_component?
                else # ELSE store instance transformation in hash,array for wrting out later
                    name = e.definition.name
                    newArray = @deferred_instances.fetch(name, Array.new).push(trans * e.transformation)
                    @deferred_instances.store(name,newArray)
                end
            end
			if (e.class == Sketchup::Face and e.layer.visible? and e.visible?)
				face_properties=find_face_material(e)
				mat = face_properties[0]
				uvHelp = face_properties[1]
				mat_dir = face_properties[2]
                matname = face_properties[3]
                distortion = face_properties[4]
                if (distortion)
                    matname = matname + SU2LUX::SUFFIX_DISTORTED_TEXTURE
                end

				if @fm_comp.last==true
					(@fm_materials[matname] ||= []) << [e,trans,uvHelp,mat_dir,mat,nil,distortion]
                    #puts "adding data to @fm_materials:"
                    #puts matname
                    #puts e,trans,uvHelp,mat_dir,mat
                    #puts ""
				else
                    #puts "adding data to @materials"
					(@materials[matname] ||= []) << [e,trans,uvHelp,mat_dir,mat,nil,distortion]
				end
				@count_faces+=1
			end
		end
	end # END collect_faces

	
	##
	# private method
	##
	def find_face_material(e)
		uvHelp=nil
		mat_dir=true
        distortion=nil
        # if material exists, use it
		if e.material!=nil
			mat=e.material
        # otherwise, check back material, parent material or ultimately create new default material
		else
			if e.back_material!=nil
				mat=e.back_material
				mat_dir=false
			else
				if @parent_mat.last!=nil
					mat=@parent_mat.last
				else
					mat = Sketchup.active_model.materials[SU2LUX::FRONT_FACE_MATERIAL]
					mat = Sketchup.active_model.materials.add SU2LUX::FRONT_FACE_MATERIAL if mat.nil?
                    scene_id = Sketchup.active_model.definitions.entityID
                    mateditor = SU2LUX.get_editor(scene_id,"material")
                    mateditor.find(SU2LUX::FRONT_FACE_MATERIAL) # creates LuxRender material
					front_color = Sketchup.active_model.rendering_options["FaceFrontColor"]
					scale = 0.8 / 255.0
					mat.color = Sketchup::Color.new(front_color.red * scale, front_color.green * scale, front_color.blue * scale)
				end
			end
		end
        matname=mat.name
        # store texture if material has any
		if (mat.respond_to?(:texture) and mat.texture !=nil)
            #puts "material responds to texture"
            puts "getting uv coordinates using store_textured_entities function"
			ret=store_textured_entities(e,mat,mat_dir)
			mat=ret[0]
			uvHelp=ret[1]
            matname=ret[3]
            distortion=ret[4]
        else
            #puts "material does not respond to texture"
		end
		return [mat,uvHelp,mat_dir,matname,distortion]
	end # END find_face_material
	 
	##
	# private method
	##
	def get_inside(e,trans,face_me)
		@fm_comp.push(face_me)
        puts "@fmcomp length: " + @fm_comp.length.to_s
		if e.material != nil
			mat = e.material
			@parent_mat.push(e.material)
            if (mat.respond_to?(:texture) and mat.texture!=nil)
                store_textured_entities(e,mat,true)
            end
		else
			@parent_mat.push(@parent_mat.last)
		end
		collect_faces(e, trans*e.transformation)
		@parent_mat.pop
		@fm_comp.pop
	end # END get_inside

	##
	#
	##
	def store_textured_entities(e,mat,mat_dir)
        verb=false #verbosity
		tw=@texturewriter
		#puts "MATERIAL: " + mat.display_name if verb==true
		uvHelp=nil
        distorted=nil
		mat_name=mat.display_name.delete"<>[]" #TODO rename material name

        # process groups and components
		if (e.class==Sketchup::Group or e.class==Sketchup::ComponentInstance) and mat.respond_to?(:texture) and mat.texture!=nil
				txcount=tw.count
				handle=tw.load e
				tname=get_texture_name(mat_name,mat)
                if (txcount!=tw.count and @model_textures[mat_name]==nil) # material has textures and has not yet been processed
                    @model_textures[mat_name]=[0,e,mat_dir,handle,tname,mat,nil]
                end
				puts "GROUP #{mat_name} H:#{handle}\n#{@model_textures[mat_name]}" if verb==true
		end

        # process individual faces, store texture info in @model_textures
		if e.class==Sketchup::Face
			if  @lrs.exp_distorted==false # do not export distorted textures
				handle = tw.load(e,mat_dir)
				tname=get_texture_name(mat_name,mat)
                if @model_textures[mat_name]==nil
                    @model_textures[mat_name]=[0,e,mat_dir,handle,tname,mat,nil]
                end
			else
                distorted=texture_distorted?(e,mat_dir) # only true with non-standard (yellow) texture distortion
				txcount=tw.count
				handle = tw.load(e,mat_dir)
				tname=get_texture_name(mat_name,mat)
				if txcount!=tw.count # texture was not present in texturewriter
					if @model_textures[mat_name]==nil
						if distorted==true
							uvHelp=get_UVHelp(e,mat_dir)
							puts "FIRST DISTORTED FACE #{mat_name} #{handle} #{e}" if verb==true
						else
							uvHelp=nil
							puts "FIRST FACE #{mat_name} #{handle} #{e}" if verb==true
						end
						@model_textures[mat_name]=[0,e,mat_dir,handle,tname,mat,distorted]
					else
						ret=add_new_texture(mat_name,e,mat,handle,mat_dir,distorted)
						mat_name=ret[0]
						uvHelp=ret[1]
						puts "DISTORTED FACE #{mat_name} #{handle} #{e}" if verb==true
					end
                else # texture was already present in texturewriter
					@model_textures.each{|key, value|
						if handle==value[3]
							mat_name=key
							uvHelp=get_UVHelp(e,mat_dir) if distorted==true
							puts "OLD MAT FACE #{key} #{handle} #{e} #{uvHelp}" if verb==true
						end
                    }
				end
			end
		end
		puts "FINAL: #{[mat_name,uvHelp,mat_dir].to_s}" if verb==true
		return [mat,uvHelp,mat_dir,mat_name,distorted]
	end # END store_textured_entities

	##
	#
	##
	def add_new_texture(mat_name,e,mat,handle,mat_dir,distorted)
		state=@model_textures[mat_name]
		number=state[0]=state[0]+1
		mat_name=mat_name+number.to_s
		tname=get_texture_name(mat_name,mat)
		uvHelp=get_UVHelp(e,mat_dir)
		@model_textures[mat_name]=[number,e,mat_dir,handle,tname,mat,distorted]
        puts "new texture created, mat_name is: " + mat_name
        #puts @model_textures[mat_name][0]
        #puts @model_textures[mat_name][1]
        #puts @model_textures[mat_name][2]
        #puts @model_textures[mat_name][3]
        #puts @model_textures[mat_name][4]
        #puts @model_textures[mat_name][5]
	return [mat_name,uvHelp]
	end # END add_new_texture

	##
	#
	##
	def get_texture_name(name,mat)
		ext=mat.texture.filename
        
        # test/todo 2014: return proper texture name instead of name based on file name
        # name=name.split("\\").last # fix for textures that have a Windows file path as their name
        
		ext=ext[(ext.length-4)..ext.length]
		ext=".png" if (ext.upcase ==".BMP" or ext.upcase ==".GIF" or ext.upcase ==".PNG") #Texture writer converts BMP,GIF to PNG
		ext=".tif" if ext.upcase=="TIFF"
		ext=".jpg" if ext.upcase==".JPG"
		ext=".jpg" if ext.upcase[0]!=46 # 46 = dot; so add .jpg if no extension is found
		s=name+ext
		return s
	end # END get_texture_name
    
    
    

	##
	#
	##
	def texture_distorted?(e,mat_dir)
		distorted = false
		if e.valid? and e.is_a? Sketchup::Face
			for v in e.vertices
				p = v.position
				uvHelp = get_UVHelp(e, mat_dir)
				uvq = mat_dir ? uvHelp.get_front_UVQ(p) : uvHelp.get_back_UVQ(p)
                #puts "uvq:"
                #puts uvq
				if ( uvq and (uvq.z.to_f - 1).abs > 1e-5)
					distorted = true
                    return distorted
					break
				end
			end
		end
        
		return distorted
	end # END texture_distorted?

	##
	#
	##
	def get_UVHelp(e,mat_dir)
        # puts "getting SketchUp UVHelper"
		uvHelp = e.get_UVHelper(mat_dir, !mat_dir, @texturewriter) # gets SketchUp UVHelper
        return uvHelp
	end # END get_UVHelp

end # END class MeshCollector
class MeshCollector

	attr_reader :count_faces, :materials, :fm_materials, :model_textures, :texturewriter

	##
	#
	##
	def initialize(model_name, os_separator)
		@model_name = model_name
		@os_separator = os_separator
		@parent_mat = []
		@fm_comp = []
		@materials = {}
		@fm_materials = {}
		@count_faces = 0
		@model_textures = {}
		@texturewriter = Sketchup.create_texture_writer
	end # END initialize

	##
	# collect entities to an array
	##
	def collect_faces(object, trans)

		if object.class == Sketchup::ComponentInstance
			entity_list=object.definition.entities
		elsif object.class == Sketchup::Group
			entity_list=object.entities
		else
			entity_list=object
		end

		# p "entity count="+entity_list.count.to_s
		text=""
		text="Component: " + object.definition.name if object.class == Sketchup::ComponentInstance
		text="Group" if object.class == Sketchup::Group
		
		Sketchup.set_status_text "Collecting Faces - Level #{@parent_mat.size} - #{text}"

		for e in entity_list
			
			if (e.class == Sketchup::Group and e.layer.visible?)
				get_inside(e,trans,false) #e,trans,false - not FM component
			end
			if (e.class == Sketchup::ComponentInstance and e.layer.visible? and e.visible?)
				get_inside(e,trans,e.definition.behavior.always_face_camera?) # e,trans, fm_component?
			end
			if (e.class == Sketchup::Face and e.layer.visible? and e.visible?)
				face_properties=find_face_material(e)
				mat=face_properties[0]
				uvHelp=face_properties[1]
				mat_dir=face_properties[2]

				if @fm_comp.last==true
					(@fm_materials[mat] ||= []) << [e,trans,uvHelp,mat_dir]
				else
					(@materials[mat] ||= []) << [e,trans,uvHelp,mat_dir] #if (@animation==false or (@animation and @export_full_frame))
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
		if e.material!=nil
			mat=e.material
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
					front_color = Sketchup.active_model.rendering_options["FaceFrontColor"]
					scale = 0.8 / 255.0
					mat.color = Sketchup::Color.new(front_color.red * scale, front_color.green * scale, front_color.blue * scale)
				end
			end
		end

		if (mat.respond_to?(:texture) and mat.texture !=nil)
			ret=store_textured_entities(e,mat,mat_dir)
			mat=ret[0]
			uvHelp=ret[1]
		end

		return [mat,uvHelp,mat_dir]
	end # END find_face_material
	 
	##
	# private method
	##
	def get_inside(e,trans,face_me)
		@fm_comp.push(face_me)
		if e.material != nil
			mat = e.material
			@parent_mat.push(e.material)
			store_textured_entities(e,mat,true) if (mat.respond_to?(:texture) and mat.texture!=nil)
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

		verb=false

		tw=@texturewriter

		puts "MATERIAL: " + mat.display_name if verb==true
		uvHelp=nil
		number=0
		mat_name=mat.display_name.delete"<>[]" #TODO rename material name

		if (e.class==Sketchup::Group or e.class==Sketchup::ComponentInstance) and mat.respond_to?(:texture) and mat.texture!=nil
				txcount=tw.count
				handle=tw.load e
				tname=get_texture_name(mat_name,mat)
				@model_textures[mat_name]=[0,e,mat_dir,handle,tname,mat] if (txcount!=tw.count and @model_textures[mat_name]==nil)
				puts "GROUP #{mat_name} H:#{handle}\n#{@model_textures[mat_name]}" if verb==true
		end

		if e.class==Sketchup::Face

			if  @exp_distorted==false
				handle = tw.load(e,mat_dir)
				tname=get_texture_name(mat_name,mat)
				@model_textures[mat_name]=[0,e,mat_dir,handle,tname,mat] if @model_textures[mat_name]==nil
				return [mat_name,uvHelp,mat_dir]
			else
				distorted=texture_distorted?(e,mat,mat_dir)# if false
				txcount=tw.count
				handle = tw.load(e,mat_dir)
				tname=get_texture_name(mat_name,mat)

				if txcount!=tw.count #if new texture added to tw

					if @model_textures[mat_name]==nil
						if distorted==true
							uvHelp=get_UVHelp(e,mat_dir)
							puts "FIRST DISTORTED FACE #{mat_name} #{handle} #{e}" if verb==true
						else
							unHelp=nil
							puts "FIRST FACE #{mat_name} #{handle} #{e}" if verb==true
						end
						@model_textures[mat_name]=[0,e,mat_dir,handle,tname,mat]
					else
						ret=add_new_texture(mat_name,e,mat,handle,mat_dir)
						mat_name=ret[0]
						uvHelp=ret[1]
						puts "DISTORTED FACE #{mat_name} #{handle} #{e}" if verb==true
					end
				else
					@model_textures.each{|key, value|
						if handle==value[3]
							mat_name=key
							uvHelp=get_UVHelp(e,mat_dir) if distorted==true
							puts "OLD MAT FACE #{key} #{handle} #{e} #{uvHelp}" if verb==true
						end}
				end
			end
		end
		puts "FINAL: #{[mat_name,uvHelp,mat_dir].to_s}" if verb==true
		return [mat_name,uvHelp,mat_dir]
	end # END store_textured_entities

	##
	#
	##
	def add_new_texture(mat_name,e,mat,handle,mat_dir)
		state=@model_textures[mat_name]
		number=state[0]=state[0]+1
		mat_name=mat_name+number.to_s
		tname=get_texture_name(mat_name,mat)
		uvHelp=get_UVHelp(e,mat_dir)
		@model_textures[mat_name]=[number,e,mat_dir,handle,tname,mat]
	return [mat_name,uvHelp]
	end # END add_new_texture

	##
	#
	##
	def get_texture_name(name,mat)
		ext=mat.texture.filename
#		p 'ext '+ext
		ext=ext[(ext.length-4)..ext.length]
		ext=".png" if (ext.upcase ==".BMP" or ext.upcase ==".GIF" or ext.upcase ==".PNG") #Texture writer converts BMP,GIF to PNG
		ext=".tif" if ext.upcase=="TIFF"
		ext=".jpg" if ext.upcase[0]!=46 # 46 = dot
		s=name+ext
		#s=@textures_prefix+@model_name+@os_separator+s
		s=SU2LUX::PREFIX_TEXTURES+@model_name+"/"+s
#		p "texture name "+s
		return s
	end # END get_texture_name

	##
	#
	##
	def texture_distorted?(e,mat,mat_dir)
		distorted = false
		if e.valid? and e.is_a? Sketchup::Face
			for v in e.vertices
				p = v.position
				uvHelp = get_UVHelp(e, mat_dir)
				# uv = uvHelp.get_front_UVQ(p) if mat_dir==true
				# uv = uvHelp.get_back_UVQ(p) if mat_dir==false
				uvq = mat_dir ? uvHelp.get_front_UVQ(p) : uvHelp.get_back_UVQ(p)
				# if ( uvq and ((uvq.z.to_f)*10000000).round != 10000000)
				if ( uvq and (uvq.z.to_f - 1).abs > 1e-5)
					distorted = true
					break
				end
			end
		end
		return distorted
	
		# distorted=false
		# temp_tw=Sketchup.create_texture_writer
		# model = Sketchup.active_model
		# entities = model.active_entities
		# model.start_operation "Group" #For Undo
		# group=entities.add_group
		# group.material = mat
		# g_handle=temp_tw.load(group)
		# temp_handle=temp_tw.load(e,mat_dir)
		# entities.erase_entities group
		# Sketchup.undo
		# distorted=true if temp_handle!=g_handle
		# temp_tw=nil
		# return distorted
	end # END texture_distorted?

	##
	#
	##
	def get_UVHelp(e,mat_dir)
		uvHelp = e.get_UVHelper(mat_dir, !mat_dir, @texturewriter)
	end # END get_UVHelp

end # END class MeshCollector
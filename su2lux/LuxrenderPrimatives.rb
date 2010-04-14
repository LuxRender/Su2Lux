model = Sketchup.active_model
entities = model.entities
selection = model.selection


class MyTool
  def initialize
    @ip = nil
    @old_ip = nil
    @curr_ip = nil
    @state = nil
    @drawn = false
    self.reset
  end
  def reset(view=nil)
    @ip = Sketchup::InputPoint.new
    @old_ip = Sketchup::InputPoint.new
    @curr_ip = Sketchup::InputPoint.new
    @state = 0
    @drawn = false
    view.invalidate if view
    puts "reset, state == #{@state}"
    self.start_commit()
  end
  def start_commit()
    model = Sketchup.active_model
    status=model.start_operation("Insert LuxCube")
    @doing_operation = true
  end
  def end_commit()
    model = Sketchup.active_model
    status=model.commit_operation
    @doing_operation = false
  end
  def activate
    self.reset
    puts "activated"
  end
  def deactivate(view)
    view.invalidate if @drawn
    model = Sketchup.active_model
    model.abort_operation if @doing_operation
    puts "deactivated"
  end
  def onLButtonDown(flags, x, y, view)
    case @state
      when 0
        @ip.pick(view, x, y)
        @state = 1
      when 1
        self.create_prim(view)
    end
  end
  def onMouseMove(flags, x, y, view)
    case @state
    when 0
      @curr_ip.pick(view, x, y)
      view.invalidate
    when 1
      @curr_ip.pick(view, x, y)
      view.invalidate if @curr_ip.position != @ip.position
      #if @curr_ip != @ip
        #view.invalidate if (@ip.display? or @curr_ip.display?)
    end
  end
  def draw(view)
    case @state
    when 0
      @curr_ip.draw(view)
    when 1
      @curr_ip.draw(view)
      @ip.draw(view)
      #@old_ip.draw(view)
      self.draw_geometry(@ip.position, @curr_ip.position, view)
    when 2

    end
    
      #@curr_ip.draw(view)if @ip.display?
      #@drawn = true
    #view.invalidate
  end
  def mouse_moved?
    moved = (@curr_ip != @old_ip)
    @old_ip.copy!(@curr_ip)
    return moved
  end
  def draw_geometry(pt1,pt2,view)
    view.line_width = 3
    view.drawing_color="blue"
    view.draw(GL_LINES, [pt1, pt2])
    case @state
    when 1
      draw_cube(pt1, pt2, view)
    end
  end
  def draw_cube(pt1, pt2, view)
    scale_vector = pt2 - pt1
    if @ip.face
      normal = @ip.face.normal
    else
      normal = Geom::Vector3d.new(0, 0, 1)
    end

    side1_half = normal.cross(scale_vector).normalize!
    side2_half = side1_half.cross(normal).normalize!

    scale = scale_vector.dot(side2_half)
    normal = apply_scale(normal, scale * 2)
    side1_half = apply_scale(side1_half, scale)
    side2_half = apply_scale(side2_half, scale)

    #on face, same angle as scale_vector as with normal in face dimension
    pts = [
      pt1 + side2_half - side1_half, pt1 + side2_half + side1_half, pt1 + side2_half + side1_half + normal, pt1 + side2_half - side1_half + normal, #side 1
      pt1 - side2_half - side1_half, pt1 - side2_half + side1_half, pt1 - side2_half + side1_half + normal, pt1 - side2_half - side1_half + normal, #side 2
      pt1 + side1_half - side2_half, pt1 + side1_half + side2_half, pt1 + side1_half + side2_half + normal, pt1 + side1_half - side2_half + normal, #side 3
      pt1 - side1_half - side2_half, pt1 - side1_half + side2_half, pt1 - side1_half + side2_half + normal, pt1 - side1_half - side2_half + normal  #side 4
      ]
    pts1 = [
     pts[0], pts[1], pts[2], pts[3] #side 1
      ]
    pts2 = [
      pts[4], pts[5], pts[6], pts[7]#side 2
      ]
    pts3 = [
      pts[8], pts[9], pts[10], pts[11] #side 3
      ]
    pts4 = [
       pts[14], pts[13], pts[12], pts[15] 
      ]
    pts5 = [pt1 - side1_half - side2_half, pt1 - side1_half + side2_half, pt1 + side1_half + side2_half, pt1 +side1_half - side2_half]
    pts6 = []
    pts5.each {|p| pts6.push(p + normal)}

    #puts "normal: #{normal}\nside1: #{side1_half}\nside2: #{side2_half}"if self.mouse_moved?
    view.draw(GL_LINE_LOOP, pts1)
    view.draw(GL_LINE_LOOP, pts2)
    view.draw(GL_LINE_LOOP, pts3)
    view.draw(GL_LINE_LOOP, pts4)
    
    return [pts1, pts2, pts3, pts4, pts5, pts6]
    #view.draw(GL_QUADS, pts)
  end
  def create_prim(view)
    grp = Sketchup.active_model.active_entities.add_group()
    ents = grp.entities
   
    sides = draw_cube(@ip.position, @curr_ip.position, view)
    sides.each do |side|
      ents.add_face(side)
    end
    
    #little hack to reverse face (still can't figure out what went wrong in the first place!)
    c = 1
    ents.each do |e| 
      if e.class == Sketchup::Face
        if c == 2
          e.reverse!
        end
        c += 1
      end
    end
    puts "created LuxCube object"
    
    end_commit()
    reset(view)
  end
  def apply_scale(vec, scale)
    vec.x = vec.x * scale
    vec.y = vec.y * scale
    vec.z = vec.z * scale
    return vec
  end
end

  


def select_my_tool()
  my_tool = MyTool.new
  model = Sketchup.active_model
  entities = model.entities
  selection = model.selection
  model.select_tool(my_tool)
end
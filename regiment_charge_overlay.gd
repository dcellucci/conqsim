extends Node2D

# Pregen the arc points because trig is expensive
var base_arc_points: Array[Vector2] = []

func _ready() -> void:
	# A constant number of segments
	var num_segments = 40.0
	# Populate the arc points array when the node is ready 
	for i in range(num_segments):
		base_arc_points.append(Vector2(
			sin(float(i)/num_segments*PI/4.0)
		  , - cos(float(i)/num_segments*PI/4.0)
		))
	
#
func update_display(regiment: GameState.Regiment) -> void:
	update_lines(regiment)
	
func update_lines(regiment: GameState.Regiment) -> void:
	# Get rid of all the existing lines
	for child in get_children():
		child.queue_free()
	# return if we are in measure mode (i.e. dont display lines)
	#if GameSettings.charge_hud_measure_mode:
	#	return
	# Create a base line
	var line = Line2D.new()
	var base_x = float(regiment.width)/2.*GameSettings.STAND_DIM_PX
	var base_y = -(float(regiment.height)/2.*GameSettings.STAND_DIM_PX)
	line.add_point(Vector2(
		   -base_x
		,   base_y 
		))
	line.add_point(Vector2(
			base_x
		,   base_y
		))
	line.default_color = Color(0,1.0,0)
	line.width = 3
	# Now populate with the maximum number of lines possible- Move + 6
	for i in range(regiment.move+6):
		# duplicate the base line 
		var new_line = line.duplicate()
		new_line.points[0].y = (base_y - (i+1)*GameSettings.PIXELS_PER_INCH)
		new_line.points[1].y = (base_y - (i+1)*GameSettings.PIXELS_PER_INCH)
		# Yellow denotes that it's not a free charge
		if i > regiment.move:
			new_line.default_color = Color(1.0,1.0,0.0)
		add_child(new_line)
		#The ability to wheel before charging means we need to draw the full front arc
		var right_arc = line.duplicate()
		right_arc.points = []
		for base_arc_point in base_arc_points:
			right_arc.add_point(base_arc_point*(i+1)*GameSettings.PIXELS_PER_INCH)
		right_arc.position = Vector2(base_x, base_y)
		if i > regiment.move:
			right_arc.default_color = Color(1.0,1.0,0.0)
		#Left arc is the same as right arc just mirrored over the y-axis
		var left_arc = right_arc.duplicate()
		left_arc.position = Vector2(-base_x, base_y)
		left_arc.scale = Vector2(-1.0,1.0)
		add_child(right_arc)
		add_child(left_arc)
		

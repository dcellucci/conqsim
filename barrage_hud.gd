extends Node2D

func update_display():
	# The game should only call this function when the barrage HUD needs to 
	# update to a new regiment- either the selection has changed or the regiment
	# has changed in dimension/position, etc.
	if GameState.selected_regiment == null: 
		return
	# Clear out the children lines.
	# Transform the lines from the local coordinate frame to the referenced 
		# regiment's coordinate frame
	transform = GameState.selected_regiment.get_transform()
	
	#for child in $BarrageLines.get_children():
	#	$BarrageLines.remove_child(child)
	for child in $LosLines.get_children():
		$LosLines.remove_child(child)
	for i in range(max(GameState.selected_regiment.width, GameState.selected_regiment.height)):
		
		# Create a base line
		var barrage_line = Line2D.new()
		# Align the base line with the center of each front-rank stand
		var base_point = Vector2(
			(i+0.5-0.5*GameState.selected_regiment.width)*GameSettings.STAND_DIM_PX
		  ,-(0.5*GameState.selected_regiment.height)*GameSettings.STAND_DIM_PX
		)
		# Add the base point
		barrage_line.add_point(base_point)
		# Set the Y-axis point just a little further up (away from the regiment)
		barrage_line.add_point(base_point - Vector2(0,GameSettings.PIXELS_PER_INCH))
		# Width is a placeholder for now
		barrage_line.width = 3
		# Color is likewise a placeholder
		barrage_line.default_color = Color(255,0,0)
		
		var range_line = barrage_line.duplicate()
		range_line.default_color = Color(255,255,0)
		
		var effective_range_line = barrage_line.duplicate()
		effective_range_line.default_color = Color(0,255,0)
		
		# Clone the barrage line and add it to the los lines array
		var los_line = barrage_line.duplicate()
		los_line.default_color = Color(0,0,255)
		
		$BarrageLines/FullExtentLines.add_child(barrage_line)
		$BarrageLines/RangeLines.add_child(range_line)
		$BarrageLines/EffectiveRangeLines.add_child(effective_range_line)
		$LosLines.add_child(los_line)
	
func _process(delta: float) -> void:
	# Need a selected regiment to work with
	if GameState.selected_regiment == null: 
		visible = false
		return
	# Only process when in barrage UI mode
	if GameState.selected_regiment_state != GameState.Regiment.UIState.BARRAGE:
		visible = false
		return
	# Get the regiment's transform (position and rotation in global space)
	var regiment_transform = GameState.selected_regiment.get_transform()
	# Get the current mouse position in global coordinates
	var global_mouse_position = get_global_mouse_position()
	# Transform mouse position from global space to regiment's local coordinate frame
	var local_mouse_position = regiment_transform.affine_inverse() * global_mouse_position
	# Determine where the mouse position is located in the local reference frame
	# of the selected regiment
	var mouse_cursor_arc = GameState.selected_regiment.determine_which_arc(local_mouse_position)
	
	if mouse_cursor_arc != GameState.Regiment.ARC.FRONT and !GameState.selected_regiment.fluid_formation:
		visible = false
	else:
		visible = true
		
	$BarrageLines.visible = !GameState.barrage_measure_los_mode
	
	update_los_lines(local_mouse_position)
	update_barrage_lines(local_mouse_position)
	
	
func update_los_lines(local_mouse_position: Vector2):
	$LosLines.visible = GameState.barrage_measure_los_mode
	# Update all line of sight lines to point from their base to the mouse position
	for child: Line2D in $LosLines.get_children():
		child.points[1] = local_mouse_position

func update_barrage_lines(local_mouse_position: Vector2):
	var stand_arc = GameState.selected_regiment.determine_which_arc(local_mouse_position)
	var stand_segments = GameState.selected_regiment.stand_segments(stand_arc)
	for stand_index:int in range(stand_segments.size(),2):
		var closest_point_on_stand = Geometry2D.get_closest_point_to_segment(
			  local_mouse_position
			, stand_segments[stand_index]
			, stand_segments[stand_index]
			)
		var delta_vector = local_mouse_position - closest_point_on_stand
		var range_scale_factor = float(GameState.selected_regiment.barrage_range)*GameSettings.PIXELS_PER_INCH/delta_vector.length()
		var effective_range_scale_factor = min(1.0,0.5*range_scale_factor)
		range_scale_factor = min(1.0, range_scale_factor)
		var child_index = floor(stand_index / 2)
		$BarrageLines/FullExtentLines.get_children()[child_index].points[1] = local_mouse_position
		$BarrageLines/FullExtentLines.get_children()[child_index].points[0] = closest_point_on_stand
		
		$BarrageLines/RangeLines.get_children()[child_index].points[1] = closest_point_on_stand+delta_vector*range_scale_factor
		$BarrageLines/RangeLines.get_children()[child_index].points[0] = closest_point_on_stand
		
		$BarrageLines/EffectiveRangeLines.get_children()[child_index].points[1] = closest_point_on_stand+delta_vector*effective_range_scale_factor
		$BarrageLines/EffectiveRangeLines.get_children()[child_index].points[0] = closest_point_on_stand

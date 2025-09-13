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
	if not UiStateMachine.ui_state_machine.is_barrage_state():
		visible = false
		return
	# Get the regiment's transform (position and rotation in global space)
	var regiment_transform = GameState.selected_regiment.get_transform()
	# Get the current mouse position in global coordinates
	var cursor_position:Vector2 = GameState.snap_cursor(get_global_mouse_position()).snap_point
	
	# Transform mouse position from global space to regiment's local coordinate frame
	var local_mouse_position = regiment_transform.affine_inverse() * cursor_position
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

# Updates the visual barrage lines showing firing trajectories from regiment stands to the target.
# Creates three types of lines for each active stand:
# - Full extent lines (red): Show the complete trajectory from stand to target
# - Range lines (yellow): Show trajectory limited by weapon maximum range
# - Effective range lines (green): Show trajectory within optimal firing effectiveness (50% of max range)
func update_barrage_lines(local_mouse_position: Vector2):
	# Determine which arc of the regiment the mouse position falls into (front, left, right, rear)
	var stand_arc = GameState.selected_regiment.determine_which_arc(local_mouse_position)
	# Get the line segments representing the stands in the determined arc
	var stand_segments = GameState.selected_regiment.stand_segments(stand_arc)
	
	# Process each stand segment (segments come in pairs: start_point, end_point)
	for stand_index:int in range(0,stand_segments.size(),2):
		# Find the closest point on the current stand segment to the mouse position
		var closest_point_on_stand = Geometry2D.get_closest_point_to_segment(
			  local_mouse_position
			, stand_segments[stand_index]      # Start point of stand segment
			, stand_segments[stand_index+1]    # End point of stand segment
			)
		
		# Calculate the vector from the stand to the target position
		var delta_vector = local_mouse_position - closest_point_on_stand
		
		# Calculate range limitation factors
		# Range scale factor: how much of the full trajectory is within maximum range
		var range_scale_factor = float(GameState.selected_regiment.barrage_range)*GameSettings.PIXELS_PER_INCH/delta_vector.length()
		# Effective range scale factor: 50% of max range for optimal effectiveness
		var effective_range_scale_factor = min(1.0,0.5*range_scale_factor)
		# Clamp range scale factor to never exceed the target distance
		range_scale_factor = min(1.0, range_scale_factor)
		
		# Convert segment index to child index (since segments come in pairs)
		var child_index = floor(stand_index / 2)
		
		# Update Full Extent Lines (red) - show complete trajectory to target
		$BarrageLines/FullExtentLines.get_children()[child_index].points[1] = local_mouse_position
		$BarrageLines/FullExtentLines.get_children()[child_index].points[0] = closest_point_on_stand
		$BarrageLines/FullExtentLines.get_children()[child_index].visible = true
		
		# Update Range Lines (yellow) - show trajectory limited by maximum weapon range
		$BarrageLines/RangeLines.get_children()[child_index].points[1] = closest_point_on_stand+delta_vector*range_scale_factor
		$BarrageLines/RangeLines.get_children()[child_index].points[0] = closest_point_on_stand
		$BarrageLines/RangeLines.get_children()[child_index].visible = true

		# Update Effective Range Lines (green) - show trajectory within optimal effectiveness range
		$BarrageLines/EffectiveRangeLines.get_children()[child_index].points[1] = closest_point_on_stand+delta_vector*effective_range_scale_factor
		$BarrageLines/EffectiveRangeLines.get_children()[child_index].points[0] = closest_point_on_stand
		$BarrageLines/EffectiveRangeLines.get_children()[child_index].visible = true

	# Hide unused barrage lines for stands not in the active arc
	# This prevents visual artifacts from previous arc selections
	for child_index:int in range(stand_segments.size()/2, $BarrageLines/FullExtentLines.get_children().size()):
		$BarrageLines/FullExtentLines.get_children()[child_index].visible = false
		$BarrageLines/RangeLines.get_children()[child_index].visible = false
		$BarrageLines/EffectiveRangeLines.get_children()[child_index].visible = false

extends Node2D

enum ChargeMeasureSnapMode {NONE, SNAPTOREGIMENT, SNAPTOFACE}

var charge_measure_snap_mode := ChargeMeasureSnapMode.NONE
var input_debounce: bool
var input_debounce_ticks_ms: int = 0

func _process(_delta: float) -> void:
	$GhostRegiment.visible = UiStateMachine.ui_state_machine.is_charge_state()
	$Line2D.visible = UiStateMachine.ui_state_machine.is_charge_measure_state()
	if not UiStateMachine.ui_state_machine.is_charge_state():
		return
		
	if GameState.selected_regiment == null:
		return
		
	if UiStateMachine.ui_state_machine.state == UiStateMachine.UIState.CHARGE_INITIALIZE:
		handle_charge_initialize()
		
	if UiStateMachine.ui_state_machine.is_charge_measure_state():
		process_charge_measure()

func handle_charge_initialize():
	# Set the size of the child node
	if GameState.selected_regiment == null:
		return
	var half_width_px = 0.5*GameState.selected_regiment.width*GameSettings.STAND_DIM_PX
	var half_height_px = 0.5*GameState.selected_regiment.height*GameSettings.STAND_DIM_PX
	
	var polygon = $GhostRegiment.get_polygon()
	if polygon == null:
		return
	if polygon.size() != 4: 
		return
	
	polygon[0] = Vector2(-half_width_px,-half_height_px)
	polygon[1] = Vector2( half_width_px,-half_height_px)
	polygon[2] = Vector2( half_width_px, half_height_px)
	polygon[3] = Vector2(-half_width_px, half_height_px)
	
	$GhostRegiment.set_polygon(polygon)
	$GhostRegiment.position = GameState.selected_regiment.position
	$GhostRegiment.rotation_degrees = -GameState.selected_regiment.rotation

func process_charge_measure():
	# Check if the mouse is in the front arc
	# if it is, draw the closest line between the front arc segment and the 
	# mouse cursor
	# optionally, the cursor position can snap to the nearest regiment. 
	# two forms of snapping- closest point to the selected regiment 
	# on the hovered regiment and closest point on the hovered regiment to the 
	# mouse cursor
	if Input.is_action_just_pressed('ui_cycle_snap_option'):
		input_debounce = true
		cycle_snap_mode()
	
	var front_segment = GameState.selected_regiment.stand_segments(GameState.Regiment.ARC.FRONT)

	var mouse_position = get_global_mouse_position()
	
	var line_points = charge_measure_get_target_position(mouse_position, front_segment)
	
	var mouse_arc = GameState.selected_regiment.determine_which_arc(
		GameState.selected_regiment.get_transform().affine_inverse()*line_points[1]
	)
	
	$Line2D.default_color = Color(0, 1.0, 0)
	if mouse_arc != GameState.Regiment.ARC.FRONT:
		$Line2D.default_color = Color(1.0, 0, 0)
	
	if len(line_points) > 0:
		$Line2D.points = [line_points[0], line_points[-1]]
	else:
		$Line2D.visible = false
	
func charge_measure_get_target_position(mouse_position: Vector2, front_segment) -> PackedVector2Array:
	# Get current UI state to determine which charge measurement mode we're in
	var uistate = UiStateMachine.ui_state_machine.state
	# Check if cursor should snap to nearby regiments and get snap information
	var snap_bundle = GameState.snap_cursor(mouse_position)

	# Transform snap point to global coordinates if we have a regiment to snap to
	var global_snap_point = snap_bundle.snap_point
	if snap_bundle.regiment != null:
		global_snap_point = snap_bundle.regiment.get_transform().affine_inverse()*snap_bundle.snap_point

	# Convert the selected regiment's front segment to global coordinates
	var global_front_segment = [
		GameState.selected_regiment.get_transform()*front_segment[0]
	  , GameState.selected_regiment.get_transform()*front_segment[-1]
	  ]

	# Handle free measurement mode or face snapping mode (or when no regiment to snap to)
	if uistate in [UiStateMachine.UIState.CHARGE_MEASURE_FREE, UiStateMachine.UIState.CHARGE_MEASURE_SNAP_FACE] or \
		snap_bundle.regiment == null:
		# Default to mouse position, but use snap point if in face snap mode
		var target_position = mouse_position
		if uistate == UiStateMachine.UIState.CHARGE_MEASURE_SNAP_FACE and snap_bundle.regiment != null:
			target_position = global_snap_point
		# Find closest point on our front segment to the target position
		var closest_point = Geometry2D.get_closest_point_to_segment(
			target_position, global_front_segment[0], global_front_segment[-1]
			)
		return PackedVector2Array([closest_point, target_position])

	# Handle regiment snapping mode - find shortest path between regiment edges
	if uistate == UiStateMachine.UIState.CHARGE_MEASURE_SNAP_REGIMENT :
		var minimum_dist = -1
		var closest_points: PackedVector2Array
		# Check all four sides of the target regiment to find the shortest connection
		for arc in [
			GameState.Regiment.ARC.FRONT, GameState.Regiment.ARC.LEFT
		  , GameState.Regiment.ARC.RIGHT, GameState.Regiment.ARC.REAR
		  ]:
			# Get the segment for this side of the target regiment
			var target_segment = snap_bundle.regiment.stand_segments(arc)
			# Find closest points between our front segment and this target segment
			var candidate_closest_points = Geometry2D.get_closest_points_between_segments(
				GameState.selected_regiment.get_transform()*front_segment[0]
			  , GameState.selected_regiment.get_transform()*front_segment[-1]
			  , snap_bundle.regiment.get_transform()*target_segment[0]
			  , snap_bundle.regiment.get_transform()*target_segment[-1]
			)
			# Calculate distance between the closest points
			var candidate_closest_point_distance = candidate_closest_points[0].distance_to(candidate_closest_points[1])
			# Keep track of the shortest distance found so far
			if minimum_dist == -1 or candidate_closest_point_distance < minimum_dist:
				closest_points = candidate_closest_points
				minimum_dist = candidate_closest_point_distance
		return closest_points

	# Fallback: return empty array if no valid state
	return PackedVector2Array([])
	
func cycle_snap_mode():
	if input_debounce:	
		input_debounce = false
		input_debounce_ticks_ms = Time.get_ticks_msec()
	elif input_debounce_ticks_ms-Time.get_ticks_msec() < GameSettings.input_debounce_interval_ms:
		return 
	
	UiStateMachine.ui_state_machine.cycle_charge_measure_state()

	
	

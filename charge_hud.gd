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
		cycle_snap_mode()
	var mouse_position = get_global_mouse_position()
	var mouse_arc = GameState.selected_regiment.determine_which_arc(
		GameState.selected_regiment.get_transform().affine_inverse()*mouse_position
	)
	$Line2D.default_color = Color(0, 1.0, 0)
	if mouse_arc != GameState.Regiment.ARC.FRONT:
		$Line2D.default_color = Color(1.0, 0, 0)
	
	var front_segment = GameState.selected_regiment.stand_segments(GameState.Regiment.ARC.FRONT)
	
	var global_front_segment = [
		  GameState.selected_regiment.get_transform()*front_segment[0]
		, GameState.selected_regiment.get_transform()*front_segment[-1]
		]
		
	var closest_point_selected_regiment = Geometry2D.get_closest_point_to_segment(
		  mouse_position
		, global_front_segment[0]
		, global_front_segment[-1]
		)
	
	$Line2D.points = [mouse_position, closest_point_selected_regiment]
	
func cycle_snap_mode():
	if input_debounce:
		input_debounce = false
		input_debounce_ticks_ms = Time.get_ticks_msec()
	if input_debounce_ticks_ms-Time.get_ticks_msec() < GameSettings.input_debounce_interval_ms:
		return 
	
	input_debounce = true
	
	

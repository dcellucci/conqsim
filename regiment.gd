extends Node2D

var regiment: GameState.Regiment = null
var regiment_size_px: Vector2
var reform_base_rotation_degrees: float
var reform_base_position: Vector2
var reform_base_mouse_click_location: Vector2
var debounce_timestamp: int
# This is the display node for a regiment- it contains all of the logic for 
# rendering a regiment in the game world and also moving it around

func _ready() -> void:
	$MouseHoverArea.mouse_entered.connect(_handle_mouse_enter_hover_area)
	$MouseHoverArea.mouse_exited.connect(_handle_mouse_leave_hover_area)
	$RegimentUI/ReformButton.pressed.connect(_handle_reform_button_pressed)
	update_display()
	
func _process(delta:float) -> void:
	# Make the stand border visible if its being hovered
	update_ui_visibility()
	process_mode()
	
func update_ui_visibility() -> void:
	$StandTray/StandHoveredBorder.visible = (GameState.hovered_regiment == regiment)
		
	$StandTray/StandSelectedBorder.visible = (GameState.selected_regiment == regiment) 
	$ChargeHUD.visible = (
		GameState.selected_regiment == regiment and 
		UiStateMachine.ui_state_machine.is_charge_state() and 
		not UiStateMachine.ui_state_machine.is_charge_measure_state()
		) 
	$RegimentUI.visible = (GameState.selected_regiment == regiment and 
		( UiStateMachine.ui_state_machine.is_charge_state() or 
		  UiStateMachine.ui_state_machine.is_move_state() or 
		  UiStateMachine.ui_state_machine.is_reform_state()
		)
	) 
	
	$RegimentUI/ReformButton.visible = (
		UiStateMachine.ui_state_machine.state in [
			UiStateMachine.UIState.CHARGE_TARGET
		  , UiStateMachine.UIState.CHARGE_REFORM_ROTATE
		  ] 
		or UiStateMachine.ui_state_machine.is_reform_state()
	)
	$RegimentUI/ReformButton.disabled = (
		UiStateMachine.ui_state_machine.state == UiStateMachine.UIState.CHARGE_REFORM_ROTATE
		)

	
func process_mode() -> void:
	if regiment:
		position = regiment.position
		rotation_degrees = -regiment.rotation
	# We do nothing further if the selected regiment isn't this regiment
	if GameState.selected_regiment != regiment:
		return
	if UiStateMachine.ui_state_machine.is_charge_measure_state():
		if GameState.selected_regiment.position != GameState.regiment_starting_position:
			GameState.selected_regiment.position = GameState.regiment_starting_position
		if GameState.selected_regiment.rotation != GameState.regiment_starting_rotation:
			GameState.selected_regiment.rotation = GameState.regiment_starting_rotation
	match UiStateMachine.ui_state_machine.state:
		UiStateMachine.UIState.CHARGE_REFORM_ROTATE:
			process_reform()	
		UiStateMachine.UIState.CHARGE_INITIALIZE:
			process_charge_initialize()
		UiStateMachine.UIState.CHARGE_TARGET:
			process_charge_target()
		UiStateMachine.UIState.CHARGE_FRONTAGE:
			process_charge_frontage()
	
	

func process_move() -> void:
	pass 
	
func process_reform() -> void:
	var base_vector = reform_base_mouse_click_location - reform_base_position
	var delta_vector = get_global_mouse_position() - reform_base_position
	var angle = base_vector.angle_to(delta_vector)
	regiment.rotation = reform_base_rotation_degrees - rad_to_deg(angle)
	if Input.is_action_just_pressed('SelectRegiment'):
		if Time.get_ticks_msec() - debounce_timestamp > GameSettings.input_debounce_interval_ms: 
			UiStateMachine.ui_state_machine.undo_state()
			GameState.regiment_starting_rotation = regiment.rotation
			
	if Input.is_action_just_pressed("ui_cancel"):
		UiStateMachine.ui_state_machine.undo_state()
		regiment.rotation = reform_base_rotation_degrees
			
func process_charge_initialize() -> void:
	UiStateMachine.ui_state_machine.set_new_state(UiStateMachine.UIState.CHARGE_TARGET)
	GameState.regiment_starting_position = GameState.selected_regiment.position
	GameState.regiment_starting_rotation = GameState.selected_regiment.rotation
	
func process_charge_target():
	var cursor_bundle = GameState.snap_cursor(get_global_mouse_position())
	# We find a point with a position, an arc, and a target regiment
	# We want to align self.regiment with the target regiment. We therefore want
	# a position for the center of the regiment and 
	# the position is the midpoint of the arc that is being contacted plus an offset
	# the offset is always going to be the half-height of self.regiment- the direction
	# comes from the unit vector between the center of the target regiment and the
	# midpoint of the arc thats being contacted.
	#print(cursor_bundle)		
	$ChargeHUD.visible = false
	$RegimentUI/ReformButton.visible = false
	if cursor_bundle.regiment == null:
		GameState.selected_regiment.position = GameState.regiment_starting_position
		GameState.selected_regiment.rotation = GameState.regiment_starting_rotation
		$ChargeHUD.visible = true
		$RegimentUI/ReformButton.visible = true
		return
		
	var normal = Vector2(0.0, -1.0)
	var offset = 0.5*cursor_bundle.regiment.height*GameSettings.STAND_DIM_PX
	var facing_rotation_deg = 180
	
	if cursor_bundle.arc == GameState.Regiment.ARC.REAR:
		facing_rotation_deg = 0
	elif cursor_bundle.arc == GameState.Regiment.ARC.LEFT:
		facing_rotation_deg = -90
		offset = 0.5*cursor_bundle.regiment.width*GameSettings.STAND_DIM_PX
	elif cursor_bundle.arc == GameState.Regiment.ARC.RIGHT:
		facing_rotation_deg = 90
		offset = 0.5*cursor_bundle.regiment.width*GameSettings.STAND_DIM_PX
	
	var regiment_rotation = cursor_bundle.regiment.rotation+facing_rotation_deg
	normal = normal.rotated(-deg_to_rad(regiment_rotation-180))
	offset = offset + 0.5*GameState.selected_regiment.height*GameSettings.STAND_DIM_PX
	GameState.selected_regiment.rotation = regiment_rotation
	GameState.selected_regiment.position = cursor_bundle.regiment.position + normal*offset
	
	if Input.is_action_just_pressed("SelectRegiment"):
		GameState.charge_selected_arc = cursor_bundle.arc
		GameState.charge_targeted_regiment = cursor_bundle.regiment
		GameState.charge_target_initial_transform = GameState.selected_regiment.get_transform()
		UiStateMachine.ui_state_machine.set_new_state(UiStateMachine.UIState.CHARGE_FRONTAGE)
	
func process_charge_frontage():
	var stand_segments = GameState.charge_targeted_regiment.stand_segments(GameState.charge_selected_arc)
	var stand_midpoint = 0.5*(stand_segments[0] + stand_segments[-1])
	var max_offset = 0.5*(stand_segments[-1].distance_to(stand_segments[0]) + GameState.selected_regiment.get_width_px())

	var local_mouse_position = GameState.charge_targeted_regiment.get_transform().affine_inverse()*get_global_mouse_position()
	var local_point = Geometry2D.get_closest_point_to_segment_uncapped(local_mouse_position, stand_segments[0], stand_segments[-1])
	var offset = local_point.distance_to(stand_midpoint)
	var angle = (local_point-stand_midpoint).angle_to(stand_segments[0]-stand_midpoint)
	var displace_vector = Vector2(1.0,0.0).rotated(angle)*clamp(offset, -max_offset, max_offset)
	if GameState.charge_selected_arc in [GameState.Regiment.ARC.LEFT, GameState.Regiment.ARC.REAR]:
		displace_vector = -displace_vector
	GameState.selected_regiment.position = GameState.charge_target_initial_transform*displace_vector

		
func update_display() -> void:
	if regiment == null:
		return
	#calculate the overall size of the regiment in px
	regiment_size_px = Vector2(
		regiment.width*GameSettings.STAND_DIM_PX
	  , regiment.height*GameSettings.STAND_DIM_PX
	  )
	# Set the size of the hover region to be the dimensions of the regiment
	$MouseHoverArea/CollisionShape2D.shape.set_size(regiment_size_px)
	
	var regiment_points = [
		Vector2( regiment_size_px.x/2.,  regiment_size_px.y/2)
	  , Vector2(-regiment_size_px.x/2.,  regiment_size_px.y/2)
	  , Vector2(-regiment_size_px.x/2., -regiment_size_px.y/2)
	  , Vector2( regiment_size_px.x/2., -regiment_size_px.y/2)
	  ]
	$StandTray.polygon = PackedVector2Array(regiment_points)
	$StandTray/StandHoveredBorder.points = PackedVector2Array(regiment_points)
	$StandTray/StandSelectedBorder.points = PackedVector2Array(regiment_points)

	$RegimentUI.update_display(regiment)
	
	$ChargeHUD.update_display(regiment)
	
	
func _handle_mouse_enter_hover_area():
	if GameState.hovered_regiment != regiment:
		GameState.hovered_regiment = regiment

func _handle_mouse_leave_hover_area():
	if GameState.hovered_regiment == regiment:
		GameState.hovered_regiment = null

func _handle_reform_button_pressed():
	print("caught")
	if regiment == null:
		return
	reform_base_rotation_degrees = regiment.rotation
	reform_base_position = regiment.position
	reform_base_mouse_click_location = get_global_mouse_position()
	UiStateMachine.ui_state_machine.set_new_state(UiStateMachine.UIState.CHARGE_REFORM_ROTATE)
	GameSettings.charge_hud_measure_mode = false
	debounce_timestamp = Time.get_ticks_msec()
	

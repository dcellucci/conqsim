extends Area2D
signal update_total_move(new_total_move)

var speed = 400
var angular_speed = PI
var total_move = 0
var pixels_per_inch = 30
var stand_size_inches = 2.5
var stand_size_pixels = stand_size_inches*pixels_per_inch
var num_stands_wide = 3
var num_stands_tall = 3

var regiment_size = Vector2(num_stands_wide*stand_size_pixels,num_stands_tall*stand_size_pixels)
#var stand_scale = stand_size_inches*pixels_per_inch/texture.get_width()

enum MoveState {IDLE, FORWARD, WHEEL_LEFT, WHEEL_RIGHT}

var current_move_state = MoveState.IDLE
var movelist = []
var start_position = position
var start_transform = transform
var delta_factor = 0
var move_start_position = position 

func _init() -> void:
	pass#transform = transform.scaled_local(Vector2(stand_scale, stand_scale))

func _ready() -> void:
	$BoundingBox.shape.set_size(regiment_size)
	# Add the unit sprites
	var unit = $Unit
	for row in range(num_stands_tall):
		for col in range(num_stands_wide):
			var copyunit = unit.duplicate()
			copyunit.visible = true
			copyunit.position = Vector2((col-num_stands_wide/2)*stand_size_pixels, (row-num_stands_tall/2)*stand_size_pixels)
			self.add_child(copyunit)
	# Position the wheel left button
	var wheel_left_button = $WheelLeftButton
	wheel_left_button.position = Vector2(
		(num_stands_wide/2+0.5)*stand_size_pixels+wheel_left_button.get_rect().size.x/2
	 , -(num_stands_tall/2)*stand_size_pixels-wheel_left_button.get_rect().size.y/2
	 )
	wheel_left_button.pivot_position = Vector2(-(num_stands_wide/2)*stand_size_pixels, -(num_stands_tall/2)*stand_size_pixels)
	
	var wheel_left_pivot = $WheelLeftPivot
	wheel_left_pivot.visible = false
	wheel_left_pivot.position = Vector2(	
	   -(num_stands_wide/2+0.5)*stand_size_pixels-wheel_left_pivot.get_rect().size.x/2
	 , -(num_stands_tall/2+0.5)*stand_size_pixels-wheel_left_pivot.get_rect().size.y/2
	 )
	
	$MoveForwardButton.position = Vector2(
	  -$MoveForwardButton.get_rect().size.x/2
	, -(num_stands_tall/2+0.5)*stand_size_pixels-$MoveForwardButton.get_rect().size.y
	)
	
	$DebugStartAngleLine.visible = false
	$DebugStartAngleLine.scale=Vector2(num_stands_wide*stand_size_pixels/20, 0.1)
	
func _process(delta: float) -> void:
	var direction = 0
	
	if current_move_state == MoveState.IDLE:
		delta_factor = 0
		if Input.is_key_pressed(KEY_W):	
			current_move_state = MoveState.FORWARD
			start_position = position
		if Input.is_key_pressed(KEY_Q):	
			current_move_state = MoveState.WHEEL_LEFT
			start_transform = transform
		if Input.is_key_pressed(KEY_E):	
			current_move_state = MoveState.WHEEL_RIGHT
			start_transform = transform
	
	if current_move_state == MoveState.FORWARD:
		if Input.is_key_pressed(KEY_ENTER):
			current_move_state = MoveState.IDLE
			total_move += delta_factor
			start_position = position
			delta_factor = 0
		print(get_local_mouse_position(), move_start_position)
		var disp_vec = Vector2(0, get_local_mouse_position().y - move_start_position.y)
		transform = start_transform.translated_local(disp_vec)
		#update_total_move.emit((total_move+delta_factor)/pixels_per_inch)
	
	if current_move_state == MoveState.WHEEL_LEFT:
		var angular_velocity = 0 
		if Input.is_key_pressed(KEY_Q):		
			angular_velocity = -angular_speed
		if Input.is_key_pressed(KEY_A):
			angular_velocity = angular_speed
		if Input.is_key_pressed(KEY_ENTER):
			current_move_state = MoveState.IDLE
			total_move += abs(delta_factor)*num_stands_wide*stand_size_inches*pixels_per_inch
			start_transform = wheel(start_transform, delta_factor, 1)
			delta_factor = 0
		delta_factor += angular_velocity * delta
		if delta_factor > 0: 
			delta_factor = 0
		transform = wheel(start_transform, delta_factor, 1)
		update_total_move.emit(total_move/pixels_per_inch+abs(delta_factor)*num_stands_wide*stand_size_inches)
		
	if current_move_state == MoveState.WHEEL_RIGHT:
		var angular_velocity = 0 
		var delta_transform = transform 
		if Input.is_key_pressed(KEY_E):		
			angular_velocity = angular_speed
		if Input.is_key_pressed(KEY_D):
			angular_velocity = -angular_speed
		if Input.is_key_pressed(KEY_ENTER):
			current_move_state = MoveState.IDLE
			total_move += abs(delta_factor)*num_stands_wide*stand_size_inches*pixels_per_inch
			start_transform = wheel(start_transform, delta_factor, -1)
			delta_factor = 0
		delta_factor += angular_velocity * delta
		if delta_factor < 0: 
			delta_factor = 0
		transform = wheel(start_transform, delta_factor, -1)
		update_total_move.emit(total_move/pixels_per_inch+abs(delta_factor)*num_stands_wide*stand_size_inches)

	
# We want a keypress to take us into a mode, where we can then increase/decrease the value
# we then confirm, goes back to an IDLE where we then can choose a new mode
# label that shows total distance travelled
# also a set of vectors illustrating the movement??	

func _receive_set_wheeling(direction, status:bool):
	$WheelLeftPivot.visible = status
	$DebugStartAngleLine.visible = status
	if status == true:
		current_move_state = MoveState.WHEEL_LEFT
		start_transform = transform
		var start_position = get_local_mouse_position()
		var pivot_to_start_vector = $WheelLeftPivot.position - start_position
		$DebugStartAngleLine.rotation = Vector2(1,0).angle_to(pivot_to_start_vector)
		$DebugStartAngleLine.position = ($WheelLeftPivot.position + start_position)/2
		$DebugStartAngleLine.z_index = 5
	if status == false:
		current_move_state = MoveState.IDLE


func wheel(starting_transform: Transform2D, amount:float, direction:int) -> Transform2D:
	var reg_width = stand_size_inches*num_stands_wide*pixels_per_inch
	var reg_height = stand_size_inches*num_stands_tall*pixels_per_inch
	var disp_vec = Vector2(
		 -reg_width/2
		, reg_height/2
		)
	if direction == 1:
		disp_vec = Vector2(
			reg_width/2
		  , reg_height/2
		  )
	return starting_transform.translated_local(-disp_vec).rotated_local(amount).translated_local(disp_vec)


func _on_move_forward_button_pressed() -> void:
	if current_move_state == MoveState.IDLE:
		current_move_state = MoveState.FORWARD
		start_transform = transform
		move_start_position = get_local_mouse_position()

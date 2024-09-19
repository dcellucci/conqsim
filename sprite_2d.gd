extends Sprite2D

var speed = 400
var angular_speed = PI
var total_move = 0
var pixels_per_inch = 30
var stand_size_inches = 2.5
var stand_scale = stand_size_inches*pixels_per_inch/texture.get_width()

enum MoveState {IDLE, FORWARD, WHEEL_LEFT, WHEEL_RIGHT}

var current_move_state = MoveState.IDLE
var movelist = []
var start_position = position
var start_transform = transform
var delta_factor = 0

func _init() -> void:
	transform = transform.scaled_local(Vector2(stand_scale, stand_scale))

func _process(delta: float) -> void:
	var direction = 0
	
	if current_move_state == MoveState.IDLE:
		if Input.is_key_pressed(KEY_W):	
			current_move_state = MoveState.FORWARD
			start_position = position
			delta_factor = 0
		if Input.is_key_pressed(KEY_Q):	
			current_move_state = MoveState.WHEEL_LEFT
			start_transform = transform
			delta_factor = 0
		if Input.is_key_pressed(KEY_E):	
			current_move_state = MoveState.WHEEL_RIGHT
			start_transform = transform
			delta_factor = 0
	
	if current_move_state == MoveState.FORWARD:
		var velocity = 0
		if Input.is_key_pressed(KEY_W):
			velocity = speed
		if Input.is_key_pressed(KEY_S):
			velocity = -speed
		if Input.is_key_pressed(KEY_ENTER):
			current_move_state = MoveState.IDLE
		delta_factor += velocity * delta
		if delta_factor < 0:
			delta_factor = 0
		position = start_position + Vector2.UP.rotated(rotation)*delta_factor
		#total_move += (velocity*delta).length()/pixels_per_inch
	
	if current_move_state == MoveState.WHEEL_LEFT:
		var angular_velocity = 0 
		var delta_transform = transform 
		if Input.is_key_pressed(KEY_Q):		
			angular_velocity = -angular_speed
		if Input.is_key_pressed(KEY_A):
			angular_velocity = angular_speed
		if Input.is_key_pressed(KEY_ENTER):
			current_move_state = MoveState.IDLE
		delta_factor += angular_velocity * delta
		if delta_factor > 0: 
			delta_factor = 0
		print(delta_factor, position)
		transform = wheel(start_transform, delta_factor, 1)
		
	'''
	if current_move_state == MoveState.WHEEL_RIGHT:
		if Input.is_key_pressed(KEY_E):		
			wheel(angular_speed*delta, -1)
		if Input.is_key_pressed(KEY_D):
			wheel(-angular_speed*delta, -1)
		if Input.is_key_pressed(KEY_ENTER):
			current_move_state = MoveState.IDLE
	'''		
	#print(total_move)
	
# We want a keypress to take us into a mode, where we can then increase/decrease the value
# we then confirm, goes back to an IDLE where we then can choose a new mode
# label that shows total distance travelled
# also a set of vectors illustrating the movement??



func wheel(starting_transform: Transform2D, amount:float,direction:int) -> Transform2D:
	var disp_vec = Vector2(
		 -texture.get_width()/2*stand_scale
		, texture.get_height()/2*stand_scale
		)
	if direction == 1:
		disp_vec = Vector2(
			texture.get_width()/2*stand_scale
		  , texture.get_height()/2*stand_scale
		  )
	return starting_transform.translated_local(-disp_vec).rotated_local(amount).translated_local(disp_vec)

extends Sprite2D


var speed = 400
var angular_speed = PI
var total_move = 0
var pixels_per_inch = 30
var stand_size_inches = 2.5
var num_stands_wide = 3
var num_stands_tall = 1
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
	pass
	
# We want a keypress to take us into a mode, where we can then increase/decrease the value
# we then confirm, goes back to an IDLE where we then can choose a new mode
# label that shows total distance travelled
# also a set of vectors illustrating the movement??
	


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

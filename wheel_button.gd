extends Sprite2D

var original_position = Vector2(0,0)
var pivot_position = Vector2(0,0)

enum { NONE, ROTATING}

var state = NONE
var mouse_on_me: bool = false
var initial_mouse_pos: Vector2
var initial_angle: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event):
	var sprite_radius = 40
	
	# This is saying, the button index which is extending from InputEventMouseButton
	# is the left mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# This is saying, the given sprite's position should update to the
		# mouse's position when it is clicked and should stay put when not 
		# being clicked
		if event.is_pressed():
			initial_angle = rotation
			initial_mouse_pos = get_local_mouse_position().rotated(rotation)
			state = ROTATING
			print("I'm being dragged")
		else:
			state=NONE
			print("I'm no longer being dragged")
			
	if event is InputEventMouseMotion:
		if state == ROTATING:
			var current_mouse_pos: Vector2 = get_local_mouse_position().rotated(rotation)
			var angle = pivot_position.angle_to(current_mouse_pos)
			print(current_mouse_pos, angle + initsial_angle)

func _on_Area2D_mouse_entered() -> void:
	mouse_on_me = true

func _on_Area2D_mouse_exited() -> void:
	mouse_on_me = false
	

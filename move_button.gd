extends Sprite2D

var moving = false
signal set_moving(status:bool)
var mouse_on_me = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _input(event):
	var sprite_radius = 40
	
	# This is saying, the button index which is extending from InputEventMouseButton
	# is the left mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and mouse_on_me:
		# This is saying, the given sprite's position should update to the
		# mouse's position when it is clicked and should stay put when not 
		# being clicked
		if event.is_pressed():
			#Left is 0, we are wheeling
			set_moving.emit(true)
			moving = true
			print("I'm being moved")
		else:
			set_moving.emit(false)
			moving = false
			print("I'm no longer being moved")

func _on_Area2D_mouse_entered() -> void:
	mouse_on_me = true

func _on_Area2D_mouse_exited() -> void:
	mouse_on_me = false

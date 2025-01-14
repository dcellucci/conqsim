extends Camera2D

var dragging = false
var drag_start_location = position
var initial_position = position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("DragCamera"):
		dragging = true
		drag_start_location = get_global_mouse_position()
		initial_position = position
	if Input.is_action_just_released("DragCamera"):
		dragging = false
	if dragging:
		var mouse_pos = get_global_mouse_position()
			
	

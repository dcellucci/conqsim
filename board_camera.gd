extends Camera2D

var dragging = false
var drag_start_location = position
var initial_position = position

@export var min_zoom := 0.7
@export var max_zoom := 3.0
@export var zoom_factor := 0.1
@export var zoom_duration := 0.2

var zoom_level: float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventPanGesture:		
		set_zoom_level(zoom_level + sign(event.delta.y)*zoom_factor)
	if event.is_action("ZoomIn"):
		set_zoom_level(zoom_level + zoom_factor)
	if event.is_action("ZoomOut"):
		set_zoom_level(zoom_level - zoom_factor)
	if event.is_action_pressed("DragCamera"):
		dragging = true
		drag_start_location = event.global_position
		initial_position = self.global_position
	if event.is_action_released("DragCamera"):
		dragging = false
	if dragging and event is InputEventMouseMotion:
		var mouse_pos = event.global_position
		self.global_position = initial_position + (drag_start_location-mouse_pos) * (1/zoom_level)
		

func set_zoom_level(level: float, mouse_world_position = self.get_global_mouse_position()):
	var old_zoom_level = zoom_level
	
	zoom_level = clampf(level, min_zoom, max_zoom)
	
	var direction = (mouse_world_position - self.global_position)
	var new_position = self.global_position + direction - ((direction) / (zoom_level/old_zoom_level))
	
	self.zoom = Vector2(zoom_level, zoom_level)
	self.global_position = new_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

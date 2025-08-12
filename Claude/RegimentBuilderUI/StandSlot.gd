extends TextureRect
class_name StandSlot

signal stand_dropped(from_slot: StandSlot, to_slot: StandSlot)
signal stand_returned_to_tray(slot: StandSlot)

@onready var background_panel: Panel = $BackgroundPanel

var stand_data: Dictionary = {}
var original_tray: Control
var is_dragging: bool = false
var drag_preview: Control

func _ready():
	custom_minimum_size = Vector2(64, 64)
	_update_background_visibility()

func set_stand_data(data: Dictionary, tray: Control):
	stand_data = data
	original_tray = tray
	if data.has("icon"):
		texture = data.icon
	tooltip_text = data.get("name", "")
	_update_background_visibility()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not stand_data.is_empty():
				_start_drag()
			elif not event.pressed and is_dragging:
				_end_drag()

func _start_drag():
	is_dragging = true
	_create_drag_preview()
	
func _create_drag_preview():
	drag_preview = TextureRect.new()
	drag_preview.texture = texture
	drag_preview.size = size
	drag_preview.modulate = Color(1, 1, 1, 0.7)
	get_viewport().add_child(drag_preview)
	
func _process(_delta):
	if is_dragging and drag_preview:
		drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2

func _end_drag():
	if not is_dragging:
		return
		
	is_dragging = false
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	
	var drop_target = _get_drop_target()
	if drop_target and drop_target != self:
		stand_dropped.emit(self, drop_target)
	elif not _is_over_valid_area():
		stand_returned_to_tray.emit(self)

func _get_drop_target() -> StandSlot:
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collision_mask = 1
	
	var all_slots = get_tree().get_nodes_in_group("stand_slots")
	for slot in all_slots:
		if slot != self and slot.get_global_rect().has_point(mouse_pos):
			return slot as StandSlot
	return null

func _is_over_valid_area() -> bool:
	var mouse_pos = get_global_mouse_position()
	var all_trays = get_tree().get_nodes_in_group("stand_trays")
	for tray in all_trays:
		if tray.get_global_rect().has_point(mouse_pos):
			return true
	return false

func clear_stand():
	stand_data = {}
	texture = null
	tooltip_text = ""
	_update_background_visibility()

func is_empty() -> bool:
	return stand_data.is_empty()

func _update_background_visibility():
	if background_panel:
		background_panel.visible = stand_data.is_empty()

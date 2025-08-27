extends TextureRect
class_name StandSlot

# Static variable to track the currently hovered slot during drag
static var currently_hovered_slot: StandSlot = null

# Signals for drag-drop operations and highlighting coordination
signal stand_dropped(from_slot: StandSlot, to_slot: StandSlot)
signal drag_started(slot: StandSlot)
signal drag_ended(slot: StandSlot)

@onready var background_panel: Panel = $BackgroundPanel

# Stand information and tray management
var stand_data: Dictionary = {}  # Contains id, name, type, icon
var original_tray: Control       # Reference to the tray this stand came from
var slot_type: String = ""       # "character", "troop", or "regiment"


# Visual highlighting for valid drop zones
var border_overlay: Control      # Green border for compatible slots
var hover_border_overlay: Control  # Yellow border for hover target

func _ready():
	custom_minimum_size = Vector2(64, 64)
	_setup_border_overlay()
	_update_background_visibility()

# Creates border overlays for highlighting (green for compatible, yellow for hover)
func _setup_border_overlay():
	# Green border for compatible slots
	border_overlay = Control.new()
	border_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_overlay.visible = false
	add_child(border_overlay)
	
	var green_style = StyleBoxFlat.new()
	green_style.bg_color = Color.TRANSPARENT
	green_style.border_width_top = 3
	green_style.border_width_bottom = 3
	green_style.border_width_left = 3
	green_style.border_width_right = 3
	green_style.border_color = Color.GREEN
	
	var green_panel = Panel.new()
	green_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	green_panel.add_theme_stylebox_override("panel", green_style)
	green_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_overlay.add_child(green_panel)
	
	# Yellow border for hover target (higher z-index for priority)
	hover_border_overlay = Control.new()
	hover_border_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hover_border_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_border_overlay.visible = false
	add_child(hover_border_overlay)
	
	var yellow_style = green_style.duplicate()
	yellow_style.border_color = Color.YELLOW
	
	var yellow_panel = Panel.new()
	yellow_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	yellow_panel.add_theme_stylebox_override("panel", yellow_style)
	yellow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_border_overlay.add_child(yellow_panel)

func set_stand_data(data: Dictionary, tray: Control):
	stand_data = data
	original_tray = tray
	if data.has("icon"):
		texture = data.icon
	tooltip_text = data.get("name", "")
	_update_background_visibility()

# Sets the slot type which determines what stand types it can accept
func set_slot_type(type: String):
	slot_type = type

# Type validation: checks if this slot can accept the given stand
func can_accept_stand(stand_data_to_check: Dictionary) -> bool:
	if slot_type == "regiment":
		return true  # Regiment slots accept both character and troop stands
	elif slot_type == "character":
		return stand_data_to_check.get("type", "") == "character"
	elif slot_type == "troop":
		return stand_data_to_check.get("type", "") == "troop"
	return false

# Shows or hides the green border highlight
func set_highlight(enabled: bool):
	if border_overlay:
		border_overlay.visible = enabled

# Shows or hides the yellow hover highlight
func set_hover_highlight(enabled: bool):
	if hover_border_overlay:
		hover_border_overlay.visible = enabled

# Updates highlight based on whether this slot can accept the dragged stand
func update_highlight_for_drag(dragged_stand_data: Dictionary):
	var can_accept = can_accept_stand(dragged_stand_data)
	set_highlight(can_accept)  # Show green border if compatible

# Godot's built-in drag and drop system
func _get_drag_data(_position):
	if stand_data.is_empty():
		return null
	
	# Emit drag started signal for highlighting
	drag_started.emit(self)
	
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = texture
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.7)
	set_drag_preview(preview)
	
	# Return the stand data as drag data
	return {
		"source_slot": self,
		"stand_data": stand_data,
		"original_tray": original_tray
	}

func _can_drop_data(_position, data):
	if not data.has("stand_data"):
		return false
	
	var dragged_stand_data = data["stand_data"]
	var can_accept = can_accept_stand(dragged_stand_data)
	
	# Clear previous hover highlight if we moved to a different slot
	if currently_hovered_slot and currently_hovered_slot != self:
		currently_hovered_slot.set_hover_highlight(false)
	
	# Show yellow hover highlight when hovering over this slot during drag
	if can_accept:
		set_hover_highlight(true)
		currently_hovered_slot = self
	
	return can_accept

func _drop_data(_position, data):
	var source_slot = data["source_slot"]
	
	# Clear hover highlight and reset tracking
	if currently_hovered_slot:
		currently_hovered_slot.set_hover_highlight(false)
		currently_hovered_slot = null
	
	# Emit the drag ended signal to clear highlights
	drag_ended.emit(source_slot)
	
	# Handle the drop
	stand_dropped.emit(source_slot, self)

# Handle drag cancellation (when drag is started but not completed)
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# Clear hover highlight and reset tracking
		if currently_hovered_slot:
			currently_hovered_slot.set_hover_highlight(false)
			currently_hovered_slot = null
		# Clear highlights when drag ends (whether successful or cancelled)
		drag_ended.emit(self)


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

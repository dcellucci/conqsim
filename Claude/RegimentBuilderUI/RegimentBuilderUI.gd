extends Control
class_name RegimentBuilderUI

signal drag_started(dragged_stand_data: Dictionary)
signal drag_ended()

@onready var width_spinbox: SpinBox = $VBoxContainer/RegimentControls/WidthSpinBox
@onready var height_spinbox: SpinBox = $VBoxContainer/RegimentControls/HeightSpinBox
@onready var character_tray: GridContainer = $VBoxContainer/MainContent/LeftPanel/CharacterTray
@onready var troop_tray: GridContainer = $VBoxContainer/MainContent/LeftPanel/TroopTray
@onready var regiment_tray: GridContainer = $VBoxContainer/MainContent/RightPanel/RegimentTray
@onready var output_button: Button = $VBoxContainer/OutputButton

var character_stands: Array = []
var troop_stands: Array = []
var stand_slot_scene: PackedScene

func _ready():
	stand_slot_scene = preload("res://StandSlot.tscn")
	
	width_spinbox.value_changed.connect(_on_regiment_size_changed)
	height_spinbox.value_changed.connect(_on_regiment_size_changed)
	output_button.pressed.connect(_on_output_button_pressed)
	
	_initialize_default_stands()
	_setup_regiment_tray()

# Creates default character and troop stands with their type information
func _initialize_default_stands():
	character_stands = [
		{"id": "char_001", "name": "Hero", "type": "character", "icon": _create_colored_texture(Color.BLUE)},
		{"id": "char_002", "name": "Wizard", "type": "character", "icon": _create_colored_texture(Color.PURPLE)},
		{"id": "char_003", "name": "Rogue", "type": "character", "icon": _create_colored_texture(Color.DARK_GREEN)},
		{"id": "char_004", "name": "Cleric", "type": "character", "icon": _create_colored_texture(Color.YELLOW)},
	]
	
	troop_stands = [
		{"id": "troop_001", "name": "Infantry", "type": "troop", "icon": _create_colored_texture(Color.RED)},
		{"id": "troop_002", "name": "Archers", "type": "troop", "icon": _create_colored_texture(Color.ORANGE)},
		{"id": "troop_003", "name": "Cavalry", "type": "troop", "icon": _create_colored_texture(Color.BROWN)},
		{"id": "troop_004", "name": "Spearmen", "type": "troop", "icon": _create_colored_texture(Color.GRAY)},
		{"id": "troop_005", "name": "Knights", "type": "troop", "icon": _create_colored_texture(Color.GOLD)},
		{"id": "troop_006", "name": "Crossbows", "type": "troop", "icon": _create_colored_texture(Color.DARK_BLUE)},
	]
	
	_populate_tray(character_tray, character_stands)
	_populate_tray(troop_tray, troop_stands)


func _create_colored_texture(color: Color) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Populates a tray with stands, creating stands.size() + 1 slots (one empty slot on the right)
func _populate_tray(tray: GridContainer, stands: Array):
	# Determine slot type based on which tray we're populating
	var slot_type = ""
	if tray == character_tray:
		slot_type = "character"
	elif tray == troop_tray:
		slot_type = "troop"
	
	# Always create one extra empty slot for dropping new stands
	var required_slots = stands.size() + 1
	
	# Create slots and populate with stands (left-aligned)
	for i in range(required_slots):
		var slot = stand_slot_scene.instantiate() as StandSlot
		tray.add_child(slot)
		slot.set_slot_type(slot_type)
		# Connect all the drag-drop and highlighting signals
		slot.stand_dropped.connect(_on_stand_dropped)
		slot.drag_started.connect(_on_drag_started)
		slot.drag_ended.connect(_on_drag_ended)
		
		# Fill slots from left to right, leaving the last one empty
		if i < stands.size():
			slot.set_stand_data(stands[i], tray)

func _clear_tray(tray: GridContainer):
	for child in tray.get_children():
		child.queue_free()

# Sets up the regiment tray grid based on width/height spinbox values
func _setup_regiment_tray():
	_clear_tray(regiment_tray)
	
	var width = int(width_spinbox.value)
	var height = int(height_spinbox.value)
	regiment_tray.columns = width
	
	# Create grid of empty slots that accept both character and troop stands
	for i in range(width * height):
		var slot = stand_slot_scene.instantiate() as StandSlot
		regiment_tray.add_child(slot)
		slot.set_slot_type("regiment")  # Accepts both character and troop types
		slot.stand_dropped.connect(_on_stand_dropped)
		slot.drag_started.connect(_on_drag_started)
		slot.drag_ended.connect(_on_drag_ended)

func _on_regiment_size_changed(_value: float):
	_return_all_regiment_stands_to_trays()
	_setup_regiment_tray()

# Returns all stands from regiment tray back to their original character/troop trays
# Preserves existing stands and prevents duplication by collecting everything first
func _return_all_regiment_stands_to_trays():
	# Collect stands to return, organized by their original tray type
	var character_stands_to_return = []
	var troop_stands_to_return = []
	
	# Extract all stands from regiment tray and sort by original tray
	for slot in regiment_tray.get_children():
		if not slot.is_empty():
			var stand_data = slot.stand_data
			var original_tray = slot.original_tray
			
			if original_tray == character_tray:
				character_stands_to_return.append(stand_data)
			elif original_tray == troop_tray:
				troop_stands_to_return.append(stand_data)
			
			slot.clear_stand()
	
	# Get stands that are already in the trays (to avoid losing them)
	var existing_character_stands = _get_tray_stands(character_tray)
	var existing_troop_stands = _get_tray_stands(troop_tray)
	
	# Combine existing stands with returned stands
	var all_character_stands = existing_character_stands + character_stands_to_return
	var all_troop_stands = existing_troop_stands + troop_stands_to_return
	
	# Rebuild trays with the complete set of stands
	_clear_tray(character_tray)
	_clear_tray(troop_tray)
	
	_populate_tray(character_tray, all_character_stands)
	_populate_tray(troop_tray, all_troop_stands)

# Handles when a stand is dropped onto another slot
# Manages tray resizing to prevent duplication bugs
func _on_stand_dropped(from_slot: StandSlot, to_slot: StandSlot):
	var from_tray = from_slot.get_parent()
	var to_tray = to_slot.get_parent()
	
	# Transfer stand (handles both move and swap automatically)
	_transfer_stand(from_slot, to_slot)
	
	if from_tray == character_tray or from_tray == troop_tray:
		_resize_tray(from_tray)
	if from_tray != to_tray and (to_tray == character_tray or to_tray == troop_tray):
		_resize_tray(to_tray)


# Handles both moving and swapping stands based on target slot state
func _transfer_stand(from_slot: StandSlot, to_slot: StandSlot):
	var stand_data = from_slot.stand_data
	var original_tray = from_slot.original_tray
	if to_slot.is_empty():
		#If to_slot is empty, then we can just clear the data in from_slot
		from_slot.clear_stand()
	else:
		# if to_slot isn't empty, then we need to swap the data
		var data2 = to_slot.stand_data
		var tray2 = to_slot.original_tray
		from_slot.set_stand_data(data2, tray2)
	to_slot.set_stand_data(stand_data, original_tray)

func _get_all_slots() -> Array[StandSlot]:
	var all_slots: Array[StandSlot] = []
	
	for child in character_tray.get_children():
		if child is StandSlot:
			all_slots.append(child as StandSlot)
	
	for child in troop_tray.get_children():
		if child is StandSlot:
			all_slots.append(child as StandSlot)
	
	for child in regiment_tray.get_children():
		if child is StandSlot:
			all_slots.append(child as StandSlot)
	
	return all_slots


# Helper function: extracts all stand data from filled slots in a tray
func _get_tray_stands(tray: GridContainer) -> Array:
	var stands = []
	for child in tray.get_children():
		var slot = child as StandSlot
		if slot and not slot.is_empty():
			stands.append(slot.stand_data)
	return stands

# Dynamically resizes character/troop trays to fit their contents + 1 empty slot
# Preserves stand order and ensures left-alignment
func _resize_tray(tray: GridContainer):
	# Don't resize the regiment tray - it uses fixed grid dimensions
	if tray == regiment_tray:
		return
	
	# Get current stands and calculate how many slots we need
	var stands = _get_tray_stands(tray)
	var required_slots = stands.size() + 1  # +1 for empty slot
	
	# Clear and rebuild the tray
	_clear_tray(tray)
	
	var slot_type = ""
	if tray == character_tray:
		slot_type = "character"
	elif tray == troop_tray:
		slot_type = "troop"
	
	for i in range(required_slots):
		var slot = stand_slot_scene.instantiate() as StandSlot
		tray.add_child(slot)
		slot.set_slot_type(slot_type)
		slot.stand_dropped.connect(_on_stand_dropped)
		#slot.stand_returned_to_tray.connect(_on_stand_returned_to_tray)
		slot.drag_started.connect(_on_drag_started)
		slot.drag_ended.connect(_on_drag_ended)
		
		if i < stands.size():
			slot.set_stand_data(stands[i], tray)

# Highlights all compatible slots when a drag operation begins
func _on_drag_started(slot: StandSlot):
	var dragged_data = slot.stand_data
	var all_slots = _get_all_slots()
	
	# Show green borders on slots that can accept this stand type
	for other_slot in all_slots:
		if other_slot != slot:
			other_slot.update_highlight_for_drag(dragged_data)

# Clears all slot highlights when a drag operation ends
func _on_drag_ended(slot: StandSlot):
	var all_slots = _get_all_slots()
	
	# Remove all green and yellow border highlights
	for other_slot in all_slots:
		other_slot.set_highlight(false)
		other_slot.set_hover_highlight(false)

func _on_output_button_pressed():
	var regiment_data = []
	var width = int(width_spinbox.value)
	var height = int(height_spinbox.value)
	
	for row in range(height):
		var row_data = []
		for col in range(width):
			var index = row * width + col
			var slot = regiment_tray.get_child(index) as StandSlot
			
			if slot and not slot.is_empty():
				row_data.append({
					"name": slot.stand_data.get("name", ""),
					"id": slot.stand_data.get("id", "")
				})
			else:
				row_data.append(null)
		regiment_data.append(row_data)
	
	print("Regiment Formation:")
	for row in regiment_data:
		var row_names = []
		for stand in row:
			if stand:
				row_names.append(stand.name + " (" + stand.id + ")")
			else:
				row_names.append("Empty")
		print("  ", row_names)
	
	var flat_stands = []
	for row in regiment_data:
		for stand in row:
			if stand:
				flat_stands.append(stand)
	
	print("\nFlat Regiment List:")
	for stand in flat_stands:
		print("  Name: ", stand.name, ", ID: ", stand.id)

extends Control
class_name RegimentBuilderUI

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

func _initialize_default_stands():
	character_stands = [
		{"id": "char_001", "name": "Hero", "icon": _create_colored_texture(Color.BLUE)},
		{"id": "char_002", "name": "Wizard", "icon": _create_colored_texture(Color.PURPLE)},
		{"id": "char_003", "name": "Rogue", "icon": _create_colored_texture(Color.DARK_GREEN)},
		{"id": "char_004", "name": "Cleric", "icon": _create_colored_texture(Color.YELLOW)},
	]
	
	troop_stands = [
		{"id": "troop_001", "name": "Infantry", "icon": _create_colored_texture(Color.RED)},
		{"id": "troop_002", "name": "Archers", "icon": _create_colored_texture(Color.ORANGE)},
		{"id": "troop_003", "name": "Cavalry", "icon": _create_colored_texture(Color.BROWN)},
		{"id": "troop_004", "name": "Spearmen", "icon": _create_colored_texture(Color.GRAY)},
		{"id": "troop_005", "name": "Knights", "icon": _create_colored_texture(Color.GOLD)},
		{"id": "troop_006", "name": "Crossbows", "icon": _create_colored_texture(Color.DARK_BLUE)},
	]
	
	_populate_tray(character_tray, character_stands)
	_populate_tray(troop_tray, troop_stands)

func initialize_stands(custom_characters: Array, custom_troops: Array):
	character_stands = custom_characters
	troop_stands = custom_troops
	
	_clear_tray(character_tray)
	_clear_tray(troop_tray)
	
	_populate_tray(character_tray, character_stands)
	_populate_tray(troop_tray, troop_stands)

func _create_colored_texture(color: Color) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _populate_tray(tray: GridContainer, stands: Array):
	for stand_data in stands:
		var slot = stand_slot_scene.instantiate() as StandSlot
		tray.add_child(slot)
		slot.set_stand_data(stand_data, tray)
		slot.stand_dropped.connect(_on_stand_dropped)
		slot.stand_returned_to_tray.connect(_on_stand_returned_to_tray)

func _clear_tray(tray: GridContainer):
	for child in tray.get_children():
		child.queue_free()

func _setup_regiment_tray():
	_clear_tray(regiment_tray)
	
	var width = int(width_spinbox.value)
	var height = int(height_spinbox.value)
	regiment_tray.columns = width
	
	for i in range(width * height):
		var slot = stand_slot_scene.instantiate() as StandSlot
		regiment_tray.add_child(slot)
		slot.stand_dropped.connect(_on_stand_dropped)
		slot.stand_returned_to_tray.connect(_on_stand_returned_to_tray)

func _on_regiment_size_changed(_value: float):
	_return_all_regiment_stands_to_trays()
	_setup_regiment_tray()

func _return_all_regiment_stands_to_trays():
	for slot in regiment_tray.get_children():
		if not slot.is_empty():
			_return_stand_to_original_tray(slot)

func _on_stand_dropped(from_slot: StandSlot, to_slot: StandSlot):
	if to_slot.is_empty():
		_move_stand(from_slot, to_slot)
	else:
		_swap_stands(from_slot, to_slot)

func _on_stand_returned_to_tray(slot: StandSlot):
	if slot.get_parent() == regiment_tray:
		_return_stand_to_original_tray(slot)

func _move_stand(from_slot: StandSlot, to_slot: StandSlot):
	var stand_data = from_slot.stand_data
	var original_tray = from_slot.original_tray
	
	to_slot.set_stand_data(stand_data, original_tray)
	from_slot.clear_stand()

func _swap_stands(slot1: StandSlot, slot2: StandSlot):
	var data1 = slot1.stand_data
	var tray1 = slot1.original_tray
	var data2 = slot2.stand_data
	var tray2 = slot2.original_tray
	
	slot1.set_stand_data(data2, tray2)
	slot2.set_stand_data(data1, tray1)

func _return_stand_to_original_tray(slot: StandSlot):
	var stand_data = slot.stand_data
	var original_tray = slot.original_tray
	
	var empty_slot = _find_empty_slot_in_tray(original_tray)
	if empty_slot:
		empty_slot.set_stand_data(stand_data, original_tray)
		slot.clear_stand()

func _find_empty_slot_in_tray(tray: GridContainer) -> StandSlot:
	for child in tray.get_children():
		var slot = child as StandSlot
		if slot and slot.is_empty():
			return slot
	return null

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
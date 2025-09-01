extends VBoxContainer

func _ready():
	# Start by updating the display based on the selected regiment values
	update_display()
	# Then connect up all of the signals with the update functions
	$RangeSpinRow/RangeSpinBox.value_changed.connect(update_regiment_barrage_range)
	$FluidFormationCheckButton.toggled.connect(update_regiment_fluid_formation)
	$BarrageModeToggleButton.pressed.connect(toggle_barrage_measure_mode)
	$CancelButton.pressed.connect(cancel_barrage_mode)
	
func _process(delta: float):
	# Display different text based on the barrage mode we are currently in
	if GameState.barrage_measure_los_mode:
		$BarrageModeToggleButton.text = "Switch to Range Mode (Tab)"
	else: 
		$BarrageModeToggleButton.text = "Switch to LOS Mode (Tab)"
	process_input()
	
func process_input():
	# Escape clause to process user input only if the current UI state is
	# the barrage state
	if GameState.selected_regiment_state != GameState.Regiment.UIState.BARRAGE:
		return
		
	if Input.is_action_just_pressed('BarrageToggleMeasureMode'):
		toggle_barrage_measure_mode()
	if Input.is_action_just_pressed('BarrageIncreaseRange'):
		GameState.selected_regiment.barrage_range = GameState.selected_regiment.barrage_range + 1
	if Input.is_action_just_pressed('BarrageDecreaseRange'):
		GameState.selected_regiment.barrage_range = GameState.selected_regiment.barrage_range - 1

func update_display():
	# Escape clause in case selected regiment has no data
	if GameState.selected_regiment == null:
		return
	# The Spinbox range value should match the selected regiment's barrage range
	$RangeSpinRow/RangeSpinBox.value = GameState.selected_regiment.barrage_range
	# The check button value for fluid formation should likewise match the 
	# selected regiment
	$FluidFormationCheckButton.button_pressed = GameState.selected_regiment.fluid_formation

func update_regiment_barrage_range(value: float):
	# Escape clause in case selected regiment has no data
	if GameState.selected_regiment == null:
		return
	# Replace the selected regiment's barrage range with the value output by the
	# spin box signal
	GameState.selected_regiment.barrage_range = int(value)
	
func update_regiment_fluid_formation(toggled_on: bool):
	# Escape clause in case selected regiment has no data
	if GameState.selected_regiment == null:
		return
	# Replace the selected regiment's fluid formation status with the value 
	# output by the check box toggled signal
	GameState.selected_regiment.fluid_formation = toggled_on
	
func toggle_barrage_measure_mode():
	GameState.barrage_measure_los_mode = !GameState.barrage_measure_los_mode

func cancel_barrage_mode():
	GameState.selected_regiment_state = GameState.Regiment.UIState.NONE

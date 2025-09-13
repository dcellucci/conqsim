extends VBoxContainer

func _ready():
	# Start by updating the display based on the selected regiment values
	update_display()
	# Then connect up all of the signals with the update functions
	$RangeSpinRow/RangeSpinBox.value_changed.connect(update_regiment_barrage_range)
	$FluidFormationCheckButton.toggled.connect(update_regiment_fluid_formation)
	$SnapToRegimentCheckButton.toggled.connect(update_barrage_ui_snap_setting)
	$BarrageModeToggleButton.pressed.connect(toggle_barrage_measure_mode)
	$CancelButton.pressed.connect(cancel_barrage_mode)
	
func _process(delta: float):
	# Display different text based on the barrage mode we are currently in
	if UiStateMachine.ui_state_machine.state == UiStateMachine.UIState.BARRAGE_LOS:
		$BarrageModeToggleButton.text = "Switch to Range Mode (Tab)"
	else: 
		$BarrageModeToggleButton.text = "Switch to LOS Mode (Tab)"
	process_input()
	update_display()
	
func process_input():
	# Escape clause to process user input only if the current UI state is
	# the barrage state
	if not UiStateMachine.ui_state_machine.is_barrage_state():
		return
		
	if Input.is_action_just_pressed('UIToggleMode'):
		toggle_barrage_measure_mode()
	if Input.is_action_just_pressed('UIIncreaseValue'):
		GameState.selected_regiment.barrage_range = GameState.selected_regiment.barrage_range + 1
	if Input.is_action_just_pressed('UIDecreaseValue'):
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
	$SnapToRegimentCheckButton.button_pressed = GameSettings.hud_regiment_snap
		
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
	

func update_barrage_ui_snap_setting(toggled_on: bool):
	# match the snap setting to the current value output by the check box
	# toggled signal
	GameSettings.hud_regiment_snap = toggled_on
	
func toggle_barrage_measure_mode():
	var new_state = UiStateMachine.UIState.BARRAGE_LOS
	if UiStateMachine.ui_state_machine.state == UiStateMachine.UIState.BARRAGE_LOS:
		UiStateMachine.ui_state_machine.set_new_state(UiStateMachine.UIState.BARRAGE_RANGE)		
	UiStateMachine.ui_state_machine.set_new_state(new_state)

func cancel_barrage_mode():
	UiStateMachine.ui_state_machine.set_new_state(UiStateMachine.UIState.NONE)

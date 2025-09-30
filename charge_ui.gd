extends VBoxContainer

func _ready():
	# Start by updating the display based on the selected regiment values
	update_display()
	# Then connect up all of the signals with the update functions
	$MoveSpinRow/MoveSpinBox.value_changed.connect(update_regiment_charge_range)
	$CycleMeasureModeButton.toggled.connect(cycle_charge_measure_mode)
	$MeasureModeToggleButton.pressed.connect(toggle_measure_mode)
	$CancelButton.pressed.connect(cancel_charge_mode)
	
func _process(delta: float):
	process_input()
	update_display()
	
	
func process_input():
	# Escape clause to process user input only if the current UI state is
	# the barrage state
	if not UiStateMachine.ui_state_machine.is_charge_state():
		return
		
	if Input.is_action_just_pressed('UIToggleMode'):
		toggle_measure_mode()
	if Input.is_action_just_pressed('UIIncreaseValue'):
		GameState.selected_regiment.barrage_range = GameState.selected_regiment.barrage_range + 1
	if Input.is_action_just_pressed('UIDecreaseValue'):
		GameState.selected_regiment.barrage_range = GameState.selected_regiment.barrage_range - 1
	
	
func update_display():
	# Escape clause in case selected regiment has no data
	if GameState.selected_regiment == null:
		return
	# Display different text based on the barrage mode we are currently in
	if UiStateMachine.ui_state_machine.state != UiStateMachine.UIState.CHARGE_FRONTAGE:
		$MeasureModeToggleButton.visible = true
		if UiStateMachine.ui_state_machine.is_charge_measure_state():
			$MeasureModeToggleButton.text = "Switch to Overlay Mode (Tab)"
		else: 
			$MeasureModeToggleButton.text = "Switch to Measure Mode (Tab)"
	else:
		$MeasureModeToggleButton.visible = false
		
	# The Spinbox range value should match the selected regiment's barrage range
	# The move box should only be visible if we are in charge state but we 
	# also aren't in a charge measure mode
	$MoveSpinRow.visible = (UiStateMachine.ui_state_machine.state in [
		UiStateMachine.UIState.CHARGE_TARGET
	  , UiStateMachine.UIState.CHARGE_REFORM_ROTATE
	  ])
	$MoveSpinRow/MoveSpinBox.value = GameState.selected_regiment.move
	
	# The check button value for fluid formation should likewise match the 
	# selected regiment
	$CycleMeasureModeButton.visible = UiStateMachine.ui_state_machine.is_charge_measure_state()
	match UiStateMachine.ui_state_machine.state:
		UiStateMachine.UIState.CHARGE_MEASURE_SNAP_FACE:
			$CycleMeasureModeButton.text = "Cycle to free mode (space)"
		UiStateMachine.UIState.CHARGE_MEASURE_FREE:
			$CycleMeasureModeButton.text = "Cycle to regiment snap mode (space)"
		UiStateMachine.UIState.CHARGE_MEASURE_SNAP_REGIMENT:
			$CycleMeasureModeButton.text = "Cycle to face snap mode (space)"
	$InfoText.custom_minimum_size.x = get_size().x
	if UiStateMachine.ui_state_machine.is_charge_measure_state():
		$InfoText.text = "Measure the distance required to charge a regiment (Press tab to swap to select target mode)"

	match UiStateMachine.ui_state_machine.state:
		UiStateMachine.UIState.CHARGE_TARGET:
			$InfoText.text = "Select a regiment and face to charge. (Press tab to swap to measure mode)"
		UiStateMachine.UIState.CHARGE_FRONTAGE:
			$InfoText.text = "Select a frontage for the regiment."
		UiStateMachine.UIState.CHARGE_REFORM_ROTATE:
			$InfoText.text = "Rotate the regiment."
	
func update_regiment_charge_range(value: float):
	# Escape clause in case selected regiment has no data
	if GameState.selected_regiment == null:
		return
	# Replace the selected regiment's barrage range with the value output by the
	# spin box signal
	GameState.selected_regiment.move = int(value)
	for displayed_regiment in GameState.displayed_regiments:
		if displayed_regiment.regiment == GameState.selected_regiment:
			displayed_regiment.update_display()

func update_cursor_regiment_snap_setting(toggled_on: bool):
	# match the snap setting to the current value output by the check box
	# toggled signal
	GameSettings.hud_regiment_snap = toggled_on
	
func toggle_measure_mode():
	if UiStateMachine.ui_state_machine.state == UiStateMachine.UIState.CHARGE_REFORM_ROTATE:
		return
	var new_state = UiStateMachine.UIState.CHARGE_TARGET
	if UiStateMachine.ui_state_machine.state == UiStateMachine.UIState.CHARGE_TARGET:
		new_state = UiStateMachine.UIState.CHARGE_MEASURE_FREE
	UiStateMachine.ui_state_machine.set_new_state(new_state)

func cycle_charge_measure_mode():
	UiStateMachine.ui_state_machine.cycle_charge_measure_state()

func cancel_charge_mode():
	UiStateMachine.ui_state_machine.cancel_state()

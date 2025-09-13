extends VBoxContainer


func _ready() -> void:
	$HBoxContainer/MoveRegimentButton.pressed.connect(
		UiStateMachine.ui_state_machine.set_new_state.bind(
			UiStateMachine.UIState.MOVE_INITIALIZE
		)
	)
	$HBoxContainer/ChargeRegimentButton.pressed.connect(
		UiStateMachine.ui_state_machine.set_new_state.bind(
			UiStateMachine.UIState.CHARGE_INITIALIZE
		)
	)
	$HBoxContainer/BarrageButton.pressed.connect(
		UiStateMachine.ui_state_machine.set_new_state.bind(
			UiStateMachine.UIState.BARRAGE_LOS
		)
	)
	
	

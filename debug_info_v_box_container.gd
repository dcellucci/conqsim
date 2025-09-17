extends VBoxContainer

func _process(delta: float) -> void:
	$UIStateLabel.text = UiStateMachine.ui_state_machine.get_state_string()

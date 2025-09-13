extends CanvasLayer

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	$LeftSidebarPanel/LeftSidebarVBoxContainer/BarrageMenu.visible = (
		UiStateMachine.ui_state_machine.is_barrage_state()
	)
	
	$LeftSidebarPanel/LeftSidebarVBoxContainer/SelectRegimentUI.visible = (
		UiStateMachine.ui_state_machine.is_idle() and 
		GameState.selected_regiment != null
	)
	
	$LeftSidebarPanel/LeftSidebarVBoxContainer/ChargeMenu.visible = (
		UiStateMachine.ui_state_machine.is_charge_state()
	)

func update_dims():
	$LeftSidebarPanel.set_size(Vector2(
		GameSettings.sidebar_width_px
	  , GameSettings.window_height_px
	  ))
	$RightSidebarPanel.set_size(Vector2(
		GameSettings.sidebar_width_px
	  , GameSettings.window_height_px
	  ))
	$RightSidebarPanel.set_position(Vector2(
		GameSettings.window_width_px-GameSettings.sidebar_width_px
	  , 0
	  ))

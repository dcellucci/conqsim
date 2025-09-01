extends CanvasLayer

func _ready() -> void:
	pass
	
	
## TODO: How do we get the UI to "wrap" Hbox entries based on the parent width?
func _process(delta: float) -> void:
	$LeftSidebarPanel/LeftSidebarVBoxContainer/BarrageMenu.visible = (
		GameState.selected_regiment_state == GameState.Regiment.UIState.BARRAGE
	)
	
	$LeftSidebarPanel/LeftSidebarVBoxContainer/SelectRegimentUI.visible = (
		GameState.selected_regiment_state == GameState.Regiment.UIState.NONE
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

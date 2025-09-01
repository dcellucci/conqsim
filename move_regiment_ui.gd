extends Control

func update_display(regiment: GameState.Regiment) -> void:
	if regiment == null:
		return
	visible = (regiment == GameState.selected_regiment)
	print(GameSettings.regiment_ui_button_size)
	# Default Button size is in the game settings
	$MarchButton.size = Vector2(
		GameSettings.regiment_ui_button_size
	  , GameSettings.regiment_ui_button_size
	  )
	#We also have to resize the texture...
	$MarchButton.texture_normal.size = Vector2(
		GameSettings.regiment_ui_button_size
	  , GameSettings.regiment_ui_button_size
	  )
	
	# The March button should be centered on the front edge of the regiment
	$MarchButton.position = Vector2(
		-GameSettings.regiment_ui_button_size/2.
	  , -regiment.height/2.*GameSettings.STAND_DIM_PX-GameSettings.regiment_ui_button_size
	  )

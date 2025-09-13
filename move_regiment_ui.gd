extends Control

#This function should ever get called when we have changed some local quality of the
#regiment (width, height)
func update_display(regiment: GameState.Regiment) -> void:
	update_march_button_display(regiment)
	update_reform_button_display(regiment)
	
func update_reform_button_display(regiment: GameState.Regiment):
	# Default Button size is in the game settings
	$ReformButton.size = Vector2(
		GameSettings.regiment_ui_button_size
	  , GameSettings.regiment_ui_button_size
	  )
	#We also have to resize the texture...
	$ReformButton.texture_normal.size = Vector2(
		GameSettings.regiment_ui_button_size
	  , GameSettings.regiment_ui_button_size
	  )
	# The March button should be centered on the front edge of the regiment
	$ReformButton.position = Vector2(
		regiment.width/2.*GameSettings.STAND_DIM_PX
	  , -GameSettings.regiment_ui_button_size/2.
	  )
func update_march_button_display(regiment: GameState.Regiment):
	$MarchButton.visible = false 
	if not UiStateMachine.ui_state_machine.is_move_state():
		return
		
	$MarchButton.visible = true 
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

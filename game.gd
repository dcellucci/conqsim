extends Node2D
var regiment_scene = preload("res://Regiment.tscn")

func _ready():
	var starting_game_state: GameState.InterimGameState = GameState.InterimGameState.new()
	var test_regiment: GameState.Regiment = GameState.Regiment.new()
	
	test_regiment.width = 3
	test_regiment.height = 1
	test_regiment.position.x = 200
	test_regiment.position.y = 200
	test_regiment.rotation = 45
	test_regiment.barrage_range = 10
	test_regiment.move = 5
	
	var test_regiment_display = regiment_scene.instantiate()
	test_regiment_display.regiment = test_regiment	
	test_regiment_display.update_display()
	add_child(test_regiment_display)
	
	var test_regiment2: GameState.Regiment = GameState.Regiment.new()
	test_regiment2.width = 3
	test_regiment2.height = 1
	test_regiment2.position.x = 200
	test_regiment2.position.y = -300
	test_regiment2.rotation = 180
	test_regiment.move = 6
	
	var test_regiment_display2 = regiment_scene.instantiate()
	test_regiment_display2.regiment = test_regiment2
	test_regiment_display2.update_display()
	add_child(test_regiment_display2)
	
	GameState.selected_regiment = test_regiment
	UiStateMachine.ui_state_machine.set_new_state(UiStateMachine.UIState.CHARGE_INITIALIZE)
	
	starting_game_state.regiments = [test_regiment,test_regiment2]
	GameState.displayed_regiments = [test_regiment_display,test_regiment_display2]
	GameState.interim_game_states = [starting_game_state]
	
	$Board.update_dims()
	$HUDCanvasLayer.update_dims()
	$BoardHUDManager/BarrageHUD.update_display()

func _process(delta: float) -> void:
	if UiStateMachine.ui_state_machine.state != UiStateMachine.UIState.NONE:
		return
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < GameSettings.sidebar_width_px or mouse_pos.x > (GameSettings.window_width_px - GameSettings.sidebar_width_px):
		return
	if Input.is_action_just_pressed('SelectRegiment'):
		GameState.selected_regiment = GameState.hovered_regiment
	

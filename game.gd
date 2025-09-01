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
	
	var test_regiment_display = regiment_scene.instantiate()
	test_regiment_display.regiment = test_regiment
	add_child(test_regiment_display)
	
	var test_regiment2: GameState.Regiment = GameState.Regiment.new()
	test_regiment2.width = 3
	test_regiment2.height = 1
	test_regiment2.position.x = 200
	test_regiment2.position.y = -500
	test_regiment2.rotation = 180
	
	var test_regiment_display2 = regiment_scene.instantiate()
	test_regiment_display2.regiment = test_regiment2
	add_child(test_regiment_display2)
	
	GameState.selected_regiment = test_regiment
	GameState.selected_regiment_state = GameState.Regiment.UIState.BARRAGE
	
	starting_game_state.regiments = [test_regiment,test_regiment2]
	GameState.displayed_regiments = [test_regiment_display,test_regiment_display2]
	GameState.interim_game_states = [starting_game_state]
	
	$Board.update_dims()
	$HUDCanvasLayer.update_dims()
	$BoardHUDManager/BarrageHUD.update_display()

func _process(delta: float) -> void:
	if GameState.selected_regiment_state != GameState.Regiment.UIState.NONE:
		return
	if Input.is_action_just_pressed('SelectRegiment'):
		GameState.selected_regiment = GameState.hovered_regiment
	

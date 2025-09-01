extends VBoxContainer


func _ready() -> void:
	$HBoxContainer/MoveRegimentButton.pressed.connect(
		set_regiment_state.bind(GameState.Regiment.UIState.MOVE)
	)
	$HBoxContainer/ChargeRegimentButton.pressed.connect(
		set_regiment_state.bind(GameState.Regiment.UIState.CHARGE)
	)
	$HBoxContainer/BarrageButton.pressed.connect(
		set_regiment_state.bind(GameState.Regiment.UIState.BARRAGE)
	)
	
# Generic set state function (so we dont have a bunch of one-off functions for 
# what is the same process over and over
func set_regiment_state(new_state: GameState.Regiment.UIState):
	GameState.selected_regiment_state = GameState.Regiment.UIState.MOVE

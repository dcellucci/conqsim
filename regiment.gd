extends Node2D

var regiment: GameState.Regiment = null
var regiment_size_px: Vector2
# This is the display node for a regiment- it contains all of the logic for 
# rendering a regiment in the game world and also moving it around

func _ready() -> void:
	$MouseHoverArea.mouse_entered.connect(_handle_mouse_enter_hover_area)
	$MouseHoverArea.mouse_exited.connect(_handle_mouse_leave_hover_area)
	update_display()
	
func _process(delta:float) -> void:
	# Make the stand border visible if its being hovered
	$StandTray/StandHoveredBorder.visible = (GameState.hovered_regiment == regiment) 
	$StandTray/StandSelectedBorder.visible = (GameState.selected_regiment == regiment) 
	process_mode()
	
func process_mode() -> void:
	if regiment:
		position = regiment.position
		rotation_degrees = -regiment.rotation
	# We do nothing further if the selected regiment isn't this regiment
	if GameState.selected_regiment != regiment:
		return
		
	match GameState.selected_regiment_state:
		GameState.Regiment.UIState.MOVE:
			process_move()
		GameState.Regiment.UIState.REFORM:
			process_reform()	
	

func process_move() -> void:
	pass 
	
func process_reform() -> void:
	pass
		
func update_display() -> void:
	if regiment == null:
		return
	#calculate the overall size of the regiment in px
	regiment_size_px = Vector2(
		regiment.width*GameSettings.STAND_DIM_PX
	  , regiment.height*GameSettings.STAND_DIM_PX
	  )
	# Set the size of the hover region to be the dimensions of the regiment
	$MouseHoverArea/CollisionShape2D.shape.set_size(regiment_size_px)
	
	var regiment_points = [
		Vector2( regiment_size_px.x/2.,  regiment_size_px.y/2)
	  , Vector2(-regiment_size_px.x/2.,  regiment_size_px.y/2)
	  , Vector2(-regiment_size_px.x/2., -regiment_size_px.y/2)
	  , Vector2( regiment_size_px.x/2., -regiment_size_px.y/2)
	  ]
	$StandTray.polygon = PackedVector2Array(regiment_points)
	$StandTray/StandHoveredBorder.points = PackedVector2Array(regiment_points)
	$StandTray/StandSelectedBorder.points = PackedVector2Array(regiment_points)

	$MoveRegimentUI.update_display(regiment)
	
	
func _handle_mouse_enter_hover_area():
	if GameState.hovered_regiment != regiment:
		GameState.hovered_regiment = regiment

func _handle_mouse_leave_hover_area():
	if GameState.hovered_regiment == regiment:
		GameState.hovered_regiment = null

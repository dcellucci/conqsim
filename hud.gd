extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_total_move(new_total_move):
	$TotalMoveLabel.text="Total Distance: %4.2f" % new_total_move

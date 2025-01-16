extends Sprite2D


var stand_size_inches = 2.5

var base_transform

func _init() -> void:
	base_transform = transform
	
func _ready() -> void:
	var pixels_per_inch = $"/root/GameInfo".pixels_per_inch 
	var stand_scale = stand_size_inches*pixels_per_inch/texture.get_width()
	transform = base_transform.scaled_local(Vector2(stand_scale, stand_scale))

func _process(delta: float) -> void:
	pass
	
# We want a keypress to take us into a mode, where we can then increase/decrease the value
# we then confirm, goes back to an IDLE where we then can choose a new mode
# label that shows total distance travelled
# also a set of vectors illustrating the movement??
	

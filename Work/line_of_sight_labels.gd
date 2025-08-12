extends Control

var los_line_x_scale = 50
var los_line_y_scale = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func configure_line_of_sight_labels(
	  num_stands_wide
	, num_stands_tall
	, stand_size_pixels
	, move_forward_button_rect
	, wheel_left_button_rect
	, wheel_right_button_rect
):
	var label_rect = $FrontLabel.get_rect()
	$FrontLabel.position=Vector2(
		-label_rect.size.x/2.0
	  , -(num_stands_tall/2.0)*stand_size_pixels-label_rect.size.y-move_forward_button_rect.size.y
	  )
	label_rect = $RearLabel.get_rect()
	$RearLabel.position=Vector2(
		-label_rect.size.x/2.0
	  , (num_stands_tall/2.0)*stand_size_pixels+move_forward_button_rect.size.y
	  )
	
	label_rect = $SideLabel.get_rect()
	$SideLabel.position=Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels-label_rect.size.y-wheel_right_button_rect.size.x
	  , label_rect.size.x/2
	  )
	
	label_rect = $SideLabel2.get_rect()
	$SideLabel2.position=Vector2(
		(num_stands_wide/2.0)*stand_size_pixels+label_rect.size.y+wheel_left_button_rect.size.x
	  , -label_rect.size.x/2
	  )
	$LOSLine1.rotation=-3.0*PI/4.0
	$LOSLine1.position=Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels
	  , -(num_stands_tall/2.0)*stand_size_pixels
	  )
	$LOSLine1.scale=Vector2( los_line_x_scale, los_line_y_scale )
	
	$LOSLine2.rotation=-PI/4.0
	$LOSLine2.position=Vector2(
		 (num_stands_wide/2.0)*stand_size_pixels
	  , -(num_stands_tall/2.0)*stand_size_pixels
	  )
	$LOSLine2.scale=Vector2( los_line_x_scale, los_line_y_scale )
	
	$LOSLine3.rotation=PI/4.0
	$LOSLine3.position=Vector2(
		 (num_stands_wide/2.0)*stand_size_pixels
	  ,  (num_stands_tall/2.0)*stand_size_pixels
	  )
	$LOSLine3.scale=Vector2( los_line_x_scale, los_line_y_scale )
	
	$LOSLine4.rotation=3.0*PI/4.0
	$LOSLine4.position=Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels
	  ,  (num_stands_tall/2.0)*stand_size_pixels
	  )
	$LOSLine4.scale=Vector2( los_line_x_scale, los_line_y_scale)

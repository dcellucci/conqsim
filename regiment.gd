extends Area2D
signal update_total_move(new_total_move)

var speed = 400
var angular_speed = PI
var total_move = 0
var pixels_per_inch = 30.
var stand_size_inches = 2.5
var stand_size_pixels = stand_size_inches*pixels_per_inch
var num_stands_wide = 4.
var num_stands_tall = 3.

var regiment_size = Vector2(num_stands_wide*stand_size_pixels,num_stands_tall*stand_size_pixels)
#var stand_scale = stand_size_inches*pixels_per_inch/texture.get_width()

enum MoveState {IDLE, FORWARD, WHEEL_LEFT, WHEEL_RIGHT}

var current_move_state = MoveState.IDLE
var movelist = []
var start_position = position
var start_transform = transform
var delta_factor = 0
var move_start_position = position 
var pivot_location = position

var selection_stroke = 3

var selected = false
var hovered = false

func _init() -> void:
	pass#transform = transform.scaled_local(Vector2(stand_scale, stand_scale))

func _ready() -> void:
	$BoundingBox.shape.set_size(regiment_size)
	# Add the unit sprites
	var unit = $Unit
	for row in range(num_stands_tall):
		for col in range(num_stands_wide):
			var copyunit = unit.duplicate()
			copyunit.visible = true
			copyunit.position = Vector2(
				(col-num_stands_wide/2.0+0.5)*stand_size_pixels
			  , (row-num_stands_tall/2.0+0.5)*stand_size_pixels
			  )
			self.add_child(copyunit)
	$MoveUI.visible = false
	# Position the wheel left button
	$MoveUI/WheelLeftButton.position = Vector2(
		(num_stands_wide/2.0)*stand_size_pixels#+wheel_left_button.get_rect().size.x/2
	 , -(num_stands_tall/2.0)*stand_size_pixels
	 )
	$MoveUI/WheelRightButton.position = Vector2(
	   -(num_stands_wide/2.0)*stand_size_pixels-$MoveUI/WheelRightButton.get_rect().size.x
	 , -(num_stands_tall/2.0)*stand_size_pixels
	 )
	
	$MoveUI/MoveForwardButton.position = Vector2(
	  -$MoveUI/MoveForwardButton.get_rect().size.x/2
	, -(num_stands_tall/2.0)*stand_size_pixels-$MoveUI/MoveForwardButton.get_rect().size.y
	)
	
	#$DebugStartAngleLine.visible = false
	#$DebugStartAngleLine.scale=Vector2(num_stands_wide*stand_size_pixels/20, 0.1)
	
	var label_rect = $LineOfSightLabels/FrontLabel.get_rect()
	$LineOfSightLabels/FrontLabel.position=Vector2(
		-label_rect.size.x/2.0
	  , -(num_stands_tall/2.0)*stand_size_pixels-label_rect.size.y-$MoveUI/MoveForwardButton.get_rect().size.y
	  )
	label_rect = $LineOfSightLabels/RearLabel.get_rect()
	$LineOfSightLabels/RearLabel.position=Vector2(
		-label_rect.size.x/2.0
	  , (num_stands_tall/2.0)*stand_size_pixels+$MoveUI/MoveForwardButton.get_rect().size.y
	  )
	
	label_rect = $LineOfSightLabels/SideLabel.get_rect()
	$LineOfSightLabels/SideLabel.position=Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels-label_rect.size.y-$MoveUI/WheelRightButton.get_rect().size.x
	  , label_rect.size.x/2
	  )
	
	label_rect = $LineOfSightLabels/SideLabel2.get_rect()
	$LineOfSightLabels/SideLabel2.position=Vector2(
		(num_stands_wide/2.0)*stand_size_pixels+label_rect.size.y+$MoveUI/WheelLeftButton.get_rect().size.x
	  , -label_rect.size.x/2
	  )
	$LineOfSightLabels/LOSLine1.rotation=-3.0*PI/4.0
	$LineOfSightLabels/LOSLine1.position=Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels
	  , -(num_stands_tall/2.0)*stand_size_pixels
	  )
	$LineOfSightLabels/LOSLine1.scale=Vector2(
		50
	  , 0.5
	  )
	
	$LineOfSightLabels/LOSLine2.rotation=-PI/4.0
	$LineOfSightLabels/LOSLine2.position=Vector2(
		 (num_stands_wide/2.0)*stand_size_pixels
	  , -(num_stands_tall/2.0)*stand_size_pixels
	  )
	$LineOfSightLabels/LOSLine2.scale=Vector2(
		50
	  , 0.5
	  )
	
	$LineOfSightLabels/LOSLine3.rotation=PI/4.0
	$LineOfSightLabels/LOSLine3.position=Vector2(
		 (num_stands_wide/2.0)*stand_size_pixels
	  ,  (num_stands_tall/2.0)*stand_size_pixels
	  )
	$LineOfSightLabels/LOSLine3.scale=Vector2(
		50
	  , 0.5
	  )
	
	$LineOfSightLabels/LOSLine4.rotation=3.0*PI/4.0
	$LineOfSightLabels/LOSLine4.position=Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels
	  ,  (num_stands_tall/2.0)*stand_size_pixels
	  )
	$LineOfSightLabels/LOSLine4.scale=Vector2(
		50
	  , 0.5
	  )
	
	$SelectionRect.size = Vector2(
		num_stands_wide*stand_size_pixels+selection_stroke
	  , num_stands_tall*stand_size_pixels+selection_stroke
	  )
	$SelectionRect.position = Vector2(
		-(num_stands_wide/2.0)*stand_size_pixels-selection_stroke/2.0
	  , -(num_stands_tall/2.0)*stand_size_pixels-selection_stroke/2.0
	  )
	$SelectionRect.visible = false
	
func _process(delta: float) -> void:
	var direction = 0
	$MoveUI.visible = selected
	if current_move_state == MoveState.IDLE:
		if Input.is_action_just_pressed('Select'):
			selected = hovered
			$SelectionRect.visible=hovered
			if hovered:
				$SelectionRect.border_color = Color(1.0,0.0,0.0)
			else:
				$SelectionRect.border_color = Color(0.0,0.547,0.931)

	if current_move_state == MoveState.FORWARD:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Done Moving.")
			current_move_state = MoveState.IDLE
			$MoveUI/MoveForwardButton.disabled = false
		var mouse_vec = start_transform.basis_xform_inv(get_global_mouse_position())
		#print(mouse_vec, get_local_mouse_position(), move_start_position)
		var disp_vec = Vector2(0, mouse_vec.y - move_start_position.y)
		if Input.is_action_pressed("SnapMovement"):
			disp_vec = Vector2(0,  round_delta_factor_to_nearest_increment(disp_vec.y, 1.*pixels_per_inch))
			print(disp_vec)
		transform = start_transform.translated_local(disp_vec)
		update_total_move.emit((total_move-disp_vec.y)/pixels_per_inch)
	
	if current_move_state == MoveState.WHEEL_LEFT:
		var mouse_vec= get_global_mouse_position()
		#The delta factor in a wheel is the angle difference between the start vector
		#and the current mouse position vector, relative to the pivot point (front corner)
		delta_factor = (move_start_position-pivot_location).angle_to(mouse_vec-pivot_location)
		#We can also snap to the nearest value
		if Input.is_action_pressed("SnapMovement"):
			#find the angle that corresponds to 1 inch
			#maybe make the increment alterable in the future			
			var increment = 1./(num_stands_wide*stand_size_inches)
			#round the delta factor value to the nearest increment
			delta_factor = round_delta_factor_to_nearest_increment(delta_factor, increment)
		transform = wheel(start_transform, delta_factor, 1)
		update_total_move.emit(total_move/pixels_per_inch+abs(delta_factor)*num_stands_wide*stand_size_inches)
		# A click when in a move mode ends the movement
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Done Wheeling Left.")
			# Reenable the button, so we can click it again later
			$MoveUI/WheelLeftButton.disabled = false
			# go back to the IDLE state to await movement requests
			current_move_state = MoveState.IDLE
			#update the total move value 
			total_move += abs(delta_factor)*num_stands_wide*stand_size_inches*pixels_per_inch
	
	if current_move_state == MoveState.WHEEL_RIGHT:
		var mouse_vec= get_global_mouse_position()#start_transform.basis_xform_inv(get_global_mouse_position())
		delta_factor = (move_start_position-pivot_location).angle_to(mouse_vec-pivot_location)
		#We can also snap to the nearest value
		if Input.is_action_pressed("SnapMovement"):
			#find the angle that corresponds to 1 inch
			#maybe make the increment alterable in the future			
			var increment = 1./(num_stands_wide*stand_size_inches)
			#round the delta factor value to the nearest increment
			delta_factor = round_delta_factor_to_nearest_increment(delta_factor, increment)
		transform = wheel(start_transform, delta_factor, -1)
		update_total_move.emit(total_move/pixels_per_inch+abs(delta_factor)*num_stands_wide*stand_size_inches)
		# A click when in a move mode ends the movement
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Done Wheeling Right.")
			# Reenable the button, so we can click it again later
			$MoveUI/WheelRightButton.disabled = false
			# go back to the IDLE state to await movement requests
			current_move_state = MoveState.IDLE
			#update the total move value 
			total_move += abs(delta_factor)*num_stands_wide*stand_size_inches*pixels_per_inch
	
# We want a keypress to take us into a mode, where we can then increase/decrease the value
# we then confirm, goes back to an IDLE where we then can choose a new mode
# label that shows total distance travelled
# also a set of vectors illustrating the movement??	

func round_delta_factor_to_nearest_increment(delta_factor: float, increment:float):
	var fractional_value = delta_factor/increment
	return round(fractional_value)*increment

func wheel(starting_transform: Transform2D, amount:float, direction:int) -> Transform2D:
	var reg_width = stand_size_inches*num_stands_wide*pixels_per_inch
	var reg_height = stand_size_inches*num_stands_tall*pixels_per_inch
	var disp_vec = Vector2(
		 -reg_width/2
		, reg_height/2
		)
	if direction == 1:
		disp_vec = Vector2(
			reg_width/2
		  , reg_height/2
		  )
	return starting_transform.translated_local(-disp_vec).rotated_local(amount).translated_local(disp_vec)


func _on_move_forward_button_pressed() -> void:
	if current_move_state == MoveState.IDLE:
		$MoveUI/MoveForwardButton.disabled = true
		print("Moving")
		current_move_state = MoveState.FORWARD
		start_transform = transform
		move_start_position = start_transform.basis_xform_inv(get_global_mouse_position())


func _on_wheel_left_button_pressed() -> void:
	if current_move_state == MoveState.IDLE:
		$MoveUI/WheelLeftButton.disabled = true
		print("Wheeling Left")
		current_move_state = MoveState.WHEEL_LEFT
		start_transform = transform
		move_start_position = get_global_mouse_position()#get_local_mouse_position()#start_transform.basis_xform_inv(get_global_mouse_position())
		var reg_width = stand_size_inches*num_stands_wide*pixels_per_inch
		var reg_height = stand_size_inches*num_stands_tall*pixels_per_inch
		pivot_location = Vector2(	
			   -reg_width/2
			 , -reg_height/2
			 )
		pivot_location = to_global(pivot_location)


func _on_wheel_right_button_pressed() -> void:
	if current_move_state == MoveState.IDLE:
		hovered = true
		$MoveUI/WheelRightButton.disabled = true
		print("Wheeling Right")
		current_move_state = MoveState.WHEEL_RIGHT
		start_transform = transform
		move_start_position = get_global_mouse_position()#get_local_mouse_position()#start_transform.basis_xform_inv(get_global_mouse_position())
		var reg_width = stand_size_inches*num_stands_wide*pixels_per_inch
		var reg_height = stand_size_inches*num_stands_tall*pixels_per_inch
		pivot_location = Vector2(	
				reg_width/2
			 , -reg_height/2
			 )
		pivot_location = to_global(pivot_location) # Replace with function body.



func _on_mouse_entered() -> void:
	$SelectionRect.visible=true
	hovered = true

func _on_mouse_exited() -> void:
	if not selected:
		$SelectionRect.visible=false
	hovered = false

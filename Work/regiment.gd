extends Area2D
signal update_total_move(new_total_move)
signal update_hovered()

var total_move = 0
var pixels_per_inch = 30.
var stand_size_inches = 2.5
var stand_size_pixels = stand_size_inches*pixels_per_inch
var num_stands_wide = 1.
var num_stands_tall = 2.

var regiment_size = Vector2(num_stands_wide*stand_size_pixels,num_stands_tall*stand_size_pixels)
#var stand_scale = stand_size_inches*pixels_per_inch/texture.get_width()

enum ConstrainedMoveState {IDLE, FORWARD, WHEEL_LEFT, WHEEL_RIGHT}
enum FreeMoveState {IDLE, MOVING}
enum RegimentState {IDLE, CONSTRAINED_MOVE, FREE_MOVE, DEPLOY}

var constrained_move_state = ConstrainedMoveState.IDLE
var free_move_state = FreeMoveState.IDLE
var current_regiment_state = RegimentState.IDLE
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
	var stand = $Stand
	for row in range(num_stands_tall):
		for col in range(num_stands_wide):
			var copyunit = stand.duplicate()
			copyunit.visible = true
			self.add_child(copyunit)
			copyunit.position = Vector2(
				(col-num_stands_wide/2.0+0.5)*stand_size_pixels
			  , (row-num_stands_tall/2.0+0.5)*stand_size_pixels
			  )
	$ConstrainedMoveUI.visible = false
	# Position the wheel left button
	$ConstrainedMoveUI/WheelLeftButton.position = Vector2(
		(num_stands_wide/2.0)*stand_size_pixels#+wheel_left_button.get_rect().size.x/2
	 , -(num_stands_tall/2.0)*stand_size_pixels
	 )
	$ConstrainedMoveUI/WheelRightButton.position = Vector2(
	   -(num_stands_wide/2.0)*stand_size_pixels-$ConstrainedMoveUI/WheelRightButton.get_rect().size.x
	 , -(num_stands_tall/2.0)*stand_size_pixels
	 )
	
	$ConstrainedMoveUI/MoveForwardButton.position = Vector2(
	  -$ConstrainedMoveUI/MoveForwardButton.get_rect().size.x/2
	, -(num_stands_tall/2.0)*stand_size_pixels-$ConstrainedMoveUI/MoveForwardButton.get_rect().size.y
	)
	
	#$DebugStartAngleLine.visible = false
	#$DebugStartAngleLine.scale=Vector2(num_stands_wide*stand_size_pixels/20, 0.1)
	$LineOfSightLabels.configure_line_of_sight_labels(
		num_stands_wide
	  , num_stands_tall
	  , stand_size_pixels
	  , $ConstrainedMoveUI/MoveForwardButton.get_rect()
	  , $ConstrainedMoveUI/WheelLeftButton.get_rect()
	  , $ConstrainedMoveUI/WheelRightButton.get_rect()
	)
	
	$LineOfSightLabels.visible = false
	
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
	$ConstrainedMoveUI.visible = current_regiment_state == RegimentState.CONSTRAINED_MOVE
	if current_regiment_state == RegimentState.IDLE:
		if Input.is_action_pressed('Select'):
			selected = hovered
			$SelectionRect.visible=hovered
			if hovered:
				$SelectionRect.border_color = Color(1.0,0.0,0.0)
			else:
				$SelectionRect.border_color = Color(0.0,0.547,0.931)
		if Input.is_action_pressed('PerformConstrainedMove') && selected:
			current_regiment_state = RegimentState.CONSTRAINED_MOVE
		if Input.is_action_pressed('PerformDeployment') && selected:
			start_transform = transform
			current_regiment_state = RegimentState.DEPLOY
	if current_regiment_state == RegimentState.CONSTRAINED_MOVE:
		handle_constrained_move()
	if current_regiment_state == RegimentState.FREE_MOVE:
		handle_free_move()
	if current_regiment_state == RegimentState.DEPLOY:
		handle_deploy()
	
# We want a keypress to take us into a mode, where we can then increase/decrease the value
# we then confirm, goes back to an IDLE where we then can choose a new mode
# label that shows total distance travelled
# also a set of vectors illustrating the movement??	

func handle_constrained_move():
	if constrained_move_state == ConstrainedMoveState.IDLE:
		if Input.is_action_pressed('ConfirmMovement'):
			current_regiment_state = RegimentState.IDLE
		if Input.is_action_pressed('ChangeMovementMode'):
			current_regiment_state = RegimentState.FREE_MOVE
			
	if constrained_move_state == ConstrainedMoveState.FORWARD:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Done Moving.")
			constrained_move_state = ConstrainedMoveState.IDLE
			$ConstrainedMoveUI/MoveForwardButton.disabled = false
		var mouse_vec = start_transform.basis_xform_inv(get_global_mouse_position())
		#print(mouse_vec, get_local_mouse_position(), move_start_position)
		var disp_vec = Vector2(0, mouse_vec.y - move_start_position.y)
		if Input.is_action_pressed("SnapMovement"):
			disp_vec = Vector2(0,  round_delta_factor_to_nearest_increment(disp_vec.y, 1.*pixels_per_inch))
		transform = start_transform.translated_local(disp_vec)
		update_total_move.emit((total_move-disp_vec.y)/pixels_per_inch)
	
	if constrained_move_state == ConstrainedMoveState.WHEEL_LEFT:
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
			$ConstrainedMoveUI/WheelLeftButton.disabled = false
			# go back to the IDLE state to await movement requests
			constrained_move_state = ConstrainedMoveState.IDLE
			#update the total move value 
			total_move += abs(delta_factor)*num_stands_wide*stand_size_inches*pixels_per_inch
	
	if constrained_move_state == ConstrainedMoveState.WHEEL_RIGHT:
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
			$ConstrainedMoveUI/WheelRightButton.disabled = false
			# go back to the IDLE state to await movement requests
			constrained_move_state = ConstrainedMoveState.IDLE
			#update the total move value 
			total_move += abs(delta_factor)*num_stands_wide*stand_size_inches*pixels_per_inch
	
func handle_deploy():
	var board = $/root/GameInfo.game_board
	var pointlist = board.get_polygon()
	var min_dist = $"/root/GameInfo".snap_distance
	var closest_point
	var normal
	var mouse_loc = get_global_mouse_position()
	transform = start_transform
	for i in range(len(pointlist)):
		var point1 = board.global_transform.basis_xform(pointlist[i])
		var point2 = board.global_transform.basis_xform(pointlist[(i+1)%(len(pointlist))])
		var point3 = Geometry2D.get_closest_point_to_segment(mouse_loc, point1, point2)
		if mouse_loc.distance_to(point3)	 < min_dist:
			min_dist = mouse_loc.distance_to(point3)	
			closest_point = point3
			normal = (point1-point2).rotated(PI/2)
	if closest_point:
		var regiment_forward = Vector2(0,1).rotated(start_transform.get_rotation())
		position = closest_point
		transform = transform.rotated_local(
			regiment_forward.angle_to(normal)
		  ).translated_local(Vector2(0, num_stands_tall/2.0*stand_size_pixels))
			
	
func handle_free_move():
	if constrained_move_state == ConstrainedMoveState.IDLE:
		if Input.is_action_pressed('ConfirmMovement'):
			current_regiment_state = RegimentState.IDLE
		if Input.is_action_pressed('ChangeMovementMode'):
			current_regiment_state = RegimentState.CONSTRAINED_MOVE

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
	if constrained_move_state == ConstrainedMoveState.IDLE:
		$ConstrainedMoveUI/MoveForwardButton.disabled = true
		print("Moving")
		constrained_move_state = ConstrainedMoveState.FORWARD
		start_transform = transform
		move_start_position = start_transform.basis_xform_inv(get_global_mouse_position())


func _on_wheel_left_button_pressed() -> void:
	if constrained_move_state == ConstrainedMoveState.IDLE:
		$ConstrainedMoveUI/WheelLeftButton.disabled = true
		print("Wheeling Left")
		constrained_move_state = ConstrainedMoveState.WHEEL_LEFT
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
	if constrained_move_state == ConstrainedMoveState.IDLE:
		$ConstrainedMoveUI/WheelRightButton.disabled = true
		print("Wheeling Right")
		constrained_move_state = ConstrainedMoveState.WHEEL_RIGHT
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
	if not selected:
		update_hovered.emit()
		
	hovered = true

func _on_mouse_exited() -> void:
	if not selected:
		$SelectionRect.visible=false
	hovered = false

extends Node

enum UIState { 
	  NONE
	, CHARGE_INITIALIZE, CHARGE_MEASURE_FREE, CHARGE_MEASURE_SNAP_REGIMENT, CHARGE_MEASURE_SNAP_FACE
	, CHARGE_TARGET, CHARGE_REFORM_ROTATE, CHARGE_FRONTAGE
	, REFORM_ROTATE
	, MOVE_INITIALIZE
	, BARRAGE_LOS, BARRAGE_RANGE
	}
			
var ui_state_machine: UIStateMachine = UIStateMachine.new()
	
class UIStateMachine:
	
	var state: UIState = UIState.NONE
	var previous_state: UIState = UIState.NONE
	
	func is_charge_state():
		return state in [ UIState.CHARGE_INITIALIZE
						, UIState.CHARGE_TARGET
						, UIState.CHARGE_MEASURE_FREE
						, UIState.CHARGE_MEASURE_SNAP_REGIMENT
						, UIState.CHARGE_MEASURE_SNAP_FACE
						, UIState.CHARGE_REFORM_ROTATE
						, UIState.CHARGE_FRONTAGE 
						]
						
	func is_charge_measure_state():
		return state in [ UIState.CHARGE_MEASURE_FREE
						, UIState.CHARGE_MEASURE_SNAP_REGIMENT
						, UIState.CHARGE_MEASURE_SNAP_FACE
						]
							
	func is_idle():
		return state == UIState.NONE
		
	func is_move_state():
		return state in [UIState.MOVE_INITIALIZE]
		
	func is_barrage_state():
		return state in [ UIState.BARRAGE_LOS
						, UIState.BARRAGE_RANGE 
						]
	
	func is_reform_state():
		return state == UIState.REFORM_ROTATE
	
	func set_new_state(new_state: UIState):
		previous_state = state
		state = new_state
		
	func cycle_charge_measure_state():
		match state:
			UIState.CHARGE_MEASURE_FREE:
				set_new_state(UIState.CHARGE_MEASURE_SNAP_REGIMENT)
			UIState.CHARGE_MEASURE_SNAP_REGIMENT:
				set_new_state(UIState.CHARGE_MEASURE_SNAP_FACE)
			UIState.CHARGE_MEASURE_SNAP_FACE:
				set_new_state(UIState.CHARGE_MEASURE_FREE)
		
	func undo_state():
		state = previous_state
		previous_state = UIState.NONE
		
	func cancel_state():
		state = UIState.NONE
		previous_state = UIState.NONE
	
	func get_state_string() -> String:
		match state:
			UIState.NONE:
				return "None"
			UIState.CHARGE_INITIALIZE:
				return "Charge Initialize"
			UIState.CHARGE_MEASURE_FREE:
				return "Charge Measure Free"
			UIState.CHARGE_MEASURE_SNAP_REGIMENT:
				return "Charge Measure Snap Regiment"
			UIState.CHARGE_MEASURE_SNAP_FACE:
				return "Charge Measure Snap Face"
			UIState.CHARGE_TARGET:
				return "Charge Target"
			UIState.CHARGE_REFORM_ROTATE:
				return "Charge Reform Rotate"
			UIState.CHARGE_FRONTAGE:
				return "Charge Frontage"
			UIState.REFORM_ROTATE:
				return "Reform Rotate"
			UIState.MOVE_INITIALIZE:
				return "Move Initialize"
			UIState.BARRAGE_LOS:
				return "Barrage Line of Sight"
			UIState.BARRAGE_RANGE:
				return "Barrage Range"
		return "Unknown State"

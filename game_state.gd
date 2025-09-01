extends Node

# The game state is the latest of a set of interim_game_states
var interim_game_states: Array[InterimGameState]
# one day we want to show replay, this allows us to do that
var current_state_location: int
# we also want to track which regiment is selected 
var selected_regiment: Regiment
var selected_regiment_state: Regiment.UIState
# also want to track which regiment is currently hovered (maybe?)
var hovered_regiment: Regiment
# one player has supremacy
var supremacy: Player

#We should also track the regiment scenes currently being displayed on the 
#board
var displayed_regiments: Array[Node]

# UI mode related to the barrage menu- do we display LOS lines or range 
# measurements
var barrage_measure_los_mode: bool = false

class InterimGameState:
	# Each interim game state is assigned a modification type purely for the 
	# purposes of display (maybe?)
	enum ModificationType {MOVE, REFORM, ROLL, NONE}
	var modification_type: ModificationType
	
	# A game state consists of an array of regiment objects referencing troop 
	# game pieces (either on the board or unplayed) 
	var regiments: Array[Regiment]
	
	# Game state related to command cards
	# Command cards is the list of all possible command cards, just in case 
	# you delete one
	var command_cards: Array[CommandCard]
	# command stack is the list of command cards still to be played
	var command_stack: Array[CommandCard]
	# discard pile is the list of command cards that have been played
	var discard_pile: Array[CommandCard]
	# city states get a special thing called the strategic stack
	var strategic_stack: Array[CommandCard]
	
	# Counters are objects that track a single named value. There's a minimum
	# of three counters: one round counter and one victory point counter for 
	# each player
	var counters: Array[Counter]
	
	# Dice roll object containing the results of a roll including which player
	# rolled it and what the results were
	var dice_roll: DiceRoll

# Class denoting a game piece
class Regiment:
	enum UIState {MOVE, REFORM, DEPLOY, CHARGE, BARRAGE, MEASURE, NONE}
	enum ARC {FRONT, LEFT, RIGHT, REAR, INSIDE}
	# Regiments have a name
	var name: String
	# They can have a list of statuses- leaving as strings so they can be 
	# customized
	var status: Array[String]
	# regiments have a type
	var type: String
	# want to track whether a regiment has been activated
	var activated: bool
	# a regiment belonds to a player
	var player: Player
	# the position denotes the location of the center of a regiment in the 
	# reference frame of the board
	var position: Vector2
	# the rotation denotes the angle between the front of the regiment and the 
	# positive y-axis of the board reference frame
	var rotation: float
	# each regiment is an integer number of stands wide
	var width: int
	# each regiment is an integer number of stands tall
	var height: int
	# each regiment consists of an array of stand objects.
	var stands: Array[Stand]
	# A regiment can have "fluid Formation", default is false
	var fluid_formation: bool = false
	# A regiment can have a barrage range, default is 0
	var barrage_range: int = 0
	
	func get_transform() -> Transform2D:
		return Transform2D(-deg_to_rad(self.rotation), self.position)  
		
	func determine_which_arc(point: Vector2) -> ARC:
		# Given a point in the local coordinate frame, determine which arc
		# this point lies inside or whether it is located in a specific arc
		# Check if the point is inside the regiment bounds
		if abs(point.x) < 0.5*self.width*GameSettings.STAND_DIM_PX and abs(point.y) < 0.5*self.height*GameSettings.STAND_DIM_PX:
			return ARC.INSIDE
		# A regiment's arcs are separated by lines rotated 45 degrees from each 
		# corner. If the x value is less than the combination of half the 
		# regiment width plus the x distance of that 45 degree line, then the 
		# point is either in the front or the rear
		elif abs(point.x) < 0.5*self.width*GameSettings.STAND_DIM_PX + (abs(point.y)-0.5*self.height*GameSettings.STAND_DIM_PX):
			# The front or rear is then determined by the sign of the y value of 
			# the test point
			if point.y < 0:
				return ARC.FRONT
			if point.y > 0:
				return ARC.REAR
		# If the point is not inside or front or rear then it's in one of the sides
		else: 
			# Left or right is then determined by the sign of the x-value
			if point.x > 0:
				return ARC.RIGHT
		return ARC.LEFT
	
	# Returns a list of points corresponding to the start and end coordinates of a 
	# regiment's stands in the requested facing. A regiment is composed of a 
	# rectangular array of rectangular stand objects. This function returns the 
	# corners of the stands that abut the requested facing
	func stand_segments(facing: ARC) -> Array[Vector2]:
		var stand_segment_list:Array[Vector2] = []
		if facing == ARC.FRONT or facing == ARC.REAR:
			var ycoord = 0.5*self.height*GameSettings.STAND_DIM_PX
			if facing == ARC.FRONT:
				ycoord = -ycoord
			for w in range(self.width):
				var xcoord_start = (w-0.5*self.width)*GameSettings.STAND_DIM_PX
				var xcoord_end = (w+1-0.5*self.width)*GameSettings.STAND_DIM_PX
				stand_segment_list.append(Vector2(xcoord_start, ycoord))
				stand_segment_list.append(Vector2(xcoord_end, ycoord))
		else:
			var xcoord = 0.5*self.width*GameSettings.STAND_DIM_PX
			if facing == ARC.LEFT:
				xcoord = -xcoord
			for h in range(self.height):
				var ycoord_start = (h-0.5*self.height)*GameSettings.STAND_DIM_PX
				var ycoord_end = (h+1-0.5*self.height)*GameSettings.STAND_DIM_PX
				stand_segment_list.append(Vector2(xcoord, ycoord_start))
				stand_segment_list.append(Vector2(xcoord, ycoord_end))
		return stand_segment_list
		

# Regiments are composed of stands
class Stand:
	# each stand has a name
	var name: String
	# each stand tracks the number of wounds it has (or those remaining)
	var wounds: int
	# track a dead stand because you might want to bring it back
	var dead: bool 
	# some stands are command stands
	var command: bool
	
# Command Cards are just a stack of names
class CommandCard:
	var name: String

# Counters track a single value in a game and allow a player to modify them
class Counter:
	# A counter has a name
	var name: String
	# A counter has a current value
	var value: int
	# A counter has a player that owns it
	var player: Player
	
# A dice roll is a record of the result of a bunch of rolled dice
class DiceRoll:
	# A player rolls dice
	var player: Player
	# the result of a roll is a list of ints
	var roll: Array[int]
	
# A player is a person playing the game (the game itself is also a player lol)
class Player:
	# Player has a name
	var name: String
	# Player is a number, the game is player 0
	var number: int

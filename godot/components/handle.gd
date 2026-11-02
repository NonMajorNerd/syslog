class_name Handle
extends Node

# The player is a handle running a rig.
# Their work is building scripts, aiming them at targets, setting standing orders, and reading what happened.


var handleName:String = "" 									# unique, 3 to 16 characters, chosen at first boot. It appears on leaderboards, in rival logs and in chat.
var clearance:int = 0 											# 1-5 the highest target tier the handle has unlocked since last prestige
var rep:Dictionary = {"alltime": 0.0			# score. rises with raids won, raids defended and corp contributions. sets primary leaderboard rank
											, "seasonal": 0.0
											, "sincelastburn": 0.0 }
var credits:Dictionary = {	"alltime": 0.0	# cash baby
													, "seasonal": 0.0
													, "sincelastburn": 0.0 } 
var intel: float = 0.0											# earned with intel exfils, spent to unlock targets, variants and layers
var echoes: int = 0													# earned by burning the handle, prestige
var heat:float = 0.0 												# 0-100 how much attention a handle is drawing. Runs add heat, time removes it.

# todo: make rig its own class
var rig:Dictionary = {	  "CPU":  1 # determines how fast a chain runs
												, "RAM":  1 # determines how many chains (threads) run at once
												, "NET":  1 # determines how much each successful run pays
												, "DISK": 1 # determines how much offline progress is saved
												
												, "THREADS": {1:{}} # a dictionary of the 1-8 threads the handle may have available
												, "REFLEXES": {	1:{} # a dictionary of the 4 reflex slots and their current configuration
																				, 2:{}
																				, 3:{}
																				, 4:{}
																			} 
											}

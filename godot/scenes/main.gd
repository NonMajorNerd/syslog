extends Node

# set up globals, set up UI
func _ready() -> void:
	Globals.loadControllers()
	$Console.setup()

# create player object for the current session
func createPlayer() -> void:
	Globals.playerHandle = Handle.new()
	

extends Node

# set up globals, set up UI
func _ready() -> void:
	Globals.loadControllers()
	$Console.setup()
	
	

extends Node

func _ready() -> void:
	Globals.loadControllers()
	$Console.setup()

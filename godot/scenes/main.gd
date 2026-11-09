extends Node

# set up globals, set up UI
func _ready() -> void:
  # Controllers must be resolved before Console.setup() connects signals
  Globals.loadControllers()
  $Console.setup()

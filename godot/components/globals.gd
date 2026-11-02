extends Node

@export var serverManager:ServerManager
@export var consoleManager:ConsoleManager

var Colors:Dictionary	=	{"CONSOLE":	{ "FONT_DEFAULT": Color("ffffffff"),
																			"FONT_SUCCESS": Color("bfffb9ff"),
																			"FONT_FAILURE": Color("ffd0c8ff")
																		}
												}

func loadControllers() -> void:
	if not get_tree().current_scene.find_child("ServerManager"): print("No Server controller")
	else:  serverManager =  get_tree().current_scene.find_child("ServerManager")
	
	if not get_tree().current_scene.find_child("ConsoleManager"): print("No Console controller")
	else:  consoleManager =  get_tree().current_scene.find_child("ConsoleManager")
	

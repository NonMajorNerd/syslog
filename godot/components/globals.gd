extends Node

var serverManager:ServerManager

var audioManager:AudioManager
var consoleManager:ConsoleManager
var gameNetworkManager:NetworkManager

var playerHandle:Handle = null


var Colors:Dictionary	=	{"CONSOLE":	{ "FONT_DEFAULT": Color("ffffffff"),
																			"FONT_SUCCESS": Color("bfffb9ff"),
																			"FONT_FAILURE": Color("ffd0c8ff"),
																			"FONT_NETWORKING": Color("a5e0ffff")
																		}
												}

func loadControllers() -> void:
	Globals.playerHandle = Handle.new()
	
	if not get_tree().current_scene.find_child("ServerManager"): print("No Server controller")
	else:  serverManager =  get_tree().current_scene.find_child("ServerManager")
	
	if not get_tree().current_scene.find_child("AudioManager"): print("No Audio controller")
	else:  audioManager =  get_tree().current_scene.find_child("AudioManager")
	
	if not get_tree().current_scene.find_child("ConsoleManager"): print("No Console controller")
	else:  consoleManager =  get_tree().current_scene.find_child("ConsoleManager")
	
	if not get_tree().current_scene.find_child("GameNetworkManager"): print("No Game Network controller")
	else: 
		gameNetworkManager =  get_tree().current_scene.find_child("GameNetworkManager")
		gameNetworkManager.loadHelix()
	

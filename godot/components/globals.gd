extends Node

var serverManager:ServerManager

var audioManager:AudioManager
var consoleManager:ConsoleManager
var gameNetworkManager:NetworkManager

var playerHandle:Handle = null


var Colors:Dictionary	=	{"CONSOLE":	{ "FONT_DEFAULT": Color("#ffffff"),
																			"FONT_NOTIF": Color("#cad3f5"), # catppuccin macchiato text
																			"FONT_SUCCESS": Color("#a6da95"), # catppuccin macchiato green
																			"FONT_FAILURE": Color("#ed8796"), # catppuccin macchiato red
																			"FONT_NETWORKING": Color("#91d7e3") # catppuccin macchiato sky
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
		gameNetworkManager.loadNetworkJson("res://components/networks/gameNetworks/HelixDynamics.json")
	

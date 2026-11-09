extends Node

var serverManager: ServerManager

var audioManager: AudioManager
var consoleManager: ConsoleManager
var gameNetworkManager: NetworkManager

var playerHandle: Handle = null


var colors: Dictionary = {
  "CONSOLE": {
    "FONT_DEFAULT": Color("d9dff8ff"), # Text
    "FONT_MUTED": Color("#a5adcb"), # Hints and secondary details
    "FONT_NOTIF": Color("fcefa6ff"), # Yellow: system notifications
    "FONT_SUCCESS": Color("#a6da95"), # Green: successful actions
    "FONT_FAILURE": Color("#ed8796"), # Red: errors and access denial
    "FONT_NETWORKING": Color("b3fef3ff") # Sky: network activity
  }
}

# Main calls this before Console.setup(); the console's signal bindings
# require these manager references to already be available.
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
    print("!!loaded")

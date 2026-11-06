class_name NetworkManager
extends Node

signal networkConnected(network: GameNetwork)
signal pathChanged(path: String)
signal networkDisconnected(network: GameNetwork)

var networks: Dictionary = {}
var activeNetwork: GameNetwork:
	set(value):
		if activeNetwork != null:
			if activeNetwork.currentPathChanged.is_connected(onPathChanged):
				activeNetwork.currentPathChanged.disconnect(onPathChanged)

		activeNetwork = value

		if activeNetwork != null:
			activeNetwork.currentPathChanged.connect(onPathChanged)
			networkConnected.emit(activeNetwork)
			
func onPathChanged(path:String) -> void: pathChanged.emit(path)
func registerNetwork(network: GameNetwork) -> void:
	networks[network.networkName] = network
	print(str(networks))
func isConnected() -> bool: return activeNetwork != null

func getAvailableNetworks() -> Array[String]:
	var result: Array[String] = []

	for networkName in networks:
		result.append(networkName)

	result.sort()
	return result
	
	
	
func connectTo(networkName: String) -> bool:
	if not networks.has(networkName): return false

	var nextNetwork: GameNetwork = networks[networkName]
	if activeNetwork == nextNetwork: return true

	var previousNetwork: GameNetwork = activeNetwork

	if previousNetwork != null:
		activeNetwork = null
		previousNetwork.resetSession()
		networkDisconnected.emit(previousNetwork)

	activateNetwork(nextNetwork)

	return true

func activateNetwork(network: GameNetwork) -> void:
	if network == null: return

	network.resetSession()

	if Globals.playerHandle != null:
		var savedPaths:Array = Globals.playerHandle.getUnlockedPaths(network.networkID)

		network.restoreUnlocks(savedPaths)

		if not network.directoryUnlocked.is_connected(Globals.playerHandle.onPathUnlocked):
			network.directoryUnlocked.connect(Globals.playerHandle.onPathUnlocked)

	activeNetwork = network
	

func disconnectFrom() -> void:
	if activeNetwork == null: return

	var homeNetwork: GameNetwork = null

	if Globals.playerHandle != null:
		if not Globals.playerHandle.realName.is_empty():
			homeNetwork = Globals.playerHandle.rig.homeNet

	if activeNetwork == homeNetwork: return

	var previousNetwork: GameNetwork = activeNetwork

	activeNetwork = null
	previousNetwork.resetSession()
	networkDisconnected.emit(previousNetwork)

	if homeNetwork != null: activateNetwork(homeNetwork)
		
func loadNetworkJson(path: String):
	if not FileAccess.file_exists(path):
		push_error("Network JSON not found: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open network JSON: " + path)
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Dictionary:
		push_error("Invalid network JSON: " + path)
		return {}

	if not data.is_empty():
		print('not empty')
		var network := GameNetwork.new(str(data["name"]), int(data["id"]), data["root"])
		Globals.gameNetworkManager.registerNetwork(network)

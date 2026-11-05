class_name cdCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "cd"
	aliases = []
	category = "General"
	description = "Change the working directory."
	usage = "cd [directory]"
	isHidden = false # used to hide internal commands from standard help

func execute(_args: Array[String]) -> void:
	var network:GameNetwork = Globals.gameNetworkManager.activeNetwork
	var path:String = ""
	for a in _args: path += " " + a
	path = path.strip_edges()

	var node := network.getNode(path)

	if node.get("type") != "directory":
		Globals.consoleManager.printOutput("Directory not found.", Globals.Colors["CONSOLE"]["FONT_FAILURE"])
		return

	var parts := network.resolvePath(path)
	#var absolutePath := "/" + "/".join(parts)
	var dP2:String = ""
	var unlocked:bool = false

	if network.isLocked(path):
		# Find the first locked directory in the path.
		var traversed: Array[String] = []

		for part in parts:
			traversed.append(part)
			var directoryPath:String = "/" + "/".join(traversed)

			# skip this part if it's not locked
			if not network.isLocked(directoryPath): continue

			# skip this part if it is locked, but has previously been unlocked
			if Globals.playerHandle.networks.keys().has(network.networkID):
				if Globals.playerHandle.networks[network.networkID].has(directoryPath): continue
			
			dP2 = directoryPath
			var password = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
			
			if not password: return 
			if not network.unlock(directoryPath, password):
				Globals.consoleManager.printOutputWithSFX("Access denied.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
				return
			else: unlocked = true

	if network.changeDirectory(path):
		if unlocked: Globals.playerHandle.onPathUnlocked(network, dP2)
	else: Globals.consoleManager.printOutputWithSFX("Access denied.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")

func validatePassword(_value: String) -> String:
	return ""

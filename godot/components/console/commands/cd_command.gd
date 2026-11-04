class_name cdCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "cd"
	aliases = []
	category = "General"
	description = "Allows you to change directories"
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

	if network.isLocked(path):
		# Find the first locked directory in the path.
		var traversed: Array[String] = []

		for part in parts:
			traversed.append(part)
			var directoryPath := "/" + "/".join(traversed)

			if not network.isLocked(directoryPath): continue

			var password = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
			if not password: return 
			if not network.unlock(directoryPath, password):
				Globals.consoleManager.printOutputWithSFX("Access denied.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
				return

	if network.changeDirectory(path): pass #Globals.consoleManager.printOutput(network.getCurrentPath())
	else: Globals.consoleManager.printOutputWithSFX("Access denied.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")

func validatePassword(_value: String) -> String:
	return ""

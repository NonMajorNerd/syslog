class_name lsCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "ls"
	aliases = []
	category = "General"
	description = "Lists the contents of the current directory."
	usage = "ls"
	isHidden = false # used to hide internal commands from standard help

func execute(_args: Array[String]) -> void:
	var network:GameNetwork = Globals.gameNetworkManager.activeNetwork
	var path:String = ""
	for a in _args: path += " " + a
	path = path.strip_edges()

	#if network == null: Globals.consoleManager.printOutput("Not connected.")

	if network.isLocked(path): Globals.consoleManager.printOutputWithSFX("Not authorized to view contents of that directory.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")

	var node := network.getNode(path)
	if node.get("type") != "directory": Globals.consoleManager.printOutputWithSFX("Directory not found.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")

	Globals.consoleManager.printOutput("\n".join(network.listDirectory(path)))

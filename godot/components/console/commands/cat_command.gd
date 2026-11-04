class_name catCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "cat"
	aliases = []
	category = "General"
	description = "Allows you to view the contents of a file."
	usage = "cat [filename]"
	isHidden = false # used to hide internal commands from standard help

func execute(_args: Array[String]) -> void:
	var network:GameNetwork = Globals.gameNetworkManager.activeNetwork
	var path:String = ""
	for a in _args: path += " " + a
	path = path.strip_edges()

	if network.isLocked(path):
		Globals.consoleManager.printOutputWithSFX("User not authorized to view the contents of this file.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
		
		
	var node := network.getNode(path)
	if node.get("type") != "file": Globals.consoleManager.printOutputWithSFX("File not found.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
		
	Globals.consoleManager.printOutput(network.readFile(path))

class_name lsCommand
extends ConsoleCommand



func _init() -> void:
	commandName = "ls"
	aliases = []
	category = "Filesystem"
	description = "List the contents of the current directory."
	usage = "ls"
	isHidden = false # used to hide internal commands from standard help

func execute(_args: Array[String]) -> void:
	var network:GameNetwork = Globals.gameNetworkManager.activeNetwork
	var path:String = ""
	for a in _args: path += " " + a
	path = path.strip_edges()

	if network.isLocked(path):
		Globals.consoleManager.printOutputWithSFX("Not authorized to view contents of that directory.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
		return
		
	var node := network.getNode(path)
	if node.get("type") != "directory":
		Globals.consoleManager.printOutputWithSFX("Directory not found.", Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
		return
		
	Globals.consoleManager.printOutput("\n".join(network.listDirectory(path)))


func getHelp() -> String:
	var helpText: String = commandName + " - " + description + "\nUsage: " + usage
	helpText += "\n\nContents are sorted by name, and the type of each item is indicated by the following icons;"
	helpText += "\n [~] File\n [#] Public Directory\n [!] Locked Directory\n [+] Unlocked Directory" 

	return helpText

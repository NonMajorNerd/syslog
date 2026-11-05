class_name DisconnectCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "disconnect"
	aliases = [""]
	category = "Networking"
	description = "Disconnect from the active network."
	usage = "disconnect"
	isHidden = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	if _args.size() != 0:
		Globals.consoleManager.printOutput("%s - %s" % [commandName,usage])
		return
		
	if Globals.gameNetworkManager.activeNetwork.networkName == "homenet":
		Globals.consoleManager.printOutput("Cannot disconnect from home network.", Globals.Colors["CONSOLE"]["FONT_FAILURE"])
		return

	Globals.gameNetworkManager.disconnectFrom()
	Globals.consoleManager.printOutput("Disconnected from network.", Globals.Colors["CONSOLE"]["FONT_NETWORKING"])

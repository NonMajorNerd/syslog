class_name ConnectCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "connect"
	aliases = [""]
	category = "Networking"
	description = "Connect to a network via an available connection."
	usage = "connect [network]"
	isHidden = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	if _args.size() != 1:
		Globals.consoleManager.printOutput("%s - %s" % commandName,usage)
		return
	Globals.consoleManager.printOutput("Connecting to network %s." % _args[0])
	await Globals.get_tree().create_timer(randf_range(0.3, 1.3)).timeout
	var result:bool = Globals.gameNetworkManager.connectTo(_args[0])
	if result == true:
		Globals.consoleManager.printOutputWithSFX("Connected to network %s." % Globals.gameNetworkManager.activeNetwork.networkName, Globals.Colors["CONSOLE"]["FONT_NETWORKING"],25,"confirm")
		Globals.consoleManager.registerCommand(DisconnectCommand.new())
			
		# display motd and readme, if the network has them
		var readme:String =  Globals.gameNetworkManager.activeNetwork.readFile("/readme.txt")
		if readme != "": Globals.consoleManager.printOutput(readme)
		var motd:String =  Globals.gameNetworkManager.activeNetwork.readFile("/motd.txt")
		if motd != "": Globals.consoleManager.printOutput(motd)
	
	else: 	Globals.consoleManager.printOutputWithSFX("Could not connect to network %s." % _args[0], Globals.Colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
	

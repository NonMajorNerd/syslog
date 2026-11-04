class_name scoutCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "scout"
	aliases = ["search"]
	category = "Networking"
	description = "Scan for nearby networks with available connections."
	usage = "scout"
	isHidden = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	Globals.consoleManager.printOutput("Scanning for available network connections.")
	await Globals.get_tree().create_timer(randf_range(0.3, 1.3)).timeout
	Globals.consoleManager.printOutput("Network(s) available: HelixDynamics", Globals.Colors["CONSOLE"]["FONT_NETWORKING"])
	Globals.consoleManager.registerCommand(ConnectCommand.new())
	

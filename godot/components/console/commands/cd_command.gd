class_name cdCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "cd"
	aliases = []
	category = "Filesystem"
	description = "Change the working directory."
	usage = "cd [directory]"
	isHidden = false # used to hide internal commands from standard help
	
func execute(args: Array[String]) -> void:
	var network: GameNetwork = Globals.gameNetworkManager.activeNetwork

	if network == null:
		Globals.consoleManager.printOutput("Not connected.")
		return

	var path: String = " ".join(args).strip_edges()
	if path.is_empty(): path = "/"

	if not network.directoryExists(path):
		Globals.consoleManager.printOutput("Directory not found.", Globals.Colors["CONSOLE"]["FONT_FAILURE"])
		return

	var parts: Array[String] = network.resolvePath(path)
	var traversed: Array[String] = []

	for part in parts:
		traversed.append(part)

		var directoryPath: String = "/" + "/".join(traversed)

		if not network.isLocked(directoryPath): continue

		var password: Variant = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
		if password == null: return

		if not network.unlock(directoryPath, str(password)):
			Globals.consoleManager.printOutputWithSFX("Access denied.", Globals.Colors["CONSOLE"]["FONT_FAILURE"], 25, "decline")
			return

	if not network.changeDirectory(path):
		Globals.consoleManager.printOutputWithSFX("Access denied.", Globals.Colors["CONSOLE"]["FONT_FAILURE"], 25, "decline")
		
func validatePassword(_value: String) -> String:
	return ""

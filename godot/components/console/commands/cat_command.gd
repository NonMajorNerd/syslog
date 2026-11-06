class_name catCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "cat"
	aliases = []
	category = "Filesystem"
	description = "Print the contents of a file to the terminal."
	usage = "cat [filename]"
	isHidden = false # used to hide internal commands from standard help

func execute(args: Array[String]) -> void:
	var network: GameNetwork = Globals.gameNetworkManager.activeNetwork

	if network == null:
		Globals.consoleManager.printOutput("Not connected.")
		return

	var path: String = " ".join(args).strip_edges()

	if network.isLocked(path):
		Globals.consoleManager.printOutputWithSFX("User not authorized to view this file.", Globals.Colors["CONSOLE"]["FONT_FAILURE"], 25, "decline")
		return
	var node: Dictionary = network.getNode(path)
	if node.get("type") != "file":
		Globals.consoleManager.printOutputWithSFX("File not found.", Globals.Colors["CONSOLE"]["FONT_FAILURE"], 25, "decline")
		return

	# Display the file contents.
	Globals.consoleManager.printOutput(network.readFile(path))

	# Automatically collect rewards, if available.
	var rewards: Dictionary = Globals.playerHandle.collectFileRewards( network, path)

	if rewards.is_empty(): return

	var rewardMessages: Array[String] = []

	for rewardType in rewards:
		var amount: Variant = rewards[rewardType]
		rewardMessages.append("+%s %s" % [str(amount), rewardType])

	Globals.consoleManager.printOutput("Rewards collected: " + ", ".join(rewardMessages), Globals.Colors["CONSOLE"]["FONT_SUCCESS"])

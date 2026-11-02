class_name HelpCommand
extends ConsoleCommand

# todo :: implement optional arguments like including/excluding category, including hidden commands, etc
		# help								Lists all visible commands, grouped by category.
		# help <command>			Displays detailed command information.
		# help <category>			Lists commands in a particular category.
		# help search <term>	Searches command names and descriptions.
		# help all						Includes hidden commands, if permitted.
		# commands						Lists command names and aliases only.
		
func _init() -> void:
	commandName = "help"
	aliases = ["?"]
	category = "General"
	description = "Displays command information."
	usage = "help [command]"


func execute(args: Array[String]) -> void:
	if args.size() > 1:
		Globals.consoleManager.printOutput("Usage: " + usage)
		return

	if args.is_empty():
		showCommandList()
		return

	showCommandHelp(args[0])


func showCommandList() -> void:
	Globals.consoleManager.printOutput("\nAvailable commands:")

	var commandNames: Array[String] = []

	# Only collect primary command names
	for command in Globals.consoleManager.commands.values():
		if Globals.consoleManager.commands[command.commandName].isHidden: continue # skip over hidden commands
		if not commandNames.has(command.commandName):
			commandNames.append(command.commandName)

	commandNames.sort()

	for cName in commandNames:
		var command:ConsoleCommand = (Globals.consoleManager.commands[cName])
		Globals.consoleManager.printOutput(" %s - %s" % [command.commandName,command.description])
		
	Globals.consoleManager.printOutput("\nUse 'help <command>' for more information.\n")


func showCommandHelp(commandName: String) -> void:
	var lookupName: String = commandName.to_lower()

	if not Globals.consoleManager.commands.has(lookupName):
		Globals.consoleManager.printOutput("Unknown command: " + commandName)
		return

	var command: ConsoleCommand = (
		Globals.consoleManager.commands[lookupName]
	)

	Globals.consoleManager.printOutput(command.getHelp())

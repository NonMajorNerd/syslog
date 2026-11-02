class_name ClearCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "clear"
	aliases = ["cls"]
	category = "General"
	description = "Clears the terminal of text."
	usage = "clear"
	isHidden = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	Globals.consoleManager.clearOutput()

func getHelp() -> String:
	var helpText: String = commandName + " - " + description + "\nUsage: " + usage

	if not aliases.is_empty():
		var aliasText: String = ", ".join(aliases)
		helpText += "\nAliases: " + aliasText
	else: helpText += "\nAliases: None"

	return helpText

class_name ClearCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "clear"
	aliases = ["cls"]
	category = "General"
	description = "Clear the terminal of text."
	usage = "clear"
	isHidden = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	Globals.consoleManager.clearOutput()

class_name ClearCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "clear"
  aliases = ["cls"]
  category = "General"
  description = "Clear the terminal output."

func execute(_input: CommandInput) -> void:
  Globals.consoleManager.clearOutput()

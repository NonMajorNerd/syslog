class_name ConsoleCommand
extends RefCounted

var commandName: String = ""
var aliases: Array[String] = []
var category: String = "General"
var description: String = ""
var isHidden: bool = false
var extraHelp: String = ""
var arguments: Array[Dictionary] = []
var options: Array[Dictionary] = []

func execute(_input: CommandInput) -> void:
  pass

func getUsage() -> String:
  return CommandSpec.formatUsage(commandName, arguments, options)

func getHelp() -> String:
  return CommandSpec.formatHelp(self)

# Override only when an argument needs dynamic completions.
func completeArgument(_argumentName: String, _partial: String) -> Array[String]:
  return []

class_name ConsoleCommand
extends RefCounted

var commandName: String = ""
var aliases: Array[String] = []
var category: String = ""
var description: String = ""
var usage: String = ""
var isHidden: bool = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	pass

func getHelp() -> String:
	var helpText: String = commandName + " - " + description + "\nUsage: " + usage

	if not aliases.is_empty():
		var aliasText: String = ", ".join(aliases)
		helpText += "\nAliases: " + aliasText
	else: helpText += "\nAliases: None"

	return helpText

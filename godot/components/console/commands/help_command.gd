class_name HelpCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "help"
  aliases = ["?"]
  category = "General"
  description = "Show available commands or detailed command help."
  arguments = [CommandSpec.argument("command", TYPE_STRING, false, "", "Command name, category or 'all'.")]
  options = [CommandSpec.flag("search", "s", "Search command names and descriptions.")]

func execute(input: CommandInput) -> void:
  var lookup: String = input.getString("command")
  if input.getBool("search"):
    if lookup.is_empty():
      Globals.consoleManager.printOutput("A search term is required.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
      Globals.consoleManager.printOutput("Usage: " + getUsage(), Globals.colors["CONSOLE"]["FONT_MUTED"])
      return
    var found: bool = false
    for command in Globals.consoleManager.getUniqueCommands():
      if command.isHidden: continue
      if command.commandName.to_lower().contains(lookup.to_lower()) or command.description.to_lower().contains(lookup.to_lower()):
        Globals.consoleManager.printOutput("%s - %s" % [command.commandName, command.description])
        found = true
    if not found: Globals.consoleManager.printOutput("No matching commands.", Globals.colors["CONSOLE"]["FONT_MUTED"])
    return
  if Globals.consoleManager.commands.has(lookup.to_lower()):
    Globals.consoleManager.printOutput(Globals.consoleManager.commands[lookup.to_lower()].getHelp())
    return
  # Group canonical commands by category; aliases share instances.
  var groups: Dictionary = {}
  for command in Globals.consoleManager.getUniqueCommands():
    if command.isHidden and lookup.to_lower() != "all": continue
    if not lookup.is_empty() and lookup.to_lower() != "all" and command.category.to_lower() != lookup.to_lower(): continue
    if not groups.has(command.category): groups[command.category] = []
    groups[command.category].append("%s - %s" % [command.commandName, command.description])
  if groups.is_empty():
    Globals.consoleManager.printOutput("Unknown command or category: " + lookup, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var categories: Array = groups.keys()
  categories.sort()
  for group in categories:
    Globals.consoleManager.printOutput("\n%s:\n  %s" % [group, "\n  ".join(groups[group])])
  Globals.consoleManager.printOutput("\nUse 'help <command>' for details, or 'help -s <term>' to search.", Globals.colors["CONSOLE"]["FONT_MUTED"])

# Help completion uses the same unique command registry as its listing.
func completeArgument(name: String, partial: String) -> Array[String]:
  var matches: Array[String] = []
  if name != "command": return matches
  for command in Globals.consoleManager.getUniqueCommands():
    if not command.isHidden and command.commandName.begins_with(partial): matches.append(command.commandName)
  return matches

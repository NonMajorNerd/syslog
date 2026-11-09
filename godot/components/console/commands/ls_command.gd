class_name LsCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "ls"
  aliases = ["dir"]
  category = "Filesystem"
  description = "List files and directories."
  arguments = [CommandSpec.argument("path", TYPE_STRING, false, ".", "Directory to list.")]
  options = [
    #CommandSpec.flag("all", "a", "Include hidden entries."),
    #CommandSpec.flag("long", "l", "Display entry details."),
    CommandSpec.option("sort", "s", TYPE_STRING, "name", "Sort entries by name or type.", ["name", "type"])
  ]
  extraHelp = "[~] file  [#] directory  [!] locked  [+] unlocked"

func execute(input: CommandInput) -> void:
  var network: GameNetwork = Globals.gameNetworkManager.activeNetwork
  if network == null:
    Globals.consoleManager.printOutput("Not connected.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var path: String = input.getString("path")
  if network.isLocked(path):
    Globals.consoleManager.printOutput("Not authorized to view that directory.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var node: Dictionary = network.getNode(path)
  if node.get("type") != "directory":
    Globals.consoleManager.printOutput("Directory not found: " + path, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var entries: Array[String] = network.listDirectory(path)
  #if not input.getBool("all"):
    #entries = entries.filter(func(entry: String) -> bool: return not entry.get_slice(" ", 1).begins_with("."))
  if input.getString("sort") == "type": entries.sort_custom(func(a: String, b: String) -> bool: return a.substr(0, 3) + a < b.substr(0, 3) + b)
  #if input.getBool("long"):
    #Globals.consoleManager.printOutput("Entries in %s: %d" % [network.getAbsolutePath(path), entries.size()], Globals.colors["CONSOLE"]["FONT_MUTED"])
  Globals.consoleManager.printOutput("\n".join(entries))

func completeArgument(name: String, partial: String) -> Array[String]:
  return CommandCompletion.paths(partial, true) if name == "path" else []

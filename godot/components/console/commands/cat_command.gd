class_name CatCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "cat"
  category = "Filesystem"
  description = "Read a file and collect its discoveries."
  arguments = [CommandSpec.argument("file", TYPE_STRING, true, null, "File to read.")]

func execute(input: CommandInput) -> void:
  var network: GameNetwork = Globals.gameNetworkManager.activeNetwork
  if network == null:
    Globals.consoleManager.printOutputWithSfx("Not connected.", Globals.colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
    return

  var path: String = input.getString("file")
  if network.isLocked(path):
    Globals.consoleManager.printOutputWithSfx("Not authorized to read that file.", Globals.colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
    return

  var node: Dictionary = network.getNode(path)
  if node.get("type") != "file":
    Globals.consoleManager.printOutputWithSfx("File not found: " + path, Globals.colors["CONSOLE"]["FONT_FAILURE"],25,"decline")
    return

  # output file and record in player knowledge
  Globals.consoleManager.printOutputWithSfx(network.readFile(path), Globals.colors["CONSOLE"]["FONT_DEFAULT"], 5,"glitch")
  Globals.playerHandle.recordFileRead(network, path)

  # check for and build rewards
  var awarded: Dictionary = Globals.playerHandle.collectFileRewards(network, path)
  if awarded.is_empty(): return
  var messages: Array[String] = []
  for resource in awarded:
    messages.append("+%s %s" % [str(int(awarded[resource])), resource])
  Globals.consoleManager.printOutputWithSfx(", ".join(messages), Globals.colors["CONSOLE"]["FONT_SUCCESS"], 25, "confirm")

func completeArgument(name: String, partial: String) -> Array[String]:
  if name == "file": return CommandCompletion.paths(partial, false, true)
  return []

class_name CdCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "cd"
  category = "Filesystem"
  description = "Change the current directory."
  arguments = [CommandSpec.argument("path", TYPE_STRING, false, "/", "Destination directory.")]

func execute(input: CommandInput) -> void:
  var network: GameNetwork = Globals.gameNetworkManager.activeNetwork
  if network == null:
    Globals.consoleManager.printOutput("Not connected.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var path: String = input.getString("path")
  if not network.directoryExists(path):
    Globals.consoleManager.printOutput("Directory not found: " + path, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  # Walk from root to target so each locked ancestor gets its own prompt.
  var parts: Array[String] = network.resolvePath(path)
  var traversed: Array[String] = []
  for part in parts:
    traversed.append(part)
    var directoryPath: String = "/" + "/".join(traversed)
    if not network.isLocked(directoryPath): continue
    # Input remains hidden; Escape/Ctrl+C resolves null and aborts traversal.
    var password: Variant = await Globals.consoleManager.requestInput("Password:", Callable(), true)
    if password == null: return
    # A pending password must never unlock a different active network.
    if Globals.gameNetworkManager.activeNetwork != network: return
    if not network.unlock(directoryPath, str(password)):
      Globals.consoleManager.printOutput("Access denied.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
      return
  if not network.changeDirectory(path):
    Globals.consoleManager.printOutput("Access denied.", Globals.colors["CONSOLE"]["FONT_FAILURE"])

func completeArgument(name: String, partial: String) -> Array[String]:
  return CommandCompletion.paths(partial, true) if name == "path" else []

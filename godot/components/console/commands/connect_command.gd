class_name ConnectCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "connect"
  aliases = ["con"]
  category = "Networking"
  description = "Connect to an available network."
  arguments = [CommandSpec.argument("network", TYPE_STRING, true, null, "Network name.")]

func execute(input: CommandInput) -> void:
  var target: String = input.getString("network")
  Globals.consoleManager.printOutput("Connecting to %s..." % target, Globals.colors["CONSOLE"]["FONT_MUTED"])
  # Simulated latency keeps the terminal's networking interaction paced.
  await Globals.get_tree().create_timer(randf_range(0.3, 1.3)).timeout
  if not Globals.gameNetworkManager.connectTo(target):
    Globals.consoleManager.printOutput("Could not connect to network: " + target, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var network: GameNetwork = Globals.gameNetworkManager.activeNetwork
  Globals.consoleManager.printOutputWithSfx("Connected to %s." % network.networkName, Globals.colors["CONSOLE"]["FONT_NETWORKING"], 25, "search")
  # Re-registration is harmless if a previous connection already unlocked it.
  Globals.consoleManager.registerCommand(DisconnectCommand.new())
  for filename in ["/readme.txt", "/motd.txt"]:
    var contents: String = network.readFile(filename)
    if not contents.is_empty():
      Globals.consoleManager.printOutput("\n" + contents)

func completeArgument(name: String, partial: String) -> Array[String]:
  var matches: Array[String] = []
  if name == "network":
    for networkName in Globals.gameNetworkManager.getAvailableNetworks():
      if networkName.to_lower().begins_with(partial.to_lower()): matches.append(networkName)
  return matches

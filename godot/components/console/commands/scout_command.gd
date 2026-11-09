class_name ScoutCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "scout"
  category = "Networking"
  description = "Scan for available networks."

func execute(_input: CommandInput) -> void:
  Globals.consoleManager.printOutput("Scanning for available networks...", Globals.colors["CONSOLE"]["FONT_MUTED"])
  await Globals.get_tree().create_timer(randf_range(0.3, 1.3)).timeout
  var names: Array[String] = Globals.gameNetworkManager.getAvailableNetworks()
  if names.is_empty():
    Globals.consoleManager.printOutput("No networks available.", Globals.colors["CONSOLE"]["FONT_NOTIF"])
  else:
    Globals.consoleManager.printOutputWithSfx("Available networks: " + ", ".join(names), Globals.colors["CONSOLE"]["FONT_NETWORKING"], 25, "search")
    for networkName in names:
      var network: GameNetwork = Globals.gameNetworkManager.networks[networkName]
      Globals.playerHandle.discoverNetwork(network)

  # Unlocking connect happens once; duplicate registration is ignored.
  Globals.consoleManager.registerCommand(ConnectCommand.new())

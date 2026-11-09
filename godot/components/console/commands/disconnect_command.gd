class_name DisconnectCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "disconnect"
  aliases = ["dc"]
  category = "Networking"
  description = "Disconnect from the active external network."

func execute(_input: CommandInput) -> void:
  var network: GameNetwork = Globals.gameNetworkManager.activeNetwork
  if network == null:
    Globals.consoleManager.printOutput("Not connected.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  if network.networkName == "homenet":
    Globals.consoleManager.printOutput("Cannot disconnect from your home network.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  Globals.gameNetworkManager.disconnectFrom()
  Globals.consoleManager.printOutput("Disconnected from network.", Globals.colors["CONSOLE"]["FONT_NETWORKING"])

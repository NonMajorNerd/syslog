extends Node

# set up globals, set up UI
func _ready() -> void:
  # Controllers must be resolved before Console.setup() connects signals
  Globals.loadControllers()
  $Console.setup()

func _notification(notif: int) -> void:
  if notif == NOTIFICATION_WM_CLOSE_REQUEST:
    print("\nClosing!")
    Globals.consoleManager.printOutput("Disconnecting from syslog...")
    await Globals.serverManager.writeHandleAsync(Globals.playerHandle)
    get_tree().quit()

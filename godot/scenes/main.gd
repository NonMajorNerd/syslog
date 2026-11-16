extends Node

# set up globals, set up UI
func _ready() -> void:
  get_tree().auto_accept_quit = false
  # Controllers must be resolved before Console.setup() connects signals
  Globals.loadControllers()
  $Console.setup()

func _notification(notif: int) -> void:
  if notif == NOTIFICATION_WM_CLOSE_REQUEST: closeGame()
    
func closeGame() -> void:
  print("\nClosing!")
  Globals.consoleManager.printOutput("Disconnecting from syslog...")
  var saved: bool = await Globals.serverManager.writeHandleAsync(Globals.playerHandle)
  if not saved: return
  
  get_tree().quit()
    
func _unhandled_key_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed \
  and not event.echo and event.keycode == KEY_F7:
    var saved: bool = await Globals.serverManager.writeHandleAsync(Globals.playerHandle )
    print("DEBUG: Manual save result = ", saved)

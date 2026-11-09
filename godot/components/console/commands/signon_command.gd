class_name SignonCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "signon"
  category = "Account"
  description = "Sign in to your account."
  arguments = [CommandSpec.argument("username", TYPE_STRING, false, "", "Username; prompts if omitted.")]

func execute(input: CommandInput) -> void:
  var username: Variant = input.getString("username")
  if str(username).is_empty():
    username = await Globals.consoleManager.requestInput("Username:", validateUsername)
    if username == null: return
  # Password input is secret and is not stored in the command history.
  var password: Variant = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
  if password == null: return
  Globals.consoleManager.printOutput("Connecting as %s..." % username, Globals.colors["CONSOLE"]["FONT_MUTED"])
  var result: int = await Globals.serverManager.authenticateAsync(str(username), "", str(password), false)
  if result != OK:
    Globals.consoleManager.printOutput(Globals.serverManager.errorMessage, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  # HTTP authentication alone is not enough for real-time world chat.
  var connection: int = await Globals.serverManager.connectSocket()
  if connection != OK:
    Globals.consoleManager.printOutput(Globals.serverManager.errorMessage, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  Globals.consoleManager.printOutput("Connected as %s." % username, Globals.colors["CONSOLE"]["FONT_SUCCESS"])
  # Loads the player, activates homeNet, registers commands, and joins chat.
  Globals.serverManager.connectToWorld(str(username))

func validateUsername(value: String) -> String:
  return "Username cannot be empty." if value.strip_edges().is_empty() else ""

func validatePassword(value: String) -> String:
  return "Password cannot be empty." if value.is_empty() else ""

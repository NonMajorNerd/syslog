class_name RegisterCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "register"
  category = "Account"
  description = "Create a new user account."

func execute(_input: CommandInput) -> void:
  Globals.consoleManager.printOutput("Account registration", Globals.colors["CONSOLE"]["FONT_NOTIF"])
  var username: Variant = await Globals.consoleManager.requestInput("Username:", validateUsername)
  if username == null: return
  var email: Variant = await Globals.consoleManager.requestInput("Email:", validateEmail)
  if email == null: return
  # Each prompt resumes this coroutine; cancelled input returns null.
  var password: Variant = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
  if password == null: return
  # Do not attempt to sign in to determine if an email address exists.
  # Only the explicit registration request creates a Nakama account.
  var result: int = await Globals.serverManager.authenticateAsync(str(username), str(email), str(password), true)
  if result == OK:
    Globals.consoleManager.printOutput("Registered user %s successfully." % username, Globals.colors["CONSOLE"]["FONT_SUCCESS"])
  else:
    Globals.consoleManager.printOutput(Globals.serverManager.errorMessage, Globals.colors["CONSOLE"]["FONT_FAILURE"])

func validateUsername(value: String) -> String:
  return "Username cannot be empty." if value.strip_edges().is_empty() else ""

func validateEmail(value: String) -> String:
  if not value.contains("@") or not value.get_slice("@", 1).contains("."): return "Please enter a valid email address."
  return ""

func validatePassword(value: String) -> String:
  return "Password must be at least 8 characters." if value.length() < 8 else ""

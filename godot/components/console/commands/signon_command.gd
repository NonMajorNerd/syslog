class_name SignonCommand
extends ConsoleCommand

# todo:: add optional args to signin as a single command
# signon [username] [password]
# signon [username] and prompt for password

func _init() -> void:
	commandName = "signon"
	aliases = ["logon", "so", "lo"]
	category = "Account"
	description = "Connects as a registered user."
	usage = "signon"

func validateUsername(_value: String) -> String: return ""
func validatePassword(_value: String) -> String: return ""

func execute(_args: Array[String]) -> void:
	Globals.consoleManager.printOutput("User signon")

	var username: Variant = await Globals.consoleManager.requestInput("Username:", validateUsername)
	if username == null: return

	var password: Variant = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
	if password == null:return

	Globals.consoleManager.printOutput("Connecting as user %s." % username)
	var exists:int = await Globals.serverManager.authenticate_async(username, "", password, false)
	if exists != OK: Globals.consoleManager.printOutput("User %s not registered." % username, Globals.Colors["CONSOLE"]["FONT_FAILURE"])
	else:
		var result:int = await Globals.serverManager.authenticate_async(username, "", password, false)
		if result == OK:
			var cresult:int = await Globals.serverManager.connectSocket()
			if cresult == OK:
				Globals.consoleManager.printOutput("Connected as user %s." % username, Globals.Colors["CONSOLE"]["FONT_SUCCESS"])
				Globals.serverManager.connectToWorld()
		else: Globals.consoleManager.printOutput("%s" % Globals.serverManager.errorMessage, Globals.Colors["CONSOLE"]["FONT_FAILURE"])

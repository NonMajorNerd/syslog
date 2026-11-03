class_name RegisterCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "register"
	aliases = ["signup"]
	category = "Account"
	description = "Creates a new user."
	usage = "register"

func execute(_args: Array[String]) -> void:
	Globals.consoleManager.printOutput("Account registration")
	
	var username: Variant = await Globals.consoleManager.requestInput("Username:", validateUsername)
	if username == null: return
	
	var email: Variant = await Globals.consoleManager.requestInput("Email:", validateEmail)
	if email == null: return

	var password: Variant = await Globals.consoleManager.requestInput("Password:", validatePassword, true)
	if password == null:return

	Globals.consoleManager.printOutput("Registering user %s." % username)
	var exists:int = await Globals.serverManager.authenticate_async(username, email, password, false)
	if exists == OK: Globals.consoleManager.printOutput("Email %s already registered." % email, Globals.Colors["CONSOLE"]["FONT_FAILURE"])
	else:
		var result:int = await Globals.serverManager.authenticate_async(username, email, password, true)
		if result == OK:
			Globals.consoleManager.printOutput("Registered user %s successfully." % username, Globals.Colors["CONSOLE"]["FONT_SUCCESS"])
			#Globals.serverManager.connectSocket()
		else: Globals.consoleManager.printOutput("%s" % Globals.serverManager.errorMessage, Globals.Colors["CONSOLE"]["FONT_FAILURE"])

func validateUsername(value: String) -> String:
	# todo :: check against existing usernames, centralize these off of the individual commands
	return""

func validateEmail(value: String) -> String:
	# todo :: check against existing emails, centralize these off of the individual commands
	if not value.contains("@") or not value.contains("."):
			return "Please enter a valid email address."
	return ""
	

func validatePassword(value: String) -> String:
	if value.length() < 8:
		return "Password must be at least 8 characters."

	return ""

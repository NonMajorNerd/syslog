class_name ConsoleManager
extends Node

signal outputPrinted(message:String, color:Color)
signal chatPrinted(message:String, color:Color)
signal promptChanged(promptText:String, secret:bool)
signal inputEnabledChanged(enabled:bool)

signal inputSubmitted(value:String)
signal inputCancelled

signal commandsRegistered(message:String)

var commands: Dictionary[String, ConsoleCommand] = {}

# info on currently running command/prompt
var isCommandRunning: bool = false
var activeCommand: ConsoleCommand
var activePrompt: ConsolePrompt

func _ready() -> void:
	# register default ('offline') commands
	registerCommand(ClearCommand.new())
	registerCommand(HelpCommand.new())
	registerCommand(RegisterCommand.new())
	registerCommand(SignonCommand.new())
	registerCommand(volumeCommand.new())
	

	
# adds a command and all aliases to the commands list
func registerCommand(command: ConsoleCommand, multi=false) -> bool:
	var commandName: String = command.commandName.to_lower()

	if commandName.is_empty():
		push_error("Cannot register a command without a name.")
		return false

	if commands.has(commandName):
		push_error("Command already registered: " + commandName)
		return false

	commands[commandName] = command
	if not multi: commandsRegistered.emit(commandName)
	
	for alias in command.aliases:
		var aliasName: String = alias.to_lower()

		if aliasName.is_empty():
			continue # skip to next alias

		if commands.has(aliasName):
			push_error("Command alias already registered: " + aliasName)
			continue # skip to next alias

		# if we haven't skipped, add alias to commands list
		commands[aliasName] = command 
		
	return true
	
# adds multiple commands at once, provides one bulk signal emit
func registerCommandsBulk(commands:Array[ConsoleCommand]):
	var commandNames:Array = []
	commands.sort_custom(func(a: ConsoleCommand, b: ConsoleCommand) -> bool:
												return a.commandName < b.commandName
												)
	for command in commands:
		if registerCommand(command,true): commandNames.append(command.commandName)
		
	if not commandNames.is_empty():  commandsRegistered.emit(", ".join(commandNames))

func executeLine(line: String) -> void:
	if isCommandRunning: return

	var trimmedLine: String = line.strip_edges()
	if trimmedLine.is_empty(): return

	var parts: PackedStringArray = trimmedLine.split(" ", false)
	if parts.is_empty(): return

	var commandName: String = parts[0].to_lower()
	var args: Array[String] = []

	for i in range(1, parts.size()):
		args.append(parts[i])

	if not commands.has(commandName):
		printOutput("Unknown command: " + commandName)
		return

	activeCommand = commands[commandName]
	isCommandRunning = true

	inputEnabledChanged.emit(false)

	#var context:= ConsoleContext.new(self)
	var commandToExecute: ConsoleCommand = activeCommand

	# await for commands that require additional input
	@warning_ignore("redundant_await")
	await commandToExecute.execute(args)
	
	activeCommand = null
	isCommandRunning = false

	inputEnabledChanged.emit(true)


func submitInput(value: String) -> void:
	if activePrompt != null:
		inputSubmitted.emit(value)
		return

	executeLine(value)
	
func requestInput(promptText: String, validator: Callable = Callable(), secret: bool = false) -> Variant:
	while true:
		var prompt := ConsolePrompt.new()
		activePrompt = prompt

		# create callable functions
		var submitCallable:= func(val: String) -> void: prompt.resolve(val)
		var cancelCallable:= func() -> void: 						prompt.resolve(null)

		# connect callables
		inputSubmitted.connect(submitCallable, CONNECT_ONE_SHOT)
		inputCancelled.connect(cancelCallable, CONNECT_ONE_SHOT	)

		# Configure the prompt before allowing input.
		promptChanged.emit(promptText, secret)
		inputEnabledChanged.emit(true)

		var value: Variant = await prompt.resolved
		# Remove whichever one-shot connection wasn't used.
		if inputSubmitted.is_connected(submitCallable): inputSubmitted.disconnect(submitCallable)
		if inputCancelled.is_connected(cancelCallable): inputCancelled.disconnect(cancelCallable)

		activePrompt = null

		# Always reset the UI's prompt and secret mode.
		promptChanged.emit("", false)
		inputEnabledChanged.emit(false)

		if value == null:
			printOutput("^C\n")
			return null

		if validator.is_valid():
			var errorMessage: String = validator.call(value)

			if not errorMessage.is_empty():
				printOutput(errorMessage)
				continue

		return value
	return null

func cancelInput() -> void:
	if activePrompt == null: return
	inputCancelled.emit()

func printOutputWithSFX(message:String, color:Color = Globals.Colors["CONSOLE"]["FONT_DEFAULT"], chance:int=25, type:String="glitch"):
	if randf() < clampf(float(chance) / 100.0, 0.0, 1.0): Globals.audioManager.playRandom(type)
	outputPrinted.emit(message, color)

func printOutput(message:String, color:Color = Globals.Colors["CONSOLE"]["FONT_DEFAULT"]) -> void:
	outputPrinted.emit(message, color)
	
func printChat(message:String, color:Color = Globals.Colors["CONSOLE"]["FONT_DEFAULT"]) -> void:
	chatPrinted.emit(message, color)

func clearOutput() -> void:
	outputPrinted.emit("CODE_CLEAR",Globals.Colors["CONSOLE"]["FONT_DEFAULT"])

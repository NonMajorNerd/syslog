extends CanvasLayer
# UI/Scene for console

@onready var rtlTerminal: RichTextLabel = $screen/Console/HBoxContainer/PanelContainer/VBoxContainer/rtlTerminal
@onready var rtlChat: RichTextLabel = $screen/Console/HBoxContainer/Sidebar/VBoxContainer/rtlWorldChat
@onready var rtlPrompt: RichTextLabel = $screen/Console/HBoxContainer/PanelContainer/VBoxContainer/inputline/HBoxContainer/rtlPrompt
@onready var txtInput: LineEdit = $screen/Console/HBoxContainer/PanelContainer/VBoxContainer/inputline/HBoxContainer/txtInput

# Command history
const MAX_HISTORY: int = 100
var commandHistory: Array[String] = []
var historyIndex: int = -1
var historyDraft: String = ""


func _ready() -> void:
	await get_tree().create_timer(6.0).timeout
	txtInput.editable = true


func setup() -> void:
	Globals.consoleManager.outputPrinted.connect(_on_output_printed)
	Globals.consoleManager.commandsRegistered.connect(_onCommandsRegistered)
	Globals.consoleManager.chatPrinted.connect(_on_chat_printed)
	Globals.gameNetworkManager.networkConnected.connect(onNetworkPathChange)
	Globals.gameNetworkManager.pathChanged.connect(onNetworkPathChange)
	Globals.consoleManager.promptChanged.connect(_on_prompt_changed)
	Globals.consoleManager.inputEnabledChanged.connect(_on_input_enabled_changed)
	txtInput.text_submitted.connect(_on_input_submitted)

	#txtInput.editable = true
	txtInput.secret = false
	txtInput.grab_focus()
	clearPrompt()


func onNetworkPathChange(_var) -> void:
	clearPrompt()


func clearPrompt() -> void:
	var nick: String = "unauth"
	var net: String = "local"
	var path: String = "/"
	var auth: String = "$"

	if Globals.playerHandle.realName != "":
		nick = Globals.playerHandle.realName #nickname once available
	if Globals.gameNetworkManager.activeNetwork:
		net = Globals.gameNetworkManager.activeNetwork.networkName.to_lower()
		path = Globals.gameNetworkManager.activeNetwork.getCurrentPath()
	if net == "homenet":
		auth = "#"

	rtlPrompt.text = "%s@%s:%s%s" % [nick, net, path, auth]


func _onCommandsRegistered(cmds: String):
	_on_output_printed("New command(s) registered; " + cmds, Globals.Colors["CONSOLE"]["FONT_NOTIF"])


func _on_chat_printed(msg: String, clr: Color) -> void:
	if not msg: return
	if msg == "CODE_CLEAR": rtlChat.clear() # sent by no command
	else: rtlChat.append_text("[color=#%s]%s[/color]\n" % [clr.to_html(false), msg])


func _on_output_printed(msg: String, clr: Color) -> void:
	if not msg:
		return
	if msg == "CODE_CLEAR":
		rtlTerminal.clear() # sent by clear_command.execute()
	else:
		rtlTerminal.append_text("[color=#%s]%s[/color]\n" % [clr.to_html(false), msg])


func _on_prompt_changed(promptText: String, secret: bool) -> void:
	if promptText == "": clearPrompt()
	else: rtlPrompt.text = promptText
	txtInput.secret = secret


func _on_input_enabled_changed(enabled: bool) -> void:
	txtInput.editable = enabled
	if enabled:
		txtInput.grab_focus()


func _on_input_submitted(input: String) -> void:
	var isPromptInput: bool = Globals.consoleManager.activePrompt != null

	# if options{"ECHO_INPUT"}:
	if txtInput.secret:
		rtlTerminal.append_text(rtlPrompt.text + "\n")
	else:
		rtlTerminal.append_text(rtlPrompt.text + " " + input + "\n")

	if input.strip_edges().is_empty() and not isPromptInput:
		return

	# Only record normal commands.
	if not isPromptInput:
		addToHistory(input)

	# random chance for glitch sfx
	if randi_range(1, 100) <= 33:
		Globals.audioManager.playRandom("glitch")

	txtInput.clear()
	Globals.consoleManager.submitInput(input)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not event.pressed or event.echo: return

	# Only navigate command history during normal command input.
	if txtInput.has_focus() and txtInput.editable and Globals.consoleManager.activePrompt == null:
		match event.keycode:
			KEY_UP:
				navigateHistory(-1)
				get_viewport().set_input_as_handled()
				return

			KEY_DOWN:
				navigateHistory(1)
				get_viewport().set_input_as_handled()
				return

	# Cancellation
	if event.keycode == KEY_ESCAPE or (event.keycode == KEY_C and event.ctrl_pressed):
		if Globals.consoleManager.activePrompt != null:
			rtlTerminal.append_text(rtlPrompt.text + "\n")
			Globals.consoleManager.cancelInput()

		txtInput.clear()
		resetHistoryNavigation()
		get_viewport().set_input_as_handled()


func addToHistory(command: String) -> void:
	command = command.strip_edges()
	if command.is_empty(): return

	# Avoid consecutive duplicate entries.
	if not commandHistory.is_empty():
		if commandHistory.back() == command:
			resetHistoryNavigation()
			return

	commandHistory.append(command)

	# Limit history size.
	if commandHistory.size() > MAX_HISTORY:
		commandHistory.pop_front()
	resetHistoryNavigation()


func navigateHistory(direction: int) -> void:
	if commandHistory.is_empty(): return

	# Save current input when first entering history.
	if historyIndex == -1:
		if direction > 0: return

		historyDraft = txtInput.text
		historyIndex = commandHistory.size() - 1

	else:
		historyIndex += direction

		# restore original input.
		if historyIndex >= commandHistory.size():
			txtInput.text = historyDraft
			resetHistoryNavigation()
			txtInput.caret_column = txtInput.text.length()
			return

		# Don't navigate beyond the oldest entry.
		historyIndex = maxi(historyIndex, 0)

	txtInput.text = commandHistory[historyIndex]
	txtInput.caret_column = txtInput.text.length()


func resetHistoryNavigation() -> void:
	historyIndex = -1
	historyDraft = ""

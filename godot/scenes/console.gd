extends Control
# UI/Scene for console

@onready var rtlTerminal: RichTextLabel = $HBoxContainer/VBoxContainer/rtlTerminal
@onready var rtlPrompt: RichTextLabel = $HBoxContainer/VBoxContainer/inputline/HBoxContainer/rtlPrompt
@onready var txtInput: LineEdit = $HBoxContainer/VBoxContainer/inputline/HBoxContainer/txtInput

func setup() -> void:	
	Globals.consoleManager.outputPrinted.connect(_on_output_printed)
	Globals.consoleManager.promptChanged.connect(_on_prompt_changed)
	Globals.consoleManager.inputEnabledChanged.connect(_on_input_enabled_changed)
	txtInput.text_submitted.connect(_on_input_submitted)

	txtInput.editable = true
	txtInput.secret = false
	txtInput.grab_focus()
	clearPrompt()

func clearPrompt() -> void:
	#if not logged in:
	rtlPrompt.text = "unauth@local:/$"

func _on_output_printed(msg:String, clr:Color) -> void:
	if not msg: return
	if msg == "CODE_CLEAR": rtlTerminal.clear() # sent by clear_command.execute()
	else:	rtlTerminal.append_text("[color=#%s]%s[/color]\n" % [clr.to_html(false), msg])
	
func _on_prompt_changed(promptText: String, secret: bool) -> void:
	if promptText == "": clearPrompt()
	else: rtlPrompt.text = promptText
	txtInput.secret = secret
	
func _on_input_enabled_changed(enabled: bool) -> void:
	txtInput.editable = enabled
	if enabled: txtInput.grab_focus() 

func _on_input_submitted(input: String) -> void:
	var isPromptInput: bool = Globals.consoleManager.activePrompt != null

	# if options{"ECHO_INPUT"}:
	if txtInput.secret: rtlTerminal.append_text(rtlPrompt.text + "\n")
	else: rtlTerminal.append_text(rtlPrompt.text + " " + input + "\n")
		
	if input.strip_edges().is_empty() and not isPromptInput:
		return

	txtInput.clear()
	Globals.consoleManager.submitInput(input)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE or (event.keycode == KEY_C	and event.ctrl_pressed==true):
				if Globals.consoleManager.activePrompt != null:
					rtlTerminal.append_text(rtlPrompt.text + "\n")
					Globals.consoleManager.cancelInput()
				txtInput.clear()
				get_viewport().set_input_as_handled()

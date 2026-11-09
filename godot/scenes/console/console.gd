extends CanvasLayer

@onready var rtlTerminal: RichTextLabel = $screen/Console/HBoxContainer/PanelContainer/VBoxContainer/rtlTerminal
@onready var rtlChat: RichTextLabel = $screen/Console/HBoxContainer/Sidebar/VBoxContainer/rtlWorldChat
@onready var rtlPrompt: RichTextLabel = $screen/Console/HBoxContainer/PanelContainer/VBoxContainer/inputline/HBoxContainer/rtlPrompt
@onready var txtInput: LineEdit = $screen/Console/HBoxContainer/PanelContainer/VBoxContainer/inputline/HBoxContainer/txtInput

@onready var rtlResources: RichTextLabel = $screen/Console/HBoxContainer/Sidebar/VBoxContainer/rtlResources
@onready var txtBody: TextEdit = $screen/Console/HBoxContainer/Sidebar/VBoxContainer/PanelContainer/VBoxContainer/PanelContainer2/txtBody

# History belongs to the view; interactive prompt answers are excluded.
const MAX_HISTORY: int = 100
var commandHistory: Array[String] = []
var historyIndex: int = -1
var historyDraft: String = ""


func _ready() -> void:
  # Keep the terminal locked during the existing boot delay.
  await get_tree().create_timer(6.0).timeout
  txtInput.editable = true
  txtInput.grab_focus()

func updateCreditsIntelRep() -> void:
  rtlResources.text = "CREDITS:\t%4.0d\nINTEL:\t\t%4.0d" % [Globals.playerHandle.credits, Globals.playerHandle.intel]

# main.gd calls this after Globals.loadControllers() has found the managers.
func setup() -> void:
  # ConsoleManager -> UI: rendered output, prompt state, and command notices.
  Globals.consoleManager.outputPrinted.connect(onOutputPrinted)
  Globals.consoleManager.outputCleared.connect(func() -> void: rtlTerminal.clear())
  Globals.consoleManager.commandsRegistered.connect(onCommandsRegistered)
  Globals.consoleManager.chatPrinted.connect(onChatPrinted)
  Globals.consoleManager.promptChanged.connect(onPromptChanged)
  Globals.consoleManager.inputEnabledChanged.connect(onInputEnabledChanged)

  # GameNetwork.currentPathChanged -> NetworkManager.pathChanged -> here.
  # A fresh network also emits networkConnected to update the prompt.
  Globals.gameNetworkManager.networkConnected.connect(onNetworkPathChange)
  Globals.gameNetworkManager.pathChanged.connect(onNetworkPathChange)

  # Resource setters on Handle notify the sidebar after rewards change.
  Globals.playerHandle.creditsChanged.connect(updateCreditsIntelRep)
  Globals.playerHandle.heatChanged.connect(updateCreditsIntelRep)
  Globals.playerHandle.intelChanged.connect(updateCreditsIntelRep)
  Globals.playerHandle.repChanged.connect(updateCreditsIntelRep)

  txtInput.text_submitted.connect(onInputSubmitted)

  rtlTerminal.add_theme_color_override("default_color", Globals.colors["CONSOLE"]["FONT_DEFAULT"])
  rtlChat.add_theme_color_override("default_color", Globals.colors["CONSOLE"]["FONT_DEFAULT"])
  rtlPrompt.add_theme_color_override("default_color", Globals.colors["CONSOLE"]["FONT_DEFAULT"])
  txtInput.add_theme_color_override("font_color", Globals.colors["CONSOLE"]["FONT_DEFAULT"])
  rtlResources.add_theme_color_override("default_color", Globals.colors["CONSOLE"]["FONT_MUTED"])

  Globals.consoleManager.printOutput("Pinnacle Systems Engine v7.4.stable.public\nEncryPS API 9.2.2 release 1.36", Globals.colors["CONSOLE"]["FONT_MUTED"])

  clearPrompt()
  txtInput.secret = false
  txtInput.grab_focus()


func onNetworkPathChange(_var) -> void:
  clearPrompt()


func clearPrompt() -> void:
  var nick: String = "unauth"
  var net: String = "local"
  var path: String = "/"
  var auth: String = "$"

  if Globals.playerHandle.realName != "": nick = Globals.playerHandle.realName #nickname once available
  if Globals.gameNetworkManager.activeNetwork:
    net = Globals.gameNetworkManager.activeNetwork.networkName.to_lower()
    path = Globals.gameNetworkManager.activeNetwork.getCurrentPath()
  if net == "homenet": auth = "#"

  rtlPrompt.text = "%s@%s:%s%s" % [nick, net, path, auth]


func onCommandsRegistered(cmds: String):
  onOutputPrinted("New command(s) registered; " + cmds, Globals.colors["CONSOLE"]["FONT_NOTIF"])


func onChatPrinted(msg: String, clr: Color) -> void:
  if not msg: return
  rtlChat.append_text("[color=#%s]%s[/color]\n" % [clr.to_html(false), msg])


func onOutputPrinted(msg: String, clr: Color) -> void:
  if not msg: return
  rtlTerminal.append_text("[color=#%s]%s[/color]\n" % [clr.to_html(false), msg])


func onPromptChanged(promptText: String, secret: bool) -> void:
  if promptText == "": clearPrompt()
  else: rtlPrompt.text = promptText
  txtInput.secret = secret


func onInputEnabledChanged(enabled: bool) -> void:
  txtInput.editable = enabled
  if enabled: txtInput.grab_focus()


func onInputSubmitted(input: String) -> void:
  var isPromptInput: bool = Globals.consoleManager.activePrompt != null

  # Suppress echo for secrets
  if txtInput.secret: rtlTerminal.append_text(rtlPrompt.text + "\n")
  else: rtlTerminal.append_text(rtlPrompt.text + " " + input + "\n")

  if input.strip_edges().is_empty() and not isPromptInput: return

  # keep prompt answers out of history
  if not isPromptInput: addToHistory(input)

  # random chance for glitch sfx
  if randi_range(1, 100) <= 33: Globals.audioManager.playRandom("glitch")

  txtInput.clear()
  # The manager routes the value to a prompt or normal command execution.
  Globals.consoleManager.submitInput(input)


func _input(event: InputEvent) -> void:
  if not event is InputEventKey: return
  if not event.pressed or event.echo: return

  # Only navigate command history during normal command input.
  # Tab and history are available only outside interactive prompts.
  if txtInput.has_focus() and txtInput.editable and Globals.consoleManager.activePrompt == null:
    match event.keycode:
      KEY_TAB:
        var completion: Dictionary = Globals.consoleManager.completeLine(txtInput.text)
        if completion["line"] != txtInput.text:
          txtInput.text = completion["line"]
          txtInput.caret_column = txtInput.text.length()
        elif completion["matches"].size() > 1:
          Globals.consoleManager.printOutput("Matches: " + ", ".join(completion["matches"]), Globals.colors["CONSOLE"]["FONT_MUTED"])
        get_viewport().set_input_as_handled()
        return
      KEY_UP:
        navigateHistory(-1)
        get_viewport().set_input_as_handled()
        return

      KEY_DOWN:
        navigateHistory(1)
        get_viewport().set_input_as_handled()
        return

  # Cancellation
  # Escape/Ctrl+C cancels, stops pending prompt via ConsoleManager
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
  if commandHistory.size() > MAX_HISTORY: commandHistory.pop_front()
  resetHistoryNavigation()


func navigateHistory(direction: int) -> void:
  if commandHistory.is_empty(): return

  # Save current input when first entering history.
  # Save the draft input so Down can restore it after browsing history.
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


func onNotesFocusExited() -> void:
  # update homenet/documents/notes.txt
  if Globals.playerHandle == null: return
  var homenet: GameNetwork = Globals.playerHandle.rig.homeNet
  homenet.writeFile("/documents/notes.txt", txtBody.text.strip_edges().strip_escapes())

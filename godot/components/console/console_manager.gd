class_name ConsoleManager
extends Node

# Output signals carry text/state to the UI; commands never edit UI nodes directly.
signal outputPrinted(message: String, color: Color)
signal chatPrinted(message: String, color: Color)
signal outputCleared
signal promptChanged(promptText: String, secret: bool)
signal inputEnabledChanged(enabled: bool)
# Input signals resolve interactive prompts rather than invoking a new command.
signal inputSubmitted(value: String)
signal inputCancelled
signal commandsRegistered(message: String)

# Canonical command names and aliases both reference one command instance.
var commands: Dictionary[String, ConsoleCommand] = {}
var isCommandRunning: bool = false
var activeCommand: ConsoleCommand
var activePrompt: ConsolePrompt

func _ready() -> void:
  registerCommandsBulk([
    ClearCommand.new(), HelpCommand.new(),
    RegisterCommand.new(), SignonCommand.new(), VolumeCommand.new()
  ])

func registerCommand(command: ConsoleCommand, multi: bool = false) -> bool:
  var key: String = command.commandName.to_lower()
  if key.is_empty():
    push_error("A command requires a name.")
    return false
    
  if commands.has(key):
    # Repeated unlock/connection registration should not generate errors.
    return false
    
  for alias in command.aliases:
    var normalized: String = alias.to_lower()
    if not normalized.is_empty() and commands.has(normalized):
      push_error("Command alias already registered: " + normalized)
      return false
      
  commands[key] = command
  for alias in command.aliases:
    var normalized: String = alias.to_lower()
    if not normalized.is_empty(): commands[normalized] = command
    
  if not multi: commandsRegistered.emit(key)
  return true

# Batch registration emits one notice instead of a notification per command.
func registerCommandsBulk(items: Array[ConsoleCommand]) -> void:
  var names: Array[String] = []
  for item in items:
    if registerCommand(item, true): names.append(item.commandName)
    
  names.sort()
  if not names.is_empty(): commandsRegistered.emit(", ".join(names))

# Discard alias duplicates when listing commands in help or discovery.
func getUniqueCommands() -> Array[ConsoleCommand]:
  var result: Array[ConsoleCommand] = []
  for command in commands.values():
    if not result.has(command): result.append(command)
    
  result.sort_custom(func(a: ConsoleCommand, b: ConsoleCommand) -> bool: return a.commandName < b.commandName)
  return result

func executeLine(line: String) -> void:
  if isCommandRunning or line.strip_edges().is_empty(): return
  
  var parsed: Dictionary = CommandParser.tokenize(line)
  if not parsed["error"].is_empty():
    printOutput(parsed["error"], Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
    
  var tokens: Array[Dictionary] = parsed["tokens"]
  if tokens.is_empty(): return
  
  var key: String = str(tokens[0]["value"]).to_lower()
  if not commands.has(key):
    printOutput("Unknown command: %s. Try 'help'." % key, Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
    
  var command: ConsoleCommand = commands[key]
  var remaining: Array[Dictionary] = tokens.slice(1)
  # Validate the entire invocation before entering the command lifecycle.
  var validated: Dictionary = CommandParser.parse(command, remaining)
  if validated.get("help", false):
    printOutput(command.getHelp())
    return
    
  if not validated["error"].is_empty():
    printOutput(str(validated["error"]), Globals.colors["CONSOLE"]["FONT_FAILURE"])
    printOutput("Usage: " + command.getUsage(), Globals.colors["CONSOLE"]["FONT_MUTED"])
    return
    
  # Block unrelated commands while execute() runs; requestInput() can
  # temporarily enable the field for the active command's next answer.
  activeCommand = command
  isCommandRunning = true
  inputEnabledChanged.emit(false)
  # Await immediate and asynchronous commands to restore input at the right time.
  @warning_ignore("redundant_await")
  await command.execute(validated["input"])
  activeCommand = null
  isCommandRunning = false
  inputEnabledChanged.emit(true)

func submitInput(value: String) -> void:
  # Enter goes to the pending prompt when one exists, not executeLine().
  if activePrompt != null:
    inputSubmitted.emit(value)
  else:
    executeLine(value)

func requestInput(promptText: String, validator: Callable = Callable(), secret: bool = false) -> Variant:
  while true:
    # Validation retries get a new one-shot prompt and fresh signal listeners.
    var prompt: ConsolePrompt = ConsolePrompt.new()
    activePrompt = prompt
    var submitCallable: Callable = func(value: String) -> void: prompt.resolve(value)
    var cancelCallable: Callable = func() -> void: prompt.resolve(null)
    # UI -> submitInput() -> inputSubmitted -> prompt.resolve(value).
    # Escape/Ctrl+C instead emits inputCancelled -> prompt.resolve(null).
    inputSubmitted.connect(submitCallable, CONNECT_ONE_SHOT)
    inputCancelled.connect(cancelCallable, CONNECT_ONE_SHOT)
    promptChanged.emit(promptText, secret)
    inputEnabledChanged.emit(true)
    # Suspend this command while Godot continues processing UI events.
    var value: Variant = await prompt.resolved
    # CONNECT_ONE_SHOT removes only the listener that fired; disconnect
    # the unused counterpart before the next prompt is created.
    if inputSubmitted.is_connected(submitCallable): inputSubmitted.disconnect(submitCallable)
    if inputCancelled.is_connected(cancelCallable): inputCancelled.disconnect(cancelCallable)
    activePrompt = null
    # Always reset prompt text and secret-entry mode, even on cancellation.
    promptChanged.emit("", false)
    inputEnabledChanged.emit(false)
    if value == null:
      printOutput("^C")
      return null
      
    if validator.is_valid():
      var errorMessage: String = str(validator.call(value))
      if not errorMessage.is_empty():
        printOutput(errorMessage, Globals.colors["CONSOLE"]["FONT_FAILURE"])
        continue
        
    return value
    
  return null

# Called by the UI; resolving null unwinds the waiting command.
func cancelInput() -> void:
  if activePrompt != null: inputCancelled.emit()

# Completion does not execute anything; return the edited line and match list.
func completeLine(line: String) -> Dictionary:
  if activePrompt != null or isCommandRunning: return {"line": line, "matches": []}
  
  var parsed: Dictionary = CommandParser.tokenize(line, true)
  var tokens: Array[Dictionary] = parsed["tokens"]
  var atNewWord: bool = line.is_empty() or line.ends_with(" ") or line.ends_with("\t")
  
  if tokens.is_empty() or (tokens.size() == 1 and not atNewWord):
    var prefix: String = "" if tokens.is_empty() else str(tokens[0]["value"])
    var names: Array[String] = []
    for key in commands.keys():
      if key.begins_with(prefix.to_lower()): names.append(key)
    names.sort()
    
    return _makeCompletion(line, 0, line.length(), names, prefix)
    
  var commandName: String = str(tokens[0]["value"]).to_lower()
  if not commands.has(commandName): return {"line": line, "matches": []}
  var command: ConsoleCommand = commands[commandName]
  var index: int = tokens.size() if atNewWord else tokens.size() - 1
  var prefix: String = "" if atNewWord else str(tokens[index]["value"])
  var start: int = line.length() if atNewWord else int(tokens[index]["start"])
  var end: int = line.length()
  var previous: Array[Dictionary] = tokens.slice(1, index)
  
  # Ignore completed options when identifying the next positional argument.
  var positionalCount: int = 0
  for token in previous:
    if not str(token["value"]).begins_with("-"): positionalCount += 1
    
  var matches: Array[String] = []
  if prefix.begins_with("-"):
    for option in command.options:
      var suggestion: String = "-" + str(option["short"])
      if option["kind"] != TYPE_BOOL: suggestion += "="
      if suggestion.begins_with(prefix): matches.append(suggestion)
    if "-h".begins_with(prefix): matches.append("-h")
    
    for option in command.options:
      var valuePrefix: String = "-" + str(option["short"]) + "="
      if prefix.begins_with(valuePrefix):
        matches.clear()
        for choice in option.get("choices", []):
          var suggestion: String = valuePrefix + str(choice)
          if suggestion.begins_with(prefix): matches.append(suggestion)
          
        break
        
  elif positionalCount < command.arguments.size():
    var spec: Dictionary = command.arguments[positionalCount]
    var choices: Array = spec.get("choices", [])
    for choice in choices:
      if str(choice).begins_with(prefix): matches.append(str(choice))
    for suggestion in command.completeArgument(str(spec["name"]), prefix):
      if suggestion.begins_with(prefix) and not matches.has(suggestion): matches.append(suggestion)
  matches.sort()
  
  return _makeCompletion(line, start, end, matches, prefix)

func _makeCompletion(line: String, start: int, end: int, matches: Array[String], prefix: String) -> Dictionary:
  if matches.is_empty(): return {"line": line, "matches": matches}
  
  # With multiple matches, complete only the longest common prefix.
  var candidate: String = matches[0]
  for matchValue in matches:
    while not str(matchValue).begins_with(candidate) and not candidate.is_empty():
      candidate = candidate.substr(0, candidate.length() - 1)
      
  if matches.size() == 1 and candidate.contains(" ") and not candidate.begins_with("-"): candidate = "\"" + candidate + "\""
  if candidate == prefix and matches.size() > 1: return {"line": line, "matches": matches}
  
  return {"line": line.substr(0, start) + candidate + line.substr(end), "matches": matches}

func printOutputWithSfx(message: String, color: Color = Globals.colors["CONSOLE"]["FONT_DEFAULT"], chance: int = 25, type: String = "glitch") -> void:
  if randf() < clampf(float(chance) / 100.0, 0.0, 1.0) and Globals.audioManager != null: Globals.audioManager.playRandom(type)
  outputPrinted.emit(message, color)

# Only emit here; console.gd handles RichTextLabel formatting.
func printOutput(message: String, color: Color = Globals.colors["CONSOLE"]["FONT_DEFAULT"]) -> void:
  outputPrinted.emit(message, color)

func printChat(message: String, color: Color = Globals.colors["CONSOLE"]["FONT_DEFAULT"]) -> void:
  chatPrinted.emit(message, color)

func clearOutput() -> void:
  outputCleared.emit()

class_name CommandParser
extends RefCounted

# Tokens preserve the span in the original input for safe completion replacement.
# Quotes group words; escape syntax and long options are intentionally unsupported.
# Include token positions so autocomplete can replace active input
static func tokenize(line: String, allowIncomplete: bool = false) -> Dictionary:
  var tokens: Array[Dictionary] = []
  var value: String = ""
  var quote: String = ""
  var started: bool = false
  var start: int = 0
  
  # go one character at a time and build tokens array
  for i in range(line.length()):
    var c: String = line.substr(i, 1)
    # already in a quote
    if quote != "":
      if c == quote:
        quote = ""
      else:
        value += c
      continue
    # starting a quote
    if c == "'" or c == "\"":
      if not started:
        start = i
        started = true
      quote = c
    # space and tab
    elif c == " " or c == "\t":
      if started:
        tokens.append({"value": value, "start": start, "end": i})
        value = ""
        started = false
    else:
      if not started:
        start = i
        started = true
      value += c
      
  # Incomplete quotes are okay while completing, but not while executing.
  if not quote.is_empty() and not allowIncomplete: return {"error": "Unterminated quoted argument.", "tokens": tokens}
  if started: tokens.append({"value": value, "start": start, "end": line.length()})
  return {"error": "", "tokens": tokens}

# Convert one argument and check its choices/range
static func convertValue(value: String, spec: Dictionary) -> Dictionary:
  var kind: int = int(spec.get("kind", TYPE_STRING))
  var converted: Variant = value
  match kind:
    TYPE_INT:
      if not value.is_valid_int():return {"error": "%s must be an integer." % spec["name"]}
      converted = int(value)
      
    TYPE_FLOAT:
      if not value.is_valid_float(): return {"error": "%s must be a number." % spec["name"]}
      converted = float(value)
      
    TYPE_STRING:
      converted = value
      
    _:
      return {"error": "Unsupported argument type for %s." % spec["name"]}
      
  var choices: Array = spec.get("choices", [])
  if not choices.is_empty() and not choices.has(converted): return {"error": "%s must be one of: %s." % [spec["name"], ", ".join(PackedStringArray(choices))]}
  if spec.get("min") != null and converted < spec["min"]: return {"error": "%s must be at least %s." % [spec["name"], spec["min"]]}
  if spec.get("max") != null and converted > spec["max"]: return {"error": "%s must be at most %s." % [spec["name"], spec["max"]]}
  
  return {"error": "", "value": converted}

static func parse(command: ConsoleCommand, rawTokens: Array[Dictionary]) -> Dictionary:
  var input: CommandInput = CommandInput.new()
  var positional: Array[String] = []
  var byShort: Dictionary = {}
  
  # Map short option letters to specs and initialize their default values.
  for option in command.options:
    var shortName: String = str(option.get("short", ""))
    if shortName.length() != 1 or shortName == "h" or byShort.has(shortName): return {"error": "Invalid option specification: -%s." % shortName}
    byShort[shortName] = option
    input.flags[option["name"]] = option.get("default", false) if option["kind"] == TYPE_BOOL else option.get("default")
    
  var positionalIndex: int = 0
  for token in rawTokens:
    var word: String = token["value"]
    
    # -h is reserved for generated command help.
    if word == "-h": return {"error": "", "help": true}
    if word.begins_with("--"): return {"error": "Long options are not supported: %s." % word}
    
    # Options are -a, combined booleans (-al), or assignments (-s=type).
    if word.begins_with("-") and word.length() > 1 and not _isNegativeNumber(word, command.arguments, positionalIndex):
      var assignment: int = word.find("=")
      if assignment >= 0:
        var shortName: String = word.substr(1, assignment - 1)
        if shortName.length() != 1 or not byShort.has(shortName): return {"error": "Unknown option: -%s." % shortName}
        var spec: Dictionary = byShort[shortName]
        if spec["kind"] == TYPE_BOOL: return {"error": "Flag -%s does not accept a value." % shortName}
        var converted: Dictionary = convertValue(word.substr(assignment + 1), spec)
        if not converted["error"].is_empty(): return converted
        input.flags[spec["name"]] = converted["value"]
        
      else:
        for i in range(1, word.length()):
          var key: String = word.substr(i, 1)
          if not byShort.has(key): return {"error": "Unknown option: -%s." % key}
          var option: Dictionary = byShort[key]
          if option["kind"] != TYPE_BOOL: return {"error": "Option -%s requires -%s=value." % [key, key]}
          input.flags[option["name"]] = true
          
    else:
      positional.append(word)
      positionalIndex += 1
      
  var index: int = 0
  # Map remaining positionals to argument definitions
  for spec in command.arguments:
    var name: String = str(spec["name"])
    # A rest argument takes remaining tokens.
    if spec.get("rest", false):
      if index >= positional.size() and spec.get("required", true):
        return {"error": "Missing required argument: %s." % name}
        
      var joined: String = " ".join(positional.slice(index))
      var result: Dictionary = convertValue(joined, spec)
      
      if not result["error"].is_empty(): return result
      
      input.values[name] = result["value"]
      index = positional.size()
      break
      
    if index >= positional.size():
      if spec.get("required", true): return {"error": "Missing required argument: %s." % name}
      input.values[name] = spec.get("default")
      continue
      
    var result: Dictionary = convertValue(positional[index], spec)
    if not result["error"].is_empty(): return result
    input.values[name] = result["value"]
    index += 1
    
  if index < positional.size(): return {"error": "Too many arguments."}
  return {"error": "", "input": input}

# Negative numeric positionals should not be interpreted as flags.
static func _isNegativeNumber(word: String, arguments: Array[Dictionary], position: int) -> bool:
  if position >= arguments.size(): return false
  var spec: Dictionary = arguments[position]
  return spec["kind"] in [TYPE_INT, TYPE_FLOAT] and word.is_valid_float()

class_name CommandSpec
extends RefCounted

# Specifications drive parsing, generated usage/help, and completion.
static func argument(name: String, kind: int = TYPE_STRING, required: bool = true, defaultValue: Variant = null, description: String = "", choices: Array = [], minimum: Variant = null, maximum: Variant = null, rest: bool = false) -> Dictionary:
  return {"name": name, "kind": kind, "required": required, "default": defaultValue, "description": description, "choices": choices, "min": minimum, "max": maximum, "rest": rest}

static func flag(name: String, shortName: String, description: String = "") -> Dictionary:
  return {"name": name, "short": shortName, "description": description, "kind": TYPE_BOOL, "default": false}

static func option(name: String, shortName: String, kind: int = TYPE_STRING, defaultValue: Variant = null, description: String = "", choices: Array = [], minimum: Variant = null, maximum: Variant = null) -> Dictionary:
  return {"name": name, "short": shortName, "description": description, "kind": kind, "default": defaultValue, "choices": choices, "min": minimum, "max": maximum}

# Generate usage from the arguments so it never drifts from validation.
static func formatUsage(commandName: String, arguments: Array[Dictionary], options: Array[Dictionary]) -> String:
  var usage: String = commandName
  if not options.is_empty(): usage += " [options]"
  
  for arg in arguments:
    var label: String = str(arg["name"])
    if arg.get("rest", false): label += "..."
    usage += (" <%s>" if arg.get("required", true) else " [%s]") % label
    
  return usage

# Render detailed help from the same definitions used by the parser.
static func formatHelp(command: ConsoleCommand) -> String:
  var result: String = "%s - %s\nUsage: %s" % [command.commandName, command.description, command.getUsage()]

  if not command.aliases.is_empty(): result += "\nAliases: " + ", ".join(command.aliases)

  if not command.arguments.is_empty():
    result += "\nArguments:"
    for arg in command.arguments:
      var info: String = str(arg["description"])
      if arg.get("default") != null: info += " (default: %s)" % str(arg["default"])
      result += "\n  %s - %s" % [arg["name"], info]

  if not command.options.is_empty():
    result += "\nOptions:"
    for opt in command.options:
      var symbol: String = "-" + str(opt["short"])
      if opt["kind"] != TYPE_BOOL: symbol += "=value"
      var info: String = str(opt["description"])

      if not opt.get("choices", []).is_empty(): info += " (choices: %s)" % ", ".join(PackedStringArray(opt["choices"]))
      result += "\n  %s - %s" % [symbol, info]

  result += "\n  -h - Show this help."

  if not command.extraHelp.is_empty(): result += "\n\n" + command.extraHelp

  return result

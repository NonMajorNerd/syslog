class_name CommandInput
extends RefCounted

var values: Dictionary = {}
var flags: Dictionary = {}

func getString(name: String) -> String:
  return str(values.get(name, flags.get(name, "")))

func getInt(name: String) -> int:
  return int(values.get(name, flags.get(name, 0)))

func getFloat(name: String) -> float:
  return float(values.get(name, flags.get(name, 0.0)))

func getBool(name: String) -> bool:
  return bool(flags.get(name, false))

func getArray(name: String) -> Array:
  return values.get(name, [])

func hasOption(name: String) -> bool:
  return flags.has(name)

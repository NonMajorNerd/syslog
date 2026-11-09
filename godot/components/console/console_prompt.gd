class_name ConsolePrompt
extends RefCounted

signal resolved(value: Variant)

var isResolved: bool = false

func resolve(value: Variant) -> void:
  # Enter and cancellation may both arrive; resolve only once.
  if isResolved: return
  isResolved = true
  resolved.emit(value)

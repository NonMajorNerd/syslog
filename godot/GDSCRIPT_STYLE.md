# GDScript style

This project's first-party GDScript follows Godot's conventions with these
intentional exceptions:

- Use **two spaces** for indentation (never tabs).
- Use **camelCase** for custom functions, variables, parameters and signals.
- Use **PascalCase** for `class_name` declarations.
- Use **UPPER_SNAKE_CASE** for constants.
- Put a single-statement `if` body on the same line when the combined line
  is shorter than 320 characters and GDScript syntax permits it.
- Keep native Godot identifiers such as `_ready()`, `_input()`,
  `_initialize()`, and external plugin methods unchanged.
- Keep file paths, serialized dictionary keys, resource names and scene node
  paths unchanged unless a separate migration is intended.
- Name manually connected signal handlers in camelCase (for example
  `onNotesFocusExited()`). If a handler is referenced by a `.tscn` file,
  update the scene connection in the same commit.

The external Nakama addon is vendored code and is not reformatted here.

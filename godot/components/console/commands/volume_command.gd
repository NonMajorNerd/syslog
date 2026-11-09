class_name VolumeCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "volume"
  aliases = ["vol"]
  category = "General"
  description = "Set music volume between 0 and 100."
  arguments = [CommandSpec.argument("level", TYPE_INT, true, null, "Volume percentage.", [], 0, 100)]

func execute(input: CommandInput) -> void:
  Globals.audioManager.audioPlayer.volume_linear = float(input.getInt("level")) / 100.0
  Globals.consoleManager.printOutput("Volume set to %d%%." % input.getInt("level"), Globals.colors["CONSOLE"]["FONT_SUCCESS"])

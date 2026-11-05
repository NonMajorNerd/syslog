class_name volumeCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "volume"
	aliases = ["vol"]
	category = "General"
	description = "Set the volume of the music and sound effects."
	usage = "volume [0-100]"
	isHidden = false # used to hide internal commands from standard help

#func execute(_context: ConsoleContext, _args: Array[String]) -> void:
func execute(_args: Array[String]) -> void:
	if _args.size() != 1: return
	Globals.audioManager.audioPlayer.volume_linear = clampf(float(_args[0]),0,100)/100

class_name AudioManager
extends Node

@onready var audioPlayer:AudioStreamPlayer = $AudioStreamPlayer

func playSfx(stream: AudioStream, volLinear: float = 0.8) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_linear = volLinear # clampf(float(val,0,100)/100
	player.bus = "SFX"
	player.finished.connect(player.queue_free)
	player.play()
	
func playRandomGlitch() -> void:
	playSfx(load("res://_assets/sfx/glitches/%s.wav" % randi_range(1,11)), audioPlayer.volume_linear)

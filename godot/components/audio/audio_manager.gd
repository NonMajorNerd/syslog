class_name AudioManager
extends Node

@onready var audioPlayer: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
  var tween = create_tween()
  tween.tween_property(audioPlayer, "volume_linear", 0.6, 6.0)
  boot()

func boot() -> void:
  await get_tree().create_timer(0.8).timeout
  playSfx(load("res://_assets/sfx/chimes/open.wav"), 0.6)

func playSfx(stream: AudioStream, volLinear: float = 0.6) -> void:
  var player := AudioStreamPlayer.new()
  add_child(player)
  player.stream = stream
  player.volume_linear = volLinear # clampf(float(val,0,100)/100
  player.bus = "SFX"
  # Release each one-shot sound player after playback completes.
  player.finished.connect(player.queue_free)
  player.play()

func playRandom(type: String = "glitch") -> void:
  match type:
    "confirm": playSfx(load("res://_assets/sfx/confirm/%s.wav" % randi_range(1,3)), audioPlayer.volume_linear)
    "decline": playSfx(load("res://_assets/sfx/decline/%s.wav" % randi_range(1,3)), audioPlayer.volume_linear)
    "search": playSfx(load("res://_assets/sfx/search/%s.wav" % randi_range(1,3)), audioPlayer.volume_linear)
    _: playSfx(load("res://_assets/sfx/glitch/%s.wav" % randi_range(1,13)), audioPlayer.volume_linear)

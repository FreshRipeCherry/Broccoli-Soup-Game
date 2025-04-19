extends AudioStreamPlayer
@onready var audio_stream_player = $"."

func _ready():
	pass

func _process(delta):
	if audio_stream_player.playing == false:
		audio_stream_player.play()

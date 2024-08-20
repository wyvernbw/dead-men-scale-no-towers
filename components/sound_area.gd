class_name SoundArea2D
extends Area2D

@onready var streams = (
	get_children()
		.filter(func(el): return el is AudioStreamPlayer)
)

func _ready() -> void:
	Tracer.info("%s: %s" % [name, str(streams)])
	body_entered.connect(
		func(body): 
			if not body is Jon:
				return
			for_each_stream(func(stream: AudioStreamPlayer): stream.playing = true)
	)
	body_exited.connect(
		func(body): 
			if not body is Jon:
				return
			for_each_stream(func(stream: AudioStreamPlayer): stream.playing = false)
	)

func for_each_stream(cb: Callable) -> void:
	for stream: AudioStreamPlayer in streams:
		cb.call(stream)

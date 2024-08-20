extends CanvasLayer

signal faded_in
signal faded_out

@export var transition_anim: AnimationPlayer

func fade_in() -> void:
	transition_anim.play("transition_fade_in")
	await transition_anim.animation_finished
	faded_in.emit()

func fade_out() -> void:
	transition_anim.play("transition_fade_out")
	await transition_anim.animation_finished
	faded_out.emit()

func fade_in_out() -> void:
	await fade_in()
	await fade_out()

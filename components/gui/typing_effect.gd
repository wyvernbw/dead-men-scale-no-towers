class_name TypingEffect
extends Node

signal typing_finished

const TYPING_SPEED := 24.0

@onready var target := get_parent() as Label

var typing_tween: Tween

func type(text: String) -> void:
	target.text = text
	target.visible_characters = 0
	typing_tween = create_tween()
	(typing_tween
		.tween_property(
			target, 
			"visible_characters", 
			text.length(), 
			float(text.length()) / TYPING_SPEED
		)
		.finished
		.connect(func(): typing_finished.emit()))
	await typing_finished

func skip() -> void:
	typing_finished.emit()
	typing_tween.kill()
	target.visible_characters = target.text.length()

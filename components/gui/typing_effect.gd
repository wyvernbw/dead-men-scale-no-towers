class_name TypingEffect
extends Node

const TYPING_SPEED := 24.0

@onready var target := get_parent() as Label

func type(text: String) -> void:
	target.text = text
	target.visible_characters = 0
	create_tween().tween_property(target, "visible_characters", text.length(), float(text.length()) / TYPING_SPEED)

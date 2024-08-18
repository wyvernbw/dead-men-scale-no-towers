class_name Screen
extends Node2D

@export var initial_screen := false

@export var next_screen: Screen
@export var previous_screen: Screen

func _ready() -> void:
	for el in get_children():
		if el is NextScreenGate:
			el.next_screen_id = next_screen.name
		elif el is PreviousScreenGate:
			el.next_screen_id = previous_screen.name

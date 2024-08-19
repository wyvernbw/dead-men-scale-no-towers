class_name Screen
extends Node2D

@export var initial_screen := false
@export var bgm_track := ""

@export var next_screen: Screen
@export var previous_screen: Screen

@onready var initial_position: ScreenInitialPosition = (
	Maybe.new(
		get_children()
		.filter(func(el): return el is ScreenInitialPosition)
		.front()
	).unwrap()
)

func _ready() -> void:
	for el in get_children():
		if el is ScreenGate and next_screen:
			el.next_screen = next_screen
		if el is NextScreenGate and next_screen:
			el.next_screen_id = next_screen.name
		elif el is PreviousScreenGate and previous_screen:
			el.next_screen_id = previous_screen.name

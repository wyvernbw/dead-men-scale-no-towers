class_name Screen
extends Node2D

@export var initial_screen := false

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
	for jon: Jon in (get_tree()
		.get_nodes_in_group("jon")
		.map(func(el): return el as Jon)
		.filter(func(el): return el)
	):
		jon.died.connect(on_jon_died)

func on_jon_died(jon: Jon) -> void:
	# TODO: death animation
	jon.global_position = initial_position.global_position

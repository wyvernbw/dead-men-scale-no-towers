class_name ScreenManager
extends Node

@onready var target: Node = get_parent()
@onready var current_screen: Screen = (
	Maybe.new(
		target
			.get_children()
			.filter(func(el): return el is Screen)
			.filter(func(el: Screen): return el.initial_screen)
			.front()
	).expect("No initial level in scene!")
)

func _ready() -> void:
	for jon: Jon in (get_tree()
		.get_nodes_in_group("jon")
		.map(func(el): return el as Jon)
		.filter(func(el): return el)
	):
		jon.died.connect(on_jon_died)

func on_jon_died(jon: Jon) -> void:
	# TODO: death animation
	jon.global_position = current_screen.initial_position.global_position

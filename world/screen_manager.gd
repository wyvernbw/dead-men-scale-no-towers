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
): set = set_current_screen

func _ready() -> void:
	add_to_group("screen_managers")
	for jon: Jon in (get_tree()
		.get_nodes_in_group("jon")
		.map(func(el): return el as Jon)
		.filter(func(el): return el)
	):
		jon.died.connect(on_jon_died)
	set_current_screen(current_screen)

func on_jon_died(jon: Jon) -> void:
	# TODO: death animation
	jon.global_position = current_screen.initial_position.global_position

func set_current_screen(value: Screen) -> void:
	current_screen = value
	Bgm.play_track(current_screen.bgm_track)

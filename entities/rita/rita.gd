class_name Rita
extends CharacterBody2D

@export var interaction_area: Area2D
@export var actor_component: ActorComponent

func _ready() -> void:
	interaction_area.body_entered.connect(
		func(_body):
			ink_player().create_story()
			actor_component.start_dialogue(ink_player())
	)

func ink_player() -> InkPlayer:
	return get_node(Events.current_rita_dialogue)


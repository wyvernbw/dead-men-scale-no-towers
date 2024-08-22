class_name Rita
extends CharacterBody2D

@export var interaction_area: Area2D
@export var actor_component: ActorComponent

var interrupted_dialogue := ""

func _ready() -> void:
	for player: InkPlayer in get_children().filter(func(el): return el is InkPlayer):
		Tracer.info("Found story beat: %s" % player.name)
		player.create_story()
	interaction_area.body_entered.connect(
		func(body: Jon):
			if not body:
				return
			if Events.progress["Screen9"]:
				Events.rita_dialogue_exhausted = false
				Events.current_rita_dialogue = "Final"
			if Events.rita_dialogue_exhausted:
				return
			Tracer.info(Events.current_rita_dialogue)
			actor_component.start_dialogue(ink_player())
	)
	interaction_area.body_exited.connect(
		func(body: Jon):
			if not body:
				return
			UILayer.cancel_dialogue()
			if Events.current_rita_dialogue != "Interrupted":
				interrupted_dialogue = Events.current_rita_dialogue
				Events.current_rita_dialogue = "Interrupted"
	)
	actor_component.dialogue_ended.connect(
		func(player):
			if player == get_node("FirstEncounter"):
				Events.rita_dialogue_exhausted = true
			if player == get_node("Interrupted"):
				Events.current_rita_dialogue = interrupted_dialogue
				actor_component.start_dialogue(ink_player())
	)

func ink_player() -> InkPlayer:
	return get_node(Events.current_rita_dialogue)


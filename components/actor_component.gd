class_name ActorComponent
extends Node

signal dialogue_ended(player)


func start_dialogue(ink_player: InkPlayer) -> void:
	while ink_player.can_continue:
		var text = ink_player.continue_story()
		Tracer.debug(text)
		await UILayer.spawn_dialogue_box(text).continued
	if ink_player.has_choices:
		Tracer.debug(str(ink_player.current_choices))
		ink_player.choose_choice_index(0)
		start_dialogue(ink_player)
	else:
		Tracer.debug("Dialogue ended.")
		dialogue_ended.emit(ink_player)

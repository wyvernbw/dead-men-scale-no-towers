extends CanvasLayer

signal continue_input

const DIALOGUE_BOX = preload("res://components/gui/dialogue_box.tscn")
const CHOICE_BOX = preload("res://components/gui/choice_box.tscn")

var current_dialogue_box = Maybe.None()

func spawn_dialogue_box(text: String) -> DialogueBox:
	var box: DialogueBox = DIALOGUE_BOX.instantiate()
	add_child(box)
	box.type(text)
	current_dialogue_box = Maybe.Some(box)
	box.continued.connect(func(): current_dialogue_box = Maybe.None())
	return box

func cancel_dialogue() -> void:
	match current_dialogue_box.expr():
		{ "Some": var box }:
			box.queue_free()
	current_dialogue_box = Maybe.None()

func spawn_choice_box(choices: Array) -> ChoiceBox:
	var box = CHOICE_BOX.instantiate()
	box.show_choices(choices)
	add_child(box)	
	return box

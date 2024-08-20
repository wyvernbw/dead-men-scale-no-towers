class_name ChoiceBox
extends PanelContainer

signal chosen(idx: int)

const CHOICE_BUTTON = preload("res://components/gui/choice_button.tscn")

@export var choices_container: VBoxContainer

func show_choices(choices: Array) -> void:
	for el in choices_container.get_children():
		choices_container.remove_child(el)
	for choice in choices:
		var button = CHOICE_BUTTON.instantiate()
		button.text = choice.text
		button.pressed.connect(
			func(): 
				chosen.emit(choice.index)
				queue_free()
		)
		choices_container.add_child(button)
		button.call_deferred("grab_focus")

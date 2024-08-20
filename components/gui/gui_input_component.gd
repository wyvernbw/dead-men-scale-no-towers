class_name GuiInputComponent
extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_dialogue_enter"):
		UILayer.continue_input.emit()
	

extends PanelContainer

signal continued

@export var typing_effect: TypingEffect

func type(text: String) -> void:
	typing_effect.type(text)

func _input(event: InputEvent) -> void:
	continued.emit()

extends CharacterBody2D

@export var dynamics: Dynamics

func _ready() -> void:
	dynamics.init()

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		dynamics.x += Vector2.RIGHT * 8.0
	dynamics.x += Vector2.DOWN * 2.0
	dynamics.update(delta)

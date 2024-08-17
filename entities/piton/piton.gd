extends CharacterBody2D

@export var max_speed: float = 256.0
@export var accel: float = 512.0

func _physics_process(delta: float) -> void:
	var dir = Vector2.DOWN.rotated(rotation)
	velocity = velocity.move_toward(
		dir * max_speed,
		delta * accel
	)
	move_and_slide()

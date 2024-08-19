class_name DebugFly
extends Node

func _physics_process(delta: float) -> void:
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_pressed("debug_fly"):
		owner.global_position += delta * 256.0 * dir
		if owner.get("movable"):
			owner.movable.use_gravity = false			

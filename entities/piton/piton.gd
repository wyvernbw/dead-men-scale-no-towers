class_name Piton
extends CharacterBody2D

signal hit

const ROPE_LENGTH := 64

@export var max_speed: float = 256.0
@export var accel: float = 512.0
@export var hit_sound: AudioStreamPlayer2D

var initial_position: Vector2
var moving = true

func _ready() -> void:
	initial_position = self.global_position

func _physics_process(delta: float) -> void:
	if not moving:
		return
	var dir = Vector2.DOWN.rotated(rotation)
	velocity = velocity.move_toward(
		dir * max_speed,
		delta * accel
	)
	if initial_position.distance_to(self.global_position) > ROPE_LENGTH + 32:
		queue_free()
		return
	if is_on_floor() or is_on_ceiling() or is_on_wall():
		hit.emit()
		hit_sound.play()
		moving = false
	move_and_slide()

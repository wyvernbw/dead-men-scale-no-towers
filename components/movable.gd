class_name Movable
extends Node

const GRAVITY := 900.0
const MAX_FALL := 160.0

@export var use_gravity: bool = true
@export var gravity: float = GRAVITY

func _ready() -> void:
	assert(owner is CharacterBody2D)

func _physics_process(delta: float) -> void:
	if not owner.is_on_floor():
		owner.velocity = owner.velocity.move_toward(
			Vector2.DOWN * MAX_FALL, 
			GRAVITY * delta
		)
	owner.move_and_slide()

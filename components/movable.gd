class_name Movable
extends Node

const GRAVITY := 900.0
const MAX_FALL := 320.0

@export var use_gravity: bool = true
@export var gravity: float = GRAVITY
@export var gravity_multiplier: float = 1.0

func _ready() -> void:
	assert(owner is CharacterBody2D)

func update(delta: float) -> void:
	if use_gravity:
		if not owner.is_on_floor():
			owner.velocity.y = min(owner.velocity.y + GRAVITY * delta, MAX_FALL * gravity_multiplier)
	owner.velocity = round(owner.velocity)
	owner.move_and_slide()

class_name Movable
extends Node

const GRAVITY := 900.0
const MAX_FALL := 320.0

@export var use_gravity: bool = true
@export var gravity: float = GRAVITY

func _ready() -> void:
	assert(owner is CharacterBody2D)

func _physics_process(delta: float) -> void:
	if not owner.is_on_floor():
		owner.velocity.y = min(owner.velocity.y + GRAVITY * delta, MAX_FALL)
	owner.move_and_slide()

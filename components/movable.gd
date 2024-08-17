extends Node

const GRAVITY := 900.0
const GRAVITY_ACCEL := 160.0

@export var use_gravity: bool = true
@export var gravity: float = GRAVITY
@export var gravity_accel: float = GRAVITY_ACCEL

func _ready() -> void:
	assert(owner is CharacterBody2D)

func _physics_process(delta: float) -> void:
	owner.velocity = owner.velocity.move_toward(
		Vector2.DOWN * gravity, 
		gravity_accel * delta
	)
	owner.move_and_slide()

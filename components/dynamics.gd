class_name Dynamics
extends Node

@export_range(0.0, 5.0, 0.1) var frequency: float
@export_range(0.0, 5.0, 0.1) var damping: float
@export_range(0.0, 5.0, 0.1) var initial_response: float

var k1: Vector2
var k2: Vector2
var k3: Vector2

var xp: Vector2
var y: Vector2
var yd: Vector2 = Vector2.ZERO
var x: Vector2

var initialized := false

func init() -> void:
	assert(owner is CharacterBody2D, "Owner must be of type CharacterBody2d")
	initialized = true
	x = owner.position
	var f = Vector2(frequency, frequency)
	var d = Vector2(damping, damping)
	var ir = Vector2(initial_response, initial_response)
	k1 = d / (PI * f)
	var d1 = pow(2 * PI * frequency, 2.0)
	k2 = Vector2.ONE / Vector2(d1, d1)
	k3 = (ir * d) / (2 * PI * f)

func update(delta: float) -> void:
	if not initialized:
		return
	xp = owner.position
	owner.move_and_slide() # integrate position by velocity
	var xd = (owner.position - xp) / delta
	owner.velocity += delta * (x + k3 * xd - owner.position - k1 * owner.velocity) / k2
	print(owner.position)

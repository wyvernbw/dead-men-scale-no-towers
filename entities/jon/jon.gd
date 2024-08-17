class_name Jon
extends CharacterBody2D

class MoveState:
	extends Wisp.State

class Idle:
	extends MoveState

class JumpState:
	extends Wisp.State

class NoJump: 
	extends JumpState

	func name() -> String:
		return "JumpState::NoJump"

	func enter(jon: Jon) -> JumpState:
		match await Async.select([jon.jump_input]):
			{ 0: _ }:
				return Jump.new()
		return await self.enter(jon)

class Jump:
	extends JumpState

	var elapsed = 0.0

	func name() -> String:
		return "JumpState::Jump"

	func enter(jon: Jon) -> JumpState:
		Tracer.info("jumped!")
		elapsed = 0.0
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		# counter act gravity
		jon.velocity = Vector2.UP * jon.jump_speed
		if elapsed > jon.min_jump_time and not Input.is_action_pressed("jump"):
			return Fall.new()
		if elapsed > jon.max_jump_time:
			return Fall.new()
		return self

class Fall:
	extends JumpState

	func name() -> String:
		return "JumpState::Fall"

	func physics_process(jon: Jon, delta: float) -> JumpState:
		if jon.is_on_floor():
			return NoJump.new()
		return self
		

@onready var move_state := await Wisp.use_state_machine(self, Idle.new())
@onready var jump_state := await Wisp.use_state_machine(self, NoJump.new())

@export var movable: Movable
@export var jump_height: float = 96.0
@export var jump_speed: float = 96.0
@export var max_jump_time: float = 1.0
@export var min_jump_time: float = 0.125

signal jump_input

var inputs = [
	jump_input,
]

signal jump_released

var releases = [
	jump_released
]

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	move_state.input(event)
	jump_state.input(event)
	InputUtils.actions_pressed(inputs, event)
	InputUtils.actions_released(releases, event)

func _process(delta: float) -> void:
	move_state.process(delta)
	jump_state.process(delta)
	Tracer.info(jump_state.current_state.name())

func _physics_process(delta: float) -> void:
	move_state.physics_process(delta)
	jump_state.physics_process(delta)

class_name Jon
extends CharacterBody2D

class MoveState:
	extends Wisp.State

	func get_x_move_dir() -> float:
		return Input.get_axis("move_left", "move_right")

class Idle:
	extends MoveState

	var elapsed = 0.0

	func name() -> String:
		return "MoveState::Idle"

	func enter(jon: Jon) -> MoveState:
		elapsed = 0.0
		jon.anim_state.travel("idle")
		return self

	func physics_process(jon: Jon, delta: float) -> MoveState:
		jon.velocity = jon.velocity.move_toward(
			Vector2(0.0, jon.velocity.y),
			jon.deacceleration * delta
		)
		elapsed += delta
		jon.sprites_node.skew = lerp(0.0, sign(jon.velocity.x) * deg_to_rad(20.0), abs(jon.velocity.x) / jon.move_speed)
		if not is_zero_approx(get_x_move_dir()):
			return Moving.new()
		return self

class Moving:
	extends MoveState

	var elapsed = 0.0

	func name() -> String:
		return "MoveState::Moving"

	func enter(jon: Jon) -> MoveState:
		elapsed = 0.0
		return self

	func physics_process(jon: Jon, delta: float) -> MoveState:
		if jon.is_on_floor():
			jon.anim_state.travel("run")
		var dir = get_x_move_dir()
		var accel = jon.acceleration if sign(jon.velocity.x) == sign(dir) else jon.acceleration * 2.0
		jon.velocity.x += dir * delta * accel
		# bhop
		var ms = jon.move_speed if jon.is_on_floor() else jon.move_speed * 1.25
		jon.velocity.x = sign(jon.velocity.x) * min(abs(jon.velocity.x), ms)
		jon.sprites_node.skew = lerp(0.0, sign(jon.velocity.x) * deg_to_rad(20.0), abs(jon.velocity.x) / ms)
		if is_zero_approx(dir):
			return Idle.new()
		return self

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
		jon.squish_anim.play("hsquish")
		await jon.get_tree().create_timer(jon.min_jump_time * 2.0, false).timeout
		jon.squish_anim.play("hunsquish")
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		jon.anim_state.travel("jump")
		# counter act gravity
		jon.velocity.y = -jon.jump_speed
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
		jon.anim_state.travel("fall")
		if jon.velocity.y == Movable.MAX_FALL:
			jon.squish_anim.play("hsquish")
		if jon.is_on_floor():
			jon.anim_state.travel("land")
			return NoJump.new()
		return self
		

@onready var anim_tree = get_node("AnimationTree")
@onready var anim_state = anim_tree.get("parameters/playback")

@onready var move_state := await Wisp.use_state_machine(self, Idle.new())
@onready var jump_state := await Wisp.use_state_machine(self, NoJump.new())

@export var movable: Movable
@export var anim_player: AnimationPlayer
@export var squish_anim: AnimationPlayer
@export var sprites_node: Node2D

@export var jump_height: float = 96.0
@export var jump_speed: float = 96.0
@export var max_jump_time: float = 1.0
@export var min_jump_time: float = 0.125

@export var acceleration: float
@export var deacceleration: float
@export var move_speed = 64.0

signal jump_input

var inputs = [
	jump_input,
]

signal jump_released

var releases = [
	jump_released
]

var look_direction: float = 1.0

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	move_state.input(event)
	jump_state.input(event)
	InputUtils.actions_pressed(inputs, event)
	InputUtils.actions_released(releases, event)
	Tracer.info(move_state.current_state.name())

func _process(delta: float) -> void:
	move_state.process(delta)
	jump_state.process(delta)

func _physics_process(delta: float) -> void:
	move_state.physics_process(delta)
	jump_state.physics_process(delta)
	if not is_zero_approx(velocity.x):
		look_direction = sign(velocity.x)
	look(look_direction)

func look(x: float) -> void:
	var flip = x < 0.0
	for sprite in get_tree().get_nodes_in_group("jon_sprite") as Array[Sprite2D]:
		sprite.flip_h = flip

func look_at_velocity() -> void:
	look(velocity.x)


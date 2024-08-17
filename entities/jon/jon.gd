class_name Jon
extends CharacterBody2D

const PITON = preload("res://entities/piton/piton.tscn")

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
		if jon.current_piton.is_some() and not jon.is_grounded():
			return Rappel.new()
		jon.constrain_position_on_piton()
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
		if jon.current_piton.is_some() and not jon.is_grounded():
			return Rappel.new()
		if jon.is_grounded():
			jon.anim_state.travel("run")
		if not jon.is_grounded() and jon.on_wall():
			return WallSlide.new()
		var dir = get_x_move_dir()
		jon.constrain_position_on_piton()
		var accel = jon.acceleration if sign(jon.velocity.x) == sign(dir) else jon.acceleration * 2.0
		jon.velocity.x += dir * delta * accel
		# bhop
		var ms = jon.move_speed if jon.is_grounded() else jon.move_speed * 1.25
		jon.velocity.x = sign(jon.velocity.x) * min(abs(jon.velocity.x), ms)
		jon.sprites_node.skew = lerp(0.0, sign(jon.velocity.x) * deg_to_rad(20.0), abs(jon.velocity.x) / ms)
		if is_zero_approx(dir):
			return Idle.new()
		return self

class WallSlide:
	extends MoveState

	func enter(jon: Jon) -> MoveState:
		jon.jump_state.transition(JumpStateWallSlide.new())
		return self

	func exit(jon: Jon) -> void:
		jon.movable.gravity_multiplier = 1.0

	func physics_process(jon: Jon, delta: float) -> MoveState:
		jon.movable.gravity_multiplier = 0.20
		var dir = get_x_move_dir()
		var accel = jon.acceleration if sign(jon.velocity.x) == sign(dir) else jon.acceleration * 2.0
		jon.velocity.x += dir * delta * accel
		# bhop
		var ms = jon.move_speed if jon.is_grounded() else jon.move_speed * 1.25
		jon.velocity.x = sign(jon.velocity.x) * min(abs(jon.velocity.x), ms)
		jon.sprites_node.skew = lerp(0.0, sign(jon.velocity.x) * deg_to_rad(20.0), abs(jon.velocity.x) / ms)
		if not jon.on_wall():
			return Moving.new()
		return self

	func input(jon: Jon, event: InputEvent) -> MoveState:
		if event.is_action_pressed("wall_grab"):
			return WallGrab.new()
		return self

class WallGrab:
	extends MoveState

	func enter(jon: Jon) -> WallGrab:
		jon.jump_state.transition(JumpStateWallSlide.new())
		return self

	func exit(jon: Jon) -> void:
		jon.movable.use_gravity = true

	func physics_process(jon: Jon, delta: float) -> MoveState:
		jon.movable.use_gravity = false
		var climb_dir = Input.get_axis("move_up", "move_down")
		jon.velocity.y = jon.move_speed / 4.0 * climb_dir
		if not jon.on_wall():
			return Moving.new()
		return self

	func input(jon: Jon, event: InputEvent) -> MoveState:
		if event.is_action_released("wall_grab"):
			return WallSlide.new()
		return self

class Rappel:
	extends MoveState

	func exit(jon: Jon) -> void:
		jon.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).tween_property(
			jon.sprites_node, "rotation", 0.0, 0.5, 
		)

	func physics_process(jon: Jon, delta: float) -> MoveState:
		if jon.is_grounded():
			return Idle.new()
		match jon.current_piton.expr():
			"None":
				return Moving.new()
			{ "Some": var piton }:
				jon.sprites_node.rotation = (
					jon.global_position.direction_to(
						piton.global_position
					).angle_to(Vector2.RIGHT)
				)
				var dir = get_x_move_dir()
				var accel = jon.acceleration * 0.5
				var piton_to_player = jon.global_position - piton.global_position
				# var target = piton.global_position + piton_to_player.limit_length(Piton.ROPE_LENGTH)
				# var theta = Vector2.DOWN.angle_to(piton_to_player.normalized())
				var motion_dir = piton_to_player.rotated(-PI / 2.0).normalized()
				jon.velocity += motion_dir * accel * dir * delta
		return self

	func input(jon: Jon, event: InputEvent) -> MoveState:
		if event.is_action_pressed("jump"):
			jon.current_piton = Maybe.new()
			jon.jump_state.transition(Jump.new())
		return self

class JumpState:
	extends Wisp.State

class NoJump: 
	extends JumpState

	signal fell_off

	func name() -> String:
		return "JumpState::NoJump"

	func enter(jon: Jon) -> JumpState:
		match await Async.select([jon.jump_input, self.fell_off]):
			{ 0: _ }:
				return Jump.new()
			{ 1: _ }:
				await jon.get_tree().create_timer(0.25, false).timeout
				return Fall.new()
		return await self.enter(jon)

	func process(jon: Jon, _delta: float) -> JumpState:
		if not jon.is_grounded():
			fell_off.emit()
		return self

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
		if jon.is_on_ceiling():
			return Fall.new()
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
		if jon.on_wall():
			return JumpStateWallSlide.new()
		if jon.velocity.y == Movable.MAX_FALL:
			jon.squish_anim.play("hsquish")
		if jon.is_grounded():
			jon.anim_state.travel("land")
			return NoJump.new()
		return self

class JumpStateWallSlide:
	extends JumpState

	signal fell_off

	func name() -> String:
		return "JumpState::JumpStateWallSlide"

	func enter(jon: Jon) -> JumpState:
		match await Async.select([jon.jump_input, self.fell_off]):
			{ 0: _ }:
				return WallJump.new()
			{ 1: _ }:
				await jon.get_tree().create_timer(0.25, false).timeout
				return Fall.new()
		return await self.enter(jon)

	func process(jon: Jon, _delta: float) -> JumpState:
		if not jon.is_grounded() and not jon.on_wall():
			fell_off.emit()
		return self
		
class WallJump:
	extends JumpState

	var elapsed = 0.0
	var axis: float = 0.0

	func name() -> String:
		return "JumpState::WallJump"

	func enter(jon: Jon) -> JumpState:
		Tracer.info("jumped!")
		elapsed = 0.0
		axis = jon.wall_axis()
		jon.squish_anim.play("hsquish")
		await jon.get_tree().create_timer(jon.min_jump_time * 2.0, false).timeout
		jon.squish_anim.play("hunsquish")
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		jon.anim_state.travel("jump")
		# counter act gravity
		jon.velocity = Vector2(-axis, -1.0).normalized() * jon.jump_speed
		if jon.is_on_ceiling():
			return Fall.new()
		if elapsed > jon.min_jump_time and not Input.is_action_pressed("jump"):
			return Fall.new()
		if elapsed > jon.max_jump_time:
			return Fall.new()
		return self

@onready var anim_tree = get_node("AnimationTree")
@onready var anim_state = anim_tree.get("parameters/playback")

@onready var move_state := await Wisp.use_state_machine(self, Idle.new())
@onready var jump_state := await Wisp.use_state_machine(self, NoJump.new())

@export var movable: Movable
@export var anim_player: AnimationPlayer
@export var squish_anim: AnimationPlayer
@export var sprites_node: Node2D
@export var floor_raycast: RayCast2D
@export var wall_raycasts: Node2D

@export var jump_height: float = 96.0
@export var jump_speed: float = 96.0
@export var max_jump_time: float = 1.0
@export var min_jump_time: float = 0.125

@export var acceleration: float
@export var deacceleration: float
@export var move_speed = 64.0

@export var rappel_damping := 0.9

signal jump_input

var inputs = [
	jump_input,
]

signal jump_released

var releases = [
	jump_released
]

var look_direction: float = 1.0
var pitons := 1
var current_piton = Maybe.new()

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	move_state.input(event)
	jump_state.input(event)
	InputUtils.actions_pressed(inputs, event)
	InputUtils.actions_released(releases, event)

	if event.is_action_pressed("piton") and pitons > 0 and current_piton.is_none():
		var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir.x == 0.0 and dir.y == 0.0:
			dir.x = look_direction
		var angle = Vector2.DOWN.angle_to(dir)
		var piton = PITON.instantiate()
		piton.rotation = angle
		piton.global_position = self.global_position
		pitons -= 1
		add_sibling(piton)
		await piton.hit
		current_piton = Maybe.new(piton)
	# Tracer.info(move_state.current_state.name())

func _process(delta: float) -> void:
	move_state.process(delta)
	jump_state.process(delta)

func _physics_process(delta: float) -> void:
	move_state.physics_process(delta)
	jump_state.physics_process(delta)
	movable.update(delta)
	if not is_zero_approx(velocity.x):
		look_direction = sign(velocity.x)
	match current_piton.expr():
		"None":
			movable.use_gravity = true
		{ "Some": var piton }:
			movable.use_gravity = false
			var piton_to_player = self.global_position - piton.global_position
			var theta = Vector2.DOWN.angle_to(piton_to_player.normalized())
			var motion_dir = piton_to_player.rotated(-PI / 2.0).normalized()
			var accel = Movable.GRAVITY * sin(theta)
			velocity += accel * motion_dir * delta
			if piton_to_player.length() > Piton.ROPE_LENGTH:
				velocity = velocity.project(motion_dir)
			velocity *= rappel_damping

	look(look_direction)

func look(x: float) -> void:
	var flip = x < 0.0
	for sprite in get_tree().get_nodes_in_group("jon_sprite") as Array[Sprite2D]:
		sprite.flip_h = flip

func look_at_velocity() -> void:
	look(velocity.x)

func is_grounded() -> bool:
	return floor_raycast.is_colliding()

func wall_axis() -> float:
	var left = wall_raycasts.get_node("Left")	
	var right = wall_raycasts.get_node("Right")	
	var check = func(node: Node): 
		return float(
			node
				.get_children()
				.map(func(el): return el as RayCast2D)
				.filter(func(el): return el)
				.reduce(func(acc, el): return acc or el.is_colliding(), false)
		)
	return check.call(right) - check.call(left)

func on_wall() -> bool:
	return wall_axis() != 0.0

func constrain_position_on_piton() -> void:
	match current_piton.expr():
		{ "Some": var piton }:
			movable.use_gravity = false
			var piton_to_player = self.global_position - piton.global_position
			var target = piton.global_position + piton_to_player.limit_length(Piton.ROPE_LENGTH)
			self.global_position = target

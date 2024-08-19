class_name Jon
extends CharacterBody2D

signal died(jon)

const PITON = preload("res://entities/piton/piton.tscn")
const MAX_STAMINA = 110
const WALL_STAMINA_DRAIN = 10
const CLIMB_JUMP_STAMINA_COST = 25

class MoveState:
	extends Wisp.State

	static func get_x_move_dir() -> float:
		return Input.get_axis("move_left", "move_right")

class Idle:
	extends MoveState

	var elapsed = 0.0

	func name() -> String:
		return "MoveState::Idle"

	func enter(jon: Jon) -> MoveState:
		elapsed = 0.0
		return self

	func physics_process(jon: Jon, delta: float) -> MoveState:
		if jon.is_grounded():
			jon.anim_state.travel("idle")
		if jon.current_piton.is_some() and not jon.is_on_floor():
			return Rappel.new()
		jon.constrain_position_on_piton()
		jon.velocity = jon.velocity.move_toward(
			Vector2(0.0, jon.velocity.y),
			jon.deacceleration * delta
		)
		elapsed += delta
		if jon.wall_axis() != 0.0 and Input.is_action_pressed("wall_grab"):
			return WallGrab.new()
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
		if jon.wall_axis() != 0.0 and Input.is_action_pressed("wall_grab"):
			return WallGrab.new()
		var dir = get_x_move_dir()
		jon.constrain_position_on_piton()
		var accel = jon.acceleration if sign(jon.velocity.x) == sign(dir) else jon.acceleration * 2.0
		jon.velocity.x += dir * delta * accel
		# bhop
		var ms = jon.move_speed if jon.is_grounded() else jon.move_speed * 1.25
		jon.velocity.x = sign(jon.velocity.x) * min(abs(jon.velocity.x), ms)
		if is_zero_approx(dir):
			return Idle.new()
		return self

class WallSlide:
	extends MoveState

	func enter(jon: Jon) -> MoveState:
		jon.jump_state.transition(JumpStateWallSlide.new())
		jon.anim_state.travel("wall_slide")
		jon.wall_dust.emitting = true
		return self

	func exit(jon: Jon) -> void:
		jon.movable.gravity_multiplier = 1.0
		jon.wall_dust.emitting = false

	func physics_process(jon: Jon, delta: float) -> MoveState:
		jon.movable.gravity_multiplier = 0.15
		jon.constrain_position_on_piton()
		var dir = get_x_move_dir()
		if dir == 0.0:
			return Idle.new()
		var accel = jon.acceleration if sign(jon.velocity.x) == sign(dir) else jon.acceleration * 2.0
		jon.velocity.x += dir * delta * accel
		# bhop
		var ms = jon.move_speed if jon.is_grounded() else jon.move_speed * 1.25
		jon.velocity.x = sign(jon.velocity.x) * min(abs(jon.velocity.x), ms)
		if Input.is_action_pressed("wall_grab") and jon.has_stamina():
			return WallGrab.new()
		if not jon.on_wall():
			return Moving.new()
		return self

	func input(jon: Jon, event: InputEvent) -> MoveState:
		return self

class WallGrab:
	extends MoveState

	var elapsed: float
	var climbing_over: bool = false

	func enter(jon: Jon) -> WallGrab:
		jon.jump_state.transition(JumpStateWallGrab.new())
		jon.global_position += Vector2.RIGHT * jon.wall_axis() * jon.get_distance_from_wall()
		jon.anim_state.travel("climb")
		return self

	func exit(jon: Jon) -> void:
		jon.movable.use_gravity = true

	func physics_process(jon: Jon, delta: float) -> MoveState:
		jon.movable.use_gravity = false
		var climb_dir = Input.get_axis("move_up", "move_down")
		jon.constrain_position_on_piton()
		jon.velocity.y = jon.move_speed / 4.0 * climb_dir
		jon.velocity.x = 0.0
		elapsed = jon.drain_stamina(elapsed + delta, Jon.WALL_STAMINA_DRAIN)
		var axis = jon.wall_axis()
		if jon.get_wall_collision_count(axis) == 1:
			# climb over wall
			jon.velocity = Vector2.UP * jon.jump_speed * 2.0
			climbing_over = true
		if not jon.has_stamina():
			return Moving.new()
		if is_zero_approx(axis):
			if climbing_over:
				jon.velocity = Vector2(axis, -1.0) * jon.jump_speed
			return Moving.new()
		if not Input.is_action_pressed("wall_grab"):
			Tracer.info("Released wall grab")
			return WallSlide.new()
		return self

class Rappel:
	extends MoveState

	func exit(jon: Jon) -> void:
		jon.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).tween_property(
			jon.sprites_node, "rotation", -jon.sprites_node.rotation + 2 * PI, 0.5, 
		).as_relative()

	func physics_process(jon: Jon, delta: float) -> MoveState:
		if not jon.jump_state.current_state is Fall:
			return Idle.new()
		if jon.is_on_floor():
			return Idle.new()
		if jon.is_on_wall():
			return WallSlide.new()
		match jon.current_piton.expr():
			"None":
				return Moving.new()
			{ "Some": var piton }:
				var jon_to_piton = jon.pivot.global_position.direction_to(
					piton.global_position
				)
				jon.sprites_node.look_at(piton.global_position)
				var dir = get_x_move_dir()
				var accel = jon.acceleration * 0.5
				var piton_to_player = jon.pivot.global_position - piton.global_position
				# var target = piton.global_position + piton_to_player.limit_length(Piton.ROPE_LENGTH)
				# var theta = Vector2.DOWN.angle_to(piton_to_player.normalized())
				var motion_dir = piton_to_player.rotated(-PI / 2.0).normalized()
				jon.velocity += motion_dir * accel * dir * delta
		return self

	func input(jon: Jon, event: InputEvent) -> MoveState:
		if event.is_action_pressed("jump"):
			jon.current_piton = Maybe.new()
			jon.jump_state.transition(RappelJump.new())
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
		jon.anim_state.travel("jump")
		await jon.get_tree().create_timer(jon.min_jump_time * 2.0, false).timeout
		jon.squish_anim.play("hunsquish")
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		# counter act gravity
		jon.velocity.y = -jon.jump_speed
		if jon.is_on_ceiling():
			return Fall.new()
		if elapsed > jon.min_jump_time and not Input.is_action_pressed("jump"):
			return Fall.new()
		if elapsed > jon.max_jump_time:
			return Fall.new()
		return self

class RappelJump:
	extends JumpState

	var elapsed = 0.0
	var stored_velocity

	func name() -> String:
		return "JumpState::Jump"

	func enter(jon: Jon) -> JumpState:
		Tracer.info("jumped!")
		elapsed = 0.0
		jon.squish_anim.play("hsquish")
		jon.anim_state.travel("jump")
		stored_velocity = jon.velocity * 1.25
		await jon.get_tree().create_timer(jon.min_jump_time * 2.0, false).timeout
		jon.squish_anim.play("hunsquish")
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		# counter act gravity
		jon.velocity = stored_velocity
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

	func enter(jon: Jon) -> JumpState:
		jon.anim_state.travel("fall")
		return self 

	func physics_process(jon: Jon, delta: float) -> JumpState:
		if jon.on_wall():
			if jon.move_state.current_state is WallSlide:
				return JumpStateWallSlide.new()
			elif jon.move_state.current_state is WallGrab:
				return JumpStateWallGrab.new()
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

class JumpStateWallGrab:
	extends JumpState

	signal fell_off

	func name() -> String:
		return "JumpState::JumpStateWallGrab"

	func enter(jon: Jon) -> JumpState:
		match await Async.select([jon.jump_input, self.fell_off]):
			{ 0: _ }:
				if MoveState.get_x_move_dir() == 0.0:
					return ClimbJump.new()
				else:
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
	var h_mod: float = 1.0
	var v_mod: float = 1.0

	func name() -> String:
		return "JumpState::WallJump"

	func enter(jon: Jon) -> JumpState:
		Tracer.info("jumped!")
		elapsed = 0.0
		axis = jon.wall_axis()
		jon.squish_anim.play("hsquish")
		jon.anim_state.travel("jump")
		await jon.get_tree().create_timer(jon.min_jump_time * 2.0, false).timeout
		jon.squish_anim.play("hunsquish")
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		# counter act gravity
		jon.velocity = Vector2(-axis, -1.0).normalized() * jon.jump_speed * Vector2(h_mod, v_mod)
		if jon.is_on_ceiling():
			return Fall.new()
		if MoveState.get_x_move_dir() == -sign(jon.velocity.x):
			h_mod = 0.3
			v_mod = 0.8
		if elapsed > jon.min_jump_time and not Input.is_action_pressed("jump"):
			return Fall.new()
		if elapsed > jon.max_jump_time:
			return Fall.new()
		return self

class ClimbJump:
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
		jon.stamina -= Jon.CLIMB_JUMP_STAMINA_COST
		jon.anim_state.travel("jump")
		await jon.get_tree().create_timer(jon.min_jump_time * 2.0, false).timeout
		jon.squish_anim.play("hunsquish")
		return self

	func physics_process(jon: Jon, delta: float) -> JumpState:
		elapsed += delta
		# counter act gravity
		jon.velocity = Vector2.UP * jon.jump_speed
		if jon.is_on_ceiling():
			return Fall.new()
		# shorter jump
		if elapsed > jon.min_jump_time * 2.0:
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
@export var floor_raycasts: Node2D
@export var wall_raycasts: Node2D
@export var rope: Rope
@export var collectibles_detector: CollectibleDetector
@export var stamina_anim: AnimationPlayer
@export var pivot: Node2D
@export var piton_spawn: Node2D
@export var hurtbox: Area2D
@export var wall_dust: GPUParticles2D

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
var stamina := 10.0 : set = set_stamina

func _ready() -> void:
	collectibles_detector.collected.connect(on_collected)
	hurtbox.area_entered.connect(on_hurtbox_area_entered)
	hurtbox.body_entered.connect(on_hurtbox_area_entered)

func _unhandled_input(event: InputEvent) -> void:
	move_state.input(event)
	jump_state.input(event)
	InputUtils.actions_pressed(inputs, event)
	InputUtils.actions_released(releases, event)

	if event.is_action_pressed("piton"): 
		if pitons > 0 and current_piton.is_none():
			var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if dir.x == 0.0 and dir.y == 0.0:
				dir.x = look_direction
			var angle = Vector2.DOWN.angle_to(dir)
			var piton = PITON.instantiate()
			piton.rotation = angle
			piton.global_position = piton_spawn.global_position
			pitons -= 1
			add_sibling(piton)
			await piton.hit
			current_piton = Maybe.new(piton)
		elif current_piton.is_some():
			current_piton = Maybe.new()

func _process(delta: float) -> void:
	move_state.process(delta)
	jump_state.process(delta)

func _physics_process(delta: float) -> void:
	hurtbox.global_skew -= hurtbox.global_skew
	if not move_state.current_state is Rappel:
		sprites_node.skew = lerp(0.0, sign(velocity.x) * deg_to_rad(20.0), abs(velocity.x) / move_speed)
	else:
		sprites_node.skew = 0.0
	Tracer.info(move_state.current_state.name() + str(wall_axis()))
	move_state.physics_process(delta)
	jump_state.physics_process(delta)
	movable.update(delta)
	if is_on_floor():
		refill_stamina()
		pitons = 1
	if self.stamina <= 0.0:
		stamina_anim.play("flash_red")
	else:
		stamina_anim.play("idle")
	if not is_zero_approx(velocity.x):
		look_direction = sign(velocity.x)
	wall_dust.global_position = pivot.global_position + wall_axis() * get_distance_from_wall() * Vector2.RIGHT + Vector2.DOWN * 8.0
	match current_piton.expr():
		"None":
			movable.use_gravity = true
			rope.visible = false
		{ "Some": var piton }:
			movable.use_gravity = false
			var piton_to_player = pivot.global_position - piton.global_position
			var theta = Vector2.DOWN.angle_to(piton_to_player.normalized())
			var motion_dir = piton_to_player.rotated(-PI / 2.0).normalized()
			var accel = Movable.GRAVITY * sin(theta)
			velocity += accel * motion_dir * delta
			if piton_to_player.length() > Piton.ROPE_LENGTH:
				var difference = piton_to_player.length() - Piton.ROPE_LENGTH
				velocity = velocity.project(motion_dir) - piton_to_player.normalized() * difference
			velocity *= rappel_damping
			rope.visible = true
			rope.extend_to(piton.global_position - pivot.global_position)

	look(look_direction)

func look(x: float) -> void:
	var flip = x < 0.0
	for sprite in get_tree().get_nodes_in_group("jon_sprite") as Array[Sprite2D]:
		sprite.flip_h = flip

func look_at_velocity() -> void:
	look(velocity.x)

func is_grounded() -> bool:
	return (
		floor_raycasts.get_children() as Array[RayCast2D]
	).reduce(
		func(acc, el: RayCast2D): return acc or el.is_colliding(), 
		false
	)

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
	var left_value = check.call(left)
	var right_value = check.call(right)
	if left_value != 0.0:
		return -left_value
	elif right_value != 0.0:
		return right_value
	else:
		return 0.0

func get_wall_collision_count(axis: float) -> int:
	var raycasts
	if sign(axis) == 1.0:
		raycasts = wall_raycasts.get_node("Right")
	elif sign(axis) == -1.0:
		raycasts = wall_raycasts.get_node("Left")
	else:
		return 0
	return (
		raycasts
			.get_children()
			.filter(func(el): return el is RayCast2D)
			.filter(func(el: RayCast2D): return el.is_colliding())
			.size()
	)
		

func get_wall_collider() -> Node2D:
	var left = wall_raycasts.get_node("Left")	
	var right = wall_raycasts.get_node("Right")	
	var check = func(node: Node): 
		return (
			Tracer.dbg("", node
				.get_children()
				.map(func(el): return el as RayCast2D)
				.filter(func(el): return el)
				.filter(func(el: RayCast2D): return el.is_colliding())
				.front().get_collider()
			)
		)
	var left_collider = check.call(left)
	var right_collider = check.call(right)

	if left_collider:
		return left_collider
	elif right_collider:
		return right_collider
	else:
		return null

func get_distance_from_wall() -> float:
	var left = wall_raycasts.get_node("Left")	
	var right = wall_raycasts.get_node("Right")	
	var collision = func(node: Node): 
		return Utils.array_at(
			node
				.get_children()
				.map(func(el): return el as RayCast2D)
				.filter(func(el): return el)
				.filter(func(el): return el.is_colliding()),
			0
			
		)
	var left_collider = collision.call(left)
	var right_collider = collision.call(right)
	var collider = left_collider.or_else(right_collider)
	match collider.expr():
		{ "Some": var raycast }:
			return raycast.get_collision_point().distance_to(raycast.global_position)
		_:
			return 0.0
 
func on_wall() -> bool:
	return wall_axis() != 0.0

func constrain_position_on_piton() -> void:
	match current_piton.expr():
		{ "Some": var piton }:
			movable.use_gravity = false
			var piton_to_player = self.global_position - piton.global_position
			var target = piton.global_position + piton_to_player.limit_length(Piton.ROPE_LENGTH)
			self.global_position = target

func on_collected(collectible: Area2D):
	if collectible is PitonGem:
		collectible.collectible.passed_through.emit()
		if pitons == 0:
			collectible.collectible.collect_received.emit()
			pitons = 1

func set_stamina(value: float) -> void:
	stamina = clamp(value, 0, MAX_STAMINA)

func refill_stamina() -> void:
	set_stamina(MAX_STAMINA)

func has_stamina() -> bool:
	return stamina > 0

## drain_stamina
##
## @param {float} elapsed Should be smaller than 2.0
## @param {int} loss_per_second
## @returns {float} Updated value of elapsed
func drain_stamina(elapsed: float, loss_per_second: int) -> float:
	if elapsed >= 1.0:
		elapsed -= 1.0
		stamina -= loss_per_second
	return elapsed
	
func on_hurtbox_area_entered(area) -> void:
	if not area:
		return
	# TODO: die
	if Events.PAUSE_ON_DEATH:
		get_tree().paused = true
	died.emit(self)
	current_piton = Maybe.None()
	Tracer.info("Player emitted `died` signal.")

func fall() -> void:
	jump_state.transition(Fall.new())

extends CharacterBody2D

class MoveState:
	extends Wisp.State

class Idle:
	extends MoveState

class JumpState:
	extends Wisp.State

class NoJump: 
	extends JumpState


@onready var move_state := Wisp.use_state_machine(self, Idle.new())
@onready var jump_state := Wisp.use_state_machine(self, NoJump.new())

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	move_state.input(event)
	jump_state.input(event)

func _process(delta: float) -> void:
	move_state.process(delta)
	jump_state.process(delta)

func _physics_process(delta: float) -> void:
	move_state.physics_process(delta)
	jump_state.physics_process(delta)

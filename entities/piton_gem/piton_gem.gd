class_name PitonGem
extends Area2D

const RECHARGE_TIME := 6.0

@export var sprite_anim: AnimationPlayer
@export var collectible: Collectible

func _ready() -> void:
	sprite_anim.play("idle")
	collectible.collected.connect(
		func():
			sprite_anim.play("collect")
			collectible.can_be_collected = false
			await get_tree().create_timer(RECHARGE_TIME, false).timeout
			sprite_anim.play("idle")
			collectible.can_be_collected = true
	)
	collectible.passed_through.connect(
		func():
			sprite_anim.play("pass_through")
	)

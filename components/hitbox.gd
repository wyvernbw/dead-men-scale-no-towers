class_name Hitbox
extends Area2D

func _ready() -> void:
	monitorable = true
	monitoring = false
	collision_layer = 16


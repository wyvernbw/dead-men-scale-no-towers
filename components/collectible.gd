class_name Collectible
extends Node

signal collected
signal collect_received

@export var can_be_collected := true

func _ready() -> void:
	assert(owner is Area2D)
	owner.area_entered.connect(
		func(area): 
			if not can_be_collected:
				return
			if not area is CollectibleDetector:
				return
			area.collected.emit(owner)
			await collect_received
			collected.emit()
	)

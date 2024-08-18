class_name ScreenGate
extends Area2D

@export var next_screen_id: String

func _ready() -> void:
	collision_mask = 32
	collision_layer = 0
	body_entered.connect(
		func(jon: Jon):
			if not jon:
				return
			var managers = (
				get_tree()
				.get_nodes_in_group("camera_managers")
				.map(func(el): return el as CameraManager)
				.filter(func(el): return el)
			) as Array[CameraManager]
			var id = "Cam" + next_screen_id
			for manager in managers:
				manager.switch_camera(id)
	)

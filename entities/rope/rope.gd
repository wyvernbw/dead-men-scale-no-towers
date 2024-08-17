class_name Rope
extends Sprite2D

@export var debug_to_cursor: bool

func _process(delta: float) -> void:
	if debug_to_cursor:
		extend_to(get_global_mouse_position())

func extend_to(pos: Vector2) -> void:
	rotation = Vector2.DOWN.angle_to(pos - Vector2.ONE * 8.0)
	region_rect.size.y = self.position.distance_to(pos)

class_name CameraManager
extends Node

signal camera_transitioned(id)

@onready var target = get_parent()
@onready var current_camera = initial_camera

@export var initial_camera: PhantomCamera2D


func _ready() -> void:
	add_to_group("camera_managers")
	initial_camera.priority = 1

func get_cameras() -> Dictionary:
	return (target
		.get_children()
		.filter(func(el): el is PhantomCamera2D)
		.reduce(func(dict, el): dict[el.name] = el; return dict)
	)

func switch_camera(id: String) -> void:
	var cameras = get_cameras()
	if id in cameras:
		cameras[id].priority = 1
		current_camera.priority = 0
		current_camera = cameras[id]
		camera_transitioned.emit(id)
	else:
		Tracer.warn("Nonexistent camera %s" % id)

extends Node

signal made_progress

const PAUSE_ON_DEATH := false

var progress = {}: set = set_progress
var current_rita_dialogue := "FirstEncounter"
var rita_dialogue_exhausted := false

func _ready() -> void:
	TraceSubscriber.new().init()
	process_mode = PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select") and Events.PAUSE_ON_DEATH and get_tree().paused:
		get_tree().paused = false
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)

func set_progress(value) -> void:
	progress = value
	made_progress.emit()

class_name InputUtils
extends RefCounted

static func actions_pressed(signal_list: Array, event: InputEvent) -> void:
	actions(signal_list, event, event.is_action_pressed)

static func actions_released(signal_list: Array, event: InputEvent) -> void:
	actions(signal_list, event, event.is_action_released)

static func actions(signal_list: Array, event: InputEvent, predicate: Callable) -> void:
	for sig in signal_list:
		var sig_name = sig.get_name()
		var action_name = sig_name.rsplit("_", true, 1)[0]
		if predicate.call(action_name):
			sig.emit()


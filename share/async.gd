class_name Async
extends RefCounted

class Future:
	extends RefCounted

	signal completed(return_value)

	var is_callable: bool
	var value

	func _init(_value) -> void:
		if _value is Callable:
			is_callable = true
		elif _value is Signal:
			is_callable = false
		else:
			assert(false, "value provided is not a signal or callable")
		value = _value

	func run():
		if is_callable:
			var ret = await value.call()
			completed.emit(ret)
			return ret
		else:
			var ret = await value
			completed.emit(ret)
			return ret

static func select(futures: Array) -> Dictionary:
	return await Selector.new().select(futures)

class Selector:
	extends RefCounted

	signal finished

	func select(futures: Array) -> Dictionary:
		var signal_map = {}
		futures = futures.map(func(el): return Future.new(el))
		for idx in futures.size():
			var future = futures[idx]
			signal_map[idx] = {
				"finished": false,
				"value": null
			}
			future.completed.connect(
				func(return_value):
					signal_map[idx].finished = true
					signal_map[idx].value = return_value
					finished.emit()
			)
		await self.finished
		for branch in signal_map.keys():
			if signal_map[branch].finished:
				return { branch: signal_map[branch].value }
		return {}

	

static func join(_futures: Array) -> Array:
	var signal_map = {}
	var futures: Array[Future] = _futures.map(func(el): return Future.new(el))
	for idx in futures.size():
		var future = futures[idx]
		signal_map[idx] = {
			"finished": false,
			"value": null
		}
		future.completed.connect(
			func(return_value):
				signal_map[idx].finished = true
				signal_map[idx].value = return_value
		)
	for future in futures:
		await future.run()
	return signal_map.values().map(func(el): return el.value)
		

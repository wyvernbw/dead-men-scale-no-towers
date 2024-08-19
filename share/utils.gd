class_name Utils
extends RefCounted

static func array_at(arr: Array, idx: int) -> Maybe:
	if idx in range(0, arr.size() - 1):
		return Maybe.Some(arr[idx])
	else:
		return Maybe.None()

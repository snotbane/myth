
class_name Async

## Calls all provided callables. Then waits for ALL of the callables/signals to finish awaiting. They can be completed in any order but must all return before continuing. Returns an array with the results of each one, in order of completion.
static func all(methods : Array) :
	var listener := AllListener.new(methods)
	if not listener.is_completed:
		await listener.completed
	return listener.payload


class AllListener extends RefCounted :
	signal completed
	var payload : Array = []
	var methods_left : int

	var is_completed : bool :
		get: return methods_left == 0


	func _init(methods : Array) -> void:
		payload.resize(methods.size())
		payload.fill(null)
		methods_left = methods.size()
		for i in methods.size():
			var method = methods[i]
			self.add(i, method)


	func add(i: int, method) -> void:
		assert(not is_completed, "This listener is already completed.")
		if method is Signal:
			receive(i, await method)
		elif method is Callable:
			receive(i, await method.call())
		else:
			assert(false, "Awaitable method must be either a Signal or a Callable.")


	func receive(i : int, value : Variant = null) -> void:
		if is_completed: return
		methods_left -= 1

		payload[i] = value
		if is_completed:
			completed.emit()


## Calls all provided callables. Then waits for the FIRST of the callables/signals to finish awaiting. Returns the result of that first method; others are never triggered. If multiple complete simultaneously, the first one in the list is prioritized.
static func any(methods : Array) :
	var listener := AnyListener.new(methods)
	if not listener.is_completed:
		await listener.completed
	return listener.payload


## Functions like [member any], but returns the index of the method which was first completed. Returns 0 if completed instantly.
static func which(methods : Array) :
	var listener := AnyListener.new(methods)
	if not listener.is_completed:
		return await listener.completed
	else:
		return 0


class AnyListener extends RefCounted :
	signal completed(idx: int)
	var payload : Variant = null
	var is_completed : bool = false


	func _init(methods : Array = []) -> void:
		for i in methods.size():
			self.add(methods[i], i)


	func add(method, idx: int) -> void:
		if is_completed: return
		if method is Signal:
			receive(await method, idx)
		elif method is Callable:
			receive(await method.call(), idx)
		else:
			assert(false, "Awaitable method must be either a Signal or a Callable.")


	func receive(value : Variant = null, idx: int = -1) -> void:
		if is_completed: return
		is_completed = true

		payload = value
		completed.emit(idx)

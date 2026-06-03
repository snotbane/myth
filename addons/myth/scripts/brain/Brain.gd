## Generic brain decisioning/sequencing/navigation node. Should be the child of the Node to be controlled, e.g. [Node3D] or [NavigationAgent3D].
class_name Brain extends Timer

static func is_valid_target(value: Variant) -> bool:
	return (
		value == null
		or value is Node2D
		or value is Node3D
		or value is Vector2
		or value is Vector3
	)


signal desired_move(direction: Variant)

var _move_vector_prev: Variant

func get_move_vector(delta: float) -> Variant:
	match travel_state:
		ROUGH:
			return _get_move_vector_rough(delta)

	return null

func _get_move_vector_rough(delta: float) -> Variant:
	return user.global_position.direction_to(agent.get_next_path_position() if agent != null else target_position)


#region Agent

## Reference to the [Node] which this [Brain] controls. If null, this defaults to the closest ancestor (or ourself) that is a [Node2D] or [Node3D].
@export var user: Node

## Reference to the NavigationAgent which this [Brain] controls. If null, this defaults to the immediate parent, if it is a [NavigationAgent2D] or [NavigationAgent3D].
@export var agent: Node

#endregion


#region Target

@export_group("Target", "target_")

## If set, [member target] will be set to this [Node] on ready.
@export var target_initial_target: Node

## The distance at which we consider the target to be reached. NOTE: this has no effect if [member agent] is set; see [member NavigationAgent3D.target_desired_distance].
@export var target_rough_desired_distance: float = 1.0


## Emitted when the Brain considers [member target] as mostly reached. If [member travel_precise_enabled], this will begin precise movement. Otherwise, this will also trigger [member target_reached].
signal target_reached_rough

## Emitted when the Brain considers [member target] as reached.
signal target_reached


## Emits when [member target] changes.
signal target_changed
var target: Variant:
	set(value):
		assert(is_valid_target(value), "Assigning target to an invalid value. Must be assigned to a Node2D, Node3D, Vector2, or Vector3.")

		if target == value: return

		if target is Node:
			target.tree_exiting.disconnect(target_clear)

		target = value

		if target is Node:
			target.tree_exiting.connect(target_clear)

		target_refresh()
		target_changed.emit()


var target_is_valid: bool:
	get: return is_valid_target(target)

var target_position: Variant:
	get:
		assert(target_is_valid, "Target is not valid. Must be assigned to a Node2D, Node3D, Vector2, or Vector3, or null.")
		return (target.global_position
			if target is Node else (target
				if target != null else user.global_position
			)
		)


func target_clear() -> void:
	target = null


func target_refresh() -> void:
	if not target_is_valid: return
	_target_refreshed()
	target_refreshed.emit()

## Emits on [member timeout] if [member target_is_valid].
signal target_refreshed

var _target_refreshed_method: Callable

func _target_refreshed() -> void:
	if _target_refreshed_method.is_null(): return

	_target_refreshed_method.call()

func _target_refreshed_agent_2d() -> void:
	agent.target_position = NavigationServer2D.map_get_closest_point(agent.get_navigation_map(), target_position) if travel_use_closest_position_on_map else target_position

func _target_refreshed_agent_3d() -> void:
	agent.target_position = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), target_position) if travel_use_closest_position_on_map else target_position


#endregion


#region Travel

@export_group("Travel", "travel_")

enum {
	STOPPED,
	ROUGH,
	PRECISE,
}

## Emits when [member travel_stop] is called while [member is_travelling] is true.
signal travel_stopped

## If enabled, we will always attempt to reach the closest point on the navigation map rather than the exact target position, even if that target is unreachable. The closest position will be treated as the actual target position (i.e. reaching it will result in a navigation success). If disabled, the user will stop moving as it will consider the target to be unreachable.
@export var travel_use_closest_position_on_map: bool = true


@export_subgroup("Precise", "travel_precise_")

## If enabled, after normal navigation has successfully completed, we will tween [member user]'s global position directly towards the [member target]. Works best with stationary targets.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var travel_precise_enabled: bool = false

## The duration of the tween. If set to 0.0, precise travelling will happen instantaneously.
@export_range(0.0, 1.0, 0.001, "or_greater") var travel_precise_tween_duration: float = 0.1


var travel_precise_tween: Tween

var travel_state: int = STOPPED:
	set(value):
		travel_state = value
		if is_travelling:
			start()
		else:
			stop()


## Returns true if [member travel] has been called and we are currently travelling to the [member target].
var is_travelling: bool:
	get: return travel_state != STOPPED
	set(value):
		if is_travelling == value: return

		travel_state = ROUGH if value else STOPPED


## Awaitable method that moves the [member user] from its current global position to a [member destination]'s global position. If [param clear_target] is enabled, [member target] will be unassigned once it has been reached. If [param precise] is set, this will override [member travel_precise_enabled] for this call. If we are already travelling, this will only change the target.
func travel(destination: Variant, clear_target: bool = false, precise: bool = travel_precise_enabled):
	if destination != null:
		target = destination
		match travel_state:
			STOPPED: pass
			ROUGH: return
			PRECISE: await travel_stopped

		travel_state = ROUGH

		await timeout

		if not _is_target_reached():
			await Async.any([travel_rough, travel_stopped])
			if not is_travelling: return

			target_reached_rough.emit()

		if precise and travel_state == ROUGH:
			await Async.any([travel_precise, travel_stopped])
			if not is_travelling: return

		target_reached.emit()

	travel_stop(clear_target)


## Stops travelling.
func travel_stop(clear_target: bool = false) -> void:
	var is_travelling_prev := is_travelling
	travel_state = STOPPED

	if is_travelling_prev:
		travel_stopped.emit()

	if clear_target:
		target_clear()


## Instantly moves [member user] to a given [param destination], or [member target] if unspecified. Doesn't affect [member target].
func teleport(destination: Variant = target) -> void:
	assert(is_valid_target(destination), "Destination must be a valid target.")

	user.global_position = destination.global_position if destination is Node else destination

func teleport_and_stop(destination: Variant = target) -> void:
	teleport(destination)
	travel_stop()


func _is_target_reached() -> bool:
	if get_parent() is NavigationAgent2D or get_parent() is NavigationAgent3D:
		return get_parent().is_target_reached()
	return false

func travel_rough():
	await _travel_rough()
func _travel_rough():
	if agent:
		await agent.target_reached
	else:
		while user.global_position.distance_to(target_position) > target_rough_desired_distance:
			await timeout


func travel_precise():
	travel_state = PRECISE
	await Async.any([_travel_precise, travel_stopped])

func _travel_precise():
	if travel_precise_tween.is_running():
		travel_precise_tween.stop()

	if travel_precise_tween_duration > 0.0:
		travel_precise_tween = create_tween()
		travel_precise_tween.set_ease(Tween.EASE_IN_OUT)
		travel_precise_tween.set_trans(Tween.TRANS_CUBIC)
		travel_precise_tween.tween_property(user, ^"global_position", target_position, travel_precise_tween_duration)

		await travel_precise_tween.finished

	else:
		user.global_position = target_position


#endregion


#region Wait

var wait_timer: Timer

func wait(duration_seconds: float):
	assert(duration_seconds > 0.0, "Wait duration must be greater than 0.")

	if not wait_timer.is_stopped():
		wait_timer.stop()

	wait_timer.wait_time = duration_seconds
	wait_timer.start()

	await wait_timer.timeout

#endregion


#region Sequence


var is_sequence_running: bool = false
func start_sequence() -> void:
	if is_sequence_running: return

	await get_tree().process_frame

	is_sequence_running = true

	while is_instance_valid(self ) and (not await _sequence()): pass

	is_sequence_running = false

## Implementation for all decision making. Returning a falsy value will end the sequence (and restart, if it loops). Returning a truthy value will break the sequence loop (until [member start_sequence] is called again).
func _sequence(): return true


#endregion


func _init() -> void:
	wait_timer = Timer.new()
	wait_timer.one_shot = true
	wait_timer.process_mode = PROCESS_MODE_INHERIT
	add_child(wait_timer)

	timeout.connect(target_refresh)


func _ready() -> void:
	if user == null:
		user = self
		while not (user is Node2D or user is Node3D):
			user = user.get_parent()

	if agent == null:
		var parent := get_parent()
		if parent is NavigationAgent2D or parent is NavigationAgent3D:
			agent = parent

	if target_initial_target:
		target = target_initial_target

	if agent is NavigationAgent2D:
		_target_refreshed_method = _target_refreshed_agent_2d

	elif agent is NavigationAgent3D:
		_target_refreshed_method = _target_refreshed_agent_3d

	else:
		_target_refreshed_method = Callable()


	start_sequence.call_deferred()


func _physics_process(delta: float) -> void:
	var move_vector := get_move_vector(delta)
	if move_vector == null: move_vector = Vector3.ZERO if user is Node3D else Vector2.ZERO


	if move_vector != _move_vector_prev:
		desired_move.emit(move_vector)
		_move_vector_prev = move_vector

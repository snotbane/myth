## Generic brain decisioning/sequencing/navigation node. Should be the child of the Node to be controlled, e.g. [Node3D] or [NavigationAgent3D].
@abstract class_name Brain extends Timer

#region Agent

## Reference to the [Node] which this [Brain] controls. If null, this defaults to the closest ancestor (or ourself) that is a [Node2D] or [Node3D].
@export var user: Node

## Reference to the NavigationAgent which this [Brain] controls. If null, this defaults to the immediate parent, if it is a [NavigationAgent2D] or [NavigationAgent3D].
@export var agent: Node

#endregion


#region Target

## Emits when [member target] changes.
signal target_changed
@export var target: Variant:
	set(value):
		assert(
				value == null
			or value is Node2D
			or value is Node3D
			or value is Vector2
			or value is Vector3,
			"Assigning target to an invalid value. Must be assigned to a Node2D, Node3D, Vector2, or Vector3."
		)
		if target == value: return

		if target is Node:
			target.tree_exiting.disconnect(unassign_target)

		target = value

		if target is Node:
			target.tree_exiting.connect(unassign_target)

		target_refresh()
		target_changed.emit()

## Emitted when the Brain considers [member target] as mostly reached. If [member precise_enabled], this will begin precise movement. Otherwise, this will also trigger [member target_reached].
signal target_reached_rough

## Emitted when the Brain considers [member target] as reached.
signal target_reached


var target_is_valid: bool:
	get: return (
			target is Node2D
		or target is Node3D
		or target is Vector2
		or target is Vector3
	)

var target_position: Variant:
	get:
		assert(target_is_valid, "Target is not valid. Must be assigned to a Node2D, Node3D, Vector2, or Vector3.")
		return target.global_position if target is Node else target


func unassign_target() -> void:
	target = null


func target_refresh() -> void:
	if not target_is_valid: return
	_target_refreshed()
	target_refreshed.emit()
## Emits on [member timeout] if [member target_is_valid].
signal target_refreshed
func _target_refreshed() -> void: pass

#endregion


#region Travel

enum {
	STOPPED,
	ROUGH,
	PRECISE,
}

## If enabled, we will always attempt to reach the closest point on the navigation map rather than the exact target position, even if that target is unreachable. The closest position will be treated as the actual target position (i.e. reaching it will result in a navigation success). If disabled, the user will stop moving as it will consider the target to be unreachable.
@export var use_closest: bool = true


var travel_state: int = STOPPED:
	set(value):
		travel_state = value
		if is_travelling:
			start()
		else:
			stop()

var is_travelling: bool:
	get: return travel_state != STOPPED
	set(value):
		if is_travelling == value: return

		travel_state = ROUGH if value else STOPPED


func travel(to: Variant, clear_target: bool = false):
	if to != null:
		var travelling_prev := is_travelling
		target = to
		travel_state = ROUGH

		if travelling_prev: return

		await timeout
		if not _is_target_reached():
			await target_reached_rough

		if precise_enabled:
			await _travel_precise()

	stop_travel()
	target_reached.emit()

	if clear_target:
		unassign_target()


func stop_travel() -> void:
	travel_state = STOPPED


func _is_target_reached() -> bool:
	if get_parent() is NavigationAgent2D or get_parent() is NavigationAgent3D:
		return get_parent().is_target_reached()
	return false


##endregion


#region Precise

@export_group("Precise", "precise_")

## If enabled, after normal navigation has successfully completed, we will perform a second, simple and direct navigation operation that will desire movement as close to the target as possible, only stopping when the parent can come no closer to it. Works best with stationary targets.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var precise_enabled: bool = false

## The maximum amount of time to wait before assuming that the target is reached.
@export var precise_max_duration: float = 0.2

## If the distance to the target is within this radius, assume the target has been reached.
@export var precise_distance: float = 0.01


func _travel_precise():
	travel_state = PRECISE

	var tween := create_tween()
	tween.tween_property(user, ^"global_position", target_position, precise_distance)


#endregion


#region Wait

var wait_timer: Timer

func wait(duration_seconds: float):
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

	if agent:
		agent.target_reached.connect(target_reached_rough.emit)


	start_sequence.call_deferred()

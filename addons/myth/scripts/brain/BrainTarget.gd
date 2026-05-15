class_name BrainTarget extends Timer

## Emitted when the target node or position is changed.
signal changed
## Emitted whenever the timer runs out, prompting a navigation update.
signal updated

var _target_pos : Variant
var _target_node : Node

## The global position of the target.
var target_position : Variant :
	get:
		assert(is_assigned, "BrainTarget must be assigned in order to get the target position.")
		if _target_node is Node2D or _target_node is Node3D:
			return _target_node.to_global(_target_pos)
		else:
			return _target_pos

## Returns true if the target is currently assigned.
var is_assigned : bool :
	get: return _target_node != null or _target_pos != null

var is_assigned_to_node : bool :
	get: return _target_node != null

var _wait_time_is_valid : bool
## Effectively the same as [member wait_time], but it allows for a value of 0.0.
var refresh_duration : float :
	get: return wait_time if _wait_time_is_valid else 0.0
	set(value):
		_wait_time_is_valid = value > 0.0
		if _wait_time_is_valid:
			wait_time = value
			if is_inside_tree():
				if is_stopped():	start()
			else:					autostart = true
		else:
			if not is_stopped(): stop()


func _init(__wait_time__: float) -> void:
	process_callback = Timer.TIMER_PROCESS_PHYSICS
	timeout.connect(try_update)
	refresh_duration = __wait_time__

func try_update() -> void:
	if not is_assigned: return
	updated.emit()

func assign(value: Variant, relative_pos: Variant = null, closest: bool = true) -> void:
	assert(value == null or value is Node2D or value is Node3D or value is Vector2 or value is Vector3, "Assigned target must be a Node2D or Node3D, or a Vector2 or Vector3.")
	assert(relative_pos == null or relative_pos is Vector2 or relative_pos is Vector3, "Relative position must be a Vector2 or Vector3.")
	if _target_node == value and _target_pos == relative_pos: return

	var value_is_node : bool = value is Node3D or value is Node2D

	if _target_node != null:
		_target_node.tree_exiting.disconnect(unassign)

	_target_node = value if value_is_node else null
	_target_pos = ((Vector3.ZERO if _target_node is Node3D else Vector2.ZERO) if value_is_node else value)
	if relative_pos != null:
		_target_pos += relative_pos

	if _target_node != null:
		_target_node.tree_exiting.connect(unassign)

	if is_assigned:
		changed.emit()

func unassign() -> void:
	assign(null)

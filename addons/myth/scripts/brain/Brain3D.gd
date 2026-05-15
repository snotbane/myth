
class_name Brain3D extends NavigationAgent3D

enum {
	STOPPED,
	ROUGH,
	PRECISE,
}

signal desired_teleport(global_pos: Vector3)
signal desired_move(direction: Vector3)
## Emitted when the precision navigation operation is complete. This operation can never fail, but will only occur if [member use_precise] is true.
signal precise_reached
## Emitted when [member target_reached] is emitted, or when [member precise_reached] is emitted, depending on whether [member use_precise] is true or not.
signal dynamic_reached

@export_subgroup("Navigation")

var _refresh_duration : float = 0.1
## If greater than 0.0, [member target_position] will be continuously updated after this many seconds. If 0.0, this will only occur when [member target] is manually changed or [member refresh_target_position] is manually called.
@export_range(0.0, 1.0, 0.01, "or_greater") var refresh_duration : float = 0.1 :
	get: return _refresh_duration
	set(value):
		if _refresh_duration == value: return
		_refresh_duration = value

		if target != null:
			target.refresh_duration = _refresh_duration

## If enabled, we will always attempt to reach the closest point on the navigation map rather than the exact target position, even if that target is unreachable. The closest position will be treated as the actual target position (i.e. reaching it will result in a navigation success). If disabled, the agent will stop moving as it will consider the target to be unreachable.
@export var use_closest : bool = true

## If enabled, after normal navigation has successfully completed, we will perform a second, simple and direct navigation operation that will desire movement as close to the target as possible, only stopping when the parent can come no closer to it.
@export var use_precise : bool = false

## This node's local position will be offset when teleporting.
@export var offset : Node3D

## If enabled, [member target_position] will be updated once every [member refresh_duration] seconds.
var continuous_update : bool :
	get: return refresh_duration > 0.0



var target : BrainTarget


var _move_vector_prev : Vector3
var _precise_distance_squared_prev : float

var _travel_state : int = STOPPED
var travelling : bool :
	get: return _travel_state != STOPPED


func _ready() -> void:
	target = BrainTarget.new(refresh_duration)
	target.changed.connect(refresh_target_position)
	target.updated.connect(refresh_target_position)

	sequence()

func sequence() -> void:
	if not has_method(&"_sequence"): return
	await get_tree().process_frame
	while is_instance_valid(self): await call(&"_sequence")

func _physics_process(delta: float) -> void:
	var move_vector : Vector3

	match _travel_state:
		ROUGH:
			move_vector = ((get_next_path_position() - get_parent().global_position)).normalized()

		PRECISE:
			var remaining : Vector3 = target_position - get_parent().global_position
			var _precise_distance_squared := remaining.length_squared()

			if is_zero_approx(_precise_distance_squared) or _precise_distance_squared >= _precise_distance_squared_prev:
				move_vector = Vector3.ZERO
				stop_and_teleport()
				precise_reached.emit()
			else:
				move_vector = remaining.normalized()

			_precise_distance_squared_prev = _precise_distance_squared

		STOPPED:
			move_vector = Vector3.ZERO

	if move_vector != _move_vector_prev:
		desired_move.emit(move_vector)
		_move_vector_prev = move_vector


func refresh_target_position() -> void:
	target_position = NavigationServer3D.map_get_closest_point(get_navigation_map(), target.target_position) if use_closest else target.target_position


func travel(destination: Variant) :
	if destination != null:
		var was_travelling := travelling
		target.assign(destination)
		_travel_state = ROUGH

		if not was_travelling:
			await wait(refresh_duration)
			if not is_target_reached():
				await target_reached

			if use_precise:
				_begin_precise_navigation()
				await precise_reached

	stop()
	dynamic_reached.emit()

func _begin_precise_navigation() -> void:
	_travel_state = PRECISE
	_precise_distance_squared_prev = target_position.distance_squared_to(get_parent().global_position) + 1_000_000.0


func stop() -> void:
	target.unassign()
	_travel_state = STOPPED

func stop_and_teleport() -> void:
	_teleport()
	stop()

func _teleport() -> void:
	desired_teleport.emit(target_position - (offset.position if offset else Vector3.ZERO))

func wait(duration_seconds: float) :
	await get_tree().create_timer(duration_seconds).timeout

## Casts the mouse location. Must be parented to a [Camera3D] and it must be the current camera.
class_name CursorCaster3D extends RayCast3D


signal focus_changed


@onready var camera : Camera3D = get_parent()


@export var length : float = 100.0


var _focus : CollisionObject3D
var focus : CollisionObject3D :
	get: return _focus
	set(value):
		if _focus == value or (value != null and value is not CollisionObject3D): return

		_focus = value
		_focus_changed()
		focus_changed.emit()


var collision_position : Vector3 :
	get: return get_collision_point() if is_colliding() else to_global(target_position)


func _physics_process(delta: float) -> void:
	if not camera.current:
		target_position = Vector3.ZERO
		return

	var mouse_position := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)
	target_position = to_local(ray_origin + ray_normal * length)

	_physics_process_current(delta)


## Called each physics tick, when the parent [member camera] is current, and after [member target_position] and [member focus] have been updated.
func _physics_process_current(delta: float) -> void:
	focus = get_collider()


## Called whenever the collided object changes.
func _focus_changed() -> void: pass

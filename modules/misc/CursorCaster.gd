## Casts the mouse location. Must be parented to a [Camera3D] and it must be the current camera.
class_name CursorCaster3D extends RayCast3D


@onready var camera : Camera3D = get_parent()


@export var length : float = 100.0


func _physics_process(delta: float) -> void:
	if not camera.current: return

	var mouse_position := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)

	target_position = to_local(ray_origin + ray_normal * length)


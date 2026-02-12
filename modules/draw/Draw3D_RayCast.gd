
@tool class_name Draw3D_RayCast extends Draw3D

var hit_color : Color :
	get: return -color

var cast_ray : Draw3D_Ray
var block_ray : Draw3D_Ray
var normal_ray : Draw3D_Ray

func _init() -> void:
	super._init()

	cast_ray = Draw3D_Ray.new()
	cast_ray.global_mode = true
	add_child(cast_ray)

	block_ray = Draw3D_Ray.new()
	block_ray.global_mode = true
	block_ray.visible = false
	block_ray.head_size = 0.0
	block_ray.color.a = 0.1
	add_child(block_ray)

	normal_ray = Draw3D_Ray.new()
	normal_ray.global_mode = true
	normal_ray.visible = false
	add_child(normal_ray)


@export_range(0.0, 1.0, 0.01, "or_greater") var head_size : float = 0.25 :
	get: return normal_ray.head_size
	set(value): normal_ray.head_size = value


@export_range(0.0, 1.0, 0.01) var block_opacity : float = 0.1 :
	get: return block_ray.color.a			/ color.a
	set(value): block_ray.color.a = value	* color.a


func _get_color() -> Color:
	return cast_ray.color
func _set_color(value: Color) -> void:
	block_ray.color = value * Color(1.0, 1.0, 1.0, block_opacity)
	cast_ray.color = value
	normal_ray.color = value


func _process(delta):
	if get_parent() is RayCast3D:
		_update_from_parent()

func update_from_query(query: PhysicsRayQueryParameters3D, response: Dictionary) -> void:
	_update_internal(
		not response.is_empty(),
		query.from,
		query.to,
		response.get(&"position", Vector3.ZERO),
		response.get(&"normal", Vector3.ZERO)
	)

func _update_from_parent() -> void:
	var parent : RayCast3D = get_parent()
	assert(parent is RayCast3D)

	parent.debug_shape_custom_color = Color.TRANSPARENT

	_update_internal(
		parent.is_colliding(),
		parent.global_position,
		parent.to_global(parent.target_position),
		parent.get_collision_point(),
		parent.get_collision_normal()
	)


func _update_internal(is_colliding: bool, global_origin: Vector3, global_target: Vector3, global_point: Vector3, global_normal: Vector3) -> void:
	global_point = global_point if is_colliding else global_target
	global_position = global_point

	# cast_ray.origin = global_origin
	# cast_ray.target = global_point
	cast_ray.position = global_origin
	cast_ray.target = global_point - global_origin
	cast_ray.head_size = 0.0 if is_colliding else head_size

	block_ray.visible = is_colliding
	# block_ray.origin = global_point
	# block_ray.target = global_target
	block_ray.position = global_point
	block_ray.target = global_target - global_point

	normal_ray.visible = is_colliding
	# normal_ray.origin = global_point
	# normal_ray.target = global_point + global_normal * head_size
	normal_ray.position = global_point
	normal_ray.target = global_normal * head_size

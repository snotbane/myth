
@tool class_name Draw3D_ShapeCast extends Draw3D

var cast_ray : Draw3D_Ray
var block_ray : Draw3D_Ray
var draw_shape : Draw3D_Shape
var normals_multimesh : Draw3D_MultiMesh

func _init() -> void:
	super._init()

	draw_shape = Draw3D_Shape.new()
	draw_shape.top_level = true
	draw_shape.color.a = 0.1
	add_child(draw_shape)

	cast_ray = Draw3D_Ray.new()
	cast_ray.global_mode = true
	cast_ray.head_size = 0.0
	add_child(cast_ray)

	block_ray = Draw3D_Ray.new()
	block_ray.global_mode = true
	block_ray.visible = false
	block_ray.head_size = 0.0
	block_ray.color.a = 0.1
	add_child(block_ray)

	normals_multimesh = Draw3D_MultiMesh.new()
	normals_multimesh.top_level = true
	normals_multimesh.mesh = ARROW_MESH
	normals_multimesh.size = 0.25
	add_child(normals_multimesh)


@export_range(0.0, 1.0, 0.01, "or_greater") var head_size : float = 0.25 :
	get: return normals_multimesh.size
	set(value): normals_multimesh.size = value

@export_range(0.0, 1.0, 0.01) var block_opacity : float = 0.1 :
	get: return block_ray.color.a			/ color.a
	set(value):
		block_ray.color.a = value	* color.a
		draw_shape.color.a = block_ray.color.a

func _get_color() -> Color:
	return cast_ray.color
func _set_color(value: Color) -> void:
	draw_shape.color = value * Color(1, 1, 1, block_opacity)
	block_ray.color = value * Color(1, 1, 1, block_opacity)
	cast_ray.color = value
	normals_multimesh.color = value


func _ready() -> void:
	if get_parent() is ShapeCast3D:
		draw_shape.shape = get_parent().shape


func _process(delta: float) -> void:
	if get_parent() is ShapeCast3D:
		_update_from_parent()

func update_from_rest(query: PhysicsShapeQueryParameters3D, rest: Dictionary) -> void:
	_update_internal(
		not rest.is_empty(),
		0.0,
		query.transform.origin,
		query.transform.origin + query.motion,
		[ rest.get(&"point") ],
		[ rest.get(&"normal") ]
	)

	draw_shape.basis = query.transform.basis

func _update_from_parent() -> void:
	var parent : ShapeCast3D = get_parent()

	var points := PackedVector3Array()
	points.resize(parent.get_collision_count())
	var normals := PackedVector3Array()
	normals.resize(points.size())

	for i in points.size():
		points[i] = parent.get_collision_point(i)
		normals[i] = parent.get_collision_normal(i)

	_update_internal(
		parent.is_colliding(),
		parent.get_closest_collision_safe_fraction(),
		parent.global_position,
		parent.to_global(parent.target_position),
		points,
		normals
	)

	draw_shape.basis = parent.global_basis

func _update_internal(is_colliding: bool, fraction: float, global_origin: Vector3, global_target: Vector3, global_points: PackedVector3Array, global_normals: PackedVector3Array) -> void:
	var shape_midpoint := global_origin.lerp(global_target, fraction) if is_colliding else global_target

	draw_shape.position = shape_midpoint

	# cast_ray.origin = global_origin
	# cast_ray.target = shape_midpoint
	cast_ray.position = global_origin
	cast_ray.target = shape_midpoint - global_origin

	block_ray.visible = is_colliding
	# block_ray.origin = shape_midpoint
	# block_ray.target = global_target
	block_ray.position = shape_midpoint
	block_ray.target = global_target - shape_midpoint

	var normal_transforms : Array[Transform3D] = []
	normal_transforms.resize(global_points.size())
	for i in normal_transforms.size():
		normal_transforms[i] = Transform3D(
			Basis.looking_at(
				global_normals[i],
				Vector3.FORWARD if absf(global_normals[i].y) == 1.0 else Vector3.UP
			) * \
			Basis(Vector3.RIGHT, deg_to_rad(-90.0)),
			global_points[i] + global_normals[i] * head_size * 0.5
		)
	normals_multimesh.transforms = normal_transforms

@tool class_name Draw3D_MultiMesh extends Draw3D

var multimesh_inst : MultiMeshInstance3D

func _init() -> void:
	super._init()

	multimesh_inst = MultiMeshInstance3D.new()
	multimesh_inst.multimesh = MultiMesh.new()
	multimesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_inst.material_override = DEFAULT_MATERIAL
	multimesh_inst.set_instance_shader_parameter(&"color", DEFAULT_COLOR)
	multimesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(multimesh_inst, false, INTERNAL_MODE_BACK)


func _get_color() -> Color:
	return multimesh_inst.get_instance_shader_parameter(&"color")
func _set_color(value: Color) -> void:
	multimesh_inst.set_instance_shader_parameter(&"color", value)

@export var mesh : Mesh :
	get: return multimesh_inst.multimesh.mesh
	set(value): multimesh_inst.multimesh.mesh = value

var _transforms : Array[Transform3D]
var transforms : Array[Transform3D] :
	get: return _transforms
	set(value):
		_transforms = value
		_refresh_multimesh()

var sizes : PackedFloat32Array:
	get:
		var result := PackedFloat32Array()
		result.resize(_transforms.size())
		for i in _transforms.size():
			result[i] = _transforms[i].basis.get_scale().x
		return result
	set(value):
		_transforms.resize(value.size())
		for i in value.size():
			_transforms[i] = Transform3D(
				Basis.from_scale(Vector3.ONE * value[i]),
				_transforms[i].origin
			)
		_refresh_multimesh()

var _size : float = 1.0
@export_range(0.0, 1.0, 0.01, "or_greater") var size : float = 1.0 :
	get: return _size
	set(value):
		_size = value
		_refresh_multimesh()

@export var points : PackedVector3Array :
	get:
		var result := PackedVector3Array()
		result.resize(_transforms.size())
		for i in _transforms.size():
			result[i] = _transforms[i].origin
		return result
	set(value):
		_transforms.resize(value.size())
		for i in value.size():
			_transforms[i].origin = value[i]
		_refresh_multimesh()

func _refresh_multimesh() -> void:
	multimesh_inst.multimesh.instance_count = _transforms.size() if not is_zero_approx(size) else 0
	for i in multimesh_inst.multimesh.instance_count:
		multimesh_inst.multimesh.set_instance_transform(i, _transforms[i].scaled_local(Vector3.ONE * size))

	# multimesh_inst.multimesh.instance_count = _points.size() if not is_zero_approx(size) else 0
	# for i in multimesh_inst.multimesh.instance_count:
	# 	multimesh_inst.multimesh.set_instance_transform(i, Transform3D(
	# 		Basis.from_scale(Vector3.ONE * size * (_sizes[i] if i < _sizes.size() else (_sizes[-1] if _sizes.size() != 0 else 1.0))),
	# 		_points[i]
	# 	))


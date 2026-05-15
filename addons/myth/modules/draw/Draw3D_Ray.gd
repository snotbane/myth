
@tool class_name Draw3D_Ray extends Draw3D

var head_offset : Node3D
var head_mesh_inst : Draw3D_Mesh
var line_mesh_inst : Draw3D_Line

func _init() -> void:
	super._init()

	head_offset = Node3D.new()
	add_child(head_offset, false, INTERNAL_MODE_BACK)

	head_mesh_inst = Draw3D_Mesh.new()
	head_mesh_inst.position.z = -0.5
	head_mesh_inst.rotation_degrees.x = -90.0
	head_mesh_inst.mesh = ARROW_MESH
	head_offset.add_child(head_mesh_inst, false, INTERNAL_MODE_BACK)

	line_mesh_inst = Draw3D_Line.new()
	line_mesh_inst.size = 0.0
	add_child(line_mesh_inst, false, INTERNAL_MODE_BACK)


@export var global_mode : bool :
	get: return top_level
	set(value):
		var t := transform
		top_level = value
		transform = t

@export var follow_parent : bool = false

var _head_size : float = 0.25
@export_range(0.0, 1.0, 0.01, "or_greater") var head_size : float = 0.25 :
	get: return _head_size
	set(value):
		_head_size = value
		_refresh()

var _origin : Vector3
@export var origin : Vector3 :
	get: return _origin
	set(value):
		_origin = value
		_refresh()

var _target : Vector3 = Vector3.FORWARD
@export var target : Vector3 = Vector3.FORWARD :
	get: return _target
	set(value):
		_target = value
		_refresh()

var _normal : Vector3
@export var normal : Vector3 :
	get: return _normal if origin.is_equal_approx(target) else (target - origin).normalized()
	set(value):
		if not value.is_zero_approx():
			_normal = value.normalized()
		target = origin + _normal * length

@export_range(0.0, 1.0, 0.01, "or_greater") var length : float = 1.0 :
	get: return origin.distance_to(target)
	set(value): target = origin + normal * value


func _get_color() -> Color:
	return head_mesh_inst.color
func _set_color(value: Color) -> void:
	head_mesh_inst.color = value
	line_mesh_inst.color = value


func _ready() -> void:
	super._ready()
	_refresh()


func _process(delta: float) -> void:
	if follow_parent:
		global_position = get_parent().global_position


func _refresh() -> void:
	if not is_inside_tree(): return

	if origin.is_equal_approx(target):
		line_mesh_inst.points = []

		head_offset.transform = Transform3D(Basis.from_scale(Vector3.ONE * head_size), origin)

		head_mesh_inst.mesh = POINT_MESH
		head_mesh_inst.position.z = 0.0

	else:
		var head_length := minf(length, head_size)
		var line_length := length - head_length

		var head_position := origin + normal * line_length
		if not is_zero_approx(line_length):
			line_mesh_inst.points = [ origin, head_position ]
		else:
			line_mesh_inst.points = []

		head_offset.scale = Vector3.ONE * head_length
		head_offset.position = head_position
		head_offset.look_at(
			head_offset.global_position + normal,
			Vector3.FORWARD if is_equal_approx(absf(normal.y), 1.0) else Vector3.UP
		)

		head_mesh_inst.mesh = ARROW_MESH
		head_mesh_inst.position.z = -0.5




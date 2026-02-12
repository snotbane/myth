
@tool class_name Draw3D_Shape extends Draw3D

var shape_mesh : Draw3D_Mesh

func _init() -> void:
	super._init()

	shape_mesh = Draw3D_Mesh.new()
	shape_mesh.mesh = null
	add_child(shape_mesh, false, INTERNAL_MODE_BACK)

func _get_color() -> Color:
	return shape_mesh.color
func _set_color(value: Color) -> void:
	shape_mesh.color = value

var _shape : Shape3D
@export var shape : Shape3D :
	get: return _shape
	set(value):
		if _shape != null and _shape.changed.is_connected(_refresh_shape):
			_shape.changed.disconnect(_refresh_shape)

		_shape = value if value != null else (get_parent().shape if get_parent() is CollisionShape3D else null)
		_refresh_shape()

		if _shape != null and not _shape.changed.is_connected(_refresh_shape):
			_shape.changed.connect(_refresh_shape)

func _refresh_shape() -> void:
	shape_mesh.mesh = _shape.get_debug_mesh() if _shape != null else null


func _enter_tree() -> void:
	if get_parent() is CollisionShape3D:
		shape = get_parent().shape

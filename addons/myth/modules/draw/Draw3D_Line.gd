
@tool class_name Draw3D_Line extends Draw3D

var line_mesh : Draw3D_Mesh
var points_multimesh : Draw3D_MultiMesh

func _init() -> void:
	super._init()

	line_mesh = Draw3D_Mesh.new()
	line_mesh.mesh = ImmediateMesh.new()
	add_child(line_mesh, false, INTERNAL_MODE_BACK)

	points_multimesh = Draw3D_MultiMesh.new()
	points_multimesh.mesh = POINT_MESH
	points_multimesh.size = 0.0
	add_child(points_multimesh, false, INTERNAL_MODE_BACK)

var _closed : bool = false
@export var closed : bool = false :
	get: return _closed
	set(value):
		_closed = value
		_refresh_line()

func _get_color() -> Color:
	return line_mesh.color
func _set_color(value: Color) -> void:
	line_mesh.color = value
	points_multimesh.color = value


@export var points : PackedVector3Array :
	get: return points_multimesh.points
	set(value):
		points_multimesh.points = value
		_refresh_line()
func _refresh_line() -> void:
	line_mesh.mesh.clear_surfaces()
	if points.size() <= 1: return

	line_mesh.mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in points.size():
		line_mesh.mesh.surface_add_vertex(points[i])
	if closed:
		line_mesh.mesh.surface_add_vertex(points[0])

	line_mesh.mesh.surface_end()

@export_range(0.0, 1.0, 0.01, "or_greater") var size : float :
	get: return points_multimesh.size
	set(value): points_multimesh.size = value


func _ready() -> void:
	_refresh_line()
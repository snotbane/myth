
@tool class_name Draw3D_Agent extends Draw3D

var line : Draw3D_Line
var host_point : Draw3D_Mesh

func _init() -> void:
	super._init()

	line = Draw3D_Line.new()
	add_child(line, false, INTERNAL_MODE_BACK)

	host_point = Draw3D_Mesh.new()
	host_point.size = 0.1
	add_child(host_point, false, INTERNAL_MODE_BACK)


func _get_color() -> Color:
	return line.color
func _set_color(value: Color) -> void:
	line.color = value
	host_point.color = value


@export_range(0.0, 1.0, 0.01, "or_greater") var host_size : float = 0.1 :
	get: return host_point.size
	set(value): host_point.size = value

var _point_size : float = 0.2
@export var point_size : float = 0.2 :
	get: return _point_size
	set(value):
		_point_size = value



@onready var _agent : NavigationAgent3D = get_parent()
@onready var _host : Node3D = _agent.get_parent()

func _ready() -> void:
	super._ready()

	if Engine.is_editor_hint(): return

	reparent.call_deferred(_host)


func _physics_process(delta: float) -> void:
	host_point.global_position = _host.global_position

	if Engine.is_editor_hint(): return

	if _agent.is_target_reached():
		if _agent is Brain3D:
			if _agent._travel_state == Brain3D.STOPPED:
				color = Color.BLUE
			else:
				color = Color.AQUAMARINE
		else:
			color = Color.BLUE
	elif _agent.is_navigation_finished():
		color = Color.RED
	else:
		color = Color.YELLOW

	if _agent == null: return

	var path_current_idx := _agent.get_current_navigation_path_index()
	var points := _agent.get_current_navigation_path()
	var sizes := PackedFloat32Array()
	sizes.resize(points.size())

	for i in points.size():
		sizes[i] = point_size * (1.0 if i >= path_current_idx else 0.25)

	points.push_back(_agent.target_position)
	sizes.push_back(_agent.target_desired_distance)

	if not Engine.is_editor_hint() and _agent is Brain3D and _agent.target.is_assigned:
		points.push_back(_agent.target.target_position)
		sizes.push_back(_agent.target_desired_distance)

	line.points = points
	line.points_multimesh.sizes = sizes


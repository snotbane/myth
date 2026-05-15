
@tool class_name Draw3D_Mesh extends Draw3D

const DEFAULT_SIZE := 1.0

var mesh_inst : MeshInstance3D

func _init() -> void:
	super._init()

	mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = POINT_MESH
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_inst.material_override = DEFAULT_MATERIAL
	mesh_inst.set_instance_shader_parameter(&"color", DEFAULT_COLOR)
	mesh_inst.scale = Vector3.ONE * DEFAULT_SIZE
	add_child(mesh_inst, false, INTERNAL_MODE_BACK)


@export var mesh : Mesh = POINT_MESH :
	get: return mesh_inst.mesh
	set(value): mesh_inst.mesh = value

func _get_color() -> Color:
	return mesh_inst.get_instance_shader_parameter(&"color")
func _set_color(value: Color) -> void:
	mesh_inst.set_instance_shader_parameter(&"color", value)


@export_range(0.0, 1.0, 0.01, "or_greater") var size : float = DEFAULT_SIZE :
	get: return mesh_inst.scale.x
	set(value): mesh_inst.scale = Vector3.ONE * value
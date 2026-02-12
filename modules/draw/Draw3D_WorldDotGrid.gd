
@tool class_name Draw3D_WorldDotGrid extends Draw3D

const MESH := preload("uid://pqjfvxv40wmq")
const MATERIAL := preload("uid://bm5n28m8boujc")

var mesh_inst : MeshInstance3D

func _init() -> void:
	super._init()

	mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = MESH
	mesh_inst.material_override = MATERIAL
	mesh_inst.set_instance_shader_parameter(&"base_color", DEFAULT_COLOR)
	mesh_inst.set_instance_shader_parameter(&"radius", 0.1)
	mesh_inst.set_instance_shader_parameter(&"spacing", 10.0)
	mesh_inst.set_instance_shader_parameter(&"range", 40.0)
	add_child(mesh_inst)

func _get_color() -> Color:
	return mesh_inst.get_instance_shader_parameter(&"color")
func _set_color(value: Color) -> void:
	mesh_inst.set_instance_shader_parameter(&"color", value)

@export_range(0.005, 1.0, 0.005, "or_greater") var size : float = 0.1 :
	get: return mesh_inst.get_instance_shader_parameter(&"radius")
	set(value): mesh_inst.set_instance_shader_parameter(&"radius", value)

@export_range(0.005, 10.0, 0.005, "or_greater") var spacing : float = 10.0 :
	get: return mesh_inst.get_instance_shader_parameter(&"spacing")
	set(value): mesh_inst.set_instance_shader_parameter(&"spacing", value)

@export_range(1.0, 100.0, 0.5, "or_greater") var range : float = 40.0 :
	get: return mesh_inst.get_instance_shader_parameter(&"range")
	set(value): mesh_inst.set_instance_shader_parameter(&"range", value)





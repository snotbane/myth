@tool
extends Node3D

@export
var face_forward: bool

@export
var color := Color.WHITE:
	set(value):
		color = value
		for child in get_children():
			child.set_instance_shader_parameter(&"color", value)
@export
var fixed_size: bool = true:
	set(value):
		fixed_size = value
		for child in get_children():
			child.set_instance_shader_parameter(&"fixed_size", value)
@export
var size: float = 0.25:
	set(value):
		size = value
		for child in get_children():
			child.set_instance_shader_parameter(&"size", value)


func _process(delta: float) -> void:
	if not face_forward:
		global_basis = Basis.IDENTITY

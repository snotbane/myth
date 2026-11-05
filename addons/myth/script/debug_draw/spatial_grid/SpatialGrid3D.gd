## Helper visual for displaying an infinite reference grid throughout the world.
@icon("res://addons/myth/script/debug_draw/spatial_grid/SpatialGrid3D.svg")
@tool
class_name SpatialGrid3D
extends VisualInstance3D

const MATERIAL_3D := preload("res://addons/myth/script/debug_draw/spatial_grid/SpatialGrid3D_material.tres")


var _visible_in_game: bool = false
## If enabled, become visible on ready in runtime. If disabled, this will be considered editor-only (but can still be toggled at runtime).
@export
var visible_in_game: bool = false:
	get: return _visible_in_game if Engine.is_editor_hint() else visible
	set(value):
		_visible_in_game = value
		if Engine.is_editor_hint(): return

		visible = _visible_in_game

## If enabled, do not destroy this Node in release builds.
@export
var release_enabled: bool = false


@export_group("Dots", "dot_")

## Dot color.
@export
var dot_color: Color = Color.WEB_GRAY:
	set(value):
		dot_color = value
		mesh_instance.set_instance_shader_parameter(&"dot_color", value)


## Dot size (radius).
@export_range(0.01, 1.0, 0.01, "or_greater")
var dot_size: float = 0.05:
	set(value):
		dot_size = value
		mesh_instance.set_instance_shader_parameter(&"dot_size", value)


## Dot separation.
@export_range(0.1, 100.0, 0.1, "or_greater")
var dot_spacing: float = 8.0:
	set(value):
		dot_spacing = value
		mesh_instance.set_instance_shader_parameter(&"dot_spacing", value)


## Distance at which dots become invisible. Increasing this valus also decreases precision.
@export_range(10.0, 100.0, 1.0, "or_greater")
var dot_range: float = 40.0:
	set(value):
		dot_range = value
		mesh_instance.set_instance_shader_parameter(&"dot_range", value)


## Returns true if we should exist. Returns false if we should be destroyed on ready.
var available: bool:
	get: return release_enabled or OS.is_debug_build()


var mesh_instance: Node


func _init() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3.ONE * 100.0
	mesh_instance.mesh.surface_set_material(0, MATERIAL_3D)
	mesh_instance.top_level = true
	mesh_instance.set_instance_shader_parameter(&"dot_color", dot_color)
	mesh_instance.set_instance_shader_parameter(&"dot_size", dot_size)
	mesh_instance.set_instance_shader_parameter(&"dot_spacing", dot_spacing)
	mesh_instance.set_instance_shader_parameter(&"dot_range", dot_range)

	add_child(mesh_instance)


func _ready() -> void:
	if not available:
		queue_free()
	elif not Engine.is_editor_hint():
		visible = visible_in_game


func _process(delta: float) -> void:
	if mesh_instance is Node3D:
		if Engine.is_editor_hint():
			mesh_instance.global_position = Myth.editor_interface_safe.get_editor_viewport_3d().get_camera_3d().global_position
		else:
			mesh_instance.global_position = get_viewport().get_camera_3d().global_position

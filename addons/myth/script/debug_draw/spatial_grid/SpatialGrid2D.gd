@icon("res://addons/myth/script/debug_draw/spatial_grid/SpatialGrid2D.svg")
@tool
class_name SpatialGrid2D
extends Node2D

const MATERIAL_2D := preload("res://addons/myth/script/debug_draw/spatial_grid/SpatialGrid2D_material.tres")


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
@export_range(1.0, 40.0, 0.01, "or_greater")
var dot_size: float = 5.0:
	set(value):
		dot_size = value
		mesh_instance.set_instance_shader_parameter(&"dot_size", value)


## Dot separation.
@export_range(1.0, 256.0, 0.1, "or_greater")
var dot_spacing: float = 128.0:
	set(value):
		dot_spacing = value
		mesh_instance.set_instance_shader_parameter(&"dot_spacing", value)


## Returns true if we should exist. Returns false if we should be destroyed on ready.
var available: bool:
	get: return release_enabled or OS.is_debug_build()


var mesh_instance: MeshInstance2D


func _init() -> void:
	mesh_instance = MeshInstance2D.new()
	mesh_instance.mesh = QuadMesh.new()
	mesh_instance.mesh.size = Vector2.ONE * 100.0
	mesh_instance.material = MATERIAL_2D
	mesh_instance.top_level = true
	mesh_instance.set_instance_shader_parameter(&"dot_color", dot_color)
	mesh_instance.set_instance_shader_parameter(&"dot_size", dot_size)
	mesh_instance.set_instance_shader_parameter(&"dot_spacing", dot_spacing)

	add_child(mesh_instance)


func _ready() -> void:
	if not available:
		queue_free()
	elif not Engine.is_editor_hint():
		visible = visible_in_game


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		var editor_viewport_2d: Viewport = Myth.editor_interface_safe.get_editor_viewport_2d()

		var editor_global_transform_2d := editor_viewport_2d.global_canvas_transform
		editor_global_transform_2d.origin /= -editor_global_transform_2d.get_scale()
		editor_global_transform_2d.origin += Vector2(editor_viewport_2d.size) / (editor_global_transform_2d.get_scale() * 2.0)

		mesh_instance.global_position = editor_global_transform_2d.origin
		mesh_instance.global_rotation = editor_global_transform_2d.get_rotation()
		mesh_instance.mesh.size = Vector2(get_viewport().size) / editor_global_transform_2d.get_scale()

		mesh_instance.set_instance_shader_parameter(&"camera_position_world", editor_global_transform_2d.origin)
		mesh_instance.set_instance_shader_parameter(&"camera_rotation_world", editor_global_transform_2d.get_rotation())
		mesh_instance.set_instance_shader_parameter(&"camera_scale", editor_global_transform_2d.get_scale())

	else:
		var viewport := get_viewport()
		var camera := viewport.get_camera_2d()

		mesh_instance.global_position = camera.global_position
		mesh_instance.global_rotation = camera.global_rotation
		mesh_instance.mesh.size = Vector2(viewport.size) / camera.zoom

		mesh_instance.set_instance_shader_parameter(&"camera_position_world", camera.global_position)
		mesh_instance.set_instance_shader_parameter(&"camera_rotation_world", camera.global_rotation)
		mesh_instance.set_instance_shader_parameter(&"camera_scale", camera.zoom)

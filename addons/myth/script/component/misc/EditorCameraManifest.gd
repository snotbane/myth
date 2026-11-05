## Keeps track of the editor camera in the scene in which it is placed, and allows you to, for example, move your player character to its position on ready, allowing for easier testing. Editor-only.
@tool
@icon("res://addons/myth/script/component/misc/EditorCameraManifest.svg")
class_name EditorCameraManifest
extends Component

@export_group("Create Ghost", "ghost_")


## If enabled, start in Debug Ghost mode.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var ghost_enabled: bool = false

@export_group("Play From View", "affect_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var affect_enabled: bool = true

## If this value is set (and the [Component] is enabled), [member affect_position_node] will be moved to the editor camera's global position on ready.
@export
var affect_position_node: Node

## These axes will affect [member affect_position_node]'s global position if enabled.
@export_flags("X", "Y", "Z")
var affect_position_axes: int = 7

## [3D Only] If this value is set (and the [Component] is enabled), [member affect_rotation_node] will be rotated to the editor camera's global rotation on ready.
@export
var affect_rotation_node: Node

## These axes will affect [member affect_position_node]'s global rotation if enabled.
@export_flags("X", "Y", "Z")
var affect_rotation_axes: int = 7


var editor_camera_3d: Camera3D
@export_storage
var editor_global_transform_3d: Transform3D

var editor_viewport_2d: SubViewport
@export_storage
var editor_global_transform_2d: Transform2D


func _init() -> void:
	if OS.has_feature("template"):
		queue_free()


func _ready() -> void:
	if Engine.is_editor_hint():
		editor_camera_3d = Myth.editor_interface_safe.get_editor_viewport_3d().get_camera_3d()
		editor_viewport_2d = Myth.editor_interface_safe.get_editor_viewport_2d()

	elif enabled and affect_enabled and OS.has_feature("editor_runtime"):
		_activate.call_deferred()

	else:
		queue_free()


func _process(delta: float) -> void:
	if editor_camera_3d:
		editor_global_transform_3d = editor_camera_3d.global_transform

	if editor_viewport_2d:
		editor_global_transform_2d = editor_viewport_2d.global_canvas_transform
		editor_global_transform_2d.origin *= -1.0
		editor_global_transform_2d.origin += editor_viewport_2d.size * 0.5


func _activate() -> void:
	if affect_position_node is Node3D:
		affect_position_node.global_position = Vector3(
			editor_global_transform_3d.origin.x if affect_position_axes & 1 else affect_position_node.global_position.x,
			editor_global_transform_3d.origin.y if affect_position_axes & 2 else affect_position_node.global_position.y,
			editor_global_transform_3d.origin.z if affect_position_axes & 4 else affect_position_node.global_position.z,
		)

	elif affect_position_node is Node2D:
		affect_position_node.global_position = Vector2(
			editor_global_transform_2d.origin.x if affect_position_axes & 1 else affect_position_node.global_position.x,
			editor_global_transform_2d.origin.y if affect_position_axes & 2 else affect_position_node.global_position.y,
		)

	else:
		assert(affect_position_node == null, "EditorCameraManifest.affect_position_node must be a Node3D or Node2D (or null).")

	if affect_rotation_node is Node3D:
		var global_rotation: Vector3 = editor_global_transform_3d.basis.get_euler()
		affect_rotation_node.global_rotation = Vector3(
			global_rotation.x if affect_rotation_axes & 1 else affect_rotation_node.global_rotation.x,
			global_rotation.y if affect_rotation_axes & 2 else affect_rotation_node.global_rotation.y,
			global_rotation.z if affect_rotation_axes & 4 else affect_rotation_node.global_rotation.z,
		)

	else:
		assert(affect_rotation_node == null, "EditorCameraManifest.affect_rotation_node must be a Node3D or Node2D (or null).")

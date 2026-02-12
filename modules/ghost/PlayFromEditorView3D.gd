## Moves a node (e.g. the player) to match the editor's view on game start. Use [member visible] to toggle whether or not this functionality is active. Only works once and in editor runtime.
@tool class_name PlayFromEditorView3D extends Node3D

## If enabled, this node will spawn a [Ghost3D] node on startup.
@export var start_in_debug_ghost_mode : bool = false

## If enabled, [member position_node] will be moved to this node on [method _ready] (i.e. the editor viewport center).
@export var transform_selected_nodes : bool = true

## If set, this node will move to the editor view transform on [methos _ready]. Set this to your player's base node.
@export var position_node : Node3D

## If set, this node will match the editor's view pitch.
@export var rotation_node_x : Node3D

## If set, this node will match the editor's view yaw. It is very common to set this to the same node as position_node.
@export var rotation_node_y : Node3D


func _ready() -> void:
	if OS.has_feature("editor_runtime") and visible:
		if transform_selected_nodes:
			activate()

		if start_in_debug_ghost_mode:
			create_ghost.call_deferred(get_parent(), global_transform)
	if not Engine.is_editor_hint(): queue_free()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return

	var editor_camera := EditorInterface.get_editor_viewport_3d().get_camera_3d()
	self.global_transform = editor_camera.global_transform


func activate() -> void:
	if position_node: position_node.global_position = self.global_position
	if rotation_node_x: rotation_node_x.global_rotation.x = self.global_rotation.x
	if rotation_node_y: rotation_node_y.global_rotation.y = self.global_rotation.y


func create_ghost(parent: Node, tform: Transform3D) -> void:
	Ghost3D.instantiate_from_camera(parent, parent.get_viewport().get_camera_3d(), tform)

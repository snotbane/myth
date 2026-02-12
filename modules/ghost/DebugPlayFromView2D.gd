## Moves a node (i.e. the player) to match the editor's view on game start. Toggle [member visible] to set whether or not this functionality is active. Only works once and in editor runtime.
@tool class_name DebugPlayFromView2D extends Node2D

## If enabled, this node will spawn a [DebugGhost2D] node on startup.
@export var start_in_debug_ghost_mode : bool = false

## If enabled, [member position_node] will be moved to this node on [method _ready] (i.e. the editor viewport center).
@export var transform_selected_nodes : bool = true

## If set, this node will move to the editor view transform on [methos _ready]. Set this to your player's base node.
@export var position_node : Node2D

## If set, this node will match the editor's view rotation.
@export var rotation_node : Node2D


func _ready() -> void:
	if OS.has_feature("editor_runtime") and visible:
		if transform_selected_nodes:
			activate()

		if start_in_debug_ghost_mode:
			create_ghost.call_deferred(get_parent(), global_transform)
	if not Engine.is_editor_hint(): queue_free()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return

	self.global_transform = EditorInterface.get_editor_viewport_2d().global_canvas_transform
	self.global_position = (-self.global_transform.origin / self.global_transform.get_scale()) + Vector2(EditorInterface.get_editor_viewport_2d().size) / (self.global_transform.get_scale() * 2.0)


func activate() -> void:
	if position_node: position_node.global_position = global_position
	if rotation_node: rotation_node.global_rotation = global_rotation


func create_ghost(parent: Node, tform: Transform2D) -> void:
	DebugGhost2D.instantiate_from_camera(parent, parent.get_viewport().get_camera_2d(), tform)

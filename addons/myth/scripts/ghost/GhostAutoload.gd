## Handles debug ghost nodes.
class_name GhostAutoload extends Node

static var ghost: Node:
	set(value):
		if ghost == value: return

		if ghost: ghost.queue_free()

		ghost = value


func _ready() -> void:
	TerminalCommandHost.create_command(&"ghost", toggle_ghost, 0, true, "Enters or exits debug ghost mode.")


func _input(event: InputEvent):
	if not OS.is_debug_build() or ghost != null: return
	if event.is_action_pressed(MythPlugin_Ghost.INPUT_GHOST_TOGGLE):
		create_ghost()
		get_viewport().set_input_as_handled()


func create_ghost(parent: Node = get_tree().root) -> Node:
	var result: Node

	if self.get_tree().current_scene is Node2D:
		result = Ghost2D.instantiate_from_parent(parent)

	elif self.get_tree().current_scene is Node3D:
		result = Ghost3D.instantiate_from_parent(parent)

	else:
		printerr("The current scene must be a Node2D or Node3D, in order to create a Ghost.")
		return null

	result.tree_exited.connect(clear_ghost)
	return result


func clear_ghost() -> void:
	ghost = null


func toggle_ghost() -> void:
	ghost = null if ghost else create_ghost()

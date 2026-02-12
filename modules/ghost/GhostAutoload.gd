
class_name GhostAutoload extends Node


var ghost : Node


func _ready() -> void:
	TerminalCommandHost.create_command(&"ghost", toggle_ghost, 0, true, "Enters or exits debug ghost mode.")


func _input(event: InputEvent):
	if not OS.is_debug_build() or ghost != null: return
	if event.is_action_pressed(MythPlugin_Ghost.INPUT_GHOST_TOGGLE):
		create_ghost()
		get_viewport().set_input_as_handled()


func create_ghost(parent: Node = get_tree().root) -> void:
	if ghost: printerr("Ghost %s already exists. Can't spawn a new one." % ghost); return
	if self.get_tree().current_scene is Node2D:
		ghost = Ghost2D.instantiate_from_camera(parent)
		self.get_tree().root.add_child(ghost)
	elif self.get_tree().current_scene is Node3D:
		ghost = Ghost3D.instantiate_from_camera(parent)
	ghost.tree_exited.connect(clear_ghost)


func clear_ghost() -> void:
	if ghost:
		ghost.queue_free()
	ghost = null


func toggle_ghost() -> void:
	if ghost:
		clear_ghost()
	else:
		create_ghost()

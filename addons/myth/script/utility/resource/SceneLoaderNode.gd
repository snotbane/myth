## Simple [Node] that loads a scene and can change to it.
@icon("res://addons/myth/script/utility/resource/SceneLoaderNode.svg")
class_name SceneLoaderNode
extends ResourceLoaderNode

## If the parent is a [Button], that button's [Button.pressed] signal will automatically be set up to switch to this scene.
@export
var auto_handle_parent_button: bool = true

func _ready() -> void:
	if get_parent() is BaseButton:
		get_parent().pressed.connect(load_threaded_and_change_scene)


func load_threaded_and_change_scene(path: String = resource_path):
	var err : int = await load_threaded(path)
	if err == OK:
		get_tree().change_scene_to_packed(resource)


func load_blocked_and_change_scene(path: String = resource_path) -> void:
	load_blocked(path)
	get_tree().change_scene_to_packed(resource)

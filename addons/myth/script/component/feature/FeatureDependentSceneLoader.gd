## Effectively an [InstancePlaceholder], this node loads a scene depending on the OS features and instantiates it in this node's place. This is primarily used in situations where a scene resource will be present/missing on certain platforms, and using a [PackedScene] as a [Node] instance in another scene's tree would result in an error on the target platform. For all other use cases, prefer [FeatureDependency].
class_name FeatureDependentSceneLoader
extends FeatureDependency

@export_file("*.tscn", "*.scn", "*.res")
var scene_path: String


func _activate(active: bool) -> void:
	if not active: return

	var scene: PackedScene = load(scene_path)
	var node: Node = scene.instantiate()

	parent.add_child.call_deferred(node)
	parent.move_child.call_deferred(node, get_index())

## Adds a hook for a [Resource] such that it can be treated like a [Node].
class_name ResourceNode extends Node

signal resource_changed

var _resource: Resource
@export var resource: Resource:
	get: return _resource if _resource else fallback_resource
	set(value):
		if _resource == value: return

		if _resource:
			_resource.changed.disconnect(emit_resource_changed)

		_resource = value

		if _resource:
			_resource.changed.connect(emit_resource_changed)

		emit_resource_changed()


var fallback_resource: Resource:
	get: return fallback_node.resource if fallback_node else null

var fallback_node: ResourceNode

@export_enum("None", "Ancestor", "Descendant") var fallback_type: int:
	set(value):
		fallback_type = value
		if not is_node_ready(): return

		if fallback_node:
			fallback_node.resource_changed.disconnect(fallback_resource_changed)

		match value:
			0: fallback_node = null
			1: fallback_node = Myth.find_ancestor_sibling_of_type(self , "ResourceNode", true)
			2: fallback_node = Myth.find_descendant_of_type(self , "ResourceNode", true)

		if fallback_node:
			fallback_node.resource_changed.connect(fallback_resource_changed)

		fallback_resource_changed()


func _ready() -> void:
	fallback_type = fallback_type

	if _resource:
		emit_resource_changed()

func fallback_resource_changed() -> void:
	if _resource: return
	emit_resource_changed()
func emit_resource_changed() -> void:
	_resource_changed()
	resource_changed.emit()
func _resource_changed() -> void:
	pass

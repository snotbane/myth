## Allows the parent node to be accessed from anywhere in script (provided that it exists), using [member Global.find].
@icon("res://addons/myth/script/component/misc/Global.svg")
class_name Global
extends Component

static var REGISTRY: Dictionary[StringName, Node]


## Returns a [Node] if it exists in the global registry. NOTE: [Global]s are added sequentially, so node order matters. To wait for a node to exist, use [member find_lazy].
static func find(node_name: StringName) -> Node:
	return REGISTRY.get(node_name)


## Searches for a [Global] in the registry. If it does not exist, try again each [param callback_interval], which should be a [Signal] or a [Callable]. Easiest implementation is to set this to [get_tree().process_frame].
static func find_lazy(node_name: StringName, interval):
	var result := find(node_name)
	while result == null:
		await interval
		result = find(node_name)
	return result


func _ready() -> void:
	enabled_changed.connect(func() -> void:
		if enabled:
			REGISTRY[parent.name] = parent
		else:
			REGISTRY.erase(parent.name)
	)

	if enabled:
		REGISTRY[parent.name] = parent

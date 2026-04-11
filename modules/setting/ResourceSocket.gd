## Keeps track of a set of [Setting]s and stores their contents inside a [Resource]. The names of the nodes must match the properties of the [Resource].
class_name ResourceSocket extends Node


const STORAGE_DIR := "user://"


static func _get_settings(node: Node) -> Array[Setting]:
	var result : Array[Setting] = []
	for child in node.get_children():
		if child is Setting:
			result.push_back(child)
		result.append_array(_get_settings(child))
	return result


static func find_ancestor(node: Node, include_internal: bool = false) -> ResourceSocket:
	var parent := node
	while parent != null:
		var result : ResourceSocket = Myth.find_child_of_type(parent, "ResourceSocket", include_internal)
		if result == null:
			parent = parent.get_parent()
			continue
		else:
			return result
	return null



## Emits when the value of [member resource] is changed to a different [Resource].
signal resource_value_changed(new_resource: Resource)

## Emits when [member resource]'s [member Resource.changed] is emitted.
signal resource_changed


var _resource : Resource
## The resource to be modified. If not set, no resource will be used and all data will be stored inside a separate, generic [JsonResource].
@export var resource : Resource :
	get: return _resource
	set(value):
		var value_changed : bool = _resource != value

		if _resource:
			_resource.changed.disconnect(resource_changed.emit)
			for sig in resource_signals.keys():
				for callable in resource_signals[sig]:
					_resource.disconnect(sig, callable)

		_resource = value

		if _resource:
			_resource.changed.connect(resource_changed.emit)
			for sig in resource_signals.keys():
				for callable in resource_signals[sig]:
					_resource.connect(sig, callable)

		if value_changed:
			resource_value_changed.emit(resource)
			resource_changed.emit()

func set_resource(value: Resource) -> void:
	resource = value


func resource_callv(method: StringName, args: Array = []) -> void:
	resource.callv(method, args)

var resource_signals : Dictionary[StringName, Array]

## Connect one of the resource's signals to a callable. If the resource changes later, the connection will be transferred to the new value of [member resource]. This will work even if [member resource] is currently unset.
func connect_resource_signal(sig: StringName, callable: Callable) -> void:
	if not resource_signals.has(sig):
		resource_signals[sig] = []
	resource_signals[sig].push_back(callable)

	if resource:
		resource.connect(sig, callable)

## Disconnect one of the resource's signals to a callable.
func disconnect_resource_signal(sig: StringName, callable: Callable) -> void:
	assert(resource_signals.has(sig), "Can't disconnect a signal name that does not exist.")
	resource_signals[sig].erase(callable)
	if resource_signals[sig].is_empty():
		resource_signals.erase(sig)

	if resource:
		resource.disconnect(sig, callable)


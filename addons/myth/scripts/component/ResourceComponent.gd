## Adds a hook for a [Resource] such that it can be treated like a [Node].
class_name ResourceComponent extends Component


static func get_nearest_ancestor_sibling(node: Node, type: String = "ResourceComponent") -> ResourceComponent:
	return Myth.find_ancestor_sibling_of_type(node, type, true)


static func get_nearest_descendent(node: Node, type: String = "ResourceComponent") -> ResourceComponent:
	return Myth.find_descendant_of_type(node, type, true)


## Adds a child [ResourceComponent] to the given [param node]. If the [param node] has a member function [member _resource_changed], it will be connected to the child's [member resource_changed] signal.
static func add_child_socket(node: Node, fallback_type: int = 2) -> ResourceComponent:
	var result := ResourceComponent.new()
	result.fallback_type = fallback_type
	node.add_child(result)
	if node.has_method(&"_resource_changed"):
		result.resource_changed.connect(node._resource_changed)
	return result


signal resource_changed


var _resource: Resource
@export var resource: Resource:
	get: return _resource if _resource else fallback_resource
	set(value):
		if _resource is JsonResource and json_enabled and json_auto_save & 1:
			_resource.save()

		if _resource:
			_resource.changed.disconnect(on_resource_changed)
			for sig in resource_signals:
				for callable: Callable in resource_signals[sig]:
					_resource.disconnect(sig, callable)

		_resource = value

		if _resource:
			_resource.changed.connect(on_resource_changed)
			for sig in resource_signals:
				for callable: Callable in resource_signals[sig]:
					_resource.connect(sig, callable)

		if _resource is JsonResource and json_enabled and json_auto_touch & 1:
			_resource.touch()

		on_resource_changed()


## If [member resource] is not set, it will refer to this [Node]'s [member resource] instead.
@export_enum("None", "Closest Descendant", "Closest Parent", "Closest Ancestor") var fallback_type: int = 3:
	set(value):
		fallback_type = value
		if not is_node_ready(): return

		if fallback_node:
			fallback_node.resource_changed.disconnect(on_fallback_resource_changed)

		match value:
			0: fallback_node = null
			1: fallback_node = Myth.find_descendant_of_type(self , "ResourceComponent", true)
			2: fallback_node = Myth.find_ancestor_sibling_of_type(self , "ResourceComponent", true, false)
			3: fallback_node = Myth.find_ancestor_sibling_of_type(self , "ResourceComponent", true, true)

		if fallback_node:
			fallback_node.resource_changed.connect(on_fallback_resource_changed)

		on_fallback_resource_changed()


@export_enum("Do Nothing", "Hide Parent", "Show Parent") var when_resource_is_null: int = 0


@export_group("JsonResource", "json_")

## If enabled, the below properties will be considered when handling [JsonResource]s. Otherwise, handle all [Resource]s the same way.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var json_enabled: bool = true

## Determines when [JsonResource]s should be saved.
@export_flags("On Resource Change:1", "On Exit Tree:2") var json_auto_save: int = 3

## Determines when [JsonResource]s should be touched.
@export_flags("On Resource Change:1") var json_auto_touch: int = 1


var fallback_node: ResourceComponent
var fallback_resource: Resource:
	get: return fallback_node.resource if fallback_node else null

var resource_signals: Dictionary[StringName, Array]


func _ready() -> void:
	fallback_type = fallback_type


func _exit_tree() -> void:
	if _resource is JsonResource and json_enabled and json_auto_save & 2:
		_resource.save()


func emit_resource_changed() -> void:
	if resource == null: return
	resource.changed.emit()
func on_fallback_resource_changed() -> void:
	if _resource != null: return
	on_resource_changed()
func on_resource_changed() -> void:
	if not enabled: return

	match when_resource_is_null:
		1: get_parent().visible = resource != null
		2: get_parent().visible = resource == null

	_resource_changed()
	resource_changed.emit()
func _resource_changed() -> void: pass


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

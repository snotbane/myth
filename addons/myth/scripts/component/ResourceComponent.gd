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


## Emits when the value of [member resource] is changed, or if [member resource.changed] is emitted.
signal resource_changed


var _resource: Resource
@export var resource: Resource:
	get: return _resource if _resource else fallback_resource
	set(value):
		auto_save_if(2)

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

		auto_touch_if(1)

		on_resource_changed()


## If [member resource] is not set, use the [Resource] used in this [ResourceComponent].
@export var fallback_component: ResourceComponent:
	set(value):
		if not is_node_ready():
			await ready

		if fallback_component:
			fallback_component.resource_changed.disconnect(on_fallback_resource_changed)

		fallback_component = value

		if fallback_component:
			fallback_component.resource_changed.connect(on_fallback_resource_changed)

		on_fallback_resource_changed()

var fallback_resource: Resource:
	get: return fallback_component.resource if fallback_component else null


## If [member fallback_component] is not set, use the [Resource] in the [ResourceComponent] found using this method.
@export_enum("None", "Closest Parent or Ancestor", "Closest Descendant") var fallback_type: int = 0:
	set(value):
		fallback_type = value

		if not is_node_ready():
			await ready

		match value:
			0: fallback_component = null
			1: fallback_component = Myth.find_ancestor_sibling_of_type(self, "ResourceComponent", true, false)
			2: fallback_component = Myth.find_descendant_of_type(self, "ResourceComponent", true)


@export_enum("Do Nothing", "Hide Parent", "Show Parent") var when_resource_is_null: int = 0


@export_group("JsonResource", "json_")

## If enabled, the below properties will be considered when handling [JsonResource]s. Otherwise, handle all [Resource]s the same way. NOTE: This only takes effect if [member resource] is directly set (i.e. not a fallback).
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var json_enabled: bool = true

## Determines when [JsonResource]s should be saved. This only occurs if [member resource] is directly set (i.e. not using a fallback).
@export_flags("On Exit Tree:1", "On Resource Set:2") var json_auto_save: int = 3

func auto_save_if(flag: int) -> void:
	if json_enabled and json_auto_save & flag and _resource is JsonResource:
		_resource.save()

## Determines when [JsonResource]s should be touched. This only occurs if [member resource] is directly set (i.e. not using a fallback).
@export_flags("On Resource Set:1") var json_auto_touch: int = 1

func auto_touch_if(flag: int) -> void:
	if json_enabled and json_auto_touch & flag and _resource is JsonResource:
		_resource.touch()


var resource_signals: Dictionary[StringName, Array]


func _ready() -> void:
	fallback_type = fallback_type


func _exit_tree() -> void:
	auto_save_if(1)


func emit_resource_changed() -> void:
	if resource == null: return
	resource.emit_changed()
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


## Calls a method on [member resource]. If it is currently unset, nothing will happen.
func call_resource_method(method: StringName, args) -> void:
	if resource == null: return

	resource.callv(method, args if args is Array else [args])

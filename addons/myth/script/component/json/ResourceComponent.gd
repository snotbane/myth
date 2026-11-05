## A hook for a [Resource] such that it can be treated like a [Node].
@icon("res://addons/myth/script/component/json/ResourceComponent.svg")
class_name ResourceComponent
extends Component

## Emitted when the value of [member resource] is changed, or if [member resource.changed] is emitted.
signal resource_changed


var _resource: Resource
## The [Resource] which this node interfaces with. If unset see [member fallback_enabled].
@export
var resource: Resource:
	get: return _resource if _resource or not fallback_enabled else fallback.resource
	set(value):
		if _resource == value: return

		if _resource:
			_resource.changed.disconnect(_on_resource_changed)
			for sig in resource_signals:
				for callable: Callable in resource_signals[sig]:
					_resource.disconnect(sig, callable)

		_resource = value

		if _resource:
			_resource.changed.connect(_on_resource_changed)
			for sig in resource_signals:
				for callable: Callable in resource_signals[sig]:
					_resource.connect(sig, callable)

		# auto_load_if(1)

		resource_changed.emit()


@export_enum("Ignore", "Show Parent", "Hide Parent")
var when_resource_is_null: int = 0


func emit_resource_changed() -> void:
	if resource == null: return
	resource.emit_changed()

func _on_resource_changed() -> void:
	if not enabled: return

	match when_resource_is_null:
		1: parent.visible = resource == null
		2: parent.visible = resource != null

	_resource_changed()
	resource_changed.emit()

## Override method.
func _resource_changed() -> void: pass


#region Fallback

@export_group("Fallback", "fallback_")

## If enabled, [member resource] will default to a fallback [ResourceComponent] if none is explicitly specified.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var fallback_enabled: bool = true

## Custom component to fallback to. If unset, the fallback component chosen will always be the first [ResourceComponent] child, in the ancestor closest to [member parent], recursively.
@export
var fallback_custom: ResourceComponent:
	get: return fallback
	set(value): fallback = value


var fallback: ResourceComponent:
	set(value):
		if fallback:
			fallback.resource_changed.disconnect(_on_fallback_changed)

		fallback = value

		if fallback:
			fallback.resource_changed.connect(_on_fallback_changed)

		_on_fallback_changed()


func _on_fallback_changed() -> void:
	if _resource != null: return
	_on_resource_changed()

#endregion


#region JsonResource

@export_group("JsonResource", "json_")

## If enabled, the below properties will be considered when handling [JsonResource]s. Otherwise, handle all [Resource]s the same way. NOTE: This only takes effect if [member resource] is directly set (i.e. not a fallback).
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var json_enabled: bool = true


## Determines when [JsonResource]s should be loaded. This only occurs if [member resource] is directly set (i.e. not using a fallback). NOTE: this will actually touch the file, creating it if it doesn't already exist.
@export_flags("On Resource Set:1")
var json_auto_load: int = 1


## Determines when [JsonResource]s should be saved. This only occurs if [member resource] is directly set (i.e. not using a fallback).
@export_flags("On Exit Tree:1", "On Resource Set:2")
var json_auto_save: int = 3


# func auto_save_if(flag: int) -> void:
# 	if json_enabled and json_auto_save & flag and _resource is JsonResource:
# 		_resource.save()


# func auto_touch_if(flag: int) -> void:
# 	if json_enabled and json_auto_touch & flag and _resource is JsonResource:
# 		_resource.touch()


#endregion

func _ready() -> void:
	super._ready()

	if fallback_custom == null:
		fallback = Myth.find_ancestor_sibling_of_type(parent, "ResourceComponent", true, false)


# func _exit_tree() -> void:
# 	auto_save_if(1)


# func _notification(what: int) -> void:
# 	match what:
# 		NOTIFICATION_WM_CLOSE_REQUEST:
# 			auto_save_if(1)


## Calls a method on [member resource]. If it is currently unset, nothing will happen.
func call_resource_method(method: StringName, args) -> void:
	if resource == null: return

	resource.callv(method, args if args is Array else [args])


#region Signals

var resource_signals: Dictionary[StringName, Array]

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

#endregion

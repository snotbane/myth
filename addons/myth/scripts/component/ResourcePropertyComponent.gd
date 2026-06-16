## Allows the end user to set the properties of a [Resource] during runtime.
##
## Designed by Bastian Weaver of Nemonix Software, 2026.
## This code is open to the public domain and 100% free to use and/or modify.
##
class_name ResourcePropertyComponent extends ResourceComponent


## Emitted when the property is modified by [member target_node], regardless of [member resource_emit_changed].
signal property_changed(new_value: Variant)


@export_subgroup("Resource", "resource_")

## The name of the property to read/write in the [member resource]. If blank, this will default to [member node_target]'s name.
@export var resource_property_name: StringName


## If enabled, [member resource_changed] will be emitted whenever the property is modified by [member target_node]. This does NOT affect if [member property_changed] is emitted. Usually you'll want this disabled if you have a separate mechanism for saving the resource.
@export var resource_emit_changed: bool = true


@export_subgroup("Node", "node_")

## The target node to read/write. If blank, this will default to this [Node]'s immediate parent.
@export var node_target: Node


## The name of the property to read/write in the [member node_target]. If blank, this will default to the [member name] of this [Node].
@export var node_property_name: StringName


## If this signal is emitted from [member node_target], this will set the [member resource]'s value to match the signal's return value. The signal's return value should be the same type as [member resource_proeprty_name]. If empty, this [Node] cannot affect [member resource] at all and is considered read-only.
@export var node_property_signal: StringName:
	set(value):
		if not is_node_ready():
			await ready

		if not node_property_signal.is_empty() and node_target.is_connected(node_property_signal, _set_property_internal):
			node_target.disconnect(node_property_signal, _set_property_internal)

		node_property_signal = value

		if not node_property_signal.is_empty() and not node_target.is_connected(node_property_signal, _set_property_internal):
			node_target.connect(node_property_signal, _set_property_internal)


var property_value: Variant:
	get: return resource.get(resource_property_name) if resource else null


var _is_setting_property: bool = false


func _ready() -> void:
	if node_target == null:
		node_target = parent

	if resource_property_name.is_empty():
		resource_property_name = node_target.name

	if node_property_name.is_empty():
		node_property_name = self.name

	super._ready()


func _resource_changed() -> void:
	if resource == null or not is_node_ready() or _is_setting_property: return

	var value = resource.get(resource_property_name)

	node_target.set(node_property_name, value)


func _get_configuration_warnings() -> PackedStringArray:
	var result := PackedStringArray()

	if resource_property_name.is_empty():
		result.push_back("resource_property_name must be set.")

	return result


func set_property(new_value: Variant) -> void:
	_set_property(true, new_value)
func set_property_no_signal(new_value: Variant) -> void:
	_set_property(false, new_value)
func _set_property_internal(new_value: Variant) -> void:
	_set_property(resource_emit_changed, new_value)
func _set_property(emit_signals: bool, new_value: Variant) -> void:
	if resource == null: return

	_is_setting_property = true

	resource.set(resource_property_name, new_value)
	property_changed.emit(new_value)
	if emit_signals:
		emit_resource_changed()

	_is_setting_property = false

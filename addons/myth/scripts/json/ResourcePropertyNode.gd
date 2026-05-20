## Allows the end user to set the properties of a [Resource] during runtime.
##
## Designed by Bastian Weaver of Nemonix Software, 2026.
## This code is open to the public domain and 100% free to use and/or modify.
##
class_name ResourcePropertyNode extends ResourceNode

static var AUTO_PROPERTIES: Dictionary = {
	&"icon": [&"Texture2D", &"icon_changed"],
	&"text": [&"String", &"text_changed"],
	&"value": [&"int", &"value_changed"],
	&"selected": [&"int", &"item_selected"],
	&"action": [&"Dictionary", &"action_changed"]
}

static func add_auto_property(prop_name: StringName, prop_type: StringName, signal_name: StringName):
	AUTO_PROPERTIES[prop_name] = [prop_type, signal_name]


## Emitted when the property is modified by [member target_node], regardless of [member resource_emit_changed].
signal property_changed(new_value: Variant)


@export_subgroup("Resource", "resource_")

var _resource_property_name: StringName
## The name of the property to read/write in the [member resource]. If blank, this will default to the [member name] of this [Node].
@export var resource_property_name: StringName:
	get: return _resource_property_name if _resource_property_name else name
	set(value): _resource_property_name = value


## If enabled, [member resource_changed] will be emitted whenever the property is modified by [member target_node]. This does NOT affect if [member property_changed] is emitted. Usually you'll want this disabled if you have a separate mechanism for saving the resource.
@export var resource_emit_changed: bool = true


@export_subgroup("Node", "node_")

var _node_target: Node
## The target node to read/write. If blank, this will default to this [Node]'s immediate parent.
@export var node_target: Node:
	get: return _node_target if _node_target else get_parent()
	set(value): _node_target = value


## The name of the property to read/write in the [member node_target]. An empty value will attempt to be assigned on ready.
@export var node_property_name: StringName

## Editor-only value used to verify the type of [member node_property_name]. Leave blank to do no assertion, or auto-assign if [member node_property_name] is also blank.
@export var node_property_type: StringName:
	get: return get_meta(&"_custom_type", &"")
	set(value): set_meta(&"_custom_type", value)


@export var node_signal: StringName:
	set(value):
		if not is_node_ready():
			node_signal = value
			return

		if not node_signal.is_empty() and node_target.is_connected(node_signal, _set_property_internal):
			node_target.disconnect(node_signal, _set_property_internal)

		node_signal = value

		if not node_signal.is_empty() and not node_target.is_connected(node_signal, _set_property_internal):
			node_target.connect(node_signal, _set_property_internal)


var property_value: Variant:
	get: return resource.get(resource_property_name) if resource else null


var _is_setting_property: bool = false


# func _init() -> void:
# 	fallback_type = 2


func _ready() -> void:
	super._ready()
	node_signal = node_signal

	if node_property_name.is_empty():
		var prop_list := node_target.get_property_list()
		for k in AUTO_PROPERTIES:
			if not Myth.is_prop_of_type(k, AUTO_PROPERTIES[k][0], prop_list): continue

			node_property_name = k

			if node_property_type.is_empty():
				node_property_type = AUTO_PROPERTIES[k][0]

			if node_signal.is_empty():
				node_signal = AUTO_PROPERTIES[k][1]

			break

	assert(not node_property_name.is_empty(), "Attempted to auto-assign node_property_name in target node '%s', but no viable property exists." % [node_target.name])


func _resource_changed() -> void:
	if resource == null or not is_node_ready() or _is_setting_property: return

	var value = resource.get(resource_property_name)
	assert(node_property_type.is_empty() or Myth.is_value_of_type(value, node_property_type), "The value of ResourcePropertyNode '%s' must match the type '%s'" % [resource_property_name, node_property_type])

	node_target.set(node_property_name, value)


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

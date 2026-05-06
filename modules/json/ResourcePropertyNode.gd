## Allows you to set the properties of the [Resource] occupying the nearest ancestor [ResourceNode] at runtime. The [member name] of this [Node] is the name of the property in the [Resource] to be set.
##
## Designed by Bastian Weaver of Nemonix Software, 2026.
## This code is open to the public domain and 100% free to use and/or modify.
##
class_name ResourcePropertyNode extends ResourceNode

static var AUTO_PROPERTIES: Dictionary = {
	&"icon": [&"Texture2D", &"icon_changed"],
	&"text": [&"String", &"text_changed"],
	&"value": [&"int", &"value_changed"],
}

static func add_auto_property(prop_name: StringName, prop_type: StringName, signal_name: StringName):
	AUTO_PROPERTIES[prop_name] = [prop_type, signal_name]


@export var node: Node

## Custom property of this [Node] that will be used to get and set the value in the [Resource]. An empty value will assign on ready.
@export var node_property_name: StringName

## Editor-only value used to verify the type of [member node_property_name]. Leave blank to do no assertion, or auto-assign if [member node_property_name] is also blank.
@export var node_property_type: StringName:
	get: return get_meta(&"_custom_type", &"")
	set(value): set_meta(&"_custom_type", &"")


@export var node_signal: StringName:
	set(value):
		if not node_signal.is_empty():
			node.disconnect(node_signal, _set_property)

		node_signal = value

		if not node_signal.is_empty():
			node.connect(node_signal, _set_property)


# func _init() -> void:
# 	fallback_type = 2


func _ready() -> void:
	if node == null: node = get_parent()

	if not node_property_name.is_empty(): return

	var prop_list := node.get_property_list()
	for k in AUTO_PROPERTIES:
		if not Myth.is_prop_of_type(k, AUTO_PROPERTIES[k][0], prop_list): continue

		node_property_name = k

		if node_property_type.is_empty():
			node_property_type = AUTO_PROPERTIES[k][0]

		if node_signal.is_empty():
			node_signal = AUTO_PROPERTIES[k][1]

		break


func _resource_changed() -> void:
	var value = resource.get(name)
	assert(node_property_type.is_empty() or Myth.is_value_of_type(value, node_property_type), "The value of ResourcePropertyNode '%s' must match the type '%s'" % [name, node_property_type])

	node.set(node_property_name, value)


func _set_property(new_value: Variant) -> void:
	if resource == null: return

	resource.set(name, new_value)
	node.set_block_signals(true)
	emit_resource_changed()
	node.set_block_signals(false)

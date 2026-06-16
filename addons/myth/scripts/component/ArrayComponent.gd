## Creates children for its parent, based on a supplied list of [Variant]s. an interface for a [PropertyResourceComponent] to represent an [Array] as an item of scenes.
class_name ArrayComponent extends Component

signal elements_changed(new_elements: Array)

## If enabled, this will always destroy and recreate an [member elements_scene] instead of updating it.
@export var elements_always_rebuild: bool = false


## Each element will instantiate and/or update one of this scene to represent itself. The root Node in the scene should either have a `value` property, or a `populate(source)` method which accepts the element.
@export var elements_scene: PackedScene


var _elements_prev: Array
@export var elements: Array:
	get: return element_nodes.keys()
	set(value):
		if not is_node_ready():
			await ready
			await get_tree().process_frame

		var __elements__ := elements

		for e in __elements__:
			if e in value: continue
			_element_nodes[e].queue_free()
			_element_nodes.erase(e)

		for e in value:
			if e in __elements__: continue
			_element_nodes[e] = null

		refresh_elements()


var _element_nodes: Dictionary[Variant, Node]
var element_nodes: Dictionary[Variant, Node]:
	get: return _element_nodes
	set(value):
		_element_nodes = value
		refresh_elements()
		elements_changed.emit()


var managed_children: Array[Node]:
	get: return _element_nodes.values()


func refresh_elements() -> void:
	assert(elements_scene != null or _element_nodes.is_empty(), "elements_scene is not set. Cannot create any children.")

	for k in _elements_prev:
		if k is not Resource: continue
		k.changed.disconnect(refresh_element)

	for k in _element_nodes:
		if elements_always_rebuild and _element_nodes[k] is Node:
			_element_nodes[k].queue_free()
			_element_nodes[k] = null

		if _element_nodes[k] == null:
			_element_nodes[k] = elements_scene.instantiate()

		_element_nodes[k].populate(k)

		if k is Resource:
			k.changed.connect(refresh_element.bind(k))

	_elements_prev = elements
	refresh_child_order()
	elements_changed.emit(_elements_prev)


func refresh_child_order() -> void:
	var children := managed_children
	children.sort_custom(_sort_children)

	for i in children.size():
		if not children[i].is_inside_tree():
			parent.add_child(children[i])

		parent.move_child(children[i], i)


func get_element_node(e) -> Node:
	return _element_nodes[e]


func add_element(e) -> void:
	_element_nodes[e] = null
	refresh_elements()


func remove_element(e) -> void:
	_element_nodes.erase(e)
	refresh_elements()

var refreshing_elements: Array
func refresh_element(e) -> void:
	if e in refreshing_elements: return

	refreshing_elements.push_back(e)
	await _element_nodes[e].populate(e)
	refresh_child_order()
	refreshing_elements.erase(e)


func _sort_children(a: Node, b: Node) -> bool:
	return Myth.compare(a, b)

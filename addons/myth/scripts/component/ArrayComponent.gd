## Creates children for its parent, based on a supplied list of [Variant]s. an interface for a [PropertyResourceComponent] to represent an [Array] as an item of scenes.
class_name ArrayComponent extends Component

signal elements_changed(new_elements: Array)

## If enabled, this will always destroy and recreate an [member elements_fallback_scene] instead of updating it.
@export var elements_always_rebuild: bool = false

## If set, this property of each element will be used as the scene to instantiate for it, assuming it is an [Object]. If blank, [member elements_fallback_scene will be used.
@export var elements_scene_property: StringName

## Any element without the property [member elements_scene_property] will use this scene to display itself.
@export var elements_fallback_scene: PackedScene


var _elements_prev: Array
@export var elements: Array:
	get: return element_nodes.keys()
	set(value):
		if not get_parent().is_node_ready():
			await get_parent().ready

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
	for k in _elements_prev:
		if k is not Resource: continue
		k.changed.disconnect(refresh_element)

	for e in _element_nodes:
		var child: Node = _element_nodes[e]
		var child_visible_prev = child.get(&"visible") if child else null

		if elements_always_rebuild and child is Node:
			child.queue_free()
			child = null

		if child == null:
			var element_scene: PackedScene = e.get(elements_scene_property) if elements_scene_property and e is Object else null
			if element_scene == null:
				element_scene = elements_fallback_scene
			assert(element_scene != null, "No scene could be created for element '%s', and no fallback scene is set." % [e])

			child = element_scene.instantiate()

		assert(child.has_method(&"populate"), "The target Node for element '%s' must contain a method 'populate'." % [e])
		child.populate(e)
		if child_visible_prev != null:
			child.visible = child_visible_prev

		_element_nodes[e] = child

		if e is Resource:
			e.changed.connect(refresh_element.bind(e))

	_elements_prev = elements
	refresh_child_order()
	elements_changed.emit(_elements_prev)


func refresh_child_order() -> void:
	var children := managed_children
	children.sort_custom(_sort_children)

	if not parent.is_node_ready():
		await parent.ready
		await get_tree().process_frame

	for i in children.size():
		if not children[i].is_inside_tree():
			parent.add_child(children[i])

	for i in children.size():
		parent.move_child(children[i], i)


func filter_elements(method: Callable) -> void:
	assert(method.is_valid(), "Filter method is not valid.")
	for e in elements:
		assert(_element_nodes[e].get(&"visible") != null, "Can't filter a node without a `visible` property.")

		_element_nodes[e].visible = method.call(e)


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

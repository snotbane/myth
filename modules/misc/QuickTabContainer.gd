## Treats its children as a [TabContainer] in that only one may be visible at a time, but has no other features.
@tool class_name QuickTabContainer extends PanelContainer

@export var selected_tab : int :
	get:
		var child : Node
		for idx in get_child_count(true):
			child = get_child(idx, true)
			if child is not Control: continue
			if child.visible: return idx
		return -1
	set(value):
		value = clampi(value, 0, get_child_count(true) - 1)
		_changing_visibility = true

		selected_child.hide()
		var child : Node
		while true:
			child = get_child(value, true)
			if child is not Control:
				value = wrapi(value + 1, 0, get_child_count(true) - 1)
				continue

			child.show()
			break

		_changing_visibility = false
var selected_child : Control :
	get: return get_child(selected_tab, true)
	set(value):	selected_tab = value.get_index(true)

func _ready() -> void:
	for child in get_children():
		_child_entered_tree(child)

	child_entered_tree.connect(_child_entered_tree)
	child_exiting_tree.connect(_child_exiting_tree)


func _child_entered_tree(node: Node) -> void:
	if node is not Control: return

	if not node.visibility_changed.is_connected(_child_visibility_changed):
		node.visibility_changed.connect(_child_visibility_changed.bind(node))

	selected_child = node


func _child_exiting_tree(node: Node) -> void:
	if node is not Control: return

	if node.visibility_changed.is_connected(_child_visibility_changed):
		node.visibility_changed.disconnect(_child_visibility_changed)

	if node.visible:
		selected_tab -= 1



var _changing_visibility : bool = false
func _child_visibility_changed(node: Node) -> void:
	if _changing_visibility: return

	_changing_visibility = true
	if node.visible:
		for child in get_children():
			if child == node or child is not Control or not child.visible: continue
			child.hide()
	else:
		var idx := node.get_index(true)
		var child : Node
		while true:
			idx = wrapi(idx + 1, 0, get_child_count(true) - 1)
			child = get_child(idx, true)
			if child is not Control: continue

			child.show()
			break

	_changing_visibility = false
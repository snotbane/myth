## Treats its children as a [TabContainer] in that only one may be visible at a time, but has no other features.
@tool class_name QuickTabContainer extends PanelContainer

var _selected_tab_prev : int = 0
@export var selected_tab : int = 0 :
	get:
		var child : Node
		for idx in get_child_count():
			child = get_child(idx)
			if child is not Control: continue
			if child.visible: return idx
		return -1
	set(value):
		if not is_node_ready(): return

		value = wrapi(value, 0, get_child_count())
		_changing_visibility = true

		for child in get_children():
			if child is not Control:
				value = wrapi(value + 1, 0, get_child_count())
				continue

			if child.visible == (value == child.get_index()): continue
			child.visible = not child.visible

		_selected_tab_prev = selected_tab
		_changing_visibility = false


func _ready() -> void:
	for child in get_children():
		if child is not Control: continue
		child.visibility_changed.connect(_child_visibility_changed.bind(child))

	child_entered_tree.connect(_child_entered_tree)
	child_exiting_tree.connect(_child_exiting_tree)


func _child_entered_tree(child: Node) -> void:
	if child is not Control: return

	if not child.visibility_changed.is_connected(_child_visibility_changed):
		child.visibility_changed.connect(_child_visibility_changed.bind(child))

	_child_visibility_changed(child)


func _child_exiting_tree(child: Node) -> void:
	if child is not Control: return

	if child.visibility_changed.is_connected(_child_visibility_changed):
		child.visibility_changed.disconnect(_child_visibility_changed)

	if not child.visible: return

	## Only trigger if we are actually getting removed.
	if Engine.is_editor_hint() and child.owner != EditorInterface.get_edited_scene_root(): return

	selected_tab = (_selected_tab_prev + 1) if _selected_tab_prev < get_child_count() - 1 else 0


var _changing_visibility : bool = false
func _child_visibility_changed(node: Node) -> void:
	if _changing_visibility: return

	_changing_visibility = true

	if node.visible:
		for child in get_children():
			if child == node or child is not Control or not child.visible: continue
			child.hide()
		_selected_tab_prev = node.get_index()
	else:
		var next : Node = get_child(wrapi(node.get_index() + 1, 0, get_child_count()))
		while next is not Control:
			next = get_child(wrapi(next.get_index() + 1, 0, get_child_count()))
		next.show()

	_changing_visibility = false
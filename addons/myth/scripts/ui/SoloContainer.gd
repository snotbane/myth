## Treats its children as a [TabContainer] in that only one may be visible at a time, but has no other features.
@tool
class_name SoloContainer
extends Container

var _current_tab_control: Control
@onready var _previous_tab: int = current_tab
## The index of the currently visible child.
@export var current_tab: int = 0:
	get:
		var control_child_count := 0
		var child: Node
		for idx in get_child_count():
			child = get_child(idx)
			if child is not Control: continue
			control_child_count += 1
			if child.visible: return idx

		return -1 if deselect_enabled or control_child_count == 0 else 0
	set(value):
		if not is_node_ready():
			await ready

		var dir := signi(value - current_tab)
		var i := wrapi(value + dir, -1 if deselect_enabled else 0, get_child_count())
		while get_child(i) is not Control or i != -1:
			if i == value: return
			i = wrapi(i + dir, -1 if deselect_enabled else 0, get_child_count())
		value = i

		_changing_visibility = true

		for child in get_children():
			if value >= 0 and child is not Control:
				value = wrapi(value + 1, 0, get_child_count())
				continue

			if child.visible == (value == child.get_index()): continue

			child.visible = not child.visible
			if child.visible:
				_child_became_visible(child)

		_previous_tab = value
		_changing_visibility = false

func set_current_tab(idx: int = -1) -> void:
	current_tab = idx


## If enabled, the container will expand to fit the largest child [Control]. If disabled, the container will shrink to fit the currently visible child.
@export var fit_largest: bool = true:
	set(value):
		fit_largest = value
		update_minimum_size()
		_child_became_visible(_current_tab_control)


## If enabled, the container will be able to hide all children.
@export var deselect_enabled: bool = false:
	set(value):
		if current_tab == -1 and not value:
			current_tab = 0
		deselect_enabled = value


func _ready() -> void:
	for child in get_children():
		if child is not Control: continue
		child.visibility_changed.connect(_child_visibility_changed.bind(child))

	child_entered_tree.connect.call_deferred(_child_entered_tree)
	child_exiting_tree.connect.call_deferred(_child_exiting_tree)


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

	current_tab = (_previous_tab + 1) if _previous_tab < get_child_count() - 1 else 0


func _get_minimum_size() -> Vector2:
	if fit_largest:
		var result := Vector2.ZERO
		for child in get_children():
			if child is not Control: continue
			result = result.max(child.get_combined_minimum_size())
		return result
	else:
		for child in get_children():
			if child is not Control or not child.visible: continue
			return child.get_combined_minimum_size()
		return Vector2.ZERO


var _changing_visibility: bool = false
func _child_visibility_changed(node: Node) -> void:
	if _changing_visibility: return

	_changing_visibility = true

	if node.visible:
		for child in get_children():
			if child == node or child is not Control or not child.visible: continue
			child.hide()
		_previous_tab = node.get_index()
		_child_became_visible(node)
	elif not deselect_enabled:
		var next: Node = get_child(wrapi(node.get_index() + 1, 0, get_child_count()))
		while next is not Control:
			next = get_child(wrapi(next.get_index() + 1, 0, get_child_count()))
		next.show()
		_child_became_visible(next)

	_changing_visibility = false


func _child_became_visible(child: Control) -> void:
	_current_tab_control = child
	if _current_tab_control == null: return

	fit_child_in_rect(_current_tab_control, Rect2(Vector2.ZERO, get_combined_minimum_size()))


func deselect() -> void:
	current_tab = -1

## Allows only one of its parent's children to be visible at any given time. Effectively a [TabContainer] without tabs, AND it can be used on any [Node].
@icon("res://addons/myth/script/component/misc/SoloComponent.svg")
@tool
class_name SoloComponent
extends Component

## Emits when the currently visible child changed.
signal changed

## If enabled, the parent will be able to display zero visual children. If disabled, one visual child will always be visible.
@export
var allow_none: bool = false:
	set(value):
		allow_none = value

		if not allow_none and current_child == null:
			show_first()

var current_child: Node:
	set(value):
		if current_child == value: return
		current_child = value
		changed.emit()

func _init() -> void:
	enabled_changed.connect((func() -> void:
		_on_child_visibility_changed(current_child, true)
	))


func _ready() -> void:
	super._ready()

	var potentially_visible_children : Array[Node] = []

	for child in parent.get_children(true):
		if not child.has_signal(&"visibility_changed"):
			continue

		potentially_visible_children.push_back(child)

		if current_child == null:
			if child.visible:
				current_child = child
		else:
			child.visible = false

	if current_child == null and not allow_none and not potentially_visible_children.is_empty():
		current_child = potentially_visible_children[0]
		current_child.visible = true


	for child in potentially_visible_children:
		if child.visibility_changed.is_connected(_child_visibility_changed):
			continue
		child.visibility_changed.connect(_child_visibility_changed.bind(child))

	parent.child_entered_tree.connect(_child_entered_tree)
	parent.child_exiting_tree.connect(_child_exiting_tree)


func _child_entered_tree(node: Node) -> void:
	if not node.has_signal(&"visibility_changed"):
		return

	if current_child:
		node.visible = false
	elif node.visible:
		current_child = node

	if node.visibility_changed.is_connected(_child_visibility_changed):
		return

	node.visibility_changed.connect(_child_visibility_changed.bind(node))



func _child_exiting_tree(node: Node) -> void:
	if node != current_child or not node.has_signal(&"visibility_changed"):
		return

	node.visibility_changed.disconnect(_child_visibility_changed)
	_on_child_visibility_changed(node, false)



var _child_visibility_changed_handling : bool = false
func _child_visibility_changed(node: Node) -> void:
	_on_child_visibility_changed(node, node.visible)


func _on_child_visibility_changed(node: Node, visible: bool) -> void:
	if _child_visibility_changed_handling or not enabled:
		return
	_child_visibility_changed_handling = true

	if visible:
		current_child = node
		for child in parent.get_children(true):
			if node == child or not child.has_signal(&"visibility_changed"):
				continue

			child.visible = false

	elif current_child == node:
		if allow_none:
			current_child = null

		else:
			show_next()

	_child_visibility_changed_handling = false


func _show_inc(inc: int) -> void:
	var min := -1 if allow_none else 0
	var max := parent.get_child_count(true)
	var origin := current_child.get_index(true) if current_child else min
	var cursor := wrapi(origin + inc, min, max)
	while true:
		## Can only happen if allow_none is true
		if cursor == -1:
			if current_child:
				current_child.visible = false
				current_child = null

			break

		## Can only happen if allow_none is false
		if cursor == origin:
			current_child.visible = true
			break

		var cursor_child := parent.get_child(cursor, true)
		if not cursor_child.has_signal(&"visibility_changed"):
			cursor = wrapi(cursor + inc, min, max)
			continue

		current_child = cursor_child
		current_child.visible = true
		break


## Shows [member parent]'s next visual child, or none if cycling to the end and [member allow_none] is enabled.
func show_next() -> void:
	_show_inc(+1)


## Shows [member parent]'s previous visual child, or none if cycling to the beginning and [member allow_none] is enabled.
func show_previous() -> void:
	_show_inc(-1)


## Shows [member parent]'s first visual child.
func show_first() -> void:
	for child in parent.get_children(true):
		if not child.has_signal(&"visibility_changed"):
			continue

		child.visible = true
		break

## Hides all children if [member allow_none] is enabled, otherwise do nothing.
func hide() -> void:
	if not allow_none:
		return

	if current_child:
		current_child.visible = false
		current_child = null


## [member hide]s all children if possible, else [member show_first].
func reset() -> void:
	if allow_none:
		hide()
	else:
		show_first()

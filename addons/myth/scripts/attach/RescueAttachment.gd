## This [Node] will keep its parent [Node] in place even if that parent's parent [Node] is destroyed.
class_name RescueAttachment extends Node

signal rescued

var node : Node :
	get: return self

var parent : Node :
	get: return node.get_parent()

var times_rescued : int = 0

func _ready() -> void:
	parent.tree_exiting.connect(rescue)

func rescue() -> void:
	if not parent.is_queued_for_deletion(): return

	var gt
	var apply_global := node is Node2D or node is Node3D
	if apply_global:
		gt = node.transform

	var ancestor : Node = parent
	while ancestor.is_queued_for_deletion():
		if apply_global:
			gt = ancestor.transform * gt
		ancestor = ancestor.get_parent()

	parent.remove_child(node)
	ancestor.add_child.call_deferred(node)

	if apply_global:
		node.transform = gt

	times_rescued += 1
	rescued.emit()

	_rescue()
func _rescue() -> void: pass


class_name InputNode extends Node

static func is_input_restricted(node: Node) -> bool:
	var focus := node.get_viewport().gui_get_focus_owner()
	return focus != null


func _unhandled_input(event: InputEvent) -> void:
	if InputNode.is_input_restricted(self):	_restricted_input()
	else:									_unrestricted_input(event)
func _restricted_input() -> void: pass
func _unrestricted_input(event: InputEvent) -> void: pass


## These functions don't work as intended, but may be useful in the future.
#
# static func get_action_raw_strength_safe(node: Node, event: InputEvent, action: StringName, handle_input := true) -> float:
# 	if event.is_action(action):
# 		if handle_input: node.get_viewport().set_input_as_handled()
# 		return Input.get_action_raw_strength(action)
# 	return 0.0

# static func get_action_strength_safe(node: Node, event: InputEvent, action: StringName, handle_input := true) -> float:
# 	if event.is_action(action):
# 		if handle_input: node.get_viewport().set_input_as_handled()
# 		return Input.get_action_strength(action)
# 	return 0.0

# static func get_axis_safe(node: Node, event: InputEvent, negative: StringName, positive: StringName, handle_input := true) -> float:
# 	if (
# 		event.is_action(negative) or
# 		event.is_action(positive)
# 	):
# 		if handle_input: node.get_viewport().set_input_as_handled()
# 		return Input.get_axis(negative, positive)
# 	return 0.0

# static func get_vector2_safe(node: Node, event: InputEvent, negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, deadzone := -1.0, handle_input := true) -> Vector2:
# 	var result := Vector2.ZERO
# 	if (
# 		event.is_action(negative_x) or
# 		event.is_action(positive_x) or
# 		event.is_action(negative_y) or
# 		event.is_action(positive_y)
# 	):
# 		result = Input.get_vector(negative_x, positive_x, negative_y, positive_y, deadzone)
# 		print(result)
# 		if handle_input: node.get_viewport().set_input_as_handled()
# 	return result

# static func get_vector3_safe(node: Node, event: InputEvent, negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, negative_z: StringName, positive_z: StringName, handle_input := true) -> Vector3:
# 	var result := Vector3.ZERO
# 	if (
# 		event.is_action(negative_x) or
# 		event.is_action(positive_x) or
# 		event.is_action(negative_y) or
# 		event.is_action(positive_y) or
# 		event.is_action(negative_z) or
# 		event.is_action(positive_z)
# 	):
# 		if handle_input: node.get_viewport().set_input_as_handled()
# 		return Vector3(Input.get_axis(negative_x, positive_x), Input.get_axis(negative_y, positive_y), Input.get_axis(negative_z, positive_z))
# 	return Vector3.ZERO
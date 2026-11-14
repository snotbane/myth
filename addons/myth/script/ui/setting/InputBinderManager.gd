## Handles all [InputBinder]s and passes them to the [SystemPrefs].
@icon("res://addons/myth/script/ui/setting/InputBinderManager.svg")
@tool
class_name InputBinderManager
extends Node

var members: Array[InputBinder]

var input_bindings: Dictionary:
	get:
		var result : Dictionary = {}
		for member in members:
			result[member.action] = member.action_data

		return result

	set(value):
		if not get_parent().is_node_ready():
			await get_parent().ready

		for member in members:
			if value.has(member.action):
				member.action_data = value[member.action]

		input_bindings_changed.emit()
signal input_bindings_changed

## Handles all [InputBinder]s which are children of its parent node, and passes them to a [Resource]. Also allows [InputBinder]s to create warnings and conflict with one another.
@icon("res://addons/myth/script/ui/setting/InputBinderManager.svg")
@tool
class_name InputBinderManager
extends Component

## Defines a list of input sections. Each section's [InputBinder]s are checked for internal conflicts. [InputBinder]s located in different sections are allowed to have conflicting input bindings. [InputBinder]s not belonging to any section, but still within this [InputBinderManager]'s parent, will be considered global (they will always be checked for conflicts).
@export
var sections: Array[Node]


var member_sections: Dictionary[InputBinder, Node]


func find_section(binder: InputBinder) -> Node:
	for section in sections:
		if section.is_ancestor_of(binder):
			return section
	return null


var members: Array[InputBinder]:
	get: return member_sections.keys()

func add_member(binder: InputBinder) -> void:
	if members.has(binder):
		return

	parent_ready.connect(binder._initialize_conflicts, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	binder.action_data_changed.connect(input_bindings_changed.emit)

	var section := find_section(binder)
	member_sections[binder] = section


func remove_member(binder: InputBinder) -> void:
	if not members.has(binder):
		return

	binder.action_data_changed.disconnect(input_bindings_changed.emit)
	member_sections.erase(binder)



var input_bindings: Dictionary:
	get:
		var result : Dictionary = {}
		for member in members:
			result[member.action] = member.action_data

		return result

	set(value):
		await ensure_parent_ready()

		for member in members:
			if value.has(member.action):
				member.action_data = value[member.action]

		input_bindings_changed.emit()
signal input_bindings_changed

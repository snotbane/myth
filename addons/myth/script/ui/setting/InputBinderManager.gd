## Handles all [InputBinder]s and passes them to the [SystemPrefs].
@icon("res://addons/myth/script/ui/setting/InputBinderManager.svg")
@tool
class_name InputBinderManager
extends Node


## Emitted when an [InputBinder]'s warning button is clicked.
signal warning_clicked(source: InputBinder)


## If enabled, [member warning_clicked] will be emitted whenever a warning appears.
@export
var auto_address_warnings: bool

@export
var auto_swap_conflicts: bool = true


## Defines a list of input sections. Each section's [InputBinder]s are checked for internal conflicts. [InputBinder]s located in different sections are allowed to have conflicting input bindings. [InputBinder]s not belonging to any section, but still within this [InputBinderManager]'s parent, will be considered global (they will always be checked for conflicts).
@export
var sections: Array[Node]


var member_sections: Dictionary[InputBinder, Node]


func find_section(binder: InputBinder) -> Node:
	for section in sections:
		if section.is_ancestor_of(binder):
			return section
	return null


## Returns true if the two [InputBinder]s can potentially conflict with one another.
func _conflicts_comparable(a: InputBinder, b: InputBinder) -> bool:
	if not member_sections.has(a) or not member_sections.has(b):
		return false

	if member_sections[a] == null or member_sections[b] == null:
		return true

	return member_sections[a] == member_sections[b]


var members: Array[InputBinder]:
	get: return member_sections.keys()

func add_member(binder: InputBinder) -> void:
	if members.has(binder):
		return

	binder.action_data_changed.connect(input_bindings_changed.emit)
	member_sections[binder] = find_section(binder)


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
		if not get_parent().is_node_ready():
			await get_parent().ready

		for member in members:
			if value.has(member.action):
				member.action_data = value[member.action]

		input_bindings_changed.emit()
signal input_bindings_changed


func _ready() -> void:
	await get_parent().ready

	_parent_ready.call_deferred()


func _parent_ready() -> void:
	for member in members:
		member._manager_ready()

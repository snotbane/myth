## Base class for a node that loads a single [Resource] at runtime. Can be used to save and load save data, or load many assets asynchronously.
@abstract
@icon("res://addons/myth/script/utility/resource/ResourceNodeBase.svg")
class_name ResourceNode
extends Node

signal resource_value_changed(resource: Resource)


@export var load_on_ready: bool = true

@export var save_on_change: bool = false:
	set(value):
		save_on_change = value
		if resource and resource.changed.is_connected(save) == value:
			if value:
				resource.changed.connect(save)
			else:
				resource.changed.disconnect(save)

var file_path: String:
	get: return _get_file_path()
	set(value): _set_file_path(value)

@abstract
func _get_file_path() -> String

@abstract
func _set_file_path(value: String) -> void

var resource: Resource:
	set(value):
		if resource == value:
			return

		if resource and resource.changed.is_connected(save):
			resource.changed.disconnect(save)

		resource = value

		if save_on_change and resource and not resource.changed.is_connected(save):
			resource.changed.connect(save)

		resource_value_changed.emit(resource)


func _ready() -> void:
	if load_on_ready:
		resource = load(file_path) if FileAccess.file_exists(file_path) else null


func save(__resource__: Resource = resource) -> void:
	if __resource__ == null:
		printerr("Resource is null.")
		return

	if file_path.is_empty():
		return

	ResourceSaver.save(__resource__, file_path)


func call_resource_method(method_name: StringName, args = null):
	if resource:
		return await resource.callv(method_name,
			args if args is Array else [args]
		)

## Provides an interface to an external resource, such as a save file stored in the user data folder.
@icon("res://addons/myth/script/utility/resource/ResourceNode.svg")
class_name ResourceNodeExternal
extends ResourceNode

## The desired path of the resource.
@export_global_file
var path: String = "user://"

## The template resource to save at the path if none exists. Defines default values for the actual resource to be stored there.
@export
var template: Resource

@export
var save_if_null: bool = false

func _get_file_path() -> String:
	return path

func _set_file_path(value: String) -> void:
	path = value


func _ready() -> void:
	super._ready()

	if resource == null and save_if_null:
		save(template)

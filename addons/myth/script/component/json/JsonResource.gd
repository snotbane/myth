## A resource which can be saved as, and loaded from, a JSON file. Useful for any kind of user save data.
@icon("res://addons/myth/script/component/json/JsonResource.svg")
class_name JsonResource
extends Resource

const DATA_NAME := "__DATA__"

static var NOW_UNIX: int:
	get: return floori(Time.get_unix_time_from_system())


static func extension_with_dot(ext: String) -> String:
	return ("." + ext) if ext else ""


static func generate_path(dir: String = "user://", ext: String = "json", name: String = generate_path_name()) -> String:
	var result: String
	var name_final := name
	while true:
		result = dir.path_join(name_final + extension_with_dot(ext))
		if not FileAccess.file_exists(result): break

		name_final = name + "_" + generate_path_name()

	return result


static func generate_path_name() -> String:
	return str(randi())


#region Base

@export
var data: Dictionary

## The time at which this [Resource] was originally created.
@export_storage
var time_created: int

## The time at which this [Resource] was last [member changed].
@export_storage
var time_changed: int


func _init(__save_as_dir__: bool = false, __path__: String = JsonResource.generate_path()) -> void:
	time_created = NOW_UNIX
	time_changed = time_created

	changed.connect(on_changed)


func on_changed() -> void:
	time_changed = NOW_UNIX

	if _auto_save_on_changed:
		save()


#endregion


#region Pathing


## The path to save/load to. Make sure extension is included. If left blank, a random path located in `user://` will be assigned.
@export
var _path: String
## The complete file path, including all parent directories. If the top directory is `res://`, `user://`, etc., that will be preserved.
var path: String:
	get: return _path
	set(value):
		if _path == value: return

		var path_prev := _path
		_path = value

		if FileAccess.file_exists(path):
			_save_as_dir = DirAccess.dir_exists_absolute(path)

		if FileAccess.file_exists(path_prev):
			DirAccess.rename_absolute(path_prev, path)


## The name of the file, without any extension.
var path_name: String:
	get: return path.get_file().get_basename()
	set(value):
		path = path_dir.path_join(value) + extension_with_dot(path_extension)

## The file extension. Uses [String.get_extension].
var path_extension: String:
	get: return path.get_extension()
	set(value): path = path.get_basename() + extension_with_dot(value)


## The full file name, including name and extension, but no containing folder.
var path_file: String:
	get: return path.get_file()
	set(value): path = path_dir.path_join(value)


## The folder containing [member path].
var path_dir: String:
	get: return path.get_base_dir()
	set(value): path = value.path_join(path_file)

## The globalized version of [member path]. This will be different on each machine.
var path_absolute: String:
	get: return ProjectSettings.globalize_path(path)

## The folder containing [member path_absolute]. This will be different on each machine.
var path_dir_absolute: String:
	get: return path_absolute.get_base_dir()


@export
var _save_as_dir: bool
var save_as_dir: bool:
	get: return _save_as_dir


## The path of the actual JSON file. Only relevant if [member save_as_dir] is true, otherwise it will be the same as [member path].
var data_path: String:
	get: return path.path_join(DATA_NAME + extension_with_dot(path_extension)) if save_as_dir else path

## The folder containing the actual JSON file (usually the same as [member path], unless directly modified). Only relevant if [member save_as_dir] is true, otherwise it will be the same as [member path_dir].
var data_dir: String:
	get: return path if save_as_dir else path_dir

## The globalized version of [member data_path]. This will be different on each machine.
var data_path_absolute: String:
	get: return ProjectSettings.globalize_path(data_path)

## The folder containing [member data_path_absolute]. This will be different on each machine.
var data_dir_absolute: String:
	get: return data_path_absolute.get_base_dir()

## Whethor or not the actual JSON file exists.
var file_exists: bool:
	get: return FileAccess.file_exists(data_path)


## Returns the [JsonResource] which loaded this as its child. This will ONLY be set if the resource is loaded via [member load_child] or [member load_children].
var parent: JsonResource

func reparent(new_parent: JsonResource, new_relative_path: String) -> void:
	parent = new_parent

#endregion


#region Save/Load

signal saved
signal loaded


@export
var _auto_save_on_changed: bool = true
var auto_save_on_changed: bool:
	get: return _auto_save_on_changed
	set(value): _auto_save_on_changed = value


@export
var _relative_path: String


func open_file(flags: int) -> FileAccess:
	return FileAccess.open(data_path, flags)


func save():
	var data_dir_touch_err := DirAccess.make_dir_recursive_absolute(data_dir_absolute)
	if data_dir_touch_err != OK:
		printerr("Failed to save JsonResource '%s': Couldn't create dir at path '%s': %s" % [self, data_dir_absolute, error_string(data_dir_touch_err)])
		return data_dir_touch_err

	var file := open_file(FileAccess.WRITE)
	if file == null:
		var file_open_err := FileAccess.get_open_error()
		printerr("Failed to save JsonResource '%s': Couldn't open file at path '%s': %s" % [self, data_path, error_string(file_open_err)])
		return file_open_err

	var json := JSON.stringify(JsonSerialize.serialize(self), "\t" if OS.is_debug_build() else "", true, true)
	if json.is_empty():
		printerr("Failed to save JsonResource '%s': Couldn't stringify to a valid JSON string." % self)
		return ERR_INVALID_DATA

	await _save_string_to_file(file, json)
	file.close()
	saved.emit()
	return OK


func _save_string_to_file(file: FileAccess, json: String):
	file.store_string(json)


func load(touch: bool = false):
	if not file_exists and touch:
		save()
		loaded.emit()
		return OK

	var file := open_file(FileAccess.READ)

	var json: String = await _load_string_from_file(file)
	file.close()

	JsonSerialize.deserialize(json, self)

	loaded.emit()
	return OK


func _load_string_from_file(file: FileAccess):
	return file.get_as_text()

#endregion


#region Tags

@export
var tags: Variant = PackedStringArray()

#endregion

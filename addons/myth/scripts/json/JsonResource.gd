## A resource which can be saved as, and loaded from, a JSON file. Useful for any kind of user save data. This does NOT provide any access to available save files on the system. Typical usage includes prompting for a file_path_relative using [FileDialog] and then either saving or loading to a new [JsonResource] instance.
class_name JsonResource extends Resource

#region Statics

const DATA_PATH := "__DATA__.json"

const KEY_SIZE := 16
const IV_SIZE := 16

const IGNORED_PROPERTY_NAMES := [
	"script",
	"metadata/_custom_type_script"
]

static var DIRECTORY_RESOURCES: Dictionary

## Generates a file path in the given [param dir]. If the path already exists, a new path is generated using [member generate_save_name], and is guaranteed to not yet exist.
static func generate_save_path(dir := ProjectSettings.globalize_path("user://"), name := generate_save_name(), ext := "json") -> String:
	var result := ""
	var actual_filename := name
	while true:
		result = dir.path_join("%s.%s" % [actual_filename, ext])
		if not FileAccess.file_exists(result): break
		actual_filename = "%s_%s" % [name, generate_save_name()]

	return result

static func generate_save_name() -> String:
	return str(randi())


static func find_parent_from_path(path: String) -> JsonResource:
	while not path.is_empty():
		path = Myth.get_parent_folder(path)
		if DIRECTORY_RESOURCES.has(path):
			return DIRECTORY_RESOURCES[path]
	return null


static var NOW: int:
	get: return floori(Time.get_unix_time_from_system())


## Adapted from:	https://github.com/godotengine/godot-proposals/issues/5515#issuecomment-1409971613
static func get_local_datetime(unix_time: int) -> int:
	return unix_time + Time.get_time_zone_from_system().bias * 60

#endregion


#region Serialization

## Converts a [Variant] into a JSON-compatible typed [Dictionary].
static func serialize(target: Variant) -> Variant:
	var json: Dictionary
	var type := typeof(target)

	match type:
		TYPE_OBJECT:
			json[&"type"] = target.get_class()
			if target.get_script():
				json[&"script"] = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(target.get_script().resource_path))

		_:
			json[&"type"] = type

	match type:
		TYPE_OBJECT:
			json[&"value"] = _serialize_object(target)

		TYPE_DICTIONARY:
			json[&"value"] = {}
			for k in target.keys():
				json[&"value"][k] = serialize(target[k])

		TYPE_ARRAY:
			json[&"value"] = []
			json[&"value"].resize(target.size())
			for i in target.size():
				json[&"value"][i] = serialize(target[i])

		TYPE_CALLABLE:
			json[&"value"] = null

		TYPE_COLOR:
			json[&"value"] = target.to_html()

		_:
			return target

	return json

## Serialize an object. To add additional properties to your object, create a method `func _serialize() -> Dictionary` which returns your custom data. This data will b e merged into the existing data. To completely override serialization, instead implement a new `func _serialize_custom() -> Variant`. It should return any value that you wish to be stored as JSON. Regardless of custom implmentations, if it's a project resource with a valid resource_path, it will simply store the UID.
static func _serialize_object(obj: Object) -> Variant:
	if obj is Resource and FileAccess.file_exists(obj.resource_path):
		return ResourceUID.id_to_text(ResourceLoader.get_resource_uid(obj.resource_path))

	if obj.has_method(&"_serialize_custom"):
		return obj._serialize_custom()

	var json := {}
	for prop in obj.get_property_list():
		if (
				prop[&"name"][0] == "_"
			or prop[&"name"] in IGNORED_PROPERTY_NAMES
			or not prop[&"usage"] & PROPERTY_USAGE_STORAGE
		): continue

		var value := serialize(obj.get(prop[&"name"]))
		if value == null and not prop[&"usage"] & PROPERTY_USAGE_STORE_IF_NULL:
			continue

		json[prop[&"name"]] = value

	if obj.has_method(&"_serialize"):
		json.merge(obj._serialize())

	return json


## Converts a JSON dictionary created using [member serialize()]. If a context object is specified, the context object will be updated, rather than replaced, so all references to it will be kept.
static func deserialize(json: Variant, context: Object = null) -> Variant:
	if json is not Dictionary:
		return json

	if json[&"type"] is String:
		return _deserialize_object(json, context)

	if json[&"type"] is float: ## Use float because JSON.parse_string() always imports numbers as floats.
		match int(json[&"type"]):
			TYPE_DICTIONARY:
				var result: Dictionary = {}
				for k in json[&"value"].keys():
					var value = json[&"value"][k]
					result[k] = deserialize(json[&"value"][k])
				return result

			TYPE_ARRAY:
				var result: Array = []
				result.resize(json[&"value"].size())
				for i in result.size():
					result[i] = deserialize(json[&"value"][i])
				return result

			TYPE_CALLABLE:
				return null

			TYPE_COLOR:
				return Color.html(json[&"value"])

			_:
				return json[&"value"]

	return null

## Deserializes an object from its JSON form. To customize deserialization for a class, implement a new `func _deserialize(json: Variant, context: Object = null) -> void`. Param `json` will be what `_serialize` created. Param `context` (advanced, not required in implementation) is the object that... tbh I don't even remember. It works.
static func _deserialize_object(json: Variant, context: Object = null) -> Object:
	if json[&"value"] is String and json[&"value"].begins_with("uid://"):
		return load(json[&"value"])

	var result: Object = ClassDB.instantiate(json[&"type"]) if context == null else context
	var data = json[&"value"]
	Myth.change_script(result, load(json[&"script"]) if json.has(&"script") else null, PROPERTY_USAGE_STORAGE, data.keys())

	if result.has_method(&"_deserialize_custom"):
		var args := [data, context]
		args.resize(result.get_method_argument_count(&"_deserialize_custom"))
		result._deserialize_custom.callv(args)
		return result

	for k: StringName in data.keys():
		if k == &"script": continue

		var value_prev = result.get(k)
		var value = deserialize(data[k], value_prev if value_prev is Object else null)
		result.set(k, value)

	if result.has_method(&"_deserialize"):
		var args := [data, context]
		args.resize(result.get_method_argument_count(&"_deserialize"))
		result._deserialize.callv(args)

	return result

#endregion


#region Signals

## Emitted when [member _ready] is called.
signal ready

## Emitted after the file has successfully been deleted from the file system.
signal deleted

#endregion


#region Properties

## The file_path_relative to save to, relative to [member parent_dir]. Make sure extension is included. If left blank, a random file_path_relative located in `user://` will be assigned.
@export var _file_path_relative: String

## The file path, relative to [member parent_dir]. Changing this will move the file on the system.
var file_path_relative: String:
	get: return _file_path_relative
	set(value): file_path = parent_dir.path_join(value) if _parent else value

## The folder containing [member file_path_relative].
var file_dir_relative: String:
	get: return Myth.get_parent_folder(file_path_relative)
	set(value): file_path_relative = value.path_join("%s.%s" % [file_name, file_ext])

## The name of the file, without any extension.
var file_name: String:
	get:
		var start = file_path_relative.rfind("/")
		return file_path_relative.substr(start + 1, file_path_relative.length() - (file_ext.length() + maxi(start, 0) + 2))
	set(value): file_path_relative = file_dir_relative.path_join("%s.%s" % [value, file_ext])

## The file extension. Uses [String.get_extension].
var file_ext: String:
	get: return file_path_relative.get_extension()
	set(value): file_path_relative = "%s.%s" % [file_path_relative.substr(0, file_path_relative.length() - (file_ext.length() + 1)), value]

## The full file name, including name and extension, but no containing folder.
var file_name_and_ext: String:
	get: return "%s.%s" % [file_name, file_ext]

## The complete file path, including all parent directories. If the top directory is `res://`, `user://`, etc., that will be preserved.
var file_path: String:
	get: return parent_dir.path_join(_file_path_relative) if _parent else _file_path_relative
	set(value):
		var file_path_prev := file_path
		if file_path_prev == value: return

		_parent = find_parent_from_path(value)
		_file_path_relative = value.substr(parent_dir.length() + 1) if _parent else value

		if FileAccess.file_exists(file_path):
			_save_as_dir = DirAccess.dir_exists_absolute(file_path)

		if FileAccess.file_exists(file_path_prev):
			DirAccess.rename_absolute(file_path_prev, file_path)

		if save_as_dir:
			DIRECTORY_RESOURCES.erase(file_path_prev)
			DIRECTORY_RESOURCES[file_path] = self

## The folder containing [member file_path].
var file_dir: String:
	get: return Myth.get_parent_folder(file_path)

## The globalized version of [member file_path]. This will be different on each machine.
var file_path_absolute: String:
	get: return ProjectSettings.globalize_path(file_path)

## The folder containing [member file_path_absolute]. This will be different on each machine.
var file_dir_absolute: String:
	get: return Myth.get_parent_folder(file_path_absolute)

## If [member file_path] exists inside of another [JsonResource] that is [member save_as_dir], that resource will be the [member _parent].
@export_storage var _parent: JsonResource
var parent: JsonResource:
	get: return _parent

## If we have a [member parent], this is a shorthand for its file path. If no [member parent] exists, it will return [member file_dir_relative].
var parent_dir: String:
	get: return _parent.file_path if _parent else file_dir_relative


var _save_as_dir: bool
## If enabled, [member file_path_relative] will actually refer to a directory, and all data will be stored in a file INSIDE this folder.
@export var save_as_dir: bool:
	get: return _save_as_dir
	set(value):
		if _save_as_dir == value: return

		if _save_as_dir:
			DIRECTORY_RESOURCES.erase(file_path)

		var data_path_absolute_prev := data_path
		_save_as_dir = value

		DirAccess.rename_absolute(data_path_absolute_prev, data_path)

		if _save_as_dir:
			DIRECTORY_RESOURCES[file_path] = self

## The path of the location of the actual JSON file, relative to [member file_path]. Only relevant if [member save_as_dir] is true
var data_path_relative: String:
	get: return DATA_PATH

## The path of the actual JSON file. Only relevant if [member save_as_dir] is true, otherwise it will be the same as [member file_path].
var data_path: String:
	get: return file_path.path_join(data_path_relative) if save_as_dir else file_path

## The folder containing the actual JSON file (usually the same as [member file_path], unless directly modified). Only relevant if [member save_as_dir] is true, otherwise it will be the same as [member file_dir].
var data_dir: String:
	get: return file_path if save_as_dir else file_dir

## The globalized version of [member data_path]. This will be different on each machine.
var data_path_absolute: String:
	get: return ProjectSettings.globalize_path(data_path)

## The folder containing [member data_path_absolute]. This will be different on each machine.
var data_dir_absolute: String:
	get: return Myth.get_parent_folder(data_path_absolute)

## Whethor or not the actual JSON file exists.
var file_exists: bool:
	get: return FileAccess.file_exists(data_path)

## Returns true if the [member file_exists], and custom conditions defined in [member _get_is_valid] pass.
var is_valid: bool:
	get: return file_exists and _get_is_valid()

## Custom implementation to check if the data is valid.
func _get_is_valid() -> bool: return true


var _aes: AESContext
var _crypto: Crypto
var __encryption_password: String
## If set, this resource will be encrypted when saved.
@export var _encryption_password: String:
	get: return __encryption_password
	set(value):
		__encryption_password = value

		if __encryption_password.is_empty(): return

		_aes = AESContext.new()
		_crypto = Crypto.new()

var _encryption_password_quantized: String:
	get: return _encryption_password # TODO: ensure it's the same size as KEY_SIZE

#endregion


@export_storage var time_created: int
@export_storage var time_changed: int
@export_storage var tags: Variant


func _init() -> void:
	time_created = NOW
	time_changed = time_created
	_init_tags()
	_save_as_dir = _get_save_as_dir_default()

	if not changed.is_connected(on_changed):
		changed.connect(on_changed)


var _is_ready: bool = false
## Called the first time the file is touched (saved or loaded).
func _ready() -> void: pass
func request_ready() -> void:
	_is_ready = false


func _get_save_as_dir_default() -> bool: return false


func on_changed() -> void:
	time_changed = NOW
	_changed()
func _changed() -> void: pass


func _saving() -> void: pass
func _loaded() -> void: pass
func _touched() -> void: pass


## Opens the JSON file for [FileAccess] use.
func open(flags: FileAccess.ModeFlags) -> FileAccess:
	return FileAccess.open(data_path, flags)


## Loads the [JsonResource] if it exists, or creates the file if it does not.
func touch(__file_path__: String = file_path) -> JsonResource:
	file_path = __file_path__
	if file_exists:
		return self.load()
	else:
		return self.save()


## Serializes object data, and saves the [JsonResource] to the file system.
func save(__file_path__: String = file_path) -> JsonResource:
	file_path = __file_path__

	var data_dir_touch_err := DirAccess.make_dir_recursive_absolute(data_dir_absolute)
	if data_dir_touch_err != OK:
		printerr("Failed to save %s at path '%s': while attempting to touch directory: %s" % [ self , data_dir_absolute, error_string(data_dir_touch_err)])
		return null

	var file := open(FileAccess.WRITE)
	if file == null:
		printerr("Failed to save %s at data path '%s': while opening file: %s" % [ self , data_path_absolute, error_string(FileAccess.get_open_error())])
		return null

	_saving()

	emit_changed()
	var json := JSON.stringify(serialize(self ), "\t" if OS.is_debug_build() else "", OS.is_debug_build(), true)
	_save(file, json)

	_touched()

	if not _is_ready:
		_ready()
		_is_ready = true
		ready.emit()

	return self

## Saves the given stringified JSON text to the file.
func _save(file: FileAccess, json: String) -> void:
	if _encryption_password.is_empty():
		file.store_string(json)
	else:
		json += " ".repeat(KEY_SIZE - (json.length() % KEY_SIZE))

		var key := _encryption_password_quantized.to_utf8_buffer()
		var iv := _crypto.generate_random_bytes(IV_SIZE)
		var decrypted := json.to_utf8_buffer()

		_aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
		var encrypted := _aes.update(decrypted)
		_aes.finish()

		var result := PackedByteArray()
		result.append_array(iv)
		result.append_array(encrypted)

		file.store_buffer(result)

	file.close()


## Loads the [JsonResource] from the file system, deserializes the JSON data, and updates object fields to match.
func load(__file_path__: String = file_path) -> JsonResource:
	file_path = __file_path__

	var file := open(FileAccess.READ)
	if file == null:
		printerr("Failed to load JsonResource. Error code: %s (%s)." % [FileAccess.get_open_error(), tag_error_string(FileAccess.get_open_error())])
		return null

	var json_string = _load(file)
	var json = JSON.parse_string(json_string)
	assert(json != null, "Couldn't parse string to json at file_path_relative: %s" % data_path)

	deserialize(json, self )
	_loaded()
	_touched()

	if not _is_ready:
		_ready()
		_is_ready = true
		ready.emit()

	return self

## Loads the given file as stringified JSON text.
func _load(file: FileAccess) -> String:
	var result: String

	if _encryption_password.is_empty():
		result = file.get_as_text()
	else:
		var data = file.get_buffer(file.get_length())

		var key := _encryption_password_quantized.to_utf8_buffer()
		var iv := data.slice(0, IV_SIZE)
		var encrypted := data.slice(IV_SIZE)

		_aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
		var decrypted := _aes.update(encrypted)
		_aes.finish()

		result = decrypted.get_string_from_utf8()

	file.close()
	return result


## Opens [member data_path_absolute] using [OS.shell_open].
func shell_open() -> void:
	var err := OS.shell_open(data_path_absolute)
	if err != OK:
		printerr("Error opening JsonResource at '%s': code %s (%s)." % [file_path_absolute, err, error_string(err)])

## Opens [member file_path_absolute] using [OS.shell_show_in_file_manager].
func shell_reveal() -> void:
	var err := OS.shell_show_in_file_manager(file_path_absolute)
	if err != OK:
		printerr("Error revealing JsonResource at '%s': code %s (%s)." % [file_path_relative, err, error_string(err)])


## Moves the file's location to a different directory.
func move(to_dir: String) -> void:
	if file_dir == to_dir:
		return

	file_path = to_dir.path_join(file_path_relative)


## Copies the resource to be placed into a directory. [param deep] determines if all sub resources are copied (only applies if [member save_as_dir] is `true`).
func copy(to_dir_absolute: String = file_dir, deep: bool = false) -> JsonResource:
	var result := duplicate(deep)
	var path := generate_save_path(to_dir_absolute, generate_save_name(), file_ext)

	result.save(path)

	return result


## Removes the JSON file from the file system. Generally, this [JsonResource] should stop being used after this is called.
func delete() -> void:
	var err := DirAccess.remove_absolute(file_path)
	if err != OK:
		printerr("Error deleting JsonResource at '%s': code %s (%s)." % [file_path, err, error_string(err)])
		return

	deleted.emit()

#region Tags

enum {
	OK,
	NULL_TAG_LIST,
	TAG_ALREADY_EXISTS,
	TAG_EMPTY_OR_WHITESPACE,
	TAG_DOES_NOT_EXIST,
}
static var ERROR_STRINGS: Dictionary[int, String] = {
	OK: "",
	TAG_ALREADY_EXISTS: "A similar tag already exists.",
	TAG_EMPTY_OR_WHITESPACE: "Tag must contain at least one non-whitespace character.",
	TAG_DOES_NOT_EXIST: "No matching or similar tag exists."

}
static func tag_error_string(code: int) -> String:
	return ERROR_STRINGS[code]


static var REGEX_TAGS_REMOVE_WHITESPACE := RegEx.create_from_string(r"^\s+|\s+$|[\n\t]+|(?:\b +(?= )\b)")
static func format_string_for_tag(s: String) -> String:
	return REGEX_TAGS_REMOVE_WHITESPACE.sub(s, "")


## Use this method to define how/if tags should be stored.
func _init_tags() -> void:
	tags = PackedStringArray()


## Returns true if the given [param tag] exists in [member tags].
func has_tag(tag: Variant) -> bool:
	return tag in tags


## Returns true if the given [param text] matches any tag in [member tags]. If [member tags] is an array of [String]s, this is equivalent to [member has_tag].
func has_tag_by_name(text: String) -> bool:
	return find_tag_by_name(text) != null


## Returns the first tag in [member tags] that matches the given [param text].
func find_tag_by_name(text: String) -> Variant:
	for tag in tags:
		if _tag_matches_text(tag, text): return tag
	return null


## Custom override to check if a [Variant] [param tag] matches the given [param text]. By default, it assumes that [param tag] is a [String] (and [member tags] is an array of [String]s).
func _tag_matches_text(tag, text: String) -> bool:
	return tag == text


## Creates a new tag, assuming that it does not already exist. Returns an error if unsuccessful.
func create_tag_by_name(text: String) -> int:
	text = format_string_for_tag(text)

	if text.is_empty(): return TAG_EMPTY_OR_WHITESPACE
	if has_tag_by_name(text): return TAG_ALREADY_EXISTS

	_create_tag_by_name(text)
	return OK


## Custom implementation for adding a tag by string name. Assumes that all validation checks have passed and the tag is formatted properly.
func _create_tag_by_name(text: String) -> void:
	tags.push_back(text)

#endregion

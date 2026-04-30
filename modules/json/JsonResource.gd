## A resource which can be saved as, and loaded from, a JSON file. Useful for any kind of user save data. This does NOT provide any access to available save files on the system. Typical usage includes prompting for a file_path using [FileDialog] and then either saving or loading to a new [JsonResource] instance.
class_name JsonResource extends Resource

#region Statics

const DATA_PATH := "__DATA__.json"

const SECONDS_IN_DAY := 86400
const SECONDS_IN_HOUR := 3600
const SECONDS_IN_MINUTE := 60

const K_TIME_CREATED := &"time_created"
const K_TIME_MODIFIED := &"time_modified"

const KEY_SIZE := 16
const IV_SIZE := 16

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
	return unix_time + Time.get_time_zone_from_system().bias * SECONDS_IN_MINUTE


static func load_from_file(path: String) -> JsonResource:
	if not FileAccess.file_exists(path): return null

	return JsonResource.new().load(path)

#endregion


#region Serialization

## Converts a [Variant] into a JSON-compatible typed [Dictionary]. Currently, [Object]s can only be serialized if it has the method [member _export_json()].
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

## Serialize an object. To customize serialization for a class, implement a new `func _serialize() -> Variant`. It should return any value that you wish to be stored as JSON. If returning nothing or null, it will serialize all values belonging to the Object and which match PROPERTY_USAGE_STORAGE. Or, if it's a project resource with a valid resource_path, it will simply store the UID.
static func _serialize_object(obj: Object) -> Variant:
	if obj.has_method(&"_serialize"):
		var value = obj._serialize()
		if value != null:
			return value

	if obj is Resource and not obj.resource_path.is_empty():
		return ResourceUID.id_to_text(ResourceLoader.get_resource_uid(obj.resource_path))

	var json := {}
	for prop in obj.get_property_list():
		if (
				prop[&"name"][0] == "_"
			or prop[&"name"] == "script"
			or not prop[&"usage"] & PROPERTY_USAGE_STORAGE
		):
			continue

		var value := serialize(obj.get(prop[&"name"]))
		if value == null and not prop[&"usage"] & PROPERTY_USAGE_STORE_IF_NULL:
			continue

		json[prop[&"name"]] = value

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

## Deserializes an object. To customize deserialization for a class, implement a new `func _deserialize(json: Variant, context: Object = null) -> Variant`. Param `json` will be what `_serialize` created. Return a truthy value to override all deserialization for this object.
static func _deserialize_object(json: Variant, context: Object = null) -> Object:
	if json[&"value"] is String and json[&"value"].begins_with("uid://"):
		return load(json[&"value"])

	var result: Object = ClassDB.instantiate(json[&"type"]) if context == null else context


	var data = json[&"value"]
	var new_script: Script = load(json[&"script"]) if json.has(&"script") else null

	if result.has_method(&"_deserialize"):
		Myth.change_script(result, new_script)

		var value = result._deserialize(data, context)
		if value:
			if result.has_method(&"_deserialized"):
				result._deserialized()
			return result

	else:
		Myth.change_script(result, new_script, PROPERTY_USAGE_STORAGE, data.keys())

	for k: StringName in data.keys():
		if k == &"script": continue
		var value_prev = result.get(k)
		var value = deserialize(data[k], value_prev if value_prev is Object else null)
		result.set(k, value)

	if result.has_method(&"_deserialized"):
		result._deserialized()

	return result

#endregion


#region Signals

## Emitted after the file has successfully been deleted from the file system.
signal deleted

#endregion

## The file_path to save to. Make sure extension is included. If left blank, a random file_path located in `user://` will be assigned.
@export var _file_path: String

## The relative file path. Changing this will move the file on the system.
var file_path: String:
	get: return _file_path
	set(value): file_path_absolute = parent_dir.path_join(value) if _parent else value

var file_dir: String:
	get: return Myth.get_parent_folder(file_path)
	set(value): file_path = value.path_join("%s.%s" % [file_name, file_ext])

var file_name: String:
	get:
		var start = file_path.rfind("/")
		return file_path.substr(start + 1, file_path.length() - (file_ext.length() + maxi(start, 0) + 2))
	set(value): file_path = file_dir.path_join("%s.%s" % [value, file_ext])

var file_ext: String:
	get: return file_path.get_extension()
	set(value): file_path = "%s.%s" % [file_path.substr(0, file_path.length() - (file_ext.length() + 1)), value]

var file_name_and_ext: String:
	get: return "%s.%s" % [file_name, file_ext]

var file_path_absolute: String:
	get: return parent_dir.path_join(_file_path) if _parent else _file_path
	set(value):
		var file_path_absolute_prev := file_path_absolute
		if file_path_absolute_prev == value: return

		_parent = find_parent_from_path(value)
		_file_path = value.substr(parent_dir.length() + 1) if _parent else value
		_save_as_dir = DirAccess.dir_exists_absolute(file_path_absolute)

		# if value.is_empty(): return

		if FileAccess.file_exists(file_path_absolute_prev):
			DirAccess.rename_absolute(file_path_absolute_prev, file_path_absolute)

		if save_as_dir:
			DIRECTORY_RESOURCES.erase(file_path_absolute_prev)
			DIRECTORY_RESOURCES[file_path_absolute] = self

var file_dir_absolute: String:
	get: return Myth.get_parent_folder(file_path_absolute)

## If [member file_path_absolute] exists inside of another [JsonResource] that is [member save_as_dir], that resource will be the [member _parent].
@export_storage var _parent: JsonResource
var parent: JsonResource:
	get: return _parent

var parent_dir: String:
	get: return _parent.file_path_absolute if _parent else file_dir


var _save_as_dir: bool
## If enabled, [member file_path] will actually refer to a directory, and all data will be stored in a file INSIDE this folder.
@export var save_as_dir: bool:
	get: return _save_as_dir
	set(value):
		if _save_as_dir == value: return

		if _save_as_dir:
			DIRECTORY_RESOURCES.erase(file_path_absolute)

		var data_path_absolute_prev := data_path_absolute
		_save_as_dir = value

		DirAccess.rename_absolute(data_path_absolute_prev, data_path_absolute)

		if _save_as_dir:
			DIRECTORY_RESOURCES[file_path_absolute] = self

var data_path: String = DATA_PATH

var data_path_absolute: String:
	get: return file_path_absolute.path_join(data_path) if save_as_dir else file_path_absolute

var data_dir_absolute: String:
	get: return file_path_absolute if save_as_dir else file_dir_absolute

var file_exists: bool:
	get: return FileAccess.file_exists(data_path_absolute)


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


var is_valid: bool:
	get: return (DirAccess.dir_exists_absolute(file_path_absolute) if save_as_dir else FileAccess.file_exists(file_path_absolute)) and _get_is_valid()
func _get_is_valid() -> bool: return true


@export_storage var time_created: int
@export_storage var time_modified: int
@export_storage var tags: Variant


func _init() -> void:
	time_created = NOW
	time_modified = time_created
	_init_tags()
	_save_as_dir = _get_save_as_dir_default()

	if not changed.is_connected(_changed):
		changed.connect(_changed)


var _is_ready: bool = false
## Called the first time the file is touched (saved or loaded).
func _ready() -> void: pass
func request_ready() -> void:
	_is_ready = false


func _get_save_as_dir_default() -> bool: return false


func _changed() -> void:
	time_modified = NOW


func _saving() -> void: pass
func _loaded() -> void: pass
func _touched() -> void: pass


func shell_open() -> void:
	if not file_exists: return
	OS.shell_open(ProjectSettings.globalize_path(file_path_absolute))
func shell_open_location() -> void:
	OS.shell_open(Myth.get_parent_folder(ProjectSettings.globalize_path(file_path_absolute)))


func open(flags: FileAccess.ModeFlags) -> FileAccess:
	return FileAccess.open(data_path_absolute, flags)


func touch(__file_path_absolute__: String = file_path_absolute) -> JsonResource:
	file_path_absolute = __file_path_absolute__
	if file_exists:
		return self.load()
	else:
		return self.save()


func save(__file_path_absolute__: String = file_path_absolute, __save_as_dir__: bool = _save_as_dir) -> JsonResource:
	file_path_absolute = __file_path_absolute__
	_save_as_dir = __save_as_dir__

	var data_dir_touch_err := DirAccess.make_dir_recursive_absolute(data_dir_absolute)
	if data_dir_touch_err != OK:
		printerr("Failed to save JsonResource at path '%s': error code %s while attempting to touch directory." % [data_dir_absolute, data_dir_touch_err])
		return null

	var file := open(FileAccess.WRITE)
	if file == null:
		printerr("Failed to save JsonResource at path '%s': error code %s while opening file." % [data_path_absolute, FileAccess.get_open_error()])
		return null

	_saving()

	emit_changed()
	var json := JSON.stringify(serialize(self ), "\t" if OS.is_debug_build() else "", OS.is_debug_build(), true)
	# print("json : %s" % [ json ])
	_save(file, json)

	_touched()

	if not _is_ready:
		_ready()
		_is_ready = true

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


func load(__file_path_absolute__: String = file_path_absolute) -> JsonResource:
	file_path_absolute = __file_path_absolute__

	var file := open(FileAccess.READ)
	if file == null:
		printerr("Failed to load JsonResource. Error code: %s (%s)." % [FileAccess.get_open_error(), tag_error_string(FileAccess.get_open_error())])
		return null

	var json_string = _load(file)
	var json = JSON.parse_string(json_string)
	assert(json != null, "Couldn't parse string to json at file_path: %s" % data_path_absolute)

	deserialize(json, self )
	_loaded()
	_touched()

	if not _is_ready:
		_ready()
		_is_ready = true

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


func reveal() -> void:
	var err := OS.shell_show_in_file_manager(file_path_absolute)
	if err != OK:
		printerr("Error revealing JsonResource at '%s': code %s (%s)." % [file_path, err, tag_error_string(err)])


func shopen() -> void:
	var err := OS.shell_open(file_path_absolute)
	if err != OK:
		printerr("Error opening JsonResource at '%s': code %s (%s)." % [file_path, err, tag_error_string(err)])


func move(to_dir_absolute: String) -> void:
	if file_dir_absolute == to_dir_absolute:
		return

	file_path_absolute = to_dir_absolute.path_join(file_path)


## Copies the resource to be placed into a directory. [param hard] determines if all sub resources are copied (only applies if [member save_as_dir] is `true`).
func copy(to_dir_absolute: String = file_dir_absolute, deep: bool = false) -> JsonResource:
	var result := duplicate(deep)
	var path := generate_save_path(to_dir_absolute, generate_save_name(), file_ext)

	result.save(path)

	return result


func delete() -> void:
	var err := DirAccess.remove_absolute(file_path_absolute)
	if err != OK:
		printerr("Error deleting JsonResource at '%s': code %s (%s)." % [file_path_absolute, err, tag_error_string(err)])
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


func has_tag(tag: Variant) -> bool:
	return tag in tags
func has_tag_by_name(text: String) -> bool:
	return find_tag(text) != null
func find_tag(text: String) -> Variant:
	for tag in tags:
		if _tag_matches_text(tag, text): return tag
	return null
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

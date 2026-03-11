## A resource which can serialize data to, and deserialize data from, a JSON file. Useful for any kind of save data. This does NOT provide any access to available save files on the system. Typical usage includes prompting for a file_path using [FileDialog] and then either saving or loading to a new [JsonResource] instance.
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

const IMPORT_ORDER : PackedStringArray = [ &"script", &"resource_local_to_scene", &"resource_name", &"time_created", &"time_modified", &"data" ]

static var DIRECTORY_RESOURCES : Dictionary

static func generate_save_path(dir := "user://", name := generate_save_name(), ext := "json") -> String:
	var result := ""
	var actual_filename := name
	while true:
		result = "%s%s.%s" % [dir, actual_filename, ext]
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


static func _sort_import_keys(a: StringName, b: StringName) -> bool:
	var ai := IMPORT_ORDER.find(a)
	if ai == -1:	return false

	var bi := IMPORT_ORDER.find(b)
	if bi == -1:	return true

	return ai < bi


static var NOW : int :
	get: return floori(Time.get_unix_time_from_system())

## Adapted from:	https://github.com/godotengine/godot-proposals/issues/5515#issuecomment-1409971613
static func get_local_datetime(unix_time: int) -> int:
	return unix_time + Time.get_time_zone_from_system().bias * SECONDS_IN_MINUTE

#endregion
#region Serialization

## Converts a [Variant] into a JSON-compatible typed [Dictionary]. Currently, [Object]s can only be serialized if it has the method [member _export_json()].
static func serialize(target: Variant) -> Dictionary:
	var json := {
		&"type": typeof(target)
	}

	match json[&"type"]:
		TYPE_OBJECT:
			json[&"class"] = target.get_class()
			if target.get_script():
				# json[&"script"] = target.get_script().get_global_name()
				json[&"script"] = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(target.get_script().resource_path))

	match json[&"type"]:
		TYPE_OBJECT when target.has_method(&"_json_export"):
			json[&"value"] = target._json_export()

		TYPE_OBJECT when target is Resource:
			json[&"value"] = _serialize_resource(target) if target.resource_path.is_empty() else ResourceUID.id_to_text(ResourceLoader.get_resource_uid(target.resource_path))

		TYPE_OBJECT:
			json[&"value"] = null
			printerr("Currently, an object can only be serialized if it implements _json_export(), or if it is a Resource.")

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
		# TYPE_CALLABLE:
		# 	var bound_arguments : Array = target.get_bound_arguments()
		# 	json[&"value"] = {
		# 		&"method": target.get_method(),
		# 		&"unbinds": target.get_unbound_arguments_count(),
		# 		&"binds": [],
		# 	}
		# 	json[&"value"][&"binds"].resize(bound_arguments.size())
		# 	for i in bound_arguments.size():
		# 		json[&"value"][&"binds"][i] = serialize(bound_arguments[i])

		TYPE_COLOR:
			json[&"value"] = target.to_html()

		_:
			json[&"value"] = target

	return json
static func _serialize_resource(res: Resource) -> Dictionary:
	var json := {}
	for prop in res.get_property_list():
		if (
				prop[&"name"][0] == "_"
			or	not prop[&"usage"] & PROPERTY_USAGE_STORAGE
		):
			continue

		json[prop[&"name"]] = serialize(res.get(prop[&"name"]))
	return json


## Converts a JSON dictionary created using [member serialize()]. Objects and Callables may not always be deserialized as expected. Currently, it is assumed that Objects found in [param json] do not refer to any existing object but instead will create a new object to be populated with more nested data. In other words, do NOT use
static func deserialize(json: Variant) -> Variant:
	if json == null: return null

	match int(json[&"type"]):
		TYPE_OBJECT when ClassDB.is_parent_class(json[&"class"], "Resource"):
			return _deserialize_resource(json)

		TYPE_OBJECT:
			return null
		# TYPE_OBJECT:
		# 	var result : Object = context if context != null else ClassDB.instantiate(json[&"class"])
		# 	if json.has(&"script_uid"):
		# 		result.set_script(load(json[&"script_uid"]))
		# 		assert(result.get_script() != null, "Attempted to deserialize an object, but couldn't set the script. Make sure that it has an _init() method with 0 *required* arguments.")

		# 	if result.has_method(&"_json_import"):
		# 		result._json_import(json[&"value"])
		# 	else:
		# 		for prop_name : StringName in json[&"value"].keys():
		# 			result.set(prop_name, deserialize(json[&"value"][prop_name]))

		# 	return result

		TYPE_DICTIONARY:
			var result : Dictionary = {}
			for k in json[&"value"].keys():
				var value = json[&"value"][k]
				result[k] = deserialize(json[&"value"][k])
			return result

		TYPE_ARRAY:
			var result : Array = []
			result.resize(json[&"value"].size())
			for i in result.size():
				result[i] = deserialize(json[&"value"][i])
			return result

		TYPE_CALLABLE:
			return null
		# TYPE_CALLABLE:
		# 	var result := Callable.create(context, json[&"value"][&"method"])
		# 	var binds : Array = []
		# 	binds.resize(json[&"value"][&"binds"].size())
		# 	for i in binds.size():
		# 		binds[i] = deserialize(json[&"value"][&"binds"][i])
		# 	return result.bindv(binds).unbind(json[&"value"][&"unbinds"])

		TYPE_COLOR:
			return Color.html(json[&"value"])

		TYPE_FLOAT:
			return float(json[&"value"])

		TYPE_INT:
			return int(json[&"value"])

		_:
			return json[&"value"]

	return null
static func _deserialize_resource(json: Variant) -> Resource:
	if json[&"value"] is String:
		return load(json[&"value"])

	var result : Resource = ClassDB.instantiate(json[&"class"])

	if json.has(&"script"):
		result.set_script(load(json[&"script"]))
		assert(result.get_script() != null, "Attempted to deserialize an object, but couldn't set the script. Make sure that it has an _init() method with 0 *required* arguments.")

	_resource_import(result, json[&"value"])
	return result

static func _resource_import(res: Resource, json: Dictionary) -> void:
	if res.has_method(&"_json_import"):
		res._json_import(json)

	else:
		var keys : Array = json.keys()
		keys.sort_custom(_sort_import_keys)

		for k : StringName in keys:
			res.set(k, deserialize(json[k]))

#endregion


signal modified


## The file_path to save to. Make sure extension is included. If left blank, a random file_path located in `user://` will be assigned.
@export var _file_path : String

## The relative file path. Changing this will move the file on the system.
var file_path : String :
	get: return _file_path
	set(value):	file_path_absolute = parent_dir.path_join(value) if parent else value

var file_dir : String :
	get: return Myth.get_parent_folder(file_path)
	set(value): file_path = value.path_join("%s.%s" % [file_name, file_ext])

var file_name : String :
	get:
		var start = file_path.rfind("/")
		return file_path.substr(start + 1, file_path.length() - (file_ext.length() + maxi(start, 0) + 2))
	set(value): file_path = file_dir.path_join("%s.%s" % [value, file_ext])

var file_ext : String :
	get: return file_path.get_extension()
	set(value): file_path = "%s.%s" % [file_path.substr(0, file_path.length() - (file_ext.length() + 1)), value]

var file_name_and_ext : String :
	get: return "%s.%s" % [ file_name, file_ext ]

var file_path_absolute : String :
	get: return parent_dir.path_join(_file_path) if parent else _file_path
	set(value):
		var file_path_absolute_prev := file_path_absolute
		if file_path_absolute_prev == value: return

		parent = find_parent_from_path(value)
		_file_path = value.substr(parent_dir.length() + 1) if parent else value

		# if value.is_empty(): return

		if FileAccess.file_exists(file_path_absolute_prev):
			DirAccess.rename_absolute(file_path_absolute_prev, file_path_absolute)

		if store_as_dir:
			DIRECTORY_RESOURCES.erase(file_path_absolute_prev)
			DIRECTORY_RESOURCES[file_path_absolute] = self

var file_dir_absolute : String :
	get: return Myth.get_parent_folder(file_path_absolute)

## If [member file_path_absolute] exists inside of another [JsonResource] that is [member store_as_dir], that resource will be the parent.
var parent : JsonResource

var parent_dir : String :
	get: return parent.file_path_absolute if parent else file_dir


var _store_as_dir : bool
## If enabled, [member file_path] will actually refer to a directory, and all data will be stored in a file INSIDE this folder.
@export var store_as_dir : bool :
	get: return _store_as_dir
	set(value):
		if _store_as_dir == value: return

		if _store_as_dir:
			DIRECTORY_RESOURCES.erase(file_path_absolute)

		var data_path_absolute_prev := data_path_absolute
		_store_as_dir = value

		DirAccess.rename_absolute(data_path_absolute_prev, data_path_absolute)

		if _store_as_dir:
			DIRECTORY_RESOURCES[file_path_absolute] = self

var data_path : String = DATA_PATH

var data_path_absolute : String :
	get: return file_path_absolute.path_join(data_path) if store_as_dir else file_path_absolute

var data_dir_absolute : String :
	get: return file_path_absolute if store_as_dir else file_dir_absolute

var file_exists : bool :
	get: return FileAccess.file_exists(data_path_absolute)


var _aes : AESContext
var _crypto : Crypto
var __encryption_password : String
## If set, this resource will be encrypted when saved.
@export var _encryption_password : String :
	get: return __encryption_password
	set(value):
		__encryption_password = value

		if __encryption_password.is_empty(): return

		_aes = AESContext.new()
		_crypto = Crypto.new()

var _encryption_password_quantized : String :
	get: return _encryption_password # TODO: ensure it's the same size as KEY_SIZE


var is_valid : bool :
	get: return (DirAccess.dir_exists_absolute(file_path_absolute) if store_as_dir else FileAccess.file_exists(file_path_absolute)) and _get_is_valid()
func _get_is_valid() -> bool: return true


@export_storage var time_created : int
@export_storage var time_modified : int
@export_storage var data : Dictionary


func _init(__file_path_absolute__: String = generate_save_path(), __store_as_dir__: bool = false) -> void:
	_store_as_dir = __store_as_dir__
	file_path_absolute = __file_path_absolute__
	time_created = NOW
	time_modified = time_created

	if file_exists:
		self.load()
	elif not __file_path_absolute__.is_empty():
		self.save()


func json_export() -> Dictionary:
	return serialize(self)


func json_import(json: Variant) -> void:
	_resource_import(self, json[&"value"])



func shell_open() -> void:
	if not file_exists: return
	OS.shell_open(ProjectSettings.globalize_path(file_path))
func shell_open_location() -> void:
	OS.shell_open(Myth.get_parent_folder(ProjectSettings.globalize_path(file_path)))


func save() -> void:
	var data_dir_touch_err := DirAccess.make_dir_recursive_absolute(data_dir_absolute)
	if data_dir_touch_err != OK:
		printerr("Failed to save JsonResource: error code %s while attempting to touch directory '%s'" % [data_dir_touch_err, data_dir_absolute])
		return

	var file := FileAccess.open(data_path_absolute, FileAccess.WRITE)
	if file == null:
		printerr("Failed to save JsonResource: error code %s" % FileAccess.get_open_error())
		return

	time_modified = NOW
	var json := JSON.stringify(json_export(), "\t" if OS.is_debug_build() else "", OS.is_debug_build(), true)
	_save(file, json)
	modified.emit()
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


func load() -> void:
	var file := FileAccess.open(data_path_absolute, FileAccess.READ)
	if file == null:
		printerr("Failed to load JsonResource. Error code: %s" % file.get_open_error())
		return

	var json_string = _load(file)
	var json = JSON.parse_string(json_string)
	assert(json != null, "Couldn't parse string to json at file_path: %s" % data_path_absolute)

	json_import(json)
## Loads the given file as stringified JSON text.
func _load(file: FileAccess) -> String:
	if _encryption_password.is_empty():
		return file.get_as_text()
	else:
		var data = file.get_buffer(file.get_length())

		var key := _encryption_password_quantized.to_utf8_buffer()
		var iv := data.slice(0, IV_SIZE)
		var encrypted := data.slice(IV_SIZE)

		_aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
		var decrypted := _aes.update(encrypted)
		_aes.finish()

		return decrypted.get_string_from_utf8()


func reveal() -> void:
	var err := OS.shell_show_in_file_manager(file_dir)
	if err != OK:
		printerr("Error revealing JsonResource at '%s': code %s." % [ err, file_path ])


func move(to_dir_absolute: String) -> void:
	if file_dir_absolute == to_dir_absolute:
		return

	file_path_absolute = to_dir_absolute.path_join(file_path)


## Copies the resource to be placed into a directory. [param hard] determines if all sub resources are copied (only applies if [member store_as_dir] is `true`).
func copy(to_dir_absolute: String, hard : bool = true) -> JsonResource:
	if file_dir_absolute == to_dir_absolute:
		printerr("Can't duplicate to the same path '%s'" % [ to_dir_absolute ])
		return null

	var copy_err := DirAccess.copy_absolute(file_dir_absolute, to_dir_absolute)
	if copy_err != OK:
		printerr("Error code (%s) while copying profile from '%s' to '%s'" % [ copy_err, file_dir_absolute, to_dir_absolute ])
		return null

	var result := JsonResource.new(to_dir_absolute.path_join(file_path), store_as_dir)

	if hard or not store_as_dir: return result

	# if FileAccess.file_exists(result.file_dir.path_join(Note.NOTES_SUBFOLDER_NAME)):
	var remove_err := DirAccess.remove_absolute(result.file_dir_absolute)
	if remove_err != OK:
		printerr("Error code (%s) while removing notes folder from copied profile '%s'" % [ remove_err, result.file_path ])

	return result



func delete() -> void:
	var err := DirAccess.remove_absolute(file_dir_absolute)
	if err != OK:
		printerr("Error deleting JsonResource at '%s': code %s." % [ file_path_absolute, err ])



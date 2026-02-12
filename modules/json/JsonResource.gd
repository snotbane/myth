## A resource which can serialize data to, and deserialize data from, a JSON file. Useful for any kind of save data. This does NOT provide any access to available save files on the system. Typical usage includes prompting for a path using [FileDialog] and then either saving or loading to a new [JsonResource] instance.
class_name JsonResource extends Resource

#region Statics

const SECONDS_IN_DAY := 86400
const SECONDS_IN_HOUR := 3600
const SECONDS_IN_MINUTE := 60

const K_TIME_CREATED := &"time_created"
const K_TIME_MODIFIED := &"time_modified"

const KEY_SIZE := 16
const IV_SIZE := 16

const IMPORT_ORDER : PackedStringArray = [ &"script", &"resource_local_to_scene", &"resource_name", &"time_created", &"time_modified", &"data" ]

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


## The path to save to. Make sure extension is included. If left blank, a random path located in `user://` will be assigned.
@export var _save_path : String
func generate_save_path(name := str(randi())) -> String:
	var result := ""
	var actual_filename := name
	while true:
		result = "%s%s%s" % ["user://", actual_filename, ".json" if _encryption_password.is_empty() else ".dat"]
		if not FileAccess.file_exists(result): break
		actual_filename = "%s_%s" % [name, str(randi())]
	return result

var save_file_exists : bool :
	get: return FileAccess.file_exists(_save_path)


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


@export_storage var time_created : int
@export_storage var time_modified : int
@export_storage var data : Dictionary


func _init(__save_path__: String = generate_save_path()) -> void:
	_save_path = __save_path__
	time_created = NOW
	time_modified = time_created

	if not save_file_exists:
		save()


func json_export() -> Dictionary:
	return serialize(self)


func json_import(json: Variant) -> void:
	_resource_import(self, json[&"value"])



func shell_open() -> void:
	if not save_file_exists: return
	OS.shell_open(ProjectSettings.globalize_path(_save_path))
func shell_open_location() -> void:
	OS.shell_open(Myth.get_parent_folder(ProjectSettings.globalize_path(_save_path)))


func save(path: String = _save_path) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	# assert(file != null, "Cannot save to file, file does not exist: %s" % path)

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


func load(path: String = _save_path) -> void:
	_save_path = path
	assert(save_file_exists, "Cannot load from file, file does not exist: %s" % _save_path)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err := file.get_open_error()
		assert(false, "File load failed in JsonResource. Error code: %s. Path: %s" % [ err, path ])

	var json_string = _load(file)
	var json = JSON.parse_string(json_string)
	assert(json != null, "Couldn't parse string to json at path: %s" % path)

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
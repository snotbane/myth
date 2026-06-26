## A resource which can be saved as, and loaded from, a JSON file. Useful for any kind of user save data. This does NOT provide any access to available save files on the system. Typical usage includes prompting for a file_path_relative using [FileDialog] and then either saving or loading to a new [JsonResource] instance.
@abstract
class_name JsonResource
extends Resource

#region Statics

const DATA_NAME := "__DATA__"

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
	return unix_time + Time.get_time_zone_from_system().bias * 60

#endregion


#region Signals

## Emitted when [member _ready] is called.
signal ready

## Emitted after the file has successfully been deleted from the file system.
signal deleted

#endregion


#region Properties

## The time at which this [Resource] was originally created.
@export_storage var time_created: int

## The time at which this [Resource] was last [member changed].
@export_storage var time_changed: int


## Returns true if the [member file_exists], and custom conditions defined in [member _get_is_valid] pass.
var is_valid: bool:
	get: return file_exists and _get_is_valid()

## Custom implementation to check if the data is valid.
func _get_is_valid() -> bool: return true


#region Path

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

func set_parent_and_path(new_parent: JsonResource, new_relative_path: String = "") -> void:
	assert(new_parent != null or not new_relative_path.is_empty(), "Either one of 'new_parent' or 'new_relative_path' must be valid.")
	if new_relative_path.is_empty():
		new_relative_path = file_path_relative

	file_path = new_parent.file_path.path_join(new_relative_path) if new_parent else new_relative_path

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

## The path of the location of the actual JSON file, relative to [member file_path]. Only relevant if [member save_as_dir] is true.
var data_path_relative: String:
	get: return "%s.%s" % [DATA_NAME, file_ext]

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

#endregion


#region Encryption

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


@export var _auto_save_on_changed: bool = true

#endregion


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


static var TAG_REMOVE_WHITESPACE_REGEX := RegEx.create_from_string(r"^\s+|\s+$|[\n\t]+|(?:\b +(?= )\b)")

static func format_string_for_tag(s: String) -> String:
	return TAG_REMOVE_WHITESPACE_REGEX.sub(s, "")


## A collection of tags to assist in filtering this [JsonResource] among others. It is a [Variant] so that one can use either an [Array] or an [Object].
@export var tags: Variant


## Custom override to initialize [member tags]. This should return whatever kind of tag collection you wish to use.
func _tags_init() -> Variant:
	return PackedStringArray()


# ## Custom override to check if a [Variant] [param tag] matches the given [param text].
# func _tag_matches_text(tag, text: String) -> bool:
# 	return str(tag) == format_string_for_tag(text)


## Returns true if the given [param tag] exists in [member tags].
func has_tag(tag: Variant) -> bool:
	return tag in tags


## Returns true if the given [param text] matches any tag in [member tags]. If [member tags] is an array of [String]s, this is equivalent to [member has_tag].
func has_tag_by_name(text: String) -> bool:
	return find_tag_by_name(text) != null


## Returns the first tag in [member tags] that matches the given [param text].
func find_tag_by_name(text: String) -> Variant:
	text = format_string_for_tag(text)

	for tag in tags:
		# if _tag_matches_text(tag, text): return tag
		if str(tag) == text: return tag

	return null


## Creates a new tag, assuming that it does not already exist. Returns an error if unsuccessful.
func create_tag_by_name(text: String) -> int:
	text = format_string_for_tag(text)

	if text.is_empty(): return TAG_EMPTY_OR_WHITESPACE
	if has_tag_by_name(text): return TAG_ALREADY_EXISTS

	var err := _create_tag_by_name(text)
	if err: return err

	emit_changed()
	return OK

## Custom implementation for adding a tag by name. Assumes that all validation checks have passed and the tag is formatted properly.
func _create_tag_by_name(text: String) -> int:
	tags.push_back(text)
	return OK


## Removes an existing tag. Returns an error if unsuccessful.
func remove_tag_by_name(text: String) -> int:
	text = format_string_for_tag(text)

	if text.is_empty(): return TAG_EMPTY_OR_WHITESPACE
	if not has_tag_by_name(text): return TAG_DOES_NOT_EXIST

	var err := _remove_tag_by_name(text)
	if err: return err

	emit_changed()
	return OK

## Custom implementation for removing a tag by name.
func _remove_tag_by_name(text: String) -> int:
	tags.erase(text)
	return OK


#endregion

#endregion


#region Methods

func _init() -> void:
	time_created = NOW
	time_changed = time_created
	tags = _tags_init()
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
	if _auto_save_on_changed and file_exists:
		save()
func _changed() -> void: pass


func _saving() -> void: pass
func _loaded() -> void: pass
func _touched() -> void: pass


## Opens the JSON file for [FileAccess] use.
func open(flags: FileAccess.ModeFlags) -> FileAccess:
	return FileAccess.open(data_path, flags)


## Loads the [JsonResource] if it exists, or creates the file if it does not.
func touch(__file_path__: String = file_path) -> JsonResource:
	if _is_manipulating_file: return self

	file_path = __file_path__
	if file_exists:
		return self.load()
	else:
		return self.save()


var _is_manipulating_file: bool

## Serializes object data, and saves the [JsonResource] to the file system.
func save(__file_path__: String = file_path) -> JsonResource:
	if _is_manipulating_file: return self
	_is_manipulating_file = true

	file_path = __file_path__

	var data_dir_touch_err := DirAccess.make_dir_recursive_absolute(data_dir_absolute)
	if data_dir_touch_err != OK:
		printerr("Failed to save %s at path '%s': while attempting to touch directory: %s" % [self, data_dir_absolute, error_string(data_dir_touch_err)])
		_is_manipulating_file = false
		return null

	var file := open(FileAccess.WRITE)
	if file == null:
		printerr("Failed to save %s at data path '%s': while opening file: %s" % [self, data_path_absolute, error_string(FileAccess.get_open_error())])
		return null

	_saving()

	emit_changed()
	var json := JSON.stringify(Serialization.serialize(self), "\t" if OS.is_debug_build() else "", OS.is_debug_build(), true)
	_save(file, json)

	_touched()

	if not _is_ready:
		_ready()
		_is_ready = true
		ready.emit()

	_is_manipulating_file = false
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
	if _is_manipulating_file: return self
	_is_manipulating_file = true

	file_path = __file_path__

	var file := open(FileAccess.READ)
	if file == null:
		printerr("Failed to load JsonResource. Error code: %s (%s) at path: %s" % [FileAccess.get_open_error(), error_string(FileAccess.get_open_error()), data_path])
		_is_manipulating_file = false
		return null

	var json_string = _load(file)
	var json = JSON.parse_string(json_string)
	assert(json != null, "Couldn't parse string to json at file_path_relative: %s" % data_path)

	Serialization.deserialize(json, self)
	_loaded()
	_touched()

	if not _is_ready:
		_ready()
		_is_ready = true
		ready.emit()

	_is_manipulating_file = false
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


func save_child(child: JsonResource, relative_path: String = file_path_relative) -> JsonResource:
	return child.save(self.file_path.path_join(relative_path))


## Loads all child [JsonResource]s in the path [param relative_dir]. A [param template] must be supplied to define the class/script of the object.
func load_children(template: JsonResource, relative_dir: String = "") -> Array:
	var result: Array

	for path in get_children_load_paths(relative_dir):
		result.push_back(template.duplicate().load(path))

	return result


func get_children_load_paths(relative_dir: String = "") -> PackedStringArray:
	return Myth.get_paths_in_folder(
		file_path.path_join(relative_dir) if relative_dir else file_path,
		true,
		null,
		RegEx.create_from_string("^%s\\..*$" % DATA_NAME)
	) if save_as_dir else []


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

#endregion

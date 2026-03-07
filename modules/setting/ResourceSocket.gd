## Keeps track of a set of [Setting]s and stores their contents inside a [Resource]. The names of the nodes must match the properties of the [Resource].
class_name ResourceSocket extends Node


const STORAGE_DIR := "user://"


static func _get_settings(node: Node) -> Array[Setting]:
	var result : Array[Setting] = []
	for child in node.get_children():
		if child is Setting:
			result.push_back(child)
		result.append_array(_get_settings(child))
	return result


## Emits when the value of [member resource] is changed to a different [Resource].
signal resource_value_changed(new_resource: Resource)

## Emits when [member resource]'s [member Resource.changed] is emitted.
signal resource_changed


var _resource : Resource
## The resource to be modified. If not set, no resource will be used and all data will be stored inside a separate, generic [JsonResource].
@export var resource : Resource :
	get: return _resource
	set(value):
		var value_changed : bool = _resource != value

		if _resource:
			_resource.changed.disconnect(resource_changed.emit)

		_resource = value

		if _resource:
			_resource.changed.connect(resource_changed.emit)

		if _resource is JsonResource:
			storage_resource = _resource
		elif not storage_path.is_empty():
			storage_resource = JsonResource.new(storage_path)
			storage_resource.data[&"resource"] = resource
		else:
			storage_resource = null

		refresh_settings_cache()

		if autoload and storage_resource:
			storage_resource.load()
			pull_all_settings_from_resource.call_deferred()

		if value_changed:
			resource_value_changed.emit(resource)
func set_resource(value: Resource) -> void:
	resource = value


# These will be explicitly added, if they do not belong to this node's parent or any descendant.
@export var manual_settings : Array[Node]
var settings_cache : Array[Node]


## If set, the data will be stored here. If blank, do nothing. Typically, leave this blank for settings which are part of the actual game object, and then save everything in bulk. Consider setting this to something like "user://settings.json" for user preferences or settings.
@export var storage_path : String :
	get: return storage_resource.save_path if storage_resource else String()
	set(value):
		if storage_resource == null: return

		storage_resource.save_path = value

## Determines when the resource should be saved to an [member storage_path]. If it's empty, this doesn't do anything.
@export_enum("No Autosave", "On Self Hidden", "On Parent Hidden", "On Value Changed") var autosave : int = ON_VALUE_CHANGED
enum {
	## This setting will not save_all automatically. Call [member commit()] on any setting in order to save_all changes to all settings with the same [member storage_path].
	NO_AUTOSAVE,
	## This setting will save_all when this [Node] is hidden.
	ON_SELF_HIDDEN,
	## This setting will save_all when its parent is hidden.
	ON_PARENT_HIDDEN,
	## This setting will save_all when any tracked [Setting] value changes.
	ON_VALUE_CHANGED,
}

## If enabled, all overridden [Setting]s present in the saved file will have their values set from this resource. If disabled (or if no save file exists), the [Setting]s will update the resource instead.
@export var autoload : bool = true


var storage_resource : JsonResource


func refresh_settings_cache() -> void:
	for setting in settings_cache:
		if setting == null: continue

		if setting.value_changed.is_connected(push_setting_to_resource):
			setting.value_changed.disconnect(push_setting_to_resource)

		if setting.value_changed.is_connected(save_all):
			setting.value_changed.disconnect(save_all)


	settings_cache = get_all_settings()

	for setting in settings_cache:
		setting.value_changed.connect(push_setting_to_resource.bind(setting).unbind(1))

		if autosave:
			setting.value_changed.connect(save_all.unbind(1))


func get_all_settings() -> Array[Node]:
	var result := manual_settings.duplicate()
	for setting in _get_settings(get_parent()):
		if setting in result or setting is not Setting: continue
		result.push_back(setting)
	return result


func push_setting_to_resource(setting: Setting) -> void:
	if resource:
		resource.set(setting.name, setting.value)
	elif setting.is_overridden:
		storage_resource.data[setting.name] = setting.value
	else:
		storage_resource.data.erase(setting.name)


func push_all_settings_to_resource() -> void:
	for setting in settings_cache:
		push_setting_to_resource(setting)


func pull_setting_from_resource(setting: Setting) -> void:
	if resource:
		setting.value = resource.get(setting.name)
	elif storage_resource.data.has(setting.name):
		setting.value = storage_resource.data[setting.name]
		print("Pulled value from storage data: ", setting.value)


func pull_all_settings_from_resource() -> void:
	for setting in settings_cache:
		pull_setting_from_resource(setting)


func save_all() -> void:
	if storage_resource == null: return

	storage_resource.save()


## Resets all [Setting]s to their default values.
func reset_all(save := false) -> void:
	for setting in settings_cache:
		setting.reset()
	if save:
		save_all()

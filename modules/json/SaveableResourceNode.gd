## Keeps track of a set of [Setting]s and stores their contents inside a [Resource]. The names of the nodes must match the properties of the [Resource].
class_name SaveableResourceNode extends Node


const STORAGE_DIR := "user://"


static func _get_prefs(node: Node) -> Array[Setting]:
	var result : Array[Setting] = []
	for child in node.get_children():
		if child is Setting:
			result.push_back(child)
		result.append_array(_get_prefs(child))
	return result


## The resource to be modified. If not set, no resource will be used and all data will be stored inside a separate, generic [JsonResource].
@export var resource : Resource

# These will be explicitly added, if they do not belong to this node's parent or any descendant.
@export var manual_prefs : Array[Setting]
var prefs_cache : Array[Setting]


## If set, the data will be stored here. If blank, do nothing. Typically, leave this blank for settings which are part of the actual game object, and then save everything in bulk. Consider setting this to something like "user://settings.json" for user preferences or settings.
@export var storage_path : String


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


func _ready() -> void:
	if not storage_path.is_empty():
		storage_resource = JsonResource.new(storage_path)
		if resource != null:
			storage_resource.data[&"resource"] = resource

	refresh_prefs_cache()

	if autoload and storage_resource:
		storage_resource.load()
		pull_all_prefs_from_resource()



func refresh_prefs_cache() -> void:
	for pref in prefs_cache:
		if pref == null: continue

		if pref.value_changed.is_connected(push_pref_to_resource):
			pref.value_changed.disconnect(push_pref_to_resource)

		if pref.value_changed.is_connected(save_all):
			pref.value_changed.disconnect(save_all)


	prefs_cache = get_all_prefs()

	for pref in prefs_cache:
		pref.value_changed.connect(push_pref_to_resource.bind(pref).unbind(1))

		if autosave:
			pref.value_changed.connect(save_all.unbind(1))


func get_all_prefs() -> Array[Setting]:
	var result := manual_prefs.duplicate()
	for pref in _get_prefs(get_parent()):
		if pref in result: continue
		result.push_back(pref)
	return result


func push_pref_to_resource(pref: Setting) -> void:
	if resource:
		resource.set(pref.name, pref.value)
		# print("set resource '%s' to '%s'" % [pref.name, resource.get(pref.name)])
	elif pref.is_overridden:
		storage_resource.data[pref.name] = pref.value
		# print("set storage resource data '%s' to '%s'" % [pref.name, storage_resource.data[pref.name]])
	else:
		storage_resource.data.erase(pref.name)


func push_all_prefs_to_resource() -> void:
	for pref in prefs_cache:
		push_pref_to_resource(pref)


func pull_pref_from_resource(pref: Setting) -> void:
	if resource:
		pref.value = resource.get(pref.name)
	elif storage_resource.data.has(pref.name):
		pref.value = storage_resource.data[pref.name]
		print("Pulled value from storage data: ", pref.value)


func pull_all_prefs_from_resource() -> void:
	for pref in prefs_cache:
		pull_pref_from_resource(pref)


func save_all() -> void:
	if storage_resource:
		storage_resource.save(storage_path)


## Resets all [Setting]s to their default values.
func reset_all(save := false) -> void:
	for pref in prefs_cache:
		pref.reset()
	if save:
		save_all()

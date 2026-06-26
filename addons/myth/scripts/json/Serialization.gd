class_name Serialization

const IGNORED_PROPERTY_NAMES := [
	"script",
	"metadata/_custom_type_script"
]

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
	var script = load(json[&"script"]) if json.has(&"script") else null

	if result.has_method(&"_deserialize_custom"):
		Myth.change_script(result, script, PROPERTY_USAGE_STORAGE)
		var args := [data, context]
		args.resize(result.get_method_argument_count(&"_deserialize_custom"))
		result._deserialize_custom.callv(args)
		return result
	else:
		Myth.change_script(result, script, PROPERTY_USAGE_STORAGE, data.keys())


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

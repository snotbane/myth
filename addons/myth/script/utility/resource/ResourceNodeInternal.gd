# @tool
# extends ResourceNode


# @export_custom(PROPERTY_HINT_NONE, "", PropertyUsageFlags.PROPERTY_USAGE_EDITOR)
# var resource: Resource:
# 	get: return load(file_path) if ResourceLoader.exists(file_path) else null
# 	set(value): file_path = value.resource_path if value else ""

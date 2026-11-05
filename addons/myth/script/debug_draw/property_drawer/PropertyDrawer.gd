@icon("res://addons/myth/script/debug_draw/property_drawer/PropertyDrawer.svg")
@tool
class_name PropertyDrawer
extends Resource

static func float_to_string(value: float, float_format: String = "%s") -> String:
	return ("+" if value > 0.0 else "-" if value < 0.0 else "±") + (float_format % absf(value))


static func int_to_string(value: int, int_format: String = "%s") -> String:
	return ("+" if value > 0 else "-" if value < 0 else "±") + (int_format % absi(value))


static func value_to_string(value: Variant, format: String = "%s") -> String:
	if value is Vector3:
		return "( %s,  %s,  %s )" % [
		float_to_string(value.x, format),
		float_to_string(value.y, format),
		float_to_string(value.z, format),
	]

	elif value is Vector2:
		return "( %s,  %s )" % [
		float_to_string(value.x, format),
		float_to_string(value.y, format),
	]

	elif value is float:
		return float_to_string(value, format)

	elif value is Vector3i:
		return "( %s,  %s,  %s )" % [
		int_to_string(value.x, format),
		int_to_string(value.y, format),
		int_to_string(value.z, format),
	]

	elif value is Vector2i:
		return "( %s,  %s )" % [
		int_to_string(value.x, format),
		int_to_string(value.y, format),
	]

	elif value is int:
		return int_to_string(value, format)

	else:
		return str(value)


@export
var path: NodePath

@export
var color: Color = Color.WHITE_SMOKE

@export_group("Text", "text_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var text_enabled: bool = true

@export
var text_format: String = "%s"


@export_group("Visual", "visual_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var visual_enabled: bool = true

@export
var visual_global_space: bool

@export_enum("Point", "Spike", "Line", "Arrow", "Axis")
var visual_shape: int

@export_range(0.0, 10.0, 0.01, "or_greater")
var visual_size: float = 0.25


func get_value_string(value: Variant) -> String:
	if text_format:
		return "%s\n%s" % [
		# return "%s : %s\n= %s\n\n" % [
			str(path),
			# path.get_concatenated_names(),
			# path.get_concatenated_subnames().replace_char(ord(":"), ord(".")),
			value_to_string(value, text_format)
		]
	else:
		return str(path)

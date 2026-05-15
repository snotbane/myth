
## Generic class for user-facing, static object data.
@tool class_name ItemDefinition extends Resource


## User-facing icon.
@export var icon : Texture2D

## User-facing name.
@export var name : String

## User-facing description.
@export_multiline var description : String

## The maximum quantity of this [Item] that can be placed inside of an [InventoryDictionary]. The value must be an [int] or [float]. 0 is unlimited, and [null] is equivalent to [int] unlimited.
@export var _capacity : Variant
var capacity : Variant :
	get: return _capacity if _capacity != null else int(0)
var capacity_is_unlimited : bool :
	get: return _capacity == null or _capacity == 0.0
var quantity_default : Variant :
	get:
		match typeof(_capacity):
			TYPE_NIL, TYPE_INT: return int(0)
			TYPE_FLOAT: return float(0.0)
			_: assert(false, "Capacity must be int, float, or null. Defaulting to int(0).")
		return int(0)


func _to_string() -> String: return name

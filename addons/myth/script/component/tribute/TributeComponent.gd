## Base class for any Component of which there are many, and only one in the entire game instance can be active.
@abstract
class_name TributeComponent
extends Component

static var TRIBUTE_REGISTRY: Dictionary
static var TRIBUTE_CURRENTS: Dictionary


static func get_current(key: StringName) -> TributeComponent:
	return TRIBUTE_CURRENTS.get(key)


## A unique key to group tributes together.
@abstract
func _get_static_key() -> StringName


var registry: Array:
	get: return TRIBUTE_REGISTRY[_get_static_key()]

var current_node: TributeComponent:
	get: return TRIBUTE_CURRENTS[_get_static_key()]
	set(value): TRIBUTE_CURRENTS[_get_static_key()] = value


@export_range(-128, 128, 1, "or_greater", "or_less")
var priority: int = 0:
	set(value):
		priority = value
		sort_registry()
		if not is_node_ready(): return

		refresh_current()


var current: bool:
	get: return self == current_node


func _init() -> void:
	if not TRIBUTE_REGISTRY.has(_get_static_key()):
		TRIBUTE_REGISTRY[_get_static_key()] = []

	if not TRIBUTE_CURRENTS.has(_get_static_key()):
		TRIBUTE_CURRENTS[_get_static_key()] = null


func _enter_tree() -> void:
	super._enter_tree()

	registry.push_back(self)
	sort_registry()


func _exit_tree() -> void:
	registry.erase(self)
	refresh_current()


func _ready() -> void:
	super._ready()

	refresh_current()


func _can_be_active() -> bool: return true


func sort_registry() -> void:
	registry.sort_custom(_sort_registry)

func _sort_registry(a: TributeComponent, b: TributeComponent) -> bool:
	return a.priority > b.priority


func _get_current() -> TributeComponent:
	for tribute in registry:
		if not (tribute.enabled and tribute._can_be_active()): continue

		return tribute

	return null


func refresh_current() -> void:
	var new_current := _get_current()
	if TRIBUTE_CURRENTS[_get_static_key()] == new_current: return

	TRIBUTE_CURRENTS[_get_static_key()] = new_current

	if new_current:
		new_current._became_current()

func _became_current() -> void: pass

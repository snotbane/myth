## Simple class for a [Node] that can be enabled and disabled, and caches its [member parent].
class_name Component extends Node

signal enabled_changed

@onready var _process_mode_onready: ProcessMode = process_mode

## If the [Component] is enabled, [member process_mode] will be set to whatever its value is on ready. If disabled, [member process_mode] will be set to [Node.PROCESS_MODE_DISABLED].
@export var enabled: bool = true:
	set(value):
		if enabled == value: return
		enabled = value

		set_block_signals(not enabled)
		process_mode = _process_mode_onready if enabled else PROCESS_MODE_DISABLED
		enabled_changed.emit()


func enable() -> void: enabled = true
func disable() -> void: enabled = false
func set_enabled(value: bool) -> void: enabled = value
func toggle_enabled() -> void: enabled = not enabled


var _parent: Node
var parent: Node:
	get: return _parent


func _enter_tree() -> void:
	_parent = get_parent()


func _ready() -> void:
	set_block_signals(not enabled)
	process_mode = _process_mode_onready if enabled else PROCESS_MODE_DISABLED

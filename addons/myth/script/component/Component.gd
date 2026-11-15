## Simple class for a [Node] that can be enabled and disabled, and caches its [member parent].
@icon("res://addons/myth/script/component/Component.svg")
class_name Component
extends Node

## Emits when [member enabled] changes.
signal enabled_changed

## Emits when the parent is ready (or when the parent changes).
signal parent_ready

@onready
var _process_mode_onready: ProcessMode = process_mode

## If the [Component] is enabled, [member process_mode] will be set to whatever its value is on ready. If disabled, [member process_mode] will be set to [Node.PROCESS_MODE_DISABLED].
@export
var enabled: bool = true:
	set(value):
		if enabled == value: return
		enabled = value

		if enabled:
			set_block_signals(false)

		process_mode = _process_mode_onready if enabled else PROCESS_MODE_DISABLED
		enabled_changed.emit()

		if not enabled:
			set_block_signals(true)


func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false

func set_enabled(value: bool) -> void:
	enabled = value

func toggle_enabled() -> void:
	enabled = not enabled


## The cached parent node. Setting this value will reparent this [Component].
var parent: Node:
	set(value):
		if parent == value:
			return

		if get_parent() != value:
			reparent(value)
			return

		if parent:
			_exit_parent()

		parent = value

		if parent:
			_enter_parent()

			if parent.is_node_ready():
				_parent_ready()
			else:
				parent.ready.connect(__on_parent_ready, CONNECT_ONE_SHOT)


func is_parent_ready() -> bool:
	return parent and parent.is_node_ready()


func ensure_parent_ready():
	if is_parent_ready():
		return

	await parent_ready


## This method is called when the [Component] enters the tree and [member parent] is assigned. [member parent] is not null, but it may not be ready. See [member _parent_ready].
func _enter_parent() -> void: pass

## This method is called just before [member parent] changes. Use this to tear down the previous [member parent] (guaranteed to not be null).
func _exit_parent() -> void: pass

## This method is called when both (A) the [member parent] changes and (B) the [member parent] is ready.
func _parent_ready() -> void: pass


func __on_parent_ready() -> void:
	parent_ready.emit()
	_parent_ready()


func _enter_tree() -> void:
	parent = get_parent()


func _exit_tree() -> void:
	set_block_signals(false)
	process_mode = _process_mode_onready


func _ready() -> void:
	set_block_signals(not enabled)
	process_mode = _process_mode_onready if enabled else PROCESS_MODE_DISABLED

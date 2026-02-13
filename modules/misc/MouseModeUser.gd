## Allows you to manage the global [Input.MouseMode] using [Node]s. Very useful for pause menues.
class_name MouseModeUser extends Node

const PROJECT_SETTING_HINT := {
	&"name": "display/mouse_cursor/default_mouse_mode",
	&"type": TYPE_INT,
	&"hint": PropertyHint.PROPERTY_HINT_ENUM,
	&"hint_string": "Visible,Hidden,Captured,Confined,Confined Hidden,Max",
}

static var DEFAULT_MOUSE_MODE : Input.MouseMode :
	get: return ProjectSettings.get_setting(PROJECT_SETTING_HINT[&"name"], Input.MouseMode.MOUSE_MODE_VISIBLE)

static var registry : Array[MouseModeUser]
static var active_node : MouseModeUser

static func _static_init() -> void:
	Input.mouse_mode = DEFAULT_MOUSE_MODE

static func is_viable_node(node: Node) -> bool:
	return node != null and node.has_signal(&"visibility_changed")

static func refresh_mouse_mode() -> void:
	active_node = get_active_node()
	Input.mouse_mode = active_node.mouse_mode if active_node != null else DEFAULT_MOUSE_MODE

static func sort_registry() -> void:
	registry.sort_custom(_sort_method)
static func _sort_method(a: MouseModeUser, b: MouseModeUser) -> bool:
	return a.priority < b.priority

static func get_active_node() -> MouseModeUser :
	for i in registry.size():
		if registry[-i-1].visible_node == null: continue
		if registry[-i-1].visible_node.visible: return registry[-i-1]
	return null

## The [Input.MouseMode] that this [Node] will enforce.
@export var mouse_mode : Input.MouseMode

var _visible_node : Node
## This is the [Node] that is actually watched to check for visibility. It must be a [Node] with a [member visible] property and [member visibility_changed] signal. Leave blank to use THIS node.
@export var visible_node : Node :
	get: return _visible_node
	set(value):
		_visible_node = value
		MouseModeUser.refresh_mouse_mode()

## Use this value to set the visibility of [member visible_node] on ready, if desired.
@export_enum("Do Nothing", "Show", "Hide") var visibility_on_ready : int
enum { NONE, SHOW, HIDE }

var _priority : int
## The priority of this [member mouse_mode]. A [MouseModeUser] with a high priority will enforce its [member mouse_mode] over other [MouseModeUser]s with a lower [member priority] (provided that it is visible).
@export var priority : int :
	get: return _priority
	set(value):
		_priority = value
		MouseModeUser.sort_registry()



func _ready() -> void:
	if (visible_node == null or not visible_node.has_signal(&"visibility_changed")) and self.has_signal(&"visibility_changed"):
		visible_node = self

	if visible_node == null: return

	visible_node.visibility_changed.connect(_visibility_changed)

	match visibility_on_ready:
		SHOW: visible_node.visible = true
		HIDE: visible_node.visible = false

func _enter_tree() -> void:
	MouseModeUser.registry.push_back(self)
	MouseModeUser.sort_registry()
	MouseModeUser.refresh_mouse_mode()


func _exit_tree() -> void:
	MouseModeUser.registry.erase(self)
	MouseModeUser.refresh_mouse_mode()


func _visibility_changed() -> void:
	MouseModeUser.refresh_mouse_mode()
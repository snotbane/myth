## Helps manage the [member Input.mouse_mode] via independent [Node]s. Can be extended to implement mouse input.
@icon("res://addons/myth/script/component/tribute/mouse/MouseComponent.svg")
class_name MouseComponent
extends TributeComponent

static var DEFAULT_MOUSE_MODE: Input.MouseMode:
	get: return ProjectSettings.get_setting("display/mouse_cursor/default_mouse_mode", Input.MOUSE_MODE_VISIBLE)


## The [Input.MouseMode] to use when the component's parent [member is_visible_in_tree]. Using Ignore ensures that this node will never change the mouse mode.
@export_enum("Visible", "Hidden", "Captured", "Confined", "Confined Hidden", "Ignore")
var mouse_mode: int = Input.MOUSE_MODE_VISIBLE:
	set(value):
		mouse_mode = value
		if not is_node_ready(): return

		if current: _became_current()


var parent_visible_in_tree: bool:
	get: return not parent.has_method(&"is_visible_in_tree") or parent.is_visible_in_tree()

func _get_static_key() -> StringName:
	return &"MouseComponent"


func _can_be_active() -> bool:
	return mouse_mode != Input.MOUSE_MODE_MAX and parent_visible_in_tree


func _became_current() -> void:
	if mouse_mode == Input.MOUSE_MODE_MAX: return

	Input.mouse_mode = mouse_mode


func _ready() -> void:
	super._ready()

	if parent.has_signal(&"visibility_changed"):
		parent.visibility_changed.connect(refresh_current)


func _input(event: InputEvent) -> void:
	if not current:
		return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_became_current()

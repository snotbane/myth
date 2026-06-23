## A window with some basic functionality and works with [AuxiliaryMenuBar]. Intended for use as an independent window as part of a utility application.
class_name AuxiliaryWindow
extends Window

var ever_shown: bool:
	get: return get_meta(&"ever_shown", false)
	set(value): set_meta(&"ever_shown", value)

func _init() -> void:
	hide()
	transient = false
	force_native = true

	close_requested.connect(queue_free)
	visibility_changed.connect(_visibility_changed)


func _ready() -> void:
	AuxiliaryMenuBar.register_window(self)


func _visibility_changed() -> void:
	if ever_shown: return

	if visible:
		ever_shown = true

		if not get_parent().is_node_ready():
			await get_parent().ready

		reset_to_parent_centered()


## Moves the window to the center of its parent window.
func reset_to_parent_centered(parent_window: Window = get_parent().get_window()) -> void:
	content_scale_factor = parent_window.content_scale_factor
	size = Vector2i(800, 1000) * parent_window.content_scale_factor
	position = parent_window.position + (parent_window.size - size) / 2


## Ensures the window's size and position will reset the next time it is shown.
func queue_reset() -> void:
	ever_shown = false


## Toggles the window visibility, or grabs focus if not focused.
func toggle_or_grab_focus() -> void:
	if visible:
		if self == Window.get_focused_window():
			hide()
		else:
			grab_focus()
	else:
		show()

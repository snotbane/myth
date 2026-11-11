## Add this as the child of a [Window]. When the [Window]'s visibility changes, this node will reparent itself to be a child of the [Window] if it is visible, and a sibling of the [Window] if it is not. This ensures that the input is always picked up, relative to this window. Common use case is to connect [member changed] to [member Window.set_visible], to toggle the window.
class_name WindowInputAction
extends InputAction

var window: Window:
	set(value):
		if window == value:
			return

		if window and window.visibility_changed.is_connected(_window_visibility_changed):
			window.visibility_changed.disconnect(_window_visibility_changed)

		window = value

		if window and not window.visibility_changed.is_connected(_window_visibility_changed):
			window.visibility_changed.connect(_window_visibility_changed, ConnectFlags.CONNECT_DEFERRED)

func _ready() -> void:
	super._ready()

	if parent is Window:
		window = parent

		if not window.visible:
			_window_visibility_changed.call_deferred()


func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not Window:
		return ["This node's parent should be a Window."]
	return []


func _window_visibility_changed() -> void:
	reparent(window if window.visible else window.get_parent())

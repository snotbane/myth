@tool
extends Button

const ICON_ERROR := preload("res://addons/myth/asset/icons/AlertError.svg")
const ICON_INFO := preload("res://addons/myth/asset/icons/AlertInfo.svg")
const ICON_WARNING := preload("res://addons/myth/asset/icons/AlertWarning.svg")

signal changed

var binder: InputBinder

var warning_button: Button

func _init(__binding__: InputBinder, __event__: InputEvent = null, create_type: int = InputBinder.EVENT_BUTTON_REMAP) -> void:
	toggle_mode = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

	binder = __binding__
	readonly = create_type == InputBinder.EVENT_BUTTON_READONLY
	button_pressed = create_type == InputBinder.EVENT_BUTTON_REMAP
	custom_minimum_size.x = binder.buttons_minimum_width
	size_flags_horizontal = binder.buttons_size_flags_horizontal

	warning_button = Button.new()
	warning_button.visible = false
	warning_button.flat = true
	warning_button.z_index = +1
	warning_button.icon = ICON_WARNING
	warning_button.pivot_offset_ratio = Vector2(0.5, 0.5)
	warning_button.set_anchors_preset(PRESET_TOP_RIGHT)
	add_child(warning_button)

	event = __event__

	focus_exited.connect(set.bind(&"button_pressed", false))
	changed.connect(binder.set_action_data_from_children)
	warning_button.pressed.connect(binder.handle_warnings.bind(self))


func _ready() -> void:
	_refresh_disabled()
	_refresh_warnings()
	_refresh_display()

var event: InputEvent:
	set(value):
		if value == null and not binder.event_can_clear_any:
			return

		if event:
			event.changed.disconnect(_refresh_display)

		event = value
		event_staged = null

		if event:
			_refresh_physical()
			_refresh_modifiers()

			if is_node_ready():
				check_duplicates()

			_refresh_warnings()
			event.changed.connect(_refresh_display)

		elif is_node_ready() and binder.event_can_remove_any:
			queue_free()

		else:
			_refresh_display()

		changed.emit()

var _event_staged: InputEvent
var event_staged: InputEvent:
	get: return _event_staged if _event_staged else event
	set(value):
		_event_staged = value
		_refresh_display()

var readonly: bool


func try_clear() -> bool:
	if disabled or not binder.event_add_and_remove:
		return false

	clear()
	return true


func clear() -> void:
	event = null


func commit(__event__: InputEvent = event_staged) -> void:
	if event == __event__:
		revert()
		return

	event = __event__
	button_pressed = false
	_refresh_warnings()


func revert() -> void:
	event = event
	button_pressed = false
	_refresh_display()


func stage(__event__: InputEvent = null) -> void:
	event_staged = __event__


func _refresh_disabled() -> void:
	disabled = readonly or get_index() < binder.event_restricteds or not binder.action_exists



func _refresh_display() -> void:
	if InputLocalization.apply_to(self): pass
	else:
		icon = null
		text = "..." if button_pressed else \
				event.as_text() if event else InputLocalization.EMPTY_SPACE_TEXT
		tooltip_text = event.as_text() if event else ""


func _refresh_physical() -> void:
	if event is not InputEventKey:
		return

	if binder.physical_toggled:
		event.physical_keycode = maxi(event.keycode, event.physical_keycode)
		event.keycode = 0
	else:
		event.keycode = maxi(event.keycode, event.physical_keycode)
		event.physical_keycode = 0


func _refresh_modifiers() -> void:
	if binder.event_allow_modifiers or event is not InputEventWithModifiers:
		return

	event.alt_pressed = false
	event.shift_pressed = false
	event.command_or_control_autoremap = false
	event.ctrl_pressed = false
	event.meta_pressed = false


func _refresh_warnings() -> void:
	pass

## Removes any duplicate events, keeping this one.
func check_duplicates(exact_match: bool = true) -> void:
	if event == null: return

	for other: InputBinder.EventButton in binder.get_event_buttons():
		if self == other or other.event == null or not event.is_match(other.event, exact_match): continue

		other.event = null


func _input(__event__: InputEvent) -> void:
	if __event__.is_echo():
		return

	if button_pressed:
		if __event__.is_pressed():
			if InputLocalization.is_escape(__event__):
				revert()
				get_viewport().set_input_as_handled()
			else:
				event_staged = __event__
				get_viewport().set_input_as_handled()

		if _event_staged and (
			not binder.event_allow_modifiers
			or __event__ is not InputEventKey
			or (
				__event__.is_released()
				and get_literal_or_physical_keycode(__event__) == get_literal_or_physical_keycode(event_staged)
			)
		):
			commit()
			get_viewport().set_input_as_handled()

	elif is_hovered() or has_focus():
		if __event__.is_action_pressed(&"_myth_input_binder_remove"):
			if try_clear():
				get_viewport().set_input_as_handled()

		elif __event__.is_action_pressed(&"_myth_input_binder_warning"):
			warning_button.pressed.emit()
			get_viewport().set_input_as_handled()


func get_literal_or_physical_keycode(__event__: InputEvent) -> int:
	return (
		KEY_UNKNOWN
		if __event__ is not InputEventKey
		else __event__.physical_keycode
		if binder.physical_toggled
		else __event__.keycode
	)

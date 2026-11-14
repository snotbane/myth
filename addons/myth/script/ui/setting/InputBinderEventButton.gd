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

	tree_exited.connect(resolve_warnings)
	warning_button.pressed.connect(binder.handle_warnings.bind(self))


func _ready() -> void:
	warning_button.position -= warning_button.size * 0.5

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
				resolve_local_duplicates()

			_refresh_warnings()
			event.changed.connect(_refresh_display)

		elif is_node_ready() and binder.event_can_remove_any:
			queue_free()

		else:
			_refresh_warnings()
			_refresh_display()

		changed.emit()

var _event_staged: InputEvent
var event_staged: InputEvent:
	get: return _event_staged if _event_staged else event
	set(value):
		_event_staged = value
		_refresh_display()

var _event_previous: InputEvent

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


## Removes any duplicate events, keeping this one.
func resolve_local_duplicates(exact_match: bool = true) -> void:
	if event == null: return

	for other: InputBinder.EventButton in binder.get_event_buttons():
		if self == other or other.event == null or not event.is_match(other.event, exact_match): continue

		other.event = null


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



class Warning \
extends RefCounted:
	enum {
		UNKNOWN = -1,
		ACTION_UNBOUND_IN_PROJECT,
		ACTION_REQUIRED_UNBOUND_BY_USER,
		CONFLICTS_WITH_ANOTHER,
	}

	func get_error_code_string() -> String:
		match code:
			UNKNOWN:
				return "Unknown error."

			ACTION_UNBOUND_IN_PROJECT:
				return "The InputBinder's action is not bound to any valid action in the ProjectSettings."

			ACTION_REQUIRED_UNBOUND_BY_USER:
				return "This action must be bound."

			CONFLICTS_WITH_ANOTHER:
				if related and related.owner:
					return "Conflicts with %s." % str(related.owner.binder.text)
				else:
					return "Conflicts with another (unknown)."

			_:
				return "Unimplemented error."


	var owner: InputBinder.EventButton
	var code: int
	var related: Warning

	func _init(__owner__: InputBinder.EventButton, __code__: int = UNKNOWN) -> void:
		owner = __owner__
		code = __code__


	func _to_string() -> String:
		return get_error_code_string()


	func resolve() -> void:
		owner.warnings.erase(self)
		owner._refresh_warning_button()

		if related:
			related.related = null
			related.resolve()
			related = null


var warnings: Array[Warning] = []


func resolve_warnings() -> void:
	for warning in warnings.duplicate():
		warning.resolve()


func create_warning(code: int) -> Warning:
	var result := Warning.new(self, code)
	warnings.push_back(result)
	_refresh_warning_button()
	return result


func has_conflict_with(other: InputBinder.EventButton) -> bool:
	for warning in warnings:
		if warning.related.owner == other:
			return true

	return false


func create_conflict_with(other: InputBinder.EventButton) -> void:
	if has_conflict_with(other):
		return

	var a := create_warning(Warning.CONFLICTS_WITH_ANOTHER)
	var b := other.create_warning(Warning.CONFLICTS_WITH_ANOTHER)
	a.related = b
	b.related = a



## Occurs any time the [member event] changes or when the [InputBinderManager] is ready.
func _refresh_warnings() -> void:
	resolve_warnings()

	assert(warnings.is_empty())

	if binder.action.is_empty():
		create_warning(Warning.ACTION_UNBOUND_IN_PROJECT)

	elif binder.event_required and binder.action_data.has("events") and binder.action_data["events"].is_empty():
		create_warning(Warning.ACTION_REQUIRED_UNBOUND_BY_USER)

	elif event:
		for other in binder.conflict_candidates:
			for other_button in other.get_event_buttons():
				if other_button.event == null:
					continue

				if event.is_match(other_button.event):
					create_conflict_with(other_button)


func _refresh_warning_button() -> void:
	warning_button.visible = not warnings.is_empty()
	var warning_tooltip_text := ""
	for warning in warnings:
		warning_tooltip_text += "* " + warning.to_string() + "\n"
	warning_tooltip_text = warning_tooltip_text.left(-1)
	warning_button.tooltip_text = warning_tooltip_text




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

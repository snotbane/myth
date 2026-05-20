@tool class_name InputBinderButton extends Button

class Warning extends RefCounted:
	var text: String
	var other: Control

	func _init(__text__: String, __other__: Control = null) -> void:
		text = __text__
		other = __other__

	func _to_string() -> String:
		return text


enum {
	READ_ONLY,
	REFRESH,
	BEGIN_REMAP,
}

const ALLOWED_INPUT_CLASSES: PackedStringArray = [
	"InputEventJoypadButton",
	"InputEventJoypadMotion",
	"InputEventKey",
	"InputEventMouseButton",
]

signal remapped

var input: InputBinder
var read_only: bool

var event: InputEvent:
	set(value):
		if value == null and not input.can_clear_button: return

		if event:
			event.changed.disconnect(_refresh_display)

		event = value
		event_staged = null

		if event:
			_refresh_physical()
			_refresh_modifiers()

			if is_node_ready():
				_check_duplicates()

			_refresh_warnings()
			event.changed.connect(_refresh_display)

		elif is_node_ready() and input.can_remove_button:
			queue_free()

		else:
			_refresh_display()

		remapped.emit()

var _event_staged: InputEvent
var event_staged: InputEvent:
	get: return _event_staged if _event_staged else event
	set(value):
		_event_staged = value
		_refresh_display()


var warning_icon: Texture2D:
	get: return preload("res://addons/myth/icons/NodeWarning.svg")


var warning_button: Button

var warnings: Array[Warning]:
	set(value):
		warnings = value
		warning_button.visible = false

		for warning in warnings:
			if warning == null: continue

			warning_button.visible = true
			warning_button.tooltip_text += "* %s\n" % [warning.text]

			if warning.other is not InputBinderButton: continue

			warning.other._refresh_warnings()
			# warning.other.receive_conflict_with(self)

		warning_button.tooltip_text = warning_button.tooltip_text.left(-1)


func _init(__selector_ancestor__: InputBinder, __event__: InputEvent = null, create_type: int = BEGIN_REMAP) -> void:
	toggle_mode = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

	input = __selector_ancestor__
	read_only = create_type == READ_ONLY
	button_pressed = create_type == BEGIN_REMAP
	size_flags_horizontal = input.buttons_size_flags_horizontal
	custom_minimum_size.x = input.buttons_minimum_width

	warning_button = Button.new()
	warning_button.visible = false
	warning_button.flat = true
	warning_button.z_index = +1
	warning_button.icon = warning_icon
	warning_button.pivot_offset_ratio = Vector2(0.5, 0.5)
	warning_button.set_anchors_preset(PRESET_TOP_RIGHT)
	add_child(warning_button)

	event = __event__

	focus_exited.connect(set.bind(&"button_pressed", false))
	remapped.connect(input.set_events_from_buttons)
	warning_button.pressed.connect(_on_warning_button_pressed)


func _exit_tree() -> void:
	for warning in warnings:
		if not warning.other is InputBinderButton: continue
		warning.other._refresh_warnings()


func _ready() -> void:
	warning_button.position -= warning_button.size * 0.5

	if button_pressed:
		grab_focus.call_deferred()

	_refresh_disabled()
	_refresh_warnings()
	_refresh_display()


func _pressed() -> void:
	if button_pressed:
		event_staged = null

		var remapper: Node = input.get_events_remap_scene().instantiate()
		remapper.open(self )


func _refresh_display() -> void:
	if InputLocalization.apply_to(self ): pass
	else:
		icon = null
		text = "..." if button_pressed else \
				event.as_text() if event else InputLocalization.EMPTY_SPACE_TEXT
		tooltip_text = event.as_text() if event else ""


func _refresh_disabled() -> void:
	disabled = read_only or get_index() < input.events_disabled_count or not input.action_exists


func _refresh_physical() -> void:
	if event is not InputEventKey: return

	if input.physical_toggled:
		event.physical_keycode = maxi(event.keycode, event.physical_keycode)
		event.keycode = 0
	else:
		event.keycode = maxi(event.keycode, event.physical_keycode)
		event.physical_keycode = 0


func _refresh_modifiers() -> void:
	if event is not InputEventWithModifiers: return
	if input.events_allow_modifiers: return

	event.alt_pressed = false
	event.shift_pressed = false
	event.command_or_control_autoremap = false
	event.ctrl_pressed = false
	event.meta_pressed = false

var _just_refreshed_warnings: bool = false
func _refresh_warnings() -> void:
	if _just_refreshed_warnings: return

	var result: Array[Warning]

	if input.action.is_empty():
		result.append(Warning.new("This input is not bound to any action in ProjectSettings."))

	elif input.events_required and input.action["events"].is_empty() and get_index() == 0:
		result.append(Warning.new("This input cannot be empty."))

	for other_input in input.get_conflict_candidates():
		result.append_array(get_conflict_warnings(other_input))

	warnings = result
	_just_refreshed_warnings = true

	for warning in warnings:
		if warning.other is not InputBinderButton: continue
		warning.other._refresh_warnings()

	_just_refreshed_warnings = false


## Removes any duplicate events, keeping this one.
func _check_duplicates(exact_match: bool = true) -> void:
	if event == null: return

	for other: InputBinderButton in input.event_buttons:
		print("self : %s" % [ self ])
		print("other : %s" % [other])
		print("self.event : %s" % [ self.event])
		print("other.event : %s" % [other.event])
		if self == other or other.event == null or not event.is_match(other.event, exact_match): continue

		other.event = null


#region Conflicts

var is_conflict_exempt: bool:
	get: return not visible or event == null or is_queued_for_deletion() or not input.conflict_enabled


func is_conflicting_with(other: InputBinderButton, exact_match := true) -> bool:
	return not (
			other == null or self == other
		or self.is_conflict_exempt or other.is_conflict_exempt
		or not self.event.is_match(other.event, exact_match)
	)

func get_conflict_warnings(other_input: InputBinder) -> Array[Warning]:
	var result: Array[Warning]

	for other_button in other_input.event_buttons:
		if not self.is_conflicting_with(other_button): continue

		result.push_back(Warning.new("Conflicts with other.", other_button))

	return result


func receive_conflict_with(other: InputBinderButton) -> void:
	pass


var warning_buttons: Array:
	get: return warnings.map(func(e):
		return e.other
	)


func create_conflict_with(other: InputBinderButton) -> void:
	if self == other: return

	if not warning_buttons.has(other):
		self.warnings.push_back(Warning.new("", other))
		self._refresh_warnings()

	if other == null: return

	if not other.warning_buttons.has(self ):
		other.warnings.push_back(Warning.new("", self ))
		other._refresh_warnings()


func _on_warning_button_pressed() -> void:
	for warning in warnings:
		if warning.other == null: continue
		warning.other.grab_focus.call_deferred()

#endregion

#region Input

func _gui_input(__event__: InputEvent) -> void:
	if disabled or button_pressed: return

	var is_unset_event: bool = (
			(__event__.is_action_pressed(&"ui_text_backspace") or __event__.is_action_pressed(&"user_input_remove"))
			or (__event__ is InputEventMouseButton and __event__.button_index == MOUSE_BUTTON_RIGHT and __event__.is_pressed())
	)

	if is_unset_event:
		event = null


func _input(__event__: InputEvent) -> void:
	if disabled or __event__.get_class() not in ALLOWED_INPUT_CLASSES: return
	if not button_pressed: return

	if __event__.is_pressed():
		if InputLocalization.is_escape(__event__):
			revert()
		else:
			event_staged = __event__

	if _event_staged and (
		not input.events_allow_modifiers
		or __event__ is not InputEventKey
		or (
			__event__.is_released()
			and get_literal_or_physical_keycode(__event__) == get_literal_or_physical_keycode(event_staged)
		)
	):
		commit()

	get_viewport().set_input_as_handled()


func get_literal_or_physical_keycode(__event__: InputEvent) -> int:
	if __event__ is not InputEventKey: return KEY_UNKNOWN

	return __event__.physical_keycode if input.physical_toggled else __event__.keycode


func stage(__event__: InputEvent = null) -> void:
	event_staged = __event__


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


#endregion

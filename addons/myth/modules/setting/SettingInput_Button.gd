
@tool class_name SettingInput_Button extends Button

enum {
	READ_ONLY,
	REFRESH,
	BEGIN_REMAP,
}

const WARNING_ICON_TEXTURE := preload("uid://ebpefvkwjfwm")

const ALLOWED_INPUT_CLASSES : PackedStringArray = [
	"InputEventJoypadButton",
	"InputEventJoypadMotion",
	"InputEventKey",
	"InputEventMouseButton",
]

signal remapped

var pref : SettingInput

var read_only : bool

var _event : InputEvent
var event : InputEvent :
	get: return _event
	set(value):
		_event = value

		if _event:
			_refresh_physical()
			_refresh_modifiers()
			_event.changed.connect(_refresh_event)
			check_conflicts()

		remapped.emit()

var _displayed_event : InputEvent
var displayed_event : InputEvent :
	get: return _displayed_event if _displayed_event else event
	set(value):
		_displayed_event = value
		_refresh_event()

var warning_icon : TextureRect


var conflict_buttons : Array[SettingInput_Button]


func _init(__pref__: SettingInput, __event__: InputEvent = null, create_type : int = BEGIN_REMAP) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle_mode = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS_FORCE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

	warning_icon = TextureRect.new()
	warning_icon.visible = false
	warning_icon.texture = WARNING_ICON_TEXTURE
	warning_icon.z_index = 1
	warning_icon.pivot_offset_ratio = Vector2(0.5, 0.5)
	warning_icon.set_anchors_preset(PRESET_TOP_RIGHT)
	add_child(warning_icon)

	pref = __pref__
	event = __event__
	read_only = create_type == READ_ONLY
	button_pressed = create_type == BEGIN_REMAP

	custom_minimum_size.x = pref.binding_minimum_width

	focus_exited.connect(set.bind(&"button_pressed", false))
	remapped.connect(pref.push_bindings)
	tree_exited.connect(pref.update_minimum_size)


func _ready() -> void:
	warning_icon.position -= warning_icon.size * 0.5

	if button_pressed:
		grab_focus.call_deferred()

	_refresh_disabled()
	_refresh_event()


func _pressed() -> void:
	if button_pressed:
		_refresh_event()


func _exit_tree() -> void:
	for conflict in conflict_buttons:
		if conflict == null: continue
		conflict.check_conflicts()


func _refresh_event() -> void:
	if InputLocalization.apply_to(self): pass
	else:
		icon = null
		text = "..." if button_pressed else event.as_text()
		tooltip_text = event.as_text()


func _refresh_physical() -> void:
	if _event is not InputEventKey: return

	if pref.physical_toggled:
		_event.physical_keycode = maxi(_event.keycode, _event.physical_keycode)
		_event.keycode = 0
	else:
		_event.keycode = maxi(_event.keycode, _event.physical_keycode)
		_event.physical_keycode = 0


func _refresh_modifiers() -> void:
	if _event is not InputEventWithModifiers: return
	if pref.allow_modifiers: return

	_event.alt_pressed = false
	_event.shift_pressed = false
	_event.command_or_control_autoremap = false
	_event.ctrl_pressed = false
	_event.meta_pressed = false


func _refresh_disabled() -> void:
	disabled = read_only or get_index() < pref.disabled_bindings



#region Conflicts

var is_conflict_exempt : bool :
	get: return not visible or event == null or is_queued_for_deletion() #or pref.binding_group == null # Redundant.
func is_not_conflicting_with(other: SettingInput_Button, exact_match := true) -> bool:
	return (
			other == null or self == other
		or	self.is_conflict_exempt or other.is_conflict_exempt
		or	not self.event.is_match(other.event, exact_match)
	)


func check_conflicts() -> void:
	conflict_buttons.clear()
	for other_pref in pref.get_conflict_candidates():
		check_conflicts_with(other_pref)

func check_conflicts_with(other_pref: SettingInput) -> void:
	for other in other_pref.binding_buttons:
		if self.is_not_conflicting_with(other):
			resolve_conflict_with(other)
			continue

		if self.pref == other_pref:
			if not other.disabled:
				other.queue_free()
			elif not self.disabled:
				self.queue_free()
				return
		else:
			create_conflict_with(other)


func create_conflict_with(other: SettingInput_Button) -> void:
	if self == other: return

	if not self.conflict_buttons.has(other):
		self.conflict_buttons.push_back(other)
		self._refresh_conflict()

	if other == null: return

	if not other.conflict_buttons.has(self):
		other.conflict_buttons.push_back(self)
		other._refresh_conflict()


func resolve_conflict_with(other: SettingInput_Button) -> void:
	self.conflict_buttons.erase(other)
	self._refresh_conflict()

	if other == null: return

	other.conflict_buttons.erase(self)
	other._refresh_conflict()


func _refresh_conflict() -> void:
	warning_icon.visible = false
	warning_icon.tooltip_text = "Binding conflicts with: "
	for conflict in conflict_buttons:
		if conflict == null or conflict.is_queued_for_deletion(): continue

		warning_icon.visible = true
		warning_icon.tooltip_text += conflict.pref.label_text + ", "
	warning_icon.tooltip_text = warning_icon.tooltip_text.substr(0, warning_icon.tooltip_text.length() - 2)

#endregion


#region Input

func _gui_input(__event__: InputEvent) -> void:
	if disabled or button_pressed: return

	if __event__.is_action_pressed(&"ui_text_backspace") \
			or __event__.is_action_pressed(&"user_input_remove") \
			or (__event__ is InputEventMouseButton and __event__.button_index == MOUSE_BUTTON_RIGHT and __event__.is_pressed()):
		queue_free()
		pref.push_bindings()


func _input(__event__: InputEvent) -> void:
	if disabled or __event__.get_class() not in ALLOWED_INPUT_CLASSES: return
	if not button_pressed: return

	if __event__.is_pressed():
		if InputLocalization.is_escape(__event__):
			revert_displayed_event()
		else:
			displayed_event = __event__

	if not pref.allow_modifiers or __event__ is not InputEventKey or (__event__.is_released() and get_literal_or_physical_keycode(__event__) == get_literal_or_physical_keycode(displayed_event)):
		commit_displayed_event()

	get_viewport().set_input_as_handled()


func get_literal_or_physical_keycode(__event__: InputEvent) -> int:
	if __event__ is not InputEventKey: return KEY_NONE

	return __event__.physical_keycode if pref.physical_toggled else __event__.keycode


func commit_displayed_event() -> void:
	if event == displayed_event: return

	event = displayed_event
	displayed_event = null

	if event == null and pref.binding_buttons.size() > 1:
		queue_free()
	else:
		set.call_deferred(&"button_pressed", false)


func revert_displayed_event() -> void:
	displayed_event = null
	button_pressed = false
	_refresh_event()

#endregion

## Creates a series of buttons that allows the user to remap the controls to their liking. Handles exactly one action.
@icon("res://addons/myth/script/ui/setting/InputBinder.svg")
@tool
class_name InputBinder
extends BoxContainer

enum {
	## The button created is marked as readonly.
	EVENT_BUTTON_READONLY,
	## The button created is marked as having already existed and is now being refreshed.
	EVENT_BUTTON_REFRESH,
	## The button created is marked as having been newly created by the user and is now being remapped.
	EVENT_BUTTON_REMAP,
}

const ADD_ICON := preload("res://addons/myth/asset/icons/Add.svg")
const PHYSICAL_ICON := preload("res://addons/myth/asset/icons/InputPhysical.svg")

const EventButton := preload("res://addons/myth/script/ui/setting/InputBinderEventButton.gd")


const ADD_REMOVE_EVENTS_SETTING := {
	&"name": "myth/input/binder/allow_add_and_remove_events",
	&"type": TYPE_BOOL,
}


signal action_data_changed

var manager: InputBinderManager:
	set(value):
		if manager == value:
			return

		if manager:
			action_data_changed.disconnect(manager.input_bindings_changed.emit)
			manager.members.erase(self)

		manager = value

		if manager:
			action_data_changed.connect(manager.input_bindings_changed.emit)
			if not manager.members.has(self):
				manager.members.push_back(self)


var event_hbox: HBoxContainer
var event_hflow: HFlowContainer
var event_add_button: Button

var misc_hbox: HBoxContainer

var physical_check: CheckButton

var deadzone_hbox: HBoxContainer
var deadzone_slider: HSlider
var deadzone_label: Label


func _init() -> void:
	event_hbox = HBoxContainer.new()
	event_hbox.custom_minimum_size.x = 100.0
	event_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	event_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
	event_hbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(event_hbox, false, INTERNAL_MODE_FRONT)

	event_hflow = HFlowContainer.new()
	event_hflow.alignment = FlowContainer.ALIGNMENT_BEGIN
	event_hflow.size_flags_horizontal = SIZE_EXPAND_FILL
	event_hflow.size_flags_vertical = SIZE_SHRINK_CENTER
	event_hflow.set_anchors_preset(PRESET_FULL_RECT)
	event_hbox.add_child(event_hflow)

	event_add_button = Button.new()
	event_add_button.visible = false
	event_add_button.flat = true
	event_add_button.icon = ADD_ICON
	event_hbox.add_child(event_add_button)

	event_hbox.move_child(event_add_button if vertical else event_hflow, 0)


	misc_hbox = HBoxContainer.new()
	misc_hbox.visible = false
	misc_hbox.alignment = BoxContainer.ALIGNMENT_END
	misc_hbox.size_flags_horizontal = SIZE_EXPAND_FILL if vertical else SIZE_SHRINK_END
	misc_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
	misc_hbox.add_theme_constant_override(&"separation", 10.0)
	add_child(misc_hbox, false, INTERNAL_MODE_FRONT)

	physical_check = CheckButton.new()
	physical_check.name = "physical_check"
	physical_check.visible = false
	physical_check.icon = PHYSICAL_ICON
	physical_check.size_flags_vertical = SIZE_SHRINK_CENTER
	physical_check.tooltip_text = "Input physical."
	physical_check.button_pressed = true
	physical_check.toggled.connect(_set_physical_toggled)
	misc_hbox.add_child(physical_check)

	deadzone_hbox = HBoxContainer.new()
	deadzone_hbox.visible = false
	deadzone_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	deadzone_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
	deadzone_hbox.add_theme_constant_override(&"separation", 6.0)
	misc_hbox.add_child(deadzone_hbox)

	deadzone_slider = HSlider.new()
	deadzone_slider.min_value = 0.0
	deadzone_slider.max_value = 1.0
	deadzone_slider.step = 0.01
	deadzone_slider.custom_minimum_size = Vector2(100.0, 0.0)
	deadzone_slider.size_flags_horizontal = SIZE_EXPAND_FILL
	deadzone_slider.size_flags_vertical = SIZE_SHRINK_CENTER
	deadzone_hbox.add_child(deadzone_slider)

	deadzone_label = Label.new()
	deadzone_label.visible = false
	deadzone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deadzone_label.text = "%01.02f" % 0.25
	deadzone_label.size_flags_vertical = SIZE_SHRINK_CENTER
	deadzone_hbox.add_child(deadzone_label)

	event_add_button.pressed.connect(create_event_button)

	if Engine.is_editor_hint():
		ProjectSettings.settings_changed.connect(refresh)
		resized.connect(func() -> void:
			event_hbox.move_child(event_hflow if vertical else event_add_button, 0)
			misc_hbox.size_flags_horizontal = SIZE_EXPAND_FILL if vertical else SIZE_SHRINK_END
			misc_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
		)


func _ready() -> void:
	event_hflow.alignment = self.alignment as FlowContainer.AlignmentMode

	if event_modifiable:
		event_add_and_remove = event_add_and_remove_global_setting

	manager = Myth.find_ancestor_sibling_of_type(self, "InputBinderManager")

	action_data = get_action_data_from_project_settings()


func refresh(data: Dictionary = action_data) -> void:
	_event_preexisting = event_hflow.get_child_count()
	Myth.clear_children(event_hflow)

	if data:
		for event: InputEvent in data["events"]:
			create_event_button(event, EVENT_BUTTON_REFRESH)
		deadzone = data.get("deadzone", 0.2)
	else:
		deadzone = 0.0

	while event_hflow.get_child_count() < event_placeholders + event_restricteds:
		create_event_button(null, EVENT_BUTTON_REFRESH)

	set.call_deferred(&"_event_preexisting", 0)


## The name of the action this binding modifies. In the editor, this will also set the name of the Node, or the parent if it is a [Setting]. Nifty!
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action: StringName:
	set(value):
		if action == value:
			return

		action = value
		if action and Engine.is_editor_hint():
			if get_parent() is Setting:
				get_parent().name = value
			else:
				name = value

		update_configuration_warnings()
		_event_restricteds = clampi(_event_restricteds, 0, action_project_setting_event_count)
		refresh()


var action_project_setting: String:
	get: return "input/" + action


var action_project_setting_event_count: int:
	get:
		var data := get_action_data_from_project_settings()
		return data["events"].size() if data else 0


var action_exists: bool:
	get: return action and ProjectSettings.has_setting(action_project_setting)


var action_data: Dictionary:
	set(value):
		action_data = value

		if not deadzone_enabled:
			value.erase("deadzone")

		if not Engine.is_editor_hint():
			SystemPrefs.set_action_in_input_map(action, value)

		refresh()

		action_data_changed.emit()


func get_action_data_from_project_settings() -> Dictionary:
	return ProjectSettings.get_setting(action_project_setting, {})


func get_action_data_from_input_map() -> Dictionary:
	return ( {
			"deadzone": InputMap.action_get_deadzone(action),
			"events": InputMap.action_get_events(action),
		}
		if InputMap.has_action(action) else {}
	)


func set_action_data_from_children() -> void:
	if not action: return

	action_data = {
		"deadzone": 0.2,
		"events": get_events_from_buttons(),
	}


@export_group("Events", "event_")


static var event_add_and_remove_global_setting: bool = false:
	get: return ProjectSettings.get_setting(ADD_REMOVE_EVENTS_SETTING.name, false)
	set(value): ProjectSettings.set_setting(ADD_REMOVE_EVENTS_SETTING.name, value)


## Allows the user to modify the bindings. NOTE: checking this box will modify its child properties (but only in the editor).
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var event_modifiable: bool = true:
	set(value):
		if not Engine.is_editor_hint(): return
		event_modifiable = value

		if event_modifiable:
			event_restricteds = 0
			event_placeholders = 1
			event_add_and_remove = event_add_and_remove_global_setting
		else:
			event_restricteds = action_project_setting_event_count
			event_placeholders = 0
			event_add_and_remove = false

## If enabled, the end user will be able to add multiple [InputEvent]s and remove existing ones, down to [member events_placeholder_count].
var event_add_and_remove: bool = false:
	get: return event_add_button.visible
	set(value): event_add_button.visible = value


## The minimum number of modifiable event buttons.
@export_range(0, 4, 1, "or_greater")
var event_placeholders: int = 1:
	set(value):
		value = maxi(value, 0)
		if event_placeholders == value:
			return

		event_placeholders = value
		refresh()


var _event_preexisting: int = 0
var _event_restricteds: int = 0
## The number of disabled events; the user cannot modify these. They are always the first event(s) listed in [ProjectSettings].
@export_range(0, 4, 1, "or_greater")
var event_restricteds: int = 0:
	get: return _event_restricteds + _event_preexisting
	set(value):
		value = clampi(value, 0, action_project_setting_event_count)
		if _event_restricteds == value:
			return

		_event_restricteds = value
		refresh()

## If enabled, this will prevent the binding from having 0 [InputEvent]s bound. If it somehow is cleared, it will generate a warning.
@export
var event_required: bool = false

## If enabled, [InputEventKey] events will be set on release instead of on press. While pressed, modifier keys may be added to alter the outcome.
@export var event_allow_modifiers: bool = false:
	set(value):
		event_allow_modifiers = value
		for button: EventButton in get_event_buttons():
			button._refresh_modifiers()


var event_can_clear_any: bool:
	get: return not event_required or get_events_from_buttons().size() > 1


var event_can_remove_any: bool:
	get: return event_add_and_remove and get_events_from_buttons().size() > event_placeholders


func get_event_buttons() -> Array[EventButton]:
	var result : Array[EventButton]
	result.resize(event_hflow.get_child_count())

	for i in result.size():
		result[i] = event_hflow.get_child(i)

	return result


func get_events_from_buttons() -> Array[InputEvent]:
	var result : Array[InputEvent] = []

	for button in get_event_buttons():
		if not button.is_queued_for_deletion() and button.event:
			result.push_back(button.event)

	return result


func create_event_button(event: InputEvent = null, creation_state: int = EVENT_BUTTON_REMAP) -> EventButton:
	var result := EventButton.new(self, event, creation_state)
	event_hflow.add_child(result, false, INTERNAL_MODE_FRONT if result.readonly else INTERNAL_MODE_DISABLED)
	return result


@export_subgroup("Buttons", "buttons_")

@export var buttons_minimum_width: float = 0.0:
	set(value):
		buttons_minimum_width = maxf(value, 0.0)
		for button: Control in get_event_buttons():
			button.custom_minimum_size.x = value

@export var buttons_size_flags_horizontal: SizeFlags = SIZE_EXPAND_FILL:
	set(value):
		buttons_size_flags_horizontal = value
		for button: Control in get_event_buttons():
			button.size_flags_horizontal = value

#region Conflicts
@export_subgroup("Conflicts", "conflict_")



func handle_warnings(button: EventButton):
	await _handle_warnings(button)

## This method is called when a child button's warning is pressed.
func _handle_warnings(button: EventButton):
	for warning in button.warnings:
		if warning.other == null: continue
		warning.other.grab_focus.call_deferred()

#endregion
@export_group("Misc", "misc_")


func _refresh_extra_visible() -> void:
	misc_hbox.visible = physical_visible or deadzone_enabled


@export_subgroup("Physical Input", "physical_")

## If enabled, the user will be able view and modify [member physical_toggled] using a [CheckButton].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var physical_visible: bool = false:
	get: return physical_check.visible
	set(value):
		physical_check.visible = value
		_refresh_extra_visible()

## Advanced setting. If enabled, all bound [InputEventKey]s will be set to their [member physical_keycode] counterpart. Games generally should enable this, UI applications generally should not.
@export var physical_toggled: bool = true:
	get: return physical_check.button_pressed
	set(value): physical_check.button_pressed = value
func _set_physical_toggled(value: bool) -> void:
	for button: EventButton in get_event_buttons():
		button._refresh_physical()


@export_subgroup("Deadzone", "deadzone_")

## If enabled, a slider will be available to the user to modify the input deadzone.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var deadzone_enabled: bool = false:
	get: return deadzone_hbox.visible
	set(value):
		deadzone_hbox.visible = value
		_refresh_extra_visible()

# @export
# var deadzone_step: float = 0.01:
# 	get: return deadzone_slider.step
# 	set(value): deadzone_slider.step = value

# @export
# var deadzone_minimum_size: Vector2 = Vector2(100.0, 0.0):
# 	get: return deadzone_slider.custom_minimum_size
# 	set(value): deadzone_slider.custom_minimum_size = value

# @export
# var deadzone_separation: float = 6.0:
# 	get: return deadzone_hbox.get_theme_constant(&"separation")
# 	set(value): deadzone_hbox.add_theme_constant_override(&"separation", value)

# @export
# var deadzone_label_enabled: bool = false:
# 	get: return deadzone_label.visible
# 	set(value): deadzone_label.visible = value

# @export
# var deadzone_label_format: String = "%01.02f":
# 	set(value):
# 		deadzone_label_format = value
# 		deadzone_label.text = deadzone_label_format % deadzone

var deadzone: float:
	get: return deadzone_slider.value
	set(value): deadzone_slider.value = value

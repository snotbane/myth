@tool class_name InputBinder extends BoxContainer

const ADD_ICON := preload("res://addons/myth/icons/Add.svg")
const PHYSICAL_ICON := preload("res://addons/myth/icons/KeyboardPhysical.svg")
const REMAP_SCENE_DEFAULT := preload("res://addons/myth/scripts/input/InputBinderRemap.tscn")

signal action_changed(value: Dictionary)

## Name of the input (from ProjectSettings) to modify.
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_name: StringName:
	set(value):
		if value and name == input_name:
			name = value
		input_name = value
		update_configuration_warnings()
		events_disabled_count = _events_disabled_count
		# refresh() ## This is currently handled by the above line.


@export_group("Events", "events_")

var events_hbox: HBoxContainer
var events_hflow: HFlowContainer
var events_add_button: Button


@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var events_modifiable: bool = true:
	set(value):
		if not Engine.is_editor_hint(): return
		events_modifiable = value

		if events_modifiable:
			events_disabled_count = 0
			events_placeholder_count = 1
		else:
			events_disabled_count = action_from_project_settings["events"].size()
			events_placeholder_count = 0
			events_allow_add_and_remove = false

## If enabled, this will prevent the binding from having 0 [InputEvent]s bound. If it somehow is cleared, it will generate a warning.
@export var events_required: bool = false:
	set(value):
		events_required = value
		for button in event_buttons:
			button._refresh_warnings()


var _preexisting_children: int = 0
var _events_disabled_count: int = 0
## This is the number of events from [ProjectSettings] that cannot be modified by the user. These are not saved. If [member add_button_allow] is enabled, the user will be allowed to add and save additional events; this only restricts modifying events present in [ProjectSettings].
@export var events_disabled_count: int = 0:
	get: return _preexisting_children + _events_disabled_count
	set(value):
		_events_disabled_count = clampi(value, 0, action_from_project_settings["events"].size())
		refresh()


## The minimum number of blank event slots that will always be present.
@export_range(0, 4, 1, "or_greater") var events_placeholder_count: int = 1:
	set(value):
		events_placeholder_count = maxi(value, 0)
		refresh()


## If enabled, the end user will be able to add multiple [InputEvent]s and remove existing ones, down to [member events_placeholder_count].
@export var events_allow_add_and_remove: bool = false:
	get: return events_add_button.visible
	set(value): events_add_button.visible = value


## If enabled, [InputEventKey] events will be set on release instead of on press. While pressed, modifier keys may be added to alter the outcome.
@export var events_allow_modifiers: bool = false:
	set(value):
		events_allow_modifiers = value
		for button: InputBinderButton in event_buttons:
			button._refresh_modifiers()


## This scene will be instantiated whenever an input is opened for remap, and destroyed when the remap is complete.
@export var events_remap_scene: PackedScene
func get_events_remap_scene() -> PackedScene:
	return events_remap_scene if events_remap_scene else REMAP_SCENE_DEFAULT


@export var events_minimum_width: float = 100.0:
	get: return events_hbox.custom_minimum_size.x
	set(value): events_hbox.custom_minimum_size.x = value


var events_in_buttons: Array[InputEvent]:
	get:
		var result: Array[InputEvent]
		for button: InputBinderButton in event_buttons:
			if button.event == null: continue
			result.push_back(button.event)
		return result


var can_clear_button: bool:
	get: return not events_required or events_in_buttons.size() > 1


var can_remove_button: bool:
	get: return events_allow_add_and_remove and event_buttons.size() > events_placeholder_count


@export_subgroup("Buttons", "buttons_")

@export var buttons_minimum_width: float = 0.0:
	set(value):
		buttons_minimum_width = maxf(value, 0.0)
		for button: Control in event_buttons:
			button.custom_minimum_size.x = value

@export var buttons_size_flags_horizontal: SizeFlags = SIZE_EXPAND_FILL:
	set(value):
		buttons_size_flags_horizontal = value
		for button: Control in event_buttons:
			button.size_flags_horizontal = value


@export_subgroup("Conflicts", "conflict_")

## If enabled, this input will consider others, and be considered by others, for overlapping inputs within the same [member conflict_group_root].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var conflict_enabled: bool = true:
	set(value):
		conflict_enabled = value
		update_configuration_warnings()

# @export_enum("Create Warning", "Overwrite", "Custom") var conflict_type: int = 0:
# 	set(value):
# 		conflict_type = value

## The root [Node] which contains descendants that may conflict with this one. Set null to conflict with none, except those listed in [member conflict_exceptions].
@export var conflict_group_root: Node:
	set(value):
		conflict_group_root = value
		update_configuration_warnings()

## List of [InputBinder]s which will be ignored when searching for conflicts.
@export var conflict_exceptions: Array[InputBinder]


@export_group("Misc", "misc_")

var misc_hbox: HBoxContainer

@export var misc_separation: float = 10.0:
	get: return misc_hbox.get_theme_constant(&"separation")
	set(value): misc_hbox.add_theme_constant_override(&"separation", value)


func _refresh_extra_visible() -> void:
	misc_hbox.visible = physical_visible or deadzone_enabled

@export_subgroup("Physical Input", "physical_")

var physical_check: CheckButton

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
	for button: InputBinderButton in event_buttons:
		button._refresh_physical()

@export_subgroup("Deadzone", "deadzone_")

var deadzone_hbox: HBoxContainer
var deadzone_slider: HSlider
var deadzone_label: Label

## Whether or not the user can view and modify the deadzone. If disabled, the deadzone will never be modified here.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var deadzone_enabled: bool = false:
	get: return deadzone_hbox.visible
	set(value):
		deadzone_hbox.visible = value
		_refresh_extra_visible()

@export var deadzone_step: float = 0.01:
	get: return deadzone_slider.step
	set(value): deadzone_slider.step = value

@export var deadzone_minimum_size: Vector2 = Vector2(100.0, 0.0):
	get: return deadzone_slider.custom_minimum_size
	set(value): deadzone_slider.custom_minimum_size = value

@export var deadzone_separation: float = 6.0:
	get: return deadzone_hbox.get_theme_constant(&"separation")
	set(value): deadzone_hbox.add_theme_constant_override(&"separation", value)

@export var deadzone_label_enabled: bool = false:
	get: return deadzone_label.visible
	set(value): deadzone_label.visible = value

@export var deadzone_label_format: String = "%01.02f":
	set(value):
		deadzone_label_format = value
		deadzone_label.text = deadzone_label_format % deadzone

var deadzone: float:
	get: return deadzone_slider.value
	set(value): deadzone_slider.value = value

@export_subgroup("")

var project_settings_input_name: String:
	get: return "input/" + input_name

var action_exists: bool:
	get: return not input_name.is_empty() and ProjectSettings.has_setting(project_settings_input_name)

var action_from_project_settings: Dictionary:
	get: return ProjectSettings.get_setting(project_settings_input_name, {})

var action_from_input_map: Dictionary:
	get:
		if not InputMap.has_action(input_name): return {}
		return {
			"events": InputMap.action_get_events(input_name),
			"deadzone": InputMap.action_get_deadzone(input_name)
		}

var action: Dictionary:
	get: return action_from_project_settings if Engine.is_editor_hint() else action_from_input_map
	set(value):
		if InputMap.has_action(input_name):
			InputMap.action_erase_events(input_name)

		for event: InputEvent in value["events"]:
			if event == null: continue

			InputMap.action_add_event(input_name, event)

		if deadzone_enabled:
			InputMap.action_set_deadzone(input_name, value["deadzone"])

		action_changed.emit(value)


func _get_configuration_warnings() -> PackedStringArray:
	var result := PackedStringArray()

	if input_name.is_empty():
		result.push_back("Input Name has not been assigned.")
	elif not ProjectSettings.has_setting(project_settings_input_name):
		result.push_back("Input '%s' does not exist in the project settings." % input_name)

	if conflict_enabled and conflict_group_root == null:
		result.push_back("Event conflicts are enabled, but no group root node has been set.")

	return result


var event_buttons: Array:
	get: return events_hflow.get_children()


func _init() -> void:
	events_hbox = HBoxContainer.new()
	events_hbox.custom_minimum_size.x = 100.0
	events_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	events_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
	events_hbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(events_hbox, false, INTERNAL_MODE_FRONT)

	events_hflow = HFlowContainer.new()
	events_hflow.alignment = FlowContainer.ALIGNMENT_BEGIN
	events_hflow.size_flags_horizontal = SIZE_EXPAND_FILL
	events_hflow.size_flags_vertical = SIZE_SHRINK_CENTER
	events_hflow.set_anchors_preset(PRESET_FULL_RECT)
	events_hbox.add_child(events_hflow)

	events_add_button = Button.new()
	events_add_button.visible = false
	events_add_button.flat = true
	events_add_button.icon = ADD_ICON
	events_hbox.add_child(events_add_button)

	events_hbox.move_child(events_add_button if vertical else events_hflow, 0)


	misc_hbox = HBoxContainer.new()
	misc_hbox.visible = false
	misc_hbox.alignment = BoxContainer.ALIGNMENT_END
	misc_hbox.size_flags_horizontal = SIZE_EXPAND_FILL if vertical else SIZE_SHRINK_END
	misc_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
	misc_hbox.add_theme_constant_override(&"separation", 10.0)
	add_child(misc_hbox, false, INTERNAL_MODE_FRONT)

	physical_check = CheckButton.new()
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

	events_add_button.pressed.connect(create_button)

	if Engine.is_editor_hint():
		ProjectSettings.settings_changed.connect(refresh)
		resized.connect(func() -> void:
			events_hbox.move_child(events_hflow if vertical else events_add_button, 0)
			misc_hbox.size_flags_horizontal = SIZE_EXPAND_FILL if vertical else SIZE_SHRINK_END
			misc_hbox.size_flags_vertical = SIZE_SHRINK_CENTER
		)


func _ready() -> void:
	refresh()


func refresh() -> void:
	_preexisting_children = event_buttons.size()
	Myth.clear_children(events_hflow)

	var __action__ := action
	if not __action__.is_empty():
		for event: InputEvent in __action__["events"]:
			create_button(event, InputBinderButton.REFRESH)
		deadzone = __action__["deadzone"]
	else:
		deadzone = 0.0

	while (event_buttons.size()) < events_placeholder_count + events_disabled_count:
		create_button(null, InputBinderButton.REFRESH)

	deadzone_label_format = deadzone_label_format

	set.call_deferred(&"_preexisting_children", 0)


func set_events_from_buttons() -> void:
	if input_name.is_empty(): return

	var result: Array[InputEvent] = []
	for button: InputBinderButton in event_buttons:
		if button.is_queued_for_deletion() or button.event == null: continue
		result.push_back(button.event)
	action = {
		"events": result,
		"deadzone": action["deadzone"]
	}


func create_button(event: InputEvent = null, create_type: int = InputBinderButton.BEGIN_REMAP) -> InputBinderButton:
	var result := InputBinderButton.new(self , event, create_type)
	events_hflow.add_child(result, false, INTERNAL_MODE_FRONT if result.read_only else INTERNAL_MODE_DISABLED)
	return result


func contains_event(event: InputEvent, exact_match: bool = true) -> bool:
	if event == null: return false

	for e: InputEvent in action["events"]:
		if e.is_match(event, exact_match): return true

	return false


func contains_event_in_buttons(event: InputEvent, exact_match: bool = true) -> bool:
	if event == null: return false

	for button: InputBinderButton in event_buttons:
		if event.is_match(button.event, exact_match): return true

	return false


func get_conflict_candidates() -> Array[InputBinder]:
	if not conflict_enabled or conflict_group_root == null: return []

	return _get_conflict_candidates(conflict_group_root)

func _get_conflict_candidates(from: Node) -> Array[InputBinder]:
	var result: Array[InputBinder]
	for child in from.get_children():
		if child is InputBinder:
			if child == self or child in conflict_exceptions or self in child.conflict_exceptions: continue
			result.push_back(child)
		else:
			result.append_array(_get_conflict_candidates(child))
	return result

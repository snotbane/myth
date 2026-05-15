
@tool class_name InputLocalization extends Resource

const EMPTY_SPACE_TEXT := " "

const PROJECT_SETTING_HINT := {
	&"name": "internationalization/locale/input",
	&"type": TYPE_STRING,
	&"hint": PropertyHint.PROPERTY_HINT_FILE,
	&"hint_string": "*.res",
	&"default": "uid://by4uei1ro2t8y"
}

static var ESCAPE_ESCAPE_KEY : InputEventKey
static var ESCAPE_START_KEY : InputEventJoypadButton

static var inst : InputLocalization


static func _static_init() -> void:
	ESCAPE_ESCAPE_KEY = InputEventKey.new()
	ESCAPE_ESCAPE_KEY.keycode = KEY_ESCAPE

	ESCAPE_START_KEY = InputEventJoypadButton.new()
	ESCAPE_START_KEY.button_index = JOY_BUTTON_START

	inst = load(ProjectSettings.get_setting(PROJECT_SETTING_HINT[&"name"], PROJECT_SETTING_HINT[&"default"]))


static func is_escape(event: InputEvent) -> bool:
	return inst._is_escape(event) if inst else false


static func apply_to(button, event: InputEvent = button.displayed_event) -> bool:
	if inst:
		inst._apply_to(button, event)
		return true
	return false


@export var escape_inputs : Array[InputEvent] = [
	ESCAPE_ESCAPE_KEY,
	ESCAPE_START_KEY,
]

@export_group("Icons")


@export var unbound_icon : Texture2D = null
@export var unknown_icon : Texture2D = null
@export var rebind_icon : Texture2D = null


@export_group("Labels")


## Text to set the button label to when there is no binding. This defaults to a single space (" ") to ensure proper height.
@export var unbound_label : String = EMPTY_SPACE_TEXT
@export var unbound_tooltip_text : String = "(Unbound)"

@export var rebind_label : String = "..."

## Text to set the button label to when there is a binding, but we don't know what it is. Leave blank to use `event.as_text()`.
@export var unknown_label : String = "???"


@export var overlap_tooltip_text : String = "Shares a binding with:"


var platform : StringName :
	get: return &"_"


@export var joypad_button_icons: Dictionary[StringName, Array] = {}
@export var joypad_button_labels : Dictionary[StringName, PackedStringArray] = {
	&"_": [
		"A",
		"B",
		"X",
		"Y",
		"Back",
		"Guide",
		"Start",
		"L Stick",
		"R Stick",
		"L Shoulder",
		"R Shoulder",
		"D-Pad Up",
		"D-Pad Down",
		"D-Pad Left",
		"D-Pad Right",
		"Misc 1",
		"Paddle 1",
		"Paddle 2",
		"Paddle 3",
		"Paddle 4",
		"Touchpad"
	],
	&"nintendo": [
		"B",
		"A",
		"Y",
		"X",
		"-",
		"",
		"+",
		"LS",
		"RS",
		"L",
		"R",
		"",
		"",
		"",
		"",
		"Capture",
		"",
		"",
		"",
		"",
		""
	],
	&"sony": [
		"Cross",
		"Circle",
		"Square",
		"Triangle",
		"Select",
		"PS",
		"Options",
		"L3",
		"R3",
		"L1",
		"R1",
		"D-Pad Up",
		"D-Pad Down",
		"D-Pad Left",
		"D-Pad Right",
		"Microphone",
		"",
		"",
		"",
		"",
		""
	],
	&"xbox": [
		"",
		"",
		"",
		"",
		"",
		"Home",
		"Menu",
		"LS",
		"RS",
		"LB",
		"RB",
		"D-Pad Up",
		"D-Pad Down",
		"D-Pad Left",
		"D-Pad Right",
		"Share",
		"",
		"",
		"",
		"",
		"",
	]
}

@export var joypad_motion_icons: Dictionary[StringName, Array] = {}
@export var joypad_motion_labels : Dictionary[StringName, PackedStringArray] = {
	&"_": [
		"LS X",
		"LS Y",
		"RS X",
		"RS Y",
		"LT",
		"RT",
	],
	&"nintendo": [
		"",
		"",
		"",
		"",
		"ZL",
		"ZR",
	],
	&"sony": [
		"",
		"",
		"",
		"",
		"L2",
		"R2",
	],
}

@export var key_icons : Dictionary[StringName, Array] = {}
@export var key_labels : Dictionary[StringName, PackedStringArray] = {}

@export var mouse_button_icons: Dictionary[StringName, Array] = {}
@export var mouse_button_labels: Dictionary[StringName, PackedStringArray] = {
	&"_": [
		"???",
		"Mouse Left",
		"Mouse Right",
		"Mouse Middle",
		"Scroll Up",
		"Scroll Down",
		"Scroll Left",
		"Scroll Right",
		"Thumb 1",
		"Thumb 2",
	]
}

@export var mouse_motion_icon : Texture2D
@export var mouse_motion_label : String = "Mouse"


func _is_escape(event: InputEvent) -> bool:
	if event == null: return false

	for escape in escape_inputs:
		if event.get_class() != escape.get_class(): continue

		if (
				(event is InputEventKey and event.keycode == escape.keycode)
			or	(event is InputEventJoypadMotion and event.axis == escape.axis)
			or	((event is InputEventJoypadButton or event is InputEventMouseButton) and event.button_index == escape.button_index)
		):
			return true
	return false


func _is_modifier(event: InputEvent) -> bool:
	return false


func _apply_to(button, event: InputEvent = button.displayed_event) -> void:
	if button.button_pressed and button._displayed_event == null:
		button.icon = rebind_icon
		button.text = EMPTY_SPACE_TEXT if button.icon != null else rebind_label
		button.tooltip_text = ""
	elif event == null:
		button.icon = unbound_icon
		button.text = EMPTY_SPACE_TEXT if button.icon != null else unbound_label
		button.tooltip_text = unbound_tooltip_text
	elif event is InputEventKey:
		button.icon = null
		button.text = OS.get_keycode_string(event.get_physical_keycode_with_modifiers() if event.keycode == 0 else event.get_keycode_with_modifiers())
		button.tooltip_text = button.text
	elif event is InputEventJoypadButton:
		button.icon = get_translation(event.button_index, joypad_button_icons)
		button.text = get_translation(event.button_index, joypad_button_labels, unknown_label) if button.icon == null else EMPTY_SPACE_TEXT
		button.tooltip_text = button.text
	elif event is InputEventJoypadMotion:
		button.icon = get_translation(event.axis, joypad_motion_icons)
		button.text = get_translation(event.axis, joypad_motion_labels, unknown_label) if button.icon == null else EMPTY_SPACE_TEXT
		if event.axis_value != 0.0:
			button.text += "+" if event.axis_value > 0.0 else "-"
		button.tooltip_text = button.text
	elif event is InputEventMouseButton:
		button.icon = get_translation(event.button_index, mouse_button_icons)
		button.text = get_translation(event.button_index, mouse_button_labels, unknown_label) if button.icon == null else EMPTY_SPACE_TEXT
		button.tooltip_text = button.text
	elif event is InputEventMouseMotion:
		button.icon = mouse_motion_icon
		button.text = mouse_motion_label if button.icon == null else EMPTY_SPACE_TEXT
		button.tooltip_text = button.text
	else:
		button.icon = unknown_icon
		button.text = EMPTY_SPACE_TEXT if button.icon != null	\
			else event.as_text() if not unknown_label.is_empty()	\
			else unknown_label
		button.tooltip_text = event.as_text()


func get_translation(idx: int, category: Dictionary, fallback_value: Variant = null, __platform__: StringName = platform) -> Variant:
	var lut : Variant = category.get(__platform__, category.get(&"_"))
	if lut == null: return fallback_value

	var result : Variant = lut[idx] if idx >= 0 and idx < lut.size() else null
	return result if result != null	\
		else get_translation(idx, category, fallback_value, &"_") if __platform__ != &"_"	\
		else fallback_value



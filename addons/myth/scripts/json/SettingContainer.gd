## Gives a label_text label to a [ResourcePropertyNode], and optionally, allows you to reset_mode its value.
@tool class_name SettingContainer extends HBoxContainer

const RESET_ICON := preload("res://addons/myth/icons/ReloadSmall.svg")

signal resetted


@export_subgroup("Label", "label_")

var text_label: Label

@export var label_text: String = "":
	get: return text_label.text
	set(value):
		text_label.text = value
		text_label.visible = not label_text.is_empty()


@export var label_settings: LabelSettings:
	get: return text_label.label_settings
	set(value): text_label.label_settings = value


@export var label_expand: bool = true:
	get: return text_label.size_flags_horizontal == SIZE_EXPAND
	set(value): text_label.size_flags_horizontal = SIZE_EXPAND if value else SIZE_SHRINK_BEGIN


@export_subgroup("Reset Button", "reset_")

var reset_container: Control
var reset_button: Button

@export_enum("Disabled", "Use Layout Group", "Enabled") var reset_mode: int = 1:
	set(value):
		reset_mode = value
		refresh_reset_container_visibility()
func refresh_reset_container_visibility() -> void:
	match reset_mode:
		0: reset_container.visible = false
		1: reset_container.visible = layout_group.reset_enabled if layout_group else false
		2: reset_container.visible = true


@export var reset_icon: Texture2D = RESET_ICON:
	get: return reset_button.icon
	set(value): reset_button.icon = value


@export_subgroup("Layout", "layout_")

@export var layout_group: SettingLayoutGroup:
	set(value):
		if layout_group:
			layout_group.remove_user(self )

		layout_group = value

		if layout_group:
			layout_group.add_user(self )

@export var layout_match_group_height: bool = true:
	set(value):
		layout_match_group_height = value
		custom_minimum_size.y = layout_group.minimum_height if (layout_group and layout_group.same_height and layout_match_group_height) else 0.0


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	text_label = Label.new()
	text_label.name = &"text_label"
	text_label.visible = false
	text_label.size_flags_horizontal = SIZE_EXPAND
	add_child(text_label, false, INTERNAL_MODE_FRONT)


	reset_container = Control.new()
	reset_container.visible = false
	reset_container.mouse_filter = MOUSE_FILTER_IGNORE
	reset_container.focus_mode = FOCUS_NONE
	add_child(reset_container, false, INTERNAL_MODE_BACK)

	reset_button = Button.new()
	reset_button.name = &"reset_button"
	reset_button.icon = RESET_ICON
	reset_button.visible = Engine.is_editor_hint()
	reset_button.flat = true
	reset_button.set_anchors_preset(PRESET_FULL_RECT)
	reset_button.pressed.connect(func() -> void:
		_resetted()
		resetted.emit()
	)
	reset_container.add_child(reset_button)


func _ready() -> void:
	layout_match_group_height = layout_match_group_height
	refresh_reset_container_visibility()

	reset_container.custom_minimum_size = reset_button.get_combined_minimum_size()


func _get_configuration_warnings() -> PackedStringArray:
	var result := PackedStringArray()

	var control_count := 0
	for child in get_children():
		if child is not Control: continue
		control_count += 1

	if control_count != 1:
		result.push_back("SettingContainers must have exactly one child Control.")

	return result


func _resetted() -> void:
	pass

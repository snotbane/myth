@icon("res://addons/myth/script/ui/setting/Setting.svg")
@tool
class_name Setting
extends HBoxContainer

signal reseted
signal child_value_changed(value: Variant)

func _init() -> void:
	label = Label.new()
	label.name = &"setting_label"
	label.text = "New Setting"
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label, false, INTERNAL_MODE_FRONT)

	separator = HSeparator.new()
	separator.self_modulate = Color.TRANSPARENT
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(separator, false, INTERNAL_MODE_FRONT)

	reset_button = TextureButton.new()
	reset_button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	reset_button.texture_normal = preload("res://addons/myth/asset/icons/Reset.svg")
	reset_button.texture_hover = preload("res://addons/myth/asset/icons/ResetHover.svg")
	reset_button.texture_disabled = preload("res://addons/myth/asset/icons/ResetDisabled.svg")
	reset_button.add_theme_icon_override("disabled_icon", Texture2D.new())
	add_child(reset_button, false, INTERNAL_MODE_BACK)

	reset_button.pressed.connect(reset)


var child: Control:
	set(value):
		if child == value:
			return

		child = value

		if child is OptionButton:
			child.item_selected.connect(_on_child_value_changed.unbind(1))

		elif child is Range:
			if child is Slider:
				child.drag_ended.connect(_on_child_value_changed.unbind(1))
			else:
				child.value_changed.connect(_on_child_value_changed.unbind(1))

		elif child is BaseButton and child.toggle_mode:
			child.toggled.connect(_on_child_value_changed.unbind(1))


var child_value: Variant:
	get:
		if child is OptionButton:
			return child.get_selected_id()
		elif child is Range:
			return child.value
		elif child is BaseButton and child.toggle_mode:
			return child.button_pressed
		else:
			return null
	set(value):
		if child_value == value:
			return

		if child is OptionButton:
			for opt in child.item_count:
				if child.get_item_id(opt) == value:
					child.selected = opt
					child.item_selected.emit(child.selected)
					break

		elif child is Range:
			child.value = value

		elif child is BaseButton and child.toggle_mode:
			child.button_pressed = value



		else:
			pass

		_on_child_value_changed()


func _on_child_value_changed() -> void:
	refresh_reset()
	child_value_changed.emit(child_value)


var initial_value: Variant

@export_group("Reset", "reset_")

var reset_button: BaseButton

## If enabled, a reset_button button will be available to reset_button the child's value to the value as defined in the scene. The button will become visible if the value changes.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var reset_enabled: bool = true:
	get: return reset_button.visible
	set(value): reset_button.visible = value

var reset_available: bool = false:
	get: return not reset_button.disabled
	set(value): reset_button.disabled = not value


@export_group("Label", "label_")

var label: Label
var separator: HSeparator

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var label_enabled: bool = true:
	get: return label.visible
	set(value): label.visible = value

@export
var label_text: String = "New Setting":
	get: return label.text
	set(value): label.text = value


@export
var label_label_settings: LabelSettings:
	get: return label.label_settings
	set(value): label.label_settings = value


func _ready() -> void:
	for c in get_children():
		if c is OptionButton or c is Range or (c is BaseButton and c.toggle_mode):
			child = c

	if child == null:
		printerr("No valid child could be found for Setting '%s'" % name)
		return

	initial_value = child_value

	if Engine.is_editor_hint():
		return

	refresh_reset()


func reset() -> void:
	child_value = initial_value


func refresh_reset() -> void:
	reset_available = child_value != initial_value

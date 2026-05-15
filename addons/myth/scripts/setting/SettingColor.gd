
@tool class_name SettingColor extends Setting


var color_picker : ColorPickerButton


func _get_value() -> Variant:
	return color_picker.color


func _set_value(new_value: Variant) -> void:
	color_picker.color = new_value
	_value_changed()


func _init() -> void:
	super._init()

	color_picker = ColorPickerButton.new()
	color_picker.custom_minimum_size.x = 100.0
	color_picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
	color_picker.edit_alpha = false
	color_picker.edit_intensity = false
	hbox_panel.add_child(color_picker)


func _ready() -> void:
	super._ready()

	color_picker.color_changed.connect(_value_changed.unbind(1))


@export var color : Color :
	get: return color_picker.color
	set(value): color_picker.color = value


@export var edit_alpha : bool = false :
	get: return color_picker.edit_alpha
	set(value): color_picker.edit_alpha = value


@export var edit_intensity : bool = false :
	get: return color_picker.edit_intensity
	set(value): color_picker.edit_intensity = value


@export var handle_minimum_width : float = 100.0 :
	get: return color_picker.custom_minimum_size.x
	set(value): color_picker.custom_minimum_size.x = value



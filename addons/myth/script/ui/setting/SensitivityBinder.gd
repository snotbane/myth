@icon("res://addons/myth/script/ui/setting/SensitivityBinder.svg")
@tool
class_name SensitivityBinder
extends GridContainer

var slider_x: HSlider
var slider_y: HSlider
var slider_z: HSlider

var invert_x: CheckBox
var invert_y: CheckBox
var invert_z: CheckBox

func _init() -> void:
	columns = 2

	slider_x = HSlider.new()
	slider_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_x.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slider_x.min_value = 0.1
	slider_x.max_value = 2.0
	slider_x.step = 0.01
	slider_x.value = 1.0
	slider_x.value_changed.connect(_refresh_text.unbind(1))
	add_child(slider_x)
	invert_x = CheckBox.new()
	invert_x.toggled.connect(_refresh_text.unbind(1))
	add_child(invert_x)

	slider_y = slider_x.duplicate()
	slider_y.visible = false
	slider_y.value_changed.connect(_refresh_text.unbind(1))
	add_child(slider_y)
	invert_y = invert_x.duplicate()
	invert_y.visible = false
	invert_y.toggled.connect(_refresh_text.unbind(1))
	add_child(invert_y)

	slider_z = slider_y.duplicate()
	slider_z.value_changed.connect(_refresh_text.unbind(1))
	add_child(slider_z)
	invert_z = invert_y.duplicate()
	invert_z.toggled.connect(_refresh_text.unbind(1))
	add_child(invert_z)


func _ready() -> void:
	_refresh_text()

	match dimensions + 1:
		1: dynamic_value = SystemPrefs.inst.get_sensitivity_1d(key)
		2: dynamic_value = SystemPrefs.inst.get_sensitivity_2d(key)
		3: dynamic_value = SystemPrefs.inst.get_sensitivity_3d(key)


@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "look_mouse,look_joystick,look_zoomed_mouse,look_zoomed_joystick,look_vehicle_mouse,look_vehicle_joystick")
var key: StringName


@export_enum("1D", "2D", "3D")
var dimensions: int = 0:
	set(value):
		dimensions = value

		slider_y.visible = dimensions >= 1
		invert_y.visible = dimensions >= 1
		slider_z.visible = dimensions >= 2
		invert_z.visible = dimensions >= 2

		_refresh_text()


@export_range(0.0, 1.0, 0.01)
var min_value: float = 0.1:
	get: return slider_x.min_value
	set(value):
		slider_x.min_value = value
		slider_y.min_value = value
		slider_z.min_value = value

@export_range(1.0, 10.0, 1.0, "or_greater")
var max_value: float = 2.0:
	get: return slider_x.max_value
	set(value):
		slider_x.max_value = value
		slider_y.max_value = value
		slider_z.max_value = value

@export_range(0.0, 1.0, 0.001)
var step: float = 0.01:
	get: return slider_x.step
	set(value):
		slider_x.step = value
		slider_y.step = value
		slider_z.step = value

@export
var text_format := "%1.2f":
	set(value):
		text_format = value
		_refresh_text()


var signed_value_x: float:
	get: return slider_x.value * (-1.0 if invert_x.button_pressed else +1.0)
	set(value):
		slider_x.value = absf(value)
		invert_x.button_pressed = value < 0.0

var signed_value_y: float:
	get: return slider_y.value * (-1.0 if invert_y.button_pressed else +1.0)
	set(value):
		slider_y.value = absf(value)
		invert_y.button_pressed = value < 0.0

var signed_value_z: float:
	get: return slider_z.value * (-1.0 if invert_z.button_pressed else +1.0)
	set(value):
		slider_z.value = absf(value)
		invert_z.button_pressed = value < 0.0


var dynamic_value: Variant:
	get:
		match dimensions + 1:
			1:
				return signed_value_x
			2:
				return Vector2(
					signed_value_x,
					signed_value_y,
				)
			3:
				return Vector3(
					signed_value_x,
					signed_value_y,
					signed_value_z,
				)
		return 1.0

	set(value):
		if value is float:
			signed_value_x = value
		elif value is Vector2:
			signed_value_x = value.x
			signed_value_y = value.y
		elif value is Vector3:
			signed_value_x = value.x
			signed_value_y = value.y
			signed_value_z = value.z
signal dynamic_value_changed


func _refresh_text() -> void:
	invert_x.text = ("X" if dimensions >= 1 else "") + PropertyDrawer.float_to_string(signed_value_x, text_format)
	invert_y.text = "Y" + PropertyDrawer.float_to_string(signed_value_y, text_format)
	invert_z.text = "Z" + PropertyDrawer.float_to_string(signed_value_z, text_format)


@tool class_name SettingNumber extends Setting

static var REGEX_STRING_FORMAT_CHECKER := RegEx.create_from_string(r"(?<!%)%[0-9\.]*[sdifv]")

static func get_format_count(s: String) -> int:
	return REGEX_STRING_FORMAT_CHECKER.search_all(s).size()


@export var number_min_value : float :
	get: return range.min_value
	set(new_value): range.min_value = new_value

@export var number_max_value : float = 100.0 :
	get: return range.max_value
	set(new_value): range.max_value = new_value

@export var number_value : float :
	get: return value
	set(new_value): value = new_value

@export_range(0.0, 1.0, 0.0001, "or_greater") var number_step : float = 1.0 :
	get: return range.step
	set(new_value): range.step = new_value


var _number_text : String
@export var number_text : String :
	get: return _number_text
	set(new_value):
		_number_text = new_value
		_refresh_number_text()


@export_enum("Horizontal Slider", "Spin Box") var input_type : int = 0 :
	get:
		if range is HSlider:	return 0
		if range is SpinBox:	return 1
		return -1

	set(value):
		if input_type == value: return

		var new_range : Range
		match value:
			0: new_range = HSlider.new()
			1: new_range = SpinBox.new()
			_: return

		new_range.custom_minimum_size.x = range.custom_minimum_size.x
		new_range.size_flags_vertical = range.size_flags_vertical
		new_range.value = range.value
		new_range.step = range.step
		new_range.min_value = range.min_value
		new_range.max_value = range.max_value
		new_range.value_changed.connect(_value_changed.unbind(1))

		hbox_panel.add_child(new_range)
		range.queue_free()
		range = new_range


@export var handle_minimum_width : float = 100.0 :
	get: return range.custom_minimum_size.x
	set(value): range.custom_minimum_size.x = value


var range : Range
var number_label : Label


func _get_value() -> Variant:
	return range.value
func _set_value(new_value: Variant) -> void:
	range.value = new_value


func _init() -> void:
	super._init()

	number_label = Label.new()
	number_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(number_label)

	range = HSlider.new()
	range.custom_minimum_size.x = 100.0
	range.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	range.min_value = 0.0
	range.max_value = 100.0
	range.value = 0.0
	range.step = 1.0
	hbox_panel.add_child(range)


func _ready() -> void:
	super._ready()

	range.value_changed.connect(_value_changed.unbind(1))

	_refresh_number_text()


func _value_changed() -> void:
	super._value_changed()

	_refresh_number_text()


func _refresh_number_text() -> void:
	number_label.visible = not number_text.is_empty()
	number_label.text = number_text % value if get_format_count(number_text) != 0 else number_text

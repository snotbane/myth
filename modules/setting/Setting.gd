## Base class for UI elements that keep track of user-set data.
@tool class_name Setting extends Control

const RESET_ICON := preload("uid://cc4at53uoxehi")

const STYLEBOX_MARGIN_LEFT : int = 6
const STYLEBOX_MARGIN_RIGHT : int = 6
const STYLEBOX_MARGIN_TOP : int = 2
const STYLEBOX_MARGIN_BOTTOM : int = 2

static var STYLEBOX_EMPTY : StyleBoxEmpty
static var STYLEBOX_INVALID : StyleBoxFlat

static func _static_init() -> void:
	STYLEBOX_EMPTY = StyleBoxEmpty.new()
	STYLEBOX_EMPTY.content_margin_left		= STYLEBOX_MARGIN_LEFT
	STYLEBOX_EMPTY.content_margin_right		= STYLEBOX_MARGIN_RIGHT
	STYLEBOX_EMPTY.content_margin_top		= STYLEBOX_MARGIN_TOP
	STYLEBOX_EMPTY.content_margin_bottom	= STYLEBOX_MARGIN_BOTTOM

	STYLEBOX_INVALID = StyleBoxFlat.new()
	STYLEBOX_INVALID.bg_color = Color.INDIAN_RED
	STYLEBOX_INVALID.content_margin_left	= STYLEBOX_MARGIN_LEFT
	STYLEBOX_INVALID.content_margin_right	= STYLEBOX_MARGIN_RIGHT
	STYLEBOX_INVALID.content_margin_top		= STYLEBOX_MARGIN_TOP
	STYLEBOX_INVALID.content_margin_bottom	= STYLEBOX_MARGIN_BOTTOM


static func _is_equal(a, b) -> bool:
	if (a == null) != (b == null): return false
	if a == b: return true

	match typeof(a):
		TYPE_ARRAY:
			if typeof(b) != TYPE_ARRAY: return false
			if a.size() != b.size(): return false

			for i in a.size():
				if not _is_equal(a[i], b[i]): return false

			return true

		TYPE_DICTIONARY:
			if typeof(b) != TYPE_DICTIONARY: return false
			if a.size() != b.size(): return false

			for k in a.keys():
				if not b.has(k): return false
				if not _is_equal(a[k], b[k]): return false

			return true

		TYPE_OBJECT:
			if typeof(b) != TYPE_OBJECT: return false

			if a.has_method(&"_is_equal"):
				return a._is_equal(b)
			elif b.has_method(&"_is_equal"):
				return b._is_equal(a)
			if a.has_method(&"is_match"):
				return a.is_match(b)

	return false


static func duplicate_value(v) -> Variant:
	match typeof(v):
		TYPE_ARRAY, TYPE_DICTIONARY:
			return v.duplicate()

		TYPE_OBJECT:
			return v.duplicate() if v.has_method(&"duplicate") else v

	return v

signal input_changed
## This signal emits when the input value is finished changing, e.g. submitted text or finished slider drag.
signal value_changed(new_value: Variant)
signal override_changed(is_overridden: bool)
## This signal emits whenever this Setting changes from being valid to invalid, or invalid to valid (regardless of the reason).
signal valid_changed(is_valid: bool)


var panel_normal : StyleBox :
	get: return get_theme_stylebox(&"setting_panel_normal", &"Setting") if has_theme_stylebox(&"setting_panel_normal", &"Setting") else STYLEBOX_EMPTY

var panel_invalid : StyleBox :
	get: return get_theme_stylebox(&"setting_panel_invalid", &"Setting") if has_theme_stylebox(&"setting_panel_invalid", &"Setting") else STYLEBOX_INVALID

var reset_icon : Texture2D :
	get: return get_theme_icon(&"setting_reset_icon", &"Setting") if has_theme_icon(&"setting_reset_icon", &"Setting") else RESET_ICON

var reset_flat : bool :
	get: return get_theme_constant(&"setting_reset_flat", &"Setting") if has_theme_constant(&"setting_reset_flat", &"Setting") else true


@export var label_text : String = "Setting" :
	get: return label.text
	set(value): label.text = value


## Preallocates space for a reset button. The button will always be visible in editor.
@export var reset_button_enabled : bool = true :
	get: return reset_button_container.visible
	set(value): reset_button_container.visible = value


var _layout_group : Setting_GroupLayout
@export var layout_group : Setting_GroupLayout :
	get: return _layout_group
	set(value):
		if _layout_group: _layout_group.remove_user(self)

		_layout_group = value

		if _layout_group: _layout_group.add_user(self)


var hbox_all : HBoxContainer
var panel_container : PanelContainer
var hbox_panel : HBoxContainer
var label : Label
var space : Control

# var tracker : SettingTracker
var reset_button_container : Control
var reset_button : Button

var default_tooltip_text : String


func _init() -> void:
	default_tooltip_text = tooltip_text

	hbox_all = HBoxContainer.new()
	hbox_all.set_anchors_preset(PRESET_FULL_RECT)
	self.add_child(hbox_all)

	panel_container = PanelContainer.new()
	panel_container.add_theme_stylebox_override(&"panel", STYLEBOX_EMPTY)
	panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_container.tooltip_text = tooltip_text
	panel_container.tooltip_auto_translate_mode = tooltip_auto_translate_mode
	hbox_all.add_child(panel_container)

	hbox_panel = HBoxContainer.new()
	panel_container.add_child(hbox_panel)

	label = Label.new()
	label.name = &"label"
	label.text = "Setting"
	hbox_panel.add_child(label)

	space = Control.new()
	space.name = &"space"
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_panel.add_child(space)

	reset_button_container = Control.new()
	hbox_all.add_child(reset_button_container)

	reset_button = Button.new()
	reset_button.visible = OS.has_feature(&"editor_hint")
	reset_button.set_anchors_preset(PRESET_FULL_RECT)
	reset_button_container.add_child(reset_button)
	reset_button.pressed.connect(reset)


func _get_minimum_size() -> Vector2:
	var result := panel_container.get_minimum_size()
	if layout_group and layout_group.ensure_same_minimum_height: result.y = layout_group.minimum_height
	return result


var _value_default : Variant
var _value_prev : Variant
var value : Variant :
	get: return _get_value()
	set(new_value): _set_value(new_value)
func _get_value() -> Variant: return null
func _set_value(new_value: Variant) -> void: pass


func _value_changed() -> void:
	if _is_equal(_value_prev, _value_default) and not _is_equal(value, _value_default):
		is_overridden = true

	elif not _is_equal(_value_prev, _value_default) and _is_equal(value, _value_default):
		is_overridden = false

	_value_prev = duplicate_value(value)
	validate()

	value_changed.emit(_value_prev)


func _ready() -> void:
	reset_button.icon = reset_icon
	reset_button.flat = reset_flat

	reset_button_container.custom_minimum_size = reset_button.get_combined_minimum_size()

	_value_default = duplicate_value(value)
	_value_prev = duplicate_value(_value_default)

	validate()


#region Validation

var _validation_tooltip_text : String
var validation_tooltip_text : String :
	get: return _validation_tooltip_text
	set(value):
		var _is_valid_prev := is_valid

		_validation_tooltip_text = value

		if is_valid:
			panel_container.tooltip_text = default_tooltip_text
			panel_container.add_theme_stylebox_override(&"panel", panel_normal)
		else:
			panel_container.tooltip_text = _validation_tooltip_text
			panel_container.add_theme_stylebox_override(&"panel", panel_invalid)

		if is_valid != _is_valid_prev:
			valid_changed.emit(is_valid)


var is_valid : bool :
	get: return _validation_tooltip_text.is_empty()


func validate() -> void:
	validation_tooltip_text = _validate()
func _validate() -> String: return String()

#endregion


var is_overridden : bool :
	get: return reset_button.visible
	set(value):
		var is_overridden_prev = is_overridden
		reset_button.visible = value

		if is_overridden_prev == value: return

		override_changed.emit(value)


func set_duplicable(a: StringName, b) -> void:
	match typeof(b):
		TYPE_ARRAY, TYPE_DICTIONARY:
			set(a, b.duplicate())

		TYPE_OBJECT:
			set(a, b.duplicate() if b.has_method(&"duplicate") else b)

		_:
			set(a, b)


func reset() -> void:
	value = duplicate_value(_value_default)

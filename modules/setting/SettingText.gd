
@tool class_name SettingText extends Setting

const FILE_DIALOG_ICON := preload("uid://da04krtpviega")

static var IS_MACOS : bool


static func _static_init() -> void:
	IS_MACOS = OS.has_feature(&"macos") or OS.has_feature(&"web_macos")


## Emitted when [member file_button] is pressed. Use with [member file_dialog_type.CUSTOM] to customize what the button does.
signal file_button_pressed

## Emitted when [member file_dialog_type] is Open Path or Open Content, and [member file_dialog] is selected and confirmed.
signal file_selected(path: String)


var _input_type : int
@export_enum("Single Line", "Multi Line", "Code") var input_type : int :
	get: return _input_type
	set(new_value):
		if _input_type == new_value: return
		_input_type = new_value

		var new_input : Control
		match _input_type:
			0: new_input = LineEdit.new()
			1: new_input = TextEdit.new()
			2: new_input = CodeEdit.new()
			_: return

		new_input.size_flags_horizontal = input.size_flags_horizontal
		new_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER if new_value <= 0 else Control.SIZE_EXPAND_FILL
		new_input.text = text
		new_input.placeholder_text = placeholder_text
		new_input.context_menu_enabled = context_menu_enabled
		new_input.text_changed.connect(get_value_changed_dynamic_unbound(new_input))


		hbox_input.add_child(new_input)
		input.queue_free()
		input = new_input

		clear_button = clear_button
		autowrap_mode = autowrap_mode


@export var text : String :
	get: return value
	set(new_value): value = new_value


@export var placeholder_text : String :
	get: return input.placeholder_text
	set(new_value): input.placeholder_text = new_value


@export var context_menu_enabled : bool = false :
	get: return input.context_menu_enabled
	set(new_value): input.context_menu_enabled = new_value


var _clear_button : bool = false
@export var clear_button : bool = false :
	get: return _clear_button
	set(new_value):
		_clear_button = new_value
		match _input_type:
			0:
				input.clear_button_enabled = _clear_button



var _autowrap_mode := TextServer.AUTOWRAP_WORD_SMART
## Sets the autowrap mode. Only works if the [member input_type] is a [TextEdit].
@export var autowrap_mode := TextServer.AUTOWRAP_WORD_SMART :
	get: return _autowrap_mode
	set(new_value):
		_autowrap_mode = new_value
		match _input_type:
			1, 2:
				input.scroll_fit_content_height = _autowrap_mode > 0
				input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if _autowrap_mode > 0 else TextEdit.LINE_WRAPPING_NONE
				input.autowrap_mode = _autowrap_mode


var _validation_method : Callable
var _validation_type : int
@export var validation_type : StringValidation :
	get: return _validation_type
	set(new_value):
		if _validation_type == new_value: return
		_validation_type = new_value

		_validation_method = VALIDATION_METHODS[_validation_type]
		validate()
enum StringValidation {
	## No validation will be applied.
	NO_VALIDATION,
	## Uses [member String.is_empty()] to validate this [String].
	NON_EMPTY,
	## Uses [member RegEx.is_valid()] to validate this [String].
	REGULAR_EXPRESSION,
	## Validates if the given path points to an existing directory.
	EXISTING_DIR_PATH,
	## Validates if the given path points to an existing file.
	EXISTING_FILE_PATH,
	## Uses [member String.is_valid_filename()] to validate this [String].
	VALID_FILE_NAME,
	## Uses [member String.is_valid_ip_address()] to validate this [String].
	VALID_IP_ADDRESS,
	## Override [member _validate_custom()] in order to use this method.
	CUSTOM,
}

var VALIDATION_METHODS : Array[Callable] = [
	func() -> String:
	return String()
	,

	func() -> String:
	return String() \
		if not text.is_empty() \
		else "Must not be empty."
	,

	func() -> String:
	return String() \
		if RegEx.create_from_string(text).is_valid() \
		else "Invalid regular expression."
	,

	func() -> String:
	return String() \
		if DirAccess.open(text) != null \
		else "Folder path does not exist."
	,

	func() -> String:
	return String() \
		if FileAccess.file_exists(text) \
		else "File path does not exist."
	,

	func() -> String:
	return String() \
		if text.is_valid_filename() \
		else "Must be a valid file name."
	,

	func() -> String:
	return String() \
		if text.is_valid_ip_address() \
		else "Must be a valid IP address."
	,

	_validate_custom
]


@export var handle_minimum_width : float = 100.0 :
	get: return hbox_input.custom_minimum_size.x
	set(new_value): hbox_input.custom_minimum_size.x = new_value


@export_group("File Dialog", "file_dialog_")

var _file_dialog_type : int
@export_enum("No Button", "Open Path", "Open Content", "Custom") var file_dialog_type : int :
	get: return _file_dialog_type
	set(new_value):
		if _file_dialog_type == new_value: return

		_file_dialog_type = new_value
		file_button.visible = _file_dialog_type != 0
enum {
	NO_FILE_DIALOG,
	OPEN_PATH,
	OPEN_CONTENT,
	OPEN_CUSTOM,
}


var file_dialog_icon : Texture2D = FILE_DIALOG_ICON :
	get: return get_theme_icon(&"setting_file_dialog_icon", &"Setting") if has_theme_icon(&"setting_file_dialog_icon", &"Setting") else FILE_DIALOG_ICON


@export var file_dialog_file_mode := FileDialog.FileMode.FILE_MODE_OPEN_FILE :
	get: return file_dialog.file_mode
	set(new_value): file_dialog.file_mode = new_value

@export var file_dialog_access := FileDialog.Access.ACCESS_USERDATA :
	get: return file_dialog.access
	set(new_value): file_dialog.access = new_value

@export var file_dialog_filters : PackedStringArray :
	get: return file_dialog.filters
	set(new_value): file_dialog.filters = new_value


var hbox_input : HBoxContainer
var input : Control
var file_button : Button
var file_dialog : FileDialog


func _get_value() -> Variant:
	return input.text


func _set_value(new_value: Variant) -> void:
	input.text = new_value

	## This is a really weird setup for this but it works. Basically for whatever reason LineEdit causes issues when setting the default on ready, so we want to not call this the first time, but only for LineEdits.
	if input is not LineEdit or input.text_changed.is_connected(_value_changed):
		_value_changed()


func _init() -> void:
	super._init()

	_validation_method = VALIDATION_METHODS[StringValidation.NO_VALIDATION]

	hbox_input = HBoxContainer.new()
	hbox_input.custom_minimum_size.x = 100.0
	hbox_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_panel.add_child(hbox_input)

	input = LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	input.context_menu_enabled = false
	input.clear_button_enabled = false
	hbox_input.add_child(input)

	file_button = Button.new()
	file_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	file_button.visible = false
	hbox_input.add_child(file_button, false, INTERNAL_MODE_BACK)

	file_dialog = FileDialog.new()
	file_dialog.use_native_dialog = true
	file_dialog.display_mode = FileDialog.DISPLAY_LIST
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	add_child(file_dialog)

	file_button.pressed.connect(_file_dialog_popup)
	file_button.pressed.connect(file_button_pressed.emit)
	file_dialog.confirmed.connect(_file_dialog_confirmed)


func _ready() -> void:
	super._ready()

	file_button.icon = file_dialog_icon

	input.text_changed.connect(get_value_changed_dynamic_unbound(input))


func _get_minimum_size() -> Vector2:
	var result := super._get_minimum_size()
	result.y = maxf(result.y, input.get_combined_minimum_size().y)
	return result


func _value_changed() -> void:
	super._value_changed()
	update_minimum_size()


## MacOS has a bug where [file_dialog.confirmed] will not emit if the file dialog is native. This implementation of [member _notification] fixes that.
var _do_notification_emission : bool
func _notification(what: int) -> void:
	if not _do_notification_emission: return
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_do_notification_emission = false
			_file_dialog_confirmed()



func _validate_custom() -> String: return "Unimplmented validation method."
func _validate() -> String: return _validation_method.call()


func _file_dialog_popup() -> void:
	_do_notification_emission = IS_MACOS and file_dialog.use_native_dialog
	file_dialog.popup_file_dialog()


func _file_dialog_confirmed() -> void:
	if file_dialog.current_path == null: return

	match file_dialog_type:
		OPEN_PATH:
			text = file_dialog.current_path

		OPEN_CONTENT:
			var file := FileAccess.open(file_dialog.current_path, FileAccess.READ)
			match file.get_open_error():
				OK:	pass
				_:	return

			text = file.get_as_text()

		OPEN_CUSTOM:
			_file_dialog_confirmed_custom()


func _file_dialog_confirmed_custom() -> void: pass


func get_value_changed_dynamic_unbound(node: Node) -> Callable :
	return _value_changed.unbind(1) if node is LineEdit else _value_changed

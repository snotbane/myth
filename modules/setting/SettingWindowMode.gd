##
@tool class_name SettingWindowMode extends Setting


const INPUT_FULLSCREEN := &"fullscreen"
const SETTING_INPUT_FULLSCREEN := "input/" + INPUT_FULLSCREEN


@export var labels : PackedStringArray = [
	"Windowed",
	"Minimized",
	"Maximized",
	"Fullscreen",
	"Fullscreen (Exclusive)"
]


var _selectable_modes : int = 25
## Available [Window.Mode]s.
@export_flags("Windowed:1", "Minimized:2", "Maximized:4", "Fullscreen:8", "Exclusive:16") var selectable_modes : int = 25 :
	get: return _selectable_modes
	set(new_value):
		_selectable_modes = new_value
		while option.item_count > 0:
			option.remove_item(0)

		if _selectable_modes & 1:
			option.add_item(labels[Window.Mode.MODE_WINDOWED])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_WINDOWED)
		if _selectable_modes & 2:
			option.add_item(labels[Window.Mode.MODE_MINIMIZED])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_MINIMIZED)
		if _selectable_modes & 4:
			option.add_item(labels[Window.Mode.MODE_MAXIMIZED])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_MAXIMIZED)
		if _selectable_modes & 8:
			option.add_item(labels[Window.Mode.MODE_FULLSCREEN])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_FULLSCREEN)
		if _selectable_modes & 16:
			option.add_item(labels[Window.Mode.MODE_EXCLUSIVE_FULLSCREEN])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_EXCLUSIVE_FULLSCREEN)


@export var selected : int :
	get: return value
	set(new_value): value = clampi(new_value, 0, option.item_count - 1)


## Determines which window mode should be used when this node is created. Generally set this to [member StartupMode.USE_PREVIOUS], and also generally make sure this node is spawned right when the game starts.
@export var startup_mode := StartupMode.USE_PREVIOUS
enum StartupMode {
	## Doesn't set the window mode. This DOES still set the setting, but it won't match the current window mode.
	IGNORE,

	## Always sets the value and save data to [member default_windowed_mode] on startup.
	WINDOWED_ALWAYS,

	## Always sets the value and save data to [member default_fullscreen_mode] on startup.
	FULLSCREEN_ALWAYS,

	## Sets the value to the saved window mode.
	USE_PREVIOUS,
}

@export var default_windowed_mode := Window.Mode.MODE_WINDOWED
@export var default_fullscreen_mode := Window.Mode.MODE_EXCLUSIVE_FULLSCREEN


@export var handle_minimum_width : float = 100.0 :
	get: return option.custom_minimum_size.x
	set(new_value): option.custom_minimum_size.x = new_value


var value_as_mode : Window.Mode :
	get: return option.get_item_id(selected)
	set(new_value):
		for i in option.item_count:
			if option.get_item_id(i) != new_value: continue

			value = i
			break

var windowed_mode : Window.Mode
var fullscreen_mode : Window.Mode

var option : OptionButton


var is_fullscreen : bool :
	get: return get_window().mode >= Window.Mode.MODE_FULLSCREEN
	set(new_value):
		value_as_mode = fullscreen_mode if new_value else windowed_mode


func _get_value() -> Variant:
	return option.selected


func _set_value(new_value: Variant) -> void:
	option.select(new_value)
	_value_changed()


func _init() -> void:
	super._init()

	option = OptionButton.new()
	option.custom_minimum_size.x = 100.0
	option.selected = 0
	option.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(option)

	selectable_modes = selectable_modes


func _ready() -> void:
	windowed_mode = default_windowed_mode
	fullscreen_mode = default_fullscreen_mode

	super._ready()

	option.item_selected.connect(_value_changed.unbind(1))

	_startup.call_deferred()

var _started_up : bool = false
func _startup() -> void:
	_started_up = true

	match startup_mode:
		StartupMode.WINDOWED_ALWAYS:
			value_as_mode = windowed_mode

		StartupMode.FULLSCREEN_ALWAYS:
			value_as_mode = fullscreen_mode

		StartupMode.USE_PREVIOUS:
			value = value


func _value_changed() -> void:
	super._value_changed()
	if Engine.is_editor_hint() or get_window() == null: return

	match value_as_mode:
		Window.Mode.MODE_WINDOWED, Window.Mode.MODE_MAXIMIZED:
			windowed_mode = value_as_mode

		Window.Mode.MODE_FULLSCREEN, Window.Mode.MODE_EXCLUSIVE_FULLSCREEN:
			fullscreen_mode = value_as_mode

	if not _started_up: return

	get_window().mode = value_as_mode


func _notification(what: int) -> void:
	if Engine.is_editor_hint() or get_window() == null: return

	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if 2 ** get_window().mode & _selectable_modes:
				value_as_mode = get_window().mode


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INPUT_FULLSCREEN):
		is_fullscreen = not is_fullscreen

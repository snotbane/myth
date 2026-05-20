@tool class_name WindowModeSelector extends OptionButton

const INPUT_FULLSCREEN := &"fullscreen"
const SETTING_INPUT_FULLSCREEN := "input/" + INPUT_FULLSCREEN

@export_custom(PROPERTY_HINT_INPUT_NAME, "loose_mode") var input_name: StringName = &"fullscreen"

@export var labels: PackedStringArray = [
	"Windowed",
	"Minimized",
	"Maximized",
	"Borderless",
	"Exclusive"
]

## Available [Window.Mode]s.
@export_flags("Windowed:1", "Minimized:2", "Maximized:4", "Borderless:8", "Exclusive:16") var selectable_modes: int = 25:
	set(value):
		selectable_modes = value

		clear()

		if selectable_modes & 1:
			add_item(labels[Window.Mode.MODE_WINDOWED])
			set_item_id(item_count - 1, Window.Mode.MODE_WINDOWED)
		if selectable_modes & 2:
			add_item(labels[Window.Mode.MODE_MINIMIZED])
			set_item_id(item_count - 1, Window.Mode.MODE_MINIMIZED)
		if selectable_modes & 4:
			add_item(labels[Window.Mode.MODE_MAXIMIZED])
			set_item_id(item_count - 1, Window.Mode.MODE_MAXIMIZED)
		if selectable_modes & 8:
			add_item(labels[Window.Mode.MODE_FULLSCREEN])
			set_item_id(item_count - 1, Window.Mode.MODE_FULLSCREEN)
		if selectable_modes & 16:
			add_item(labels[Window.Mode.MODE_EXCLUSIVE_FULLSCREEN])
			set_item_id(item_count - 1, Window.Mode.MODE_EXCLUSIVE_FULLSCREEN)


@export var default_windowed_mode := Window.Mode.MODE_WINDOWED
@export var default_fullscreen_mode := Window.Mode.MODE_EXCLUSIVE_FULLSCREEN


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


var windowed_mode: Window.Mode
var fullscreen_mode: Window.Mode


var is_fullscreen: bool:
	get: return get_window().mode >= Window.Mode.MODE_FULLSCREEN
	set(value):
		var id := fullscreen_mode if value else windowed_mode
		select_mode(id)


var ignore_events: bool:
	get: return Engine.is_editor_hint() or get_window() == null


func select_mode(mode: Window.Mode) -> void:
	for i in item_count:
		if get_item_id(i) != mode: continue

		select(i)
		item_selected.emit(i)
		break


func _init() -> void:
	selectable_modes = selectable_modes


func _ready() -> void:
	windowed_mode = default_windowed_mode
	fullscreen_mode = default_fullscreen_mode

	item_selected.connect(_item_selected)

	_ready_deferred.call_deferred()


var _started_up: bool = false
func _ready_deferred() -> void:
	_started_up = true

	match startup_mode:
		StartupMode.WINDOWED_ALWAYS:
			get_window().mode = windowed_mode

		StartupMode.FULLSCREEN_ALWAYS:
			get_window().mode = fullscreen_mode


func _item_selected(idx: int) -> void:
	if ignore_events: return

	match selected:
		Window.Mode.MODE_WINDOWED, Window.Mode.MODE_MAXIMIZED:
			windowed_mode = selected

		Window.Mode.MODE_FULLSCREEN, Window.Mode.MODE_EXCLUSIVE_FULLSCREEN:
			fullscreen_mode = selected

	if not _started_up: return

	get_window().mode = get_item_id(selected)


func _notification(what: int) -> void:
	if button_pressed or ignore_events: return

	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if 2 ** get_window().mode & selectable_modes:
				select_mode(get_window().mode)


func _unhandled_input(event: InputEvent) -> void:
	if input_name.is_empty(): return

	if event.is_action_pressed(input_name):
		is_fullscreen = not is_fullscreen

		get_viewport().set_input_as_handled()

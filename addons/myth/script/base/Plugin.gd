@tool
class_name MythPlugin
extends EditorPlugin

const BASE_AUTOLOAD_NAME := "myth"
const BASE_AUTOLOAD_SCRIPT := "res://addons/myth/script/Myth.tscn"

const GHOST_AUTOLOAD_NAME := "myth_ghost_handler"
const GHOST_AUTOLOAD_SCRIPT := "res://addons/myth/script/component/tribute/ghost/MythGhostHandler.tscn"

const TERMINAL_AUTOLOAD_NAME := "myth_terminal_window"
const TERMINAL_AUTOLOAD_SCRIPT := "res://addons/myth/script/terminal/MythTerminalWindow.tscn"


const WINDOW_MODE_AUTOLOAD_NAME := "myth_window_mode_handler"
const WINDOW_MODE_AUTOLOAD_SCRIPT := "res://addons/myth/script/utility/window_mode/WindowModeHandler.tscn"

const SYSTEM_PREFS_AUTOLOAD_NAME := "myth_system_prefs"
const SYSTEM_PREFS_AUTOLOAD_SCRIPT := "res://addons/myth/script/utility/system_prefs/SystemPrefsAutoload.tscn"


## Adds a new input binding to the project settings.
static func add_default_input_binding(binding_name: String, events: Array = [], deadzone := 0.2) -> void:
	if not binding_name.begins_with("input/"):
		binding_name = "input/" + binding_name

	if ProjectSettings.get_setting(binding_name) != null: return

	ProjectSettings.set_setting(binding_name, {
		"deadzone": deadzone,
		"events": events,
	})


## Adds a new project setting.
static func add_default_project_setting(setting_info: Dictionary, value: Variant) -> void:
	if not ProjectSettings.has_setting(setting_info.name):
		ProjectSettings.set_setting(setting_info.name, value)
		ProjectSettings.save()

	ProjectSettings.add_property_info(setting_info)
	ProjectSettings.set_initial_value(setting_info.name, value)


func _enter_tree() -> void:
	add_default_project_setting(
		{
			&"name": "display/mouse_cursor/default_mouse_mode",
			&"type": TYPE_INT,
			&"hint": PropertyHint.PROPERTY_HINT_ENUM,
			&"hint_string": "Visible,Hidden,Captured,Confined,Confined Hidden,Ignore",
		},
		Input.MOUSE_MODE_VISIBLE
	)

	add_default_project_setting(
		{
			&"name": "myth/debug/property_drawer/present_in",
			&"type": TYPE_INT,
			&"hint": PropertyHint.PROPERTY_HINT_FLAGS,
			&"hint_string": "Editor Runtime,Debug,Release",
		},
		3
	)

	add_default_project_setting(
		{
			&"name": "myth/debug/property_drawer/show_in",
			&"type": TYPE_INT,
			&"hint": PropertyHint.PROPERTY_HINT_FLAGS,
			&"hint_string": "Editor Runtime,Debug,Release",
		},
		1
	)

	add_default_project_setting(InputBinder.ADD_REMOVE_EVENTS_SETTING, false)


	add_autoload_singleton(BASE_AUTOLOAD_NAME, BASE_AUTOLOAD_SCRIPT)
	# add_autoload_singleton(TERMINAL_AUTOLOAD_NAME, TERMINAL_AUTOLOAD_SCRIPT)
	# add_autoload_singleton(GHOST_AUTOLOAD_NAME, GHOST_AUTOLOAD_SCRIPT)
	# add_autoload_singleton(WINDOW_MODE_AUTOLOAD_NAME, WINDOW_MODE_AUTOLOAD_SCRIPT)
	# add_autoload_singleton(SYSTEM_PREFS_AUTOLOAD_NAME, SYSTEM_PREFS_AUTOLOAD_SCRIPT)


	var ghost_toggle_input_0 := InputEventKey.new()
	ghost_toggle_input_0.keycode = KEY_G
	ghost_toggle_input_0.shift_pressed = true
	add_default_input_binding("_myth_ghost_toggle", [
		ghost_toggle_input_0,
	])

	var terminal_toggle_input_0 := InputEventKey.new()
	terminal_toggle_input_0.keycode = KEY_QUOTELEFT
	add_default_input_binding("_myth_terminal_toggle", [
		terminal_toggle_input_0,
	])

	var fullscreen_toggle_input_0 := InputEventKey.new()
	fullscreen_toggle_input_0.physical_keycode = KEY_F11
	var fullscreen_toggle_input_1 := InputEventKey.new()
	fullscreen_toggle_input_1.keycode = KEY_F
	fullscreen_toggle_input_1.command_or_control_autoremap = true
	fullscreen_toggle_input_1.shift_pressed = true
	add_default_input_binding("_myth_fullscreen_toggle", [
		fullscreen_toggle_input_0,
		fullscreen_toggle_input_1,
	])

	var input_binder_remove_input_0 := InputEventMouseButton.new()
	input_binder_remove_input_0.button_index = MOUSE_BUTTON_RIGHT
	var input_binder_remove_input_1 := InputEventKey.new()
	input_binder_remove_input_1.keycode = KEY_BACKSPACE
	var input_binder_remove_input_2 := InputEventJoypadButton.new()
	input_binder_remove_input_2.button_index = JOY_BUTTON_Y
	add_default_input_binding("_myth_input_binder_remove", [
		input_binder_remove_input_0,
		input_binder_remove_input_1,
		input_binder_remove_input_2,
	])

	var input_binder_warning_input_0 := InputEventJoypadButton.new()
	input_binder_warning_input_0.button_index = JOY_BUTTON_X
	add_default_input_binding("_myth_input_binder_warning", [
		input_binder_warning_input_0,
	])

	var menu_input_0 := InputEventKey.new()
	menu_input_0.physical_keycode = KEY_ESCAPE
	var menu_input_1 := InputEventKey.new()
	menu_input_1.physical_keycode = KEY_P
	var menu_input_2 := InputEventJoypadButton.new()
	menu_input_2.button_index = JOY_BUTTON_START
	add_default_input_binding("menu", [
		menu_input_0,
		menu_input_1,
		menu_input_2,
	])

	var move_left_input_0 := InputEventKey.new()
	move_left_input_0.physical_keycode = KEY_A
	var move_left_input_1 := InputEventJoypadMotion.new()
	move_left_input_1.axis = JOY_AXIS_LEFT_X
	move_left_input_1.axis_value = -1.0
	add_default_input_binding("move_left", [
		move_left_input_0,
		move_left_input_1,
	])

	var move_right_input_0 := InputEventKey.new()
	move_right_input_0.physical_keycode = KEY_D
	var move_right_input_1 := InputEventJoypadMotion.new()
	move_right_input_1.axis = JOY_AXIS_LEFT_X
	move_right_input_1.axis_value = +1.0
	add_default_input_binding("move_right", [
		move_right_input_0,
		move_right_input_1,
	])

	var move_forward_input_0 := InputEventKey.new()
	move_forward_input_0.physical_keycode = KEY_W
	var move_forward_input_1 := InputEventJoypadMotion.new()
	move_forward_input_1.axis = JOY_AXIS_LEFT_Y
	move_forward_input_1.axis_value = -1.0
	add_default_input_binding("move_forward", [
		move_forward_input_0,
		move_forward_input_1,
	])

	var move_back_input_0 := InputEventKey.new()
	move_back_input_0.physical_keycode = KEY_S
	var move_back_input_1 := InputEventJoypadMotion.new()
	move_back_input_1.axis = JOY_AXIS_LEFT_Y
	move_back_input_1.axis_value = +1.0
	add_default_input_binding("move_back", [
		move_back_input_0,
		move_back_input_1,
	])

	var sprint_input_0 := InputEventKey.new()
	sprint_input_0.physical_keycode = KEY_SHIFT
	var sprint_input_1 := InputEventJoypadButton.new()
	sprint_input_1.button_index = JOY_BUTTON_LEFT_STICK
	add_default_input_binding("sprint", [
		sprint_input_0,
		sprint_input_1,
	])

	var crouch_input_0 := InputEventKey.new()
	crouch_input_0.physical_keycode = KEY_CTRL
	var crouch_input_1 := InputEventJoypadButton.new()
	crouch_input_1.button_index = JOY_BUTTON_RIGHT_STICK
	add_default_input_binding("crouch", [
		crouch_input_0,
		crouch_input_1,
	])

	var jump_input_0 := InputEventKey.new()
	jump_input_0.physical_keycode = KEY_SPACE
	var jump_input_1 := InputEventJoypadButton.new()
	jump_input_1.button_index = JOY_BUTTON_A
	add_default_input_binding("jump", [
		jump_input_0,
		jump_input_1,
	])

	Myth.editor_interface_safe = get_editor_interface()



func _exit_tree() -> void:
	remove_autoload_singleton(BASE_AUTOLOAD_NAME)
	# remove_autoload_singleton(TERMINAL_AUTOLOAD_NAME)
	# remove_autoload_singleton(GHOST_AUTOLOAD_NAME)
	# remove_autoload_singleton(WINDOW_MODE_AUTOLOAD_NAME)
	# remove_autoload_singleton(SYSTEM_PREFS_AUTOLOAD_NAME)

	Myth.editor_interface_safe = null

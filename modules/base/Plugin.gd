
@tool class_name MythPlugin extends EditorPlugin

const INPUT_QUIT := &"quit"
const INPUT_FULLSCREEN := &"fullscreen"

const SETTING_INPUT_QUIT := "input/" + INPUT_QUIT
const SETTING_INPUT_FULLSCREEN := "input/" + INPUT_FULLSCREEN

static func add_default_input_binding(binding_name: String, events: Array = [], deadzone := 0.2) -> void:
	if ProjectSettings.get_setting(binding_name) != null: return

	ProjectSettings.set_setting(binding_name, {
		"deadzone": deadzone,
		"events": events,
	})


func _enable_plugin() -> void:
	if not ProjectSettings.has_setting(MouseModeUser.PROJECT_SETTING_HINT[&"name"]):
		ProjectSettings.set_setting(MouseModeUser.PROJECT_SETTING_HINT[&"name"], Input.MOUSE_MODE_VISIBLE)
		ProjectSettings.add_property_info(MouseModeUser.PROJECT_SETTING_HINT)
		ProjectSettings.set_initial_value(MouseModeUser.PROJECT_SETTING_HINT[&"name"], Input.MOUSE_MODE_VISIBLE)
		ProjectSettings.save()

	configure_input()


func _disable_plugin() -> void:
	pass


func configure_input() -> void:
	var quit_0 := InputEventKey.new()
	quit_0.physical_keycode = KEY_Q
	quit_0.ctrl_pressed = true
	MythPlugin.add_default_input_binding(SETTING_INPUT_QUIT, [
		quit_0,
	])

	var fullscreen_0 := InputEventKey.new()
	fullscreen_0.physical_keycode = KEY_F11
	var fullscreen_1 := InputEventKey.new()
	fullscreen_1.physical_keycode = KEY_F
	fullscreen_1.ctrl_pressed = true
	fullscreen_1.command_or_control_autoremap = true
	MythPlugin.add_default_input_binding(SETTING_INPUT_FULLSCREEN, [
		fullscreen_0,
		fullscreen_1,
	])

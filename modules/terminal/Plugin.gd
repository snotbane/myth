
@tool extends EditorPlugin

func _enable_plugin() -> void:
	if not ProjectSettings.has_setting(MouseModeUser.PROJECT_SETTING_HINT[&"name"]):
		ProjectSettings.set_setting(MouseModeUser.PROJECT_SETTING_HINT[&"name"], Input.MOUSE_MODE_VISIBLE)
		ProjectSettings.add_property_info(MouseModeUser.PROJECT_SETTING_HINT)
		ProjectSettings.set_initial_value(MouseModeUser.PROJECT_SETTING_HINT[&"name"], Input.MOUSE_MODE_VISIBLE)
		ProjectSettings.save()

	add_autoload_singleton(DebugGhostAutoload.AUTOLOAD_NAME, DebugGhostAutoload.AUTOLOAD_PATH)
	add_autoload_singleton(TerminalAutoload.AUTOLOAD_NAME, TerminalAutoload.AUTOLOAD_PATH)

	configure_input()

func _disable_plugin() -> void:
	remove_autoload_singleton(DebugGhostAutoload.AUTOLOAD_NAME)
	remove_autoload_singleton(TerminalAutoload.AUTOLOAD_NAME)

func configure_input() -> void:
	var quit_0 := InputEventKey.new()
	quit_0.physical_keycode = KEY_Q
	quit_0.ctrl_pressed = true
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_QUIT, [
		quit_0,
	])

	var fullscreen_0 := InputEventKey.new()
	fullscreen_0.physical_keycode = KEY_F11
	var fullscreen_1 := InputEventKey.new()
	fullscreen_1.physical_keycode = KEY_F
	fullscreen_1.ctrl_pressed = true
	fullscreen_1.command_or_control_autoremap = true
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_FULLSCREEN, [
		fullscreen_0,
		fullscreen_1,
	])

	var cli_toggle_0 := InputEventKey.new()
	cli_toggle_0.physical_keycode = KEY_QUOTELEFT
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_TERMINAL_TOGGLE, [
		cli_toggle_0
	])

	var ghost_toggle_0 := InputEventKey.new()
	ghost_toggle_0.physical_keycode = KEY_V
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_TOGGLE, [
		ghost_toggle_0,
	])


	var ghost_teleport_0 := InputEventKey.new()
	ghost_teleport_0.physical_keycode = KEY_V
	ghost_teleport_0.shift_pressed = true
	var ghost_teleport_1 := InputEventKey.new()
	ghost_teleport_1.physical_keycode = KEY_ENTER
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_TELEPORT, [
		ghost_teleport_0,
		ghost_teleport_1,
	])


	var ghost_sprint_0 := InputEventKey.new()
	ghost_sprint_0.physical_keycode = KEY_SHIFT
	var ghost_sprint_1 := InputEventJoypadButton.new()
	ghost_sprint_1.button_index = JOY_BUTTON_LEFT_STICK
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_SPRINT, [
		ghost_sprint_0,
		ghost_sprint_1,
	])


	var ghost_move_left_0 := InputEventKey.new()
	ghost_move_left_0.physical_keycode = KEY_A
	var ghost_move_left_1 := InputEventJoypadMotion.new()
	ghost_move_left_1.axis = JOY_AXIS_LEFT_X
	ghost_move_left_1.axis_value = -1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_MOVE_LEFT, [
		ghost_move_left_0,
		ghost_move_left_1,
	])


	var ghost_move_right_0 := InputEventKey.new()
	ghost_move_right_0.physical_keycode = KEY_D
	var ghost_move_right_1 := InputEventJoypadMotion.new()
	ghost_move_right_1.axis = JOY_AXIS_LEFT_X
	ghost_move_right_1.axis_value = +1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_MOVE_RIGHT, [
		ghost_move_right_0,
		ghost_move_right_1,
	])


	var ghost_move_down_0 := InputEventKey.new()
	ghost_move_down_0.physical_keycode = KEY_Q
	var ghost_move_down_1 := InputEventKey.new()
	ghost_move_down_1.physical_keycode = KEY_CTRL
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_MOVE_DOWN, [
		ghost_move_down_0,
		ghost_move_down_1,
	])


	var ghost_move_up_0 := InputEventKey.new()
	ghost_move_up_0.physical_keycode = KEY_E
	var ghost_move_up_1 := InputEventKey.new()
	ghost_move_up_1.physical_keycode = KEY_SPACE
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_MOVE_UP, [
		ghost_move_up_0,
		ghost_move_up_1,
	])


	var ghost_move_back_0 := InputEventKey.new()
	ghost_move_back_0.physical_keycode = KEY_S
	var ghost_move_back_1 := InputEventJoypadMotion.new()
	ghost_move_back_1.axis = JOY_AXIS_LEFT_Y
	ghost_move_back_1.axis_value = -1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_MOVE_BACK, [
		ghost_move_back_0,
		ghost_move_back_1,
	])


	var ghost_move_forward_0 := InputEventKey.new()
	ghost_move_forward_0.physical_keycode = KEY_W
	var ghost_move_forward_1 := InputEventJoypadMotion.new()
	ghost_move_forward_1.axis = JOY_AXIS_LEFT_Y
	ghost_move_forward_1.axis_value = +1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_MOVE_FORWARD, [
		ghost_move_forward_0,
		ghost_move_forward_1,
	])


	var ghost_camera_left_0 := InputEventKey.new()
	ghost_camera_left_0.physical_keycode = KEY_LEFT
	var ghost_camera_left_1 := InputEventJoypadMotion.new()
	ghost_camera_left_1.axis = JOY_AXIS_RIGHT_X
	ghost_camera_left_1.axis_value = -1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_CAMERA_LEFT, [
		ghost_camera_left_0,
		ghost_camera_left_1,
	])


	var ghost_camera_right_0 := InputEventKey.new()
	ghost_camera_right_0.physical_keycode = KEY_RIGHT
	var ghost_camera_right_1 := InputEventJoypadMotion.new()
	ghost_camera_right_1.axis = JOY_AXIS_RIGHT_X
	ghost_camera_right_1.axis_value = +1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_CAMERA_RIGHT, [
		ghost_camera_right_0,
		ghost_camera_right_1,
	])


	var ghost_camera_down_0 := InputEventKey.new()
	ghost_camera_down_0.physical_keycode = KEY_DOWN
	var ghost_camera_down_1 := InputEventJoypadMotion.new()
	ghost_camera_down_1.axis = JOY_AXIS_RIGHT_Y
	ghost_camera_down_1.axis_value = -1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_CAMERA_DOWN, [
		ghost_camera_down_0,
		ghost_camera_down_1,
	])


	var ghost_camera_up_0 := InputEventKey.new()
	ghost_camera_up_0.physical_keycode = KEY_UP
	var ghost_camera_up_1 := InputEventJoypadMotion.new()
	ghost_camera_up_1.axis = JOY_AXIS_RIGHT_Y
	ghost_camera_up_1.axis_value = +1.0
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_GHOST_CAMERA_UP, [
		ghost_camera_up_0,
		ghost_camera_up_1,
	])


	var debug_grid_toggle_0 := InputEventKey.new()
	debug_grid_toggle_0.physical_keycode = KEY_PERIOD
	Snotbane.add_default_input_binding(Snotbane.SETTING_INPUT_DEBUG_GRID_TOGGLE, [
		debug_grid_toggle_0,
	])

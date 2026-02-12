
@tool class_name MythPlugin_Ghost extends EditorPlugin

const AUTOLOAD_NAME := "myth_ghost_autoload"
const AUTOLOAD_PATH := "GhostAutoload.gd"

const INPUT_GHOST_TOGGLE := &"ghost_toggle"
const INPUT_GHOST_TELEPORT := &"ghost_teleport"
const INPUT_GHOST_SPRINT := &"ghost_sprint"
const INPUT_GHOST_MOVE_LEFT := &"ghost_move_left"
const INPUT_GHOST_MOVE_RIGHT := &"ghost_move_right"
const INPUT_GHOST_MOVE_DOWN := &"ghost_move_down"
const INPUT_GHOST_MOVE_UP := &"ghost_move_up"
const INPUT_GHOST_MOVE_BACK := &"ghost_move_back"
const INPUT_GHOST_MOVE_FORWARD := &"ghost_move_forward"
const INPUT_GHOST_CAMERA_LEFT := &"ghost_camera_left"
const INPUT_GHOST_CAMERA_RIGHT := &"ghost_camera_right"
const INPUT_GHOST_CAMERA_DOWN := &"ghost_camera_down"
const INPUT_GHOST_CAMERA_UP := &"ghost_camera_up"

const SETTING_INPUT_GHOST_TOGGLE := "input/" + INPUT_GHOST_TOGGLE
const SETTING_INPUT_GHOST_TELEPORT := "input/" + INPUT_GHOST_TELEPORT
const SETTING_INPUT_GHOST_SPRINT := "input/" + INPUT_GHOST_SPRINT
const SETTING_INPUT_GHOST_MOVE_LEFT := "input/" + INPUT_GHOST_MOVE_LEFT
const SETTING_INPUT_GHOST_MOVE_RIGHT := "input/" + INPUT_GHOST_MOVE_RIGHT
const SETTING_INPUT_GHOST_MOVE_DOWN := "input/" + INPUT_GHOST_MOVE_DOWN
const SETTING_INPUT_GHOST_MOVE_UP := "input/" + INPUT_GHOST_MOVE_UP
const SETTING_INPUT_GHOST_MOVE_BACK := "input/" + INPUT_GHOST_MOVE_BACK
const SETTING_INPUT_GHOST_MOVE_FORWARD := "input/" + INPUT_GHOST_MOVE_FORWARD
const SETTING_INPUT_GHOST_CAMERA_LEFT := "input/" + INPUT_GHOST_CAMERA_LEFT
const SETTING_INPUT_GHOST_CAMERA_RIGHT := "input/" + INPUT_GHOST_CAMERA_RIGHT
const SETTING_INPUT_GHOST_CAMERA_DOWN := "input/" + INPUT_GHOST_CAMERA_DOWN
const SETTING_INPUT_GHOST_CAMERA_UP := "input/" + INPUT_GHOST_CAMERA_UP


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	configure_input()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func configure_input() -> void:
	var ghost_teleport_0 := InputEventKey.new()
	ghost_teleport_0.physical_keycode = KEY_V
	ghost_teleport_0.shift_pressed = true
	var ghost_teleport_1 := InputEventKey.new()
	ghost_teleport_1.physical_keycode = KEY_ENTER
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_TELEPORT, [
		ghost_teleport_0,
		ghost_teleport_1,
	])


	var ghost_sprint_0 := InputEventKey.new()
	ghost_sprint_0.physical_keycode = KEY_SHIFT
	var ghost_sprint_1 := InputEventJoypadButton.new()
	ghost_sprint_1.button_index = JOY_BUTTON_LEFT_STICK
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_SPRINT, [
		ghost_sprint_0,
		ghost_sprint_1,
	])


	var ghost_move_left_0 := InputEventKey.new()
	ghost_move_left_0.physical_keycode = KEY_A
	var ghost_move_left_1 := InputEventJoypadMotion.new()
	ghost_move_left_1.axis = JOY_AXIS_LEFT_X
	ghost_move_left_1.axis_value = -1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_MOVE_LEFT, [
		ghost_move_left_0,
		ghost_move_left_1,
	])


	var ghost_move_right_0 := InputEventKey.new()
	ghost_move_right_0.physical_keycode = KEY_D
	var ghost_move_right_1 := InputEventJoypadMotion.new()
	ghost_move_right_1.axis = JOY_AXIS_LEFT_X
	ghost_move_right_1.axis_value = +1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_MOVE_RIGHT, [
		ghost_move_right_0,
		ghost_move_right_1,
	])


	var ghost_move_down_0 := InputEventKey.new()
	ghost_move_down_0.physical_keycode = KEY_Q
	var ghost_move_down_1 := InputEventKey.new()
	ghost_move_down_1.physical_keycode = KEY_CTRL
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_MOVE_DOWN, [
		ghost_move_down_0,
		ghost_move_down_1,
	])


	var ghost_move_up_0 := InputEventKey.new()
	ghost_move_up_0.physical_keycode = KEY_E
	var ghost_move_up_1 := InputEventKey.new()
	ghost_move_up_1.physical_keycode = KEY_SPACE
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_MOVE_UP, [
		ghost_move_up_0,
		ghost_move_up_1,
	])


	var ghost_move_back_0 := InputEventKey.new()
	ghost_move_back_0.physical_keycode = KEY_S
	var ghost_move_back_1 := InputEventJoypadMotion.new()
	ghost_move_back_1.axis = JOY_AXIS_LEFT_Y
	ghost_move_back_1.axis_value = -1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_MOVE_BACK, [
		ghost_move_back_0,
		ghost_move_back_1,
	])


	var ghost_move_forward_0 := InputEventKey.new()
	ghost_move_forward_0.physical_keycode = KEY_W
	var ghost_move_forward_1 := InputEventJoypadMotion.new()
	ghost_move_forward_1.axis = JOY_AXIS_LEFT_Y
	ghost_move_forward_1.axis_value = +1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_MOVE_FORWARD, [
		ghost_move_forward_0,
		ghost_move_forward_1,
	])


	var ghost_camera_left_0 := InputEventKey.new()
	ghost_camera_left_0.physical_keycode = KEY_LEFT
	var ghost_camera_left_1 := InputEventJoypadMotion.new()
	ghost_camera_left_1.axis = JOY_AXIS_RIGHT_X
	ghost_camera_left_1.axis_value = -1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_CAMERA_LEFT, [
		ghost_camera_left_0,
		ghost_camera_left_1,
	])


	var ghost_camera_right_0 := InputEventKey.new()
	ghost_camera_right_0.physical_keycode = KEY_RIGHT
	var ghost_camera_right_1 := InputEventJoypadMotion.new()
	ghost_camera_right_1.axis = JOY_AXIS_RIGHT_X
	ghost_camera_right_1.axis_value = +1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_CAMERA_RIGHT, [
		ghost_camera_right_0,
		ghost_camera_right_1,
	])


	var ghost_camera_down_0 := InputEventKey.new()
	ghost_camera_down_0.physical_keycode = KEY_DOWN
	var ghost_camera_down_1 := InputEventJoypadMotion.new()
	ghost_camera_down_1.axis = JOY_AXIS_RIGHT_Y
	ghost_camera_down_1.axis_value = -1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_CAMERA_DOWN, [
		ghost_camera_down_0,
		ghost_camera_down_1,
	])


	var ghost_camera_up_0 := InputEventKey.new()
	ghost_camera_up_0.physical_keycode = KEY_UP
	var ghost_camera_up_1 := InputEventJoypadMotion.new()
	ghost_camera_up_1.axis = JOY_AXIS_RIGHT_Y
	ghost_camera_up_1.axis_value = +1.0
	MythPlugin.add_default_input_binding(SETTING_INPUT_GHOST_CAMERA_UP, [
		ghost_camera_up_0,
		ghost_camera_up_1,
	])

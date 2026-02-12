
@tool class_name MythPlugin_Terminal extends EditorPlugin

const AUTOLOAD_NAME := "myth_terminal_autoload"
const AUTOLOAD_PATH := "TerminalAutoload.gd"

const INPUT_TERMINAL_TOGGLE := &"terminal_toggle"
const SETTING_INPUT_TERMINAL_TOGGLE := "input/" + INPUT_TERMINAL_TOGGLE


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	configure_input()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func configure_input() -> void:
	var cli_toggle_0 := InputEventKey.new()
	cli_toggle_0.physical_keycode = KEY_QUOTELEFT
	MythPlugin.add_default_input_binding(SETTING_INPUT_TERMINAL_TOGGLE, [
		cli_toggle_0
	])
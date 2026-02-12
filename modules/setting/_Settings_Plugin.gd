
@tool extends EditorPlugin

func _ready() -> void:
	touch_settings()
	configure_input()


func _enable_plugin() -> void:
	touch_settings()
	configure_input()


func touch_settings() -> void:
	if not ProjectSettings.has_setting(InputLocalization.PROJECT_SETTING_HINT[&"name"]):
		ProjectSettings.set_setting(InputLocalization.PROJECT_SETTING_HINT[&"name"], "uid://by4uei1ro2t8y")
		ProjectSettings.set_initial_value(InputLocalization.PROJECT_SETTING_HINT[&"name"], "uid://by4uei1ro2t8y")
		ProjectSettings.add_property_info(InputLocalization.PROJECT_SETTING_HINT)
		ProjectSettings.save()


func configure_input() -> void:
	var user_input_remove_0 := InputEventJoypadButton.new()
	user_input_remove_0.button_index = JOY_BUTTON_B
	var user_input_remove_1 := InputEventKey.new()
	user_input_remove_1.keycode = KEY_DELETE
	var user_input_remove_2 := InputEventKey.new()
	user_input_remove_2.keycode = KEY_BACKSPACE
	add_default_input_binding("input/user_input_remove", [
		user_input_remove_0,
		user_input_remove_1,
		user_input_remove_2,
	])


static func add_default_input_binding(binding_name: String, events: Array = [], deadzone := 0.2) -> void:
	if ProjectSettings.get_setting(binding_name) != null: return

	ProjectSettings.set_setting(binding_name, {
		"deadzone": deadzone,
		"events": events,
	})
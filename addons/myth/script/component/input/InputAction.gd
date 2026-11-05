## Handles a single input action which can be pressed and/or released.
@icon("res://addons/myth/script/component/input/InputAction.svg")
class_name InputAction
extends InputComponent

## Emits when the input was either pressed or released.
signal changed(new_pressed: bool)

## Emits when the input is pressed. Always alternates between [member pressed] and [member released].
signal pressed

func emit_pressed() -> void:
	changed.emit(true)
	pressed.emit()


## Emits when the input is released. Always alternates between [member pressed] and [member released].
signal released

func emit_released() -> void:
	changed.emit(false)
	released.emit()


## The name of the action in the project settings to listen for.
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action_name: StringName:
	set(value):
		action_name = value
		validate_actions()


## Returns true if the action is currently activated. (Note: In subclasses of [InputAction], such as [InputActionBuffered], this may not necessarily correlate exactly to whether or not the physical button is being pressed.)
var is_pressed: bool:
	set(value):
		if is_pressed == value: return
		is_pressed = value

		if is_pressed:
			emit_pressed()
		else:
			emit_released()


func _component_input(event: InputEvent) -> bool:
	if event.is_action(action_name):
		is_pressed = event.is_pressed()
		return true

	return false


func _validate_actions() -> bool:
	return validate_action_name(action_name)

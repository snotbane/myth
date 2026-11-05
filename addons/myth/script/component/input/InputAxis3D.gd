## Handles a 3D input action, combining multiple axis actions together.
@icon("res://addons/myth/script/component/input/InputAxis3D.svg")
class_name InputAxis3D
extends InputComponent

## Emits when a motion is desired via input.
signal desired_input(vector: Vector3)

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_left: StringName:
	set(value):
		input_left = value
		validate_actions()

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_right: StringName:
	set(value):
		input_right = value
		validate_actions()

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_down: StringName:
	set(value):
		input_down = value
		validate_actions()

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_up: StringName:
	set(value):
		input_up = value
		validate_actions()

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_forward: StringName:
	set(value):
		input_forward = value
		validate_actions()

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_back: StringName:
	set(value):
		input_back = value
		validate_actions()


func set_actions(
	left: StringName,
	right: StringName,
	down: StringName,
	up: StringName,
	forward: StringName,
	back: StringName,
) -> void:
	input_left = left
	input_right = right
	input_down = down
	input_up = up
	input_forward = forward
	input_back = back


func _validate_actions() -> bool:
	return (
		validate_action_name(input_left)
		and validate_action_name(input_right)
		and validate_action_name(input_down)
		and validate_action_name(input_up)
		and validate_action_name(input_forward)
		and validate_action_name(input_back)
	)


func _component_input(event: InputEvent) -> bool:
	if (
		event.is_action(input_left)
		or event.is_action(input_right)
		or event.is_action(input_down)
		or event.is_action(input_up)
		or event.is_action(input_forward)
		or event.is_action(input_back)
	):
		var vector := Vector3(
			Input.get_axis(
				input_left,
				input_right,
			),
			Input.get_axis(
				input_down,
				input_up,
			),
			Input.get_axis(
				input_forward,
				input_back,
			),
		)
		desired_input.emit(vector.limit_length())

		return true

	return false

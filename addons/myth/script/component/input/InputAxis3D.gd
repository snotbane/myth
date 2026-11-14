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

## If enabled, the final input vector emitted by [member desired_input] will be normalized to a length of 1.0 if it is longer than that, while still allowing for values shorter than 1.0.
@export
var constrained: bool = true


## Final scalar which is applied after everything. NOTE: This ignores [member constrained] and allows the input to desire values greater than 1.0.
@export_range(-1.0, 1.0, 0.001, "or_greater", "or_less")
var scalar: float = 1.0



@export_group("Auto Move", "auto_")

## If enabled, the axis will simulate moving in the [member auto_direction]. You will likely want to leave this unchecked, and have a separate [InputAction] connected to [member toggle_auto_enabled]. Then use [member cancel_auto_enabled] to manually disable (e.g. if the player gets hurt).
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only")
var auto_enabled: bool = false

## The direction to automatically move in.
@export
var auto_direction := Vector3.FORWARD:
	set(value):
		auto_direction = value.normalized()

## If enabled, [member cancel_auto_enabled] will be called if the user inputs in a direction opposite of [member auto_direction].
@export
var auto_reverse_cancel : bool = true


## Cancels auto movement.
func cancel_auto_enabled() -> void:
	auto_enabled = false


## Toggles auto movement on or off.
func toggle_auto_enabled() -> void:
	auto_enabled = not auto_enabled


func _process_auto(vector: Vector3) -> Vector3:
	if auto_enabled:
		if auto_reverse_cancel and vector.dot(auto_direction) < 0.0:
			cancel_auto_enabled()

		else:
			return vector.slide(auto_direction) + auto_direction

	return vector

@export_group("")


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
		vector = _process_auto(vector)
		if constrained:
			vector = vector.limit_length()

		desired_input.emit(vector * scalar)

		return true

	return false

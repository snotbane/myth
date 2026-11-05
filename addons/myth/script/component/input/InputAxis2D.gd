## Handles a 2D input action for joystick and/or mouse.
@icon("res://addons/myth/script/component/input/InputAxis2D.svg")
class_name InputAxis2D
extends InputComponent

## Emits when a motion is desired via input.
signal desired_input(vector: Vector2)

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
var input_up: StringName:
	set(value):
		input_up = value
		validate_actions()

@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var input_down: StringName:
	set(value):
		input_down = value
		validate_actions()

## If enabled, the final input vector emitted by [member desired_input] will be normalized to a length of 1.0 if it is longer than that, while still allowing for values shorter than 1.0.
@export
var constrained: bool = true

@export_group("Mouse", "mouse_")

## If enabled, the mouse motion (see [member InputEventMouseMotion.screen_relative]) will also be used to handle this input, in addition to the input actions.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var mouse_enabled: bool = false

## If enabled, the mouse input will also be constrained to a length of 1.0. If disabled, mouse input will be added to other inputs separately. Typically used in situations where the mouse controls the physical movement of something. (NOTE: this only has an effect if [member constrained] is also enabled.)
@export
var mouse_constrained: bool = false

## Higher values make [member desired_input] output higher values.
@export
var mouse_sensitivity: Vector2 = Vector2.ONE


var invert_mouse_x: bool = false:
	get: return mouse_sensitivity.x < 0.0
	set(value): mouse_sensitivity.x = absf(mouse_sensitivity.x) * (+1.0 if value else -1.0)

var invert_mouse_y: bool = false:
	get: return mouse_sensitivity.y < 0.0
	set(value): mouse_sensitivity.y = absf(mouse_sensitivity.y) * (+1.0 if value else -1.0)

var action_vector: Vector2

var mouse_vector: Vector2

var _input_vector_prev: Vector2

## The current input vector exerted by both the actions and the mouse.
var input_vector: Vector2

func set_actions(
	left: StringName,
	right: StringName,
	up: StringName,
	down: StringName,
) -> void:
	input_left = left
	input_right = right
	input_up = up
	input_down = down


func _process(delta: float) -> void:
	if mouse_vector:
		input_vector = (
			(mouse_vector).limit_length()
			if mouse_constrained
			else mouse_vector
		)
		mouse_vector = Vector2.ZERO

	elif action_vector:
		input_vector = (
			action_vector.limit_length()
			if constrained
			else action_vector
		)

	else:
		input_vector = Vector2.ZERO

	if input_vector == _input_vector_prev: return
	_input_vector_prev = input_vector

	desired_input.emit(input_vector)


func _validate_actions() -> bool:
	return (
		validate_action_name(input_left)
		and validate_action_name(input_right)
		and validate_action_name(input_up)
		and validate_action_name(input_down)
	)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or input_callback != 0:
		return

	if _mouse_input(event):
		pass
	elif actions_are_valid:
		component_input(event)


func _input(event: InputEvent) -> void:
	if not enabled or input_callback != 1:
		return

	if _mouse_input(event):
		pass
	elif actions_are_valid:
		component_input(event)


func _mouse_input(event: InputEvent) -> bool:
	if (
		mouse_enabled
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		and event is InputEventMouseMotion
	):
		mouse_vector += event.screen_relative * mouse_sensitivity
		if consume:
			get_viewport().set_input_as_handled()
		return true

	return false


func _component_input(event: InputEvent) -> bool:
	if (
		event.is_action(input_left)
		or event.is_action(input_right)
		or event.is_action(input_up)
		or event.is_action(input_down)
	):
		action_vector = Vector2(
			Input.get_axis(
				input_left,
				input_right
			),
			Input.get_axis(
				input_up,
				input_down
			)
		)

		return true

	return false

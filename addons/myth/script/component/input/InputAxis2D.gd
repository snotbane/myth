## Handles a 2D input action for joystick and/or mouse.
@icon("res://addons/myth/script/component/input/InputAxis2D.svg")
class_name InputAxis2D
extends InputComponent

## Emits when a motion is desired via input.
signal desired_input(vector: Vector2)


var action_vector: Vector2

## -X input action name.
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action_left: StringName:
	set(value):
		action_left = value
		validate_actions()

## +X input action name.
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action_right: StringName:
	set(value):
		action_right = value
		validate_actions()

## -Y input action name.
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action_up: StringName:
	set(value):
		action_up = value
		validate_actions()

## +Y input action name.
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action_down: StringName:
	set(value):
		action_down = value
		validate_actions()

## If enabled, the final input vector emitted by [member desired_input] will be normalized to a length of 1.0 if it is longer than that, while still allowing for values shorter than 1.0.
@export
var constrained: bool = true


## Final scalar which is applied after everything. NOTE: This ignores [member constrained] and allows the input to desire values greater than 1.0.
@export_range(-1.0, 1.0, 0.001, "or_greater", "or_less")
var scalar: float = 1.0


@export_group("Use Mouse", "mouse_")

var mouse_vector: Vector2

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


@export_group("Auto Move", "auto_")

## If enabled, the axis will simulate moving in the [member auto_direction]. You will likely want to leave this unchecked, and have a separate [InputAction] connected to [member toggle_auto_enabled]. Then use [member cancel_auto_enabled] to manually disable (e.g. if the player gets hurt).
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only")
var auto_enabled: bool = false

## The direction to automatically move in.
@export
var auto_direction := Vector2.UP:
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


func _process_auto(vector: Vector2) -> Vector2:
	if auto_enabled:
		if auto_reverse_cancel and vector.dot(auto_direction) < 0.0:
			cancel_auto_enabled()

		else:
			return vector.slide(auto_direction) + auto_direction

	return vector

@export_group("")


## The current input vector exerted by either the actions and the mouse (mouse takes priority).
var input_vector: Vector2
var _input_vector_prev: Vector2

func set_actions(
	left: StringName,
	right: StringName,
	up: StringName,
	down: StringName,
) -> void:
	action_left = left
	action_right = right
	action_up = up
	action_down = down


func _process(delta: float) -> void:
	if mouse_vector:
		mouse_vector = _process_auto(mouse_vector)

		input_vector = (
			(mouse_vector).limit_length()
			if mouse_constrained
			else mouse_vector
		)
		mouse_vector = Vector2.ZERO

	elif action_vector:
		action_vector = _process_auto(action_vector)

		input_vector = (
			action_vector.limit_length()
			if constrained
			else action_vector
		)

	else:
		input_vector = _process_auto(Vector2.ZERO)


	if input_vector == _input_vector_prev: return
	_input_vector_prev = input_vector

	desired_input.emit(input_vector * scalar)


func _validate_actions() -> bool:
	return (
		validate_action_name(action_left)
		and validate_action_name(action_right)
		and validate_action_name(action_up)
		and validate_action_name(action_down)
	)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or input_callback != 0:
		return

	if actions_are_valid:
		component_input(event)


func _input(event: InputEvent) -> void:
	if _mouse_input(event):
		return

	if not enabled or input_callback != 1:
		return

	if actions_are_valid:
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
		event.is_action(action_left)
		or event.is_action(action_right)
		or event.is_action(action_up)
		or event.is_action(action_down)
	):
		action_vector = Vector2(
			Input.get_axis(
				action_left,
				action_right
			),
			Input.get_axis(
				action_up,
				action_down
			)
		)

		return true

	return false

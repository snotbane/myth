## An input action which will be buffered. This means that a condition will be checked. If the condition is true at the time of input, or at any point during the specified time frame, the input will trigger as soon as the condition is met.
## For example, in a situation where a player wants to jump, but must be on the ground when they jump, this gives the player a grace period to input before touching the ground, and then jump as soon as it is possible to do so.
## NOTE: this is not affected by time dilation.
@icon("res://addons/myth/script/component/input/InputActionBuffered.svg")
class_name InputActionBuffered
extends InputAction

## Emits if the action was pressed, and its condition was not met, and then the action was released.
signal sequence_failed

## Determines which process method is used to check the input conditions.
@export_enum("Process", "Physics")
var process_callback: int = 0

## Returns true if the input is currently pressed. Unlike [member is_pressed], this will exactly correlate to the whether or not the physical button is being pressed.
var is_pressed_absolute: bool:
	set(value):
		if is_pressed_absolute == value: return
		is_pressed_absolute = value

		if is_pressed_absolute:
			press_try()
		else:
			release_try()


func _component_input(event: InputEvent) -> bool:
	if event.is_action(action_name):
		is_pressed_absolute = event.is_pressed()
		return true

	return false


func _process(delta: float) -> void:
	if process_callback != 0: return

	_buffer_update()


func _physics_process(delta: float) -> void:
	if process_callback != 1: return

	_buffer_update()


func _buffer_update() -> void:
	if is_pressed:
		if (
			release_enabled
			and	(
				(not is_pressed_absolute and _release_buffer_duration_usec == 0)
				or Time.get_ticks_usec() <= _release_buffer_stamp + _release_buffer_duration_usec
			)
			and release_condition_value
			):
				_release_buffer_stamp = INT64_MIN
				_check_sequence()
				is_pressed = false
				is_pressed = is_pressed_absolute

	else:
		if (
			press_enabled
			and	(
				(is_pressed_absolute and _press_buffer_duration_usec == 0)
				or Time.get_ticks_usec() <= _press_buffer_stamp + _press_buffer_duration_usec
			)
			and press_condition_value
			):
				_press_buffer_stamp = INT64_MIN
				is_pressed = true
				is_pressed = is_pressed_absolute


@export_group("Press", "press_")

## Enables input buffering for pressing the action.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var press_enabled: bool = true

## This condition is checked when pressing. If not met, keep trying to press until [member press_buffer_duration] runs out.
@export
var press_condition: NodePath


@export
var press_condition_invert: bool


var press_condition_value: Variant:
	get: return Myth.get_node_path_value(self, press_condition) != press_condition_invert

var _press_buffer_stamp: int = INT64_MIN
var _press_buffer_duration_usec: int = 0

## The length of time for which the condition will be checked each frame. 0.0 means we will check continuously, as long as the button is pressed (e.g. interacting the moment it becomes available, a la DRG).
@export
var press_buffer_duration: float = 0.0:
	get: return float(_press_buffer_duration_usec) * 0.00_000_1
	set(value): _press_buffer_duration_usec = floori(value * 1_000_000)


func press_try() -> void:
	if press_enabled:
		if press_condition_value:
			is_pressed = true
		else:
			_press_buffer_stamp = Time.get_ticks_usec()
	else:
		is_pressed = true

@export_group("Release", "release_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var release_enabled: bool = false

## This condition is checked when releasing. If not met, keep trying to press until [member release_buffer_duration] runs out.
@export
var release_condition: NodePath

@export
var release_condition_invert: bool


var release_condition_value: Variant:
	get: return Myth.get_node_path_value(self, release_condition) != release_condition_invert

var _release_buffer_stamp: int = INT64_MIN
var _release_buffer_duration_usec: int = 0

## The length of time for which the condition will be checked each frame. 0.0 means we will check continuously, as long as the button is not pressed (e.g. uncrouching when there is a ceiling above).
@export
var release_buffer_duration: float = 0.0:
	get: return float(_release_buffer_duration_usec) * 0.00_000_1
	set(value): _release_buffer_duration_usec = floori(value * 1_000_000)


func release_try() -> void:
	if release_enabled:
		if release_condition_value:
			_check_sequence()
			is_pressed = false
		else:
			_release_buffer_stamp = Time.get_ticks_usec()
	else:
		_check_sequence()
		is_pressed = false


func _check_sequence() -> void:
	if not is_pressed and not is_pressed_absolute:
		sequence_failed.emit()

## An input action which will be buffered. This means that a condition will be checked. If the condition is true at the time of input, or at any point during the specified time frame, the input will trigger as soon as the condition is met.
## For example, in a situation where a player wants to jump, but must be on the ground when they jump, this gives the player a grace period to input before touching the ground, and then jump as soon as it is possible to do so.
## NOTE: this is not affected by time dilation.
@icon("res://addons/myth/script/component/input/InputActionBuffered.svg")
class_name InputActionBuffered
extends InputAction

enum Continuity {
	## No continuity. Only check the condition for the specified time frame after the initial press (or release).
	NONE,

	## Check the condition as long as the button is pressed (or released), and for the specified time frame after the release (or press), up to a maximum of one time. Ensures a single input action correlates to a single game action.
	SINGLE,

	## Check the condition as long as the button is pressed (or released), and for the specified time frame after the release (or press), with no limits on how many times the game action can trigger.
	PERPETUAL,
}

func _init() -> void:
	super._init()

	press_buffer_timer = Timer.new()
	press_buffer_timer.autostart = false
	press_buffer_timer.one_shot = true
	add_child(press_buffer_timer, false, INTERNAL_MODE_FRONT)

	release_buffer_timer = press_buffer_timer.duplicate()
	add_child(release_buffer_timer, false, INTERNAL_MODE_FRONT)



## Emits if the action was pressed, and its condition was not met, and then the action was released.
signal sequence_failed

## Returns true if the input is currently pressed. Unlike [member is_pressed], this will exactly correlate to the whether or not the physical button is being pressed.
var is_pressed_absolute: bool:
	set(value):
		if is_pressed_absolute == value: return
		is_pressed_absolute = value

		if is_pressed_absolute:
			press_try()
		else:
			release_try()


func _get_is_pressed_desired() -> bool:
	return is_pressed_absolute


func _set_is_pressed_desired(value: bool) -> void:
	is_pressed_absolute = value


func _process(delta: float) -> void:
	if press_valid:
		if (press_buffer_timer.is_stopped() and not is_pressed_desired) or not press_condition_value:
			return

		press_buffer_timer.stop()

		if press_continuity == Continuity.PERPETUAL:
			is_pressed = false

		is_pressed = true
		is_pressed = is_pressed_desired

	if release_valid:
		if (release_buffer_timer.is_stopped() and is_pressed_desired) or not release_condition_value:
			return

		release_buffer_timer.stop()

		if release_continuity == Continuity.PERPETUAL:
			is_pressed = true

		_check_sequence()
		is_pressed = false
		is_pressed = is_pressed_desired


@export_group("Press", "press_")

var press_buffer_timer: Timer


## Enables input buffering for pressing the action.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var press_enabled: bool = true


## This condition is checked when pressing. If not met, keep trying to press until [member press_buffer_duration] runs out.
@export
var press_condition: NodePath


var press_valid: bool:
	get: return press_enabled and not press_condition.is_empty()


@export
var press_condition_invert: bool

## Determines if the condition is checked while holding press.
@export
var press_continuity := Continuity.NONE

var press_condition_value: Variant:
	get: return Myth.get_node_path_value(self, press_condition) != press_condition_invert

## The length of time for which the condition will be checked each frame. 0.0 means we will check continuously, as long as the button is pressed (e.g. interacting the moment it becomes available, a la DRG).
@export_range(0.0, 2.0, 0.01)
var press_buffer_duration: float = 0.0:
	set(value):
		press_buffer_duration = value

		if press_buffer_duration > 0.05:
			press_buffer_timer.wait_time = press_buffer_duration


func press_try() -> void:
	if release_valid and release_buffer_duration and release_continuity:
		release_buffer_timer.start()

	if press_valid:
		if press_condition_value:
			is_pressed = true
		elif not press_continuity:
			press_buffer_timer.start()
	else:
		is_pressed = true


@export_group("Release", "release_")

var release_buffer_timer: Timer

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var release_enabled: bool = false

## This condition is checked when releasing. If not met, keep trying to press until [member release_buffer_duration] runs out.
@export
var release_condition: NodePath

var release_valid: bool:
	get: return release_enabled and not release_condition.is_empty()

@export
var release_condition_invert: bool

var release_condition_value: Variant:
	get: return Myth.get_node_path_value(self, release_condition) != release_condition_invert


## Determines if the condition is checked while holding press.
@export
var release_continuity := Continuity.NONE


@export
var release_buffer_duration: float = 0.0:
	set(value):
		release_buffer_duration = value

		if release_buffer_duration > 0.05:
			release_buffer_timer.wait_time = release_buffer_duration


func release_try() -> void:
	if press_enabled and press_buffer_duration and press_continuity:
		press_buffer_timer.start()

	if release_valid:
		if release_condition_value:
			_check_sequence()
			is_pressed = false
		else:
			release_buffer_timer.start()
	else:
		_check_sequence()
		is_pressed = false


func _check_sequence() -> void:
	if not is_pressed and not is_pressed_desired:
		sequence_failed.emit()

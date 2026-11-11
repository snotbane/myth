## Handles a single input action which can be pressed and/or released.
@icon("res://addons/myth/script/component/input/InputAction.svg")
class_name InputAction
extends InputComponent

enum Actuation {
	## Only triggers press, then immediately releases on the same frame. NOTE: This will disable dynamic Continuity settings, as well as the [member changed] and [member released] signals.
	INSTANT,
	## Press and release like normal.
	HOLD,
	## Press the input once to actuate, then press again to release actuation.
	TOGGLE,
	## Press the input and release again within a time frame to behave like [Actuation.TOGGLE]. If held for longer, behave like [Actuation.HOLD].
	AUTO
}

enum {
	RELEASE_ON_PRESS,
	RELEASE_ON_RELEASE,
}

enum Continuity {
	## No continuity. Only check the condition for the specified time frame after the initial press (or release).
	NONE,

	## Check the condition as long as the button is pressed (or released), and for the specified time frame after the release (or press), up to a maximum of one time. Ensures a single input action correlates to a single game action.
	SINGLE,

	## Check the condition as long as the button is pressed (or released), and for the specified time frame after the release (or press), with no limits on how many times the game action can trigger.
	PERPETUAL,
}

## Emits if the action was pressed, and its condition was not met, and then the action was released.
signal sequence_failed


func _init() -> void:
	toggle_auto_timer = Timer.new()
	toggle_auto_timer.name = &"toggle_auto_timer"
	toggle_auto_timer.autostart = false
	toggle_auto_timer.one_shot = true
	toggle_auto_timer.wait_time = 0.25
	add_child(toggle_auto_timer, false, INTERNAL_MODE_FRONT)

	press_buffer_timer = toggle_auto_timer.duplicate()
	press_buffer_timer.name = &"press_buffer_timer"
	add_child(press_buffer_timer, false, INTERNAL_MODE_FRONT)

	release_buffer_timer = toggle_auto_timer.duplicate()
	release_buffer_timer.name = &"release_buffer_timer"
	add_child(release_buffer_timer, false, INTERNAL_MODE_FRONT)


func _ready() -> void:
	match actuate_mode:
		Actuation.TOGGLE, \
		Actuation.AUTO:
			is_pressed_desired = toggle_is_pressed_on_ready
			is_pressed = toggle_is_pressed_on_ready
			_actuate_sequence = 2 if toggle_is_pressed_on_ready else 0

	super._ready()


func _process(delta: float) -> void:
	if press_enabled:

		if (press_continuity and is_pressed_desired) or not press_buffer_timer.is_stopped():
			if not press_condition_value:
				return

			# if (press_buffer_timer.is_stopped() and not is_pressed_desired and  press_continuity)) or not press_condition_value:
			# 	return

			press_buffer_timer.stop()

			if press_continuity == Continuity.PERPETUAL:
				is_pressed = false

			is_pressed = true
			is_pressed = is_pressed_desired

	if release_enabled:
		if (release_buffer_timer.is_stopped() and is_pressed_desired) or not release_condition_value:
			return

		release_buffer_timer.stop()

		if release_continuity == Continuity.PERPETUAL:
			is_pressed = true

		_check_sequence()
		is_pressed = false
		is_pressed = is_pressed_desired


func _validate_actions() -> bool:
	return validate_action_name(action)


func _component_input(event: InputEvent) -> bool:
	if event.is_action(action) and not event.is_echo():
		_actuate_method.call(event)

		return true

	return false


var _actuate_sequence: int = 0


func _actuate_instant(event: InputEvent) -> void:
	if event.is_pressed():
		is_pressed_desired = true
		is_pressed_desired = false


func _actuate_hold(event: InputEvent) -> void:
	is_pressed_desired = event.is_pressed()


func _actuate_toggle(event: InputEvent) -> void:
	match _actuate_sequence:
		0:
			if event.is_pressed():
				is_pressed_desired = true
				_actuate_sequence = 1
		1:
			if event.is_released():
				_actuate_sequence = 2
		2:
			if event.is_pressed():
				if not toggle_release_on_release:
					is_pressed_desired = false
					_actuate_sequence = 0
				else:
					_actuate_sequence = 3
		3:
			if event.is_released():
				is_pressed_desired = false
				_actuate_sequence = 0


func _actuate_auto(event: InputEvent) -> void:
	match _actuate_sequence:
		0:
			if event.is_pressed():
				is_pressed_desired = true
				toggle_auto_timer.start()
				_actuate_sequence = 1
		1:
			if event.is_released():
				if toggle_auto_timer.is_stopped():
					is_pressed_desired = false
					_actuate_sequence = 0
				else:
					_actuate_sequence = 2
		2:
			if event.is_pressed():
				if not toggle_release_on_release:
					is_pressed_desired = false
					_actuate_sequence = 0
				else:
					_actuate_sequence = 3
		3:
			if event.is_released():
				is_pressed_desired = false
				_actuate_sequence = 0



## Returns true if the input is currently pressed. Unlike [member is_pressed], this will exactly correlate to the whether or not the physical button is being pressed.
var is_pressed_desired: bool:
	set(value):
		if is_pressed_desired == value: return
		is_pressed_desired = value

		if is_pressed_desired:
			press_try()
		else:
			release_try()


## Returns true if the game action is currently actuated. This does NOT necessarily correlate directly to if the input button is pressed.
var is_pressed: bool:
	set(value):
		if is_pressed == value: return
		is_pressed = value

		if is_pressed:
			emit_pressed()
		else:
			emit_released()


## Emits when the action was either pressed or released.
signal changed(new_pressed: bool)


## The name of the action in the project settings to listen for.
@export_custom(PROPERTY_HINT_INPUT_NAME, "")
var action: StringName:
	set(value):
		action = value
		validate_actions()


var _actuate_method: Callable = _actuate_hold
## Determines how the input is actuated. Hold and Toggle are self-explanatory; Auto is able to dynamically switch between both.
@export
var actuate_mode := Actuation.HOLD:
	get:
		match _actuate_method:
			_actuate_hold: return Actuation.HOLD
			_actuate_toggle: return Actuation.TOGGLE
			_actuate_auto: return Actuation.AUTO
			_: return Actuation.INSTANT
	set(value):
		match value:
			Actuation.INSTANT: _actuate_method = _actuate_instant
			Actuation.HOLD: _actuate_method = _actuate_hold
			Actuation.TOGGLE: _actuate_method = _actuate_toggle
			Actuation.AUTO: _actuate_method = _actuate_auto


@export_group("Toggle", "toggle_")

var toggle_auto_timer: Timer

## If enabled, the input will start actuated on ready.
@export
var toggle_is_pressed_on_ready: bool


## If enabled, releasing the toggle will occur when the input is released (for the second time).
@export
var toggle_release_on_release: bool = false


## Only used if [member actuate_mode] is set to Auto. If the player presses and releases in under this amount of time, it will count as a toggle.
@export_range(0.05, 2.0, 0.01)
var toggle_auto_delay: float = 0.25:
	get: return toggle_auto_timer.wait_time
	set(value): toggle_auto_timer.wait_time = value


@export_group("Dynamic Press", "press_")

## Emits when the input is pressed. Always alternates between [member pressed] and [member released].
signal pressed


var press_buffer_timer: Timer


## Enables conditions, buffering, and continuity for the press action. If disabled, the press action will always succeed as long as the input was previously released.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var press_enabled: bool = false


## This condition is checked when pressing. If not met, keep trying to press until [member press_buffer_duration] runs out.
@export
var press_condition: NodePath


@export
var press_condition_invert: bool

## Determines if the condition is checked while holding press.
@export
var press_continuity := Continuity.NONE

var press_condition_value: Variant:
	get: return press_condition.is_empty() or Myth.get_node_path_value(self, press_condition) != press_condition_invert

## The length of time for which the condition will be checked each frame. 0.0 means we will check continuously, as long as the button is pressed (e.g. interacting the moment it becomes available, a la DRG).
@export_range(0.0, 2.0, 0.01)
var press_buffer_duration: float = 0.0:
	set(value):
		press_buffer_duration = value
		press_buffer_timer.wait_time = maxf(press_buffer_duration, 0.05)


func press_try() -> void:
	if release_enabled and release_buffer_duration and release_continuity:
		release_buffer_timer.start()

	if press_enabled:
		if press_condition_value:
			is_pressed = true
		elif not press_continuity and press_buffer_duration:
			press_buffer_timer.start()
	else:
		is_pressed = true

func emit_pressed() -> void:
	if actuate_mode != Actuation.INSTANT:
		changed.emit(true)
	pressed.emit()


@export_group("Dynamic Release", "release_")

var release_buffer_timer: Timer


## Enables conditions, buffering, and continuity for the release action. If disabled, the release action will always succeed as long as the input was previously pressed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var release_enabled: bool = false

## This condition is checked when releasing. If not met, keep trying to press until [member release_buffer_duration] runs out.
@export
var release_condition: NodePath

@export
var release_condition_invert: bool

var release_condition_value: Variant:
	get: return release_condition.is_empty() or Myth.get_node_path_value(self, release_condition) != release_condition_invert


## Determines if the condition is checked while holding press.
@export
var release_continuity := Continuity.NONE


@export
var release_buffer_duration: float = 0.0:
	set(value):
		release_buffer_duration = value
		release_buffer_timer.wait_time = maxf(release_buffer_duration, 0.05)



func release_try() -> void:
	if press_enabled and press_buffer_duration and press_continuity:
		press_buffer_timer.start()

	if release_enabled:
		if release_condition_value:
			_check_sequence()
			is_pressed = false
		elif not release_continuity and release_buffer_duration:
			release_buffer_timer.start()
	else:
		_check_sequence()
		is_pressed = false


func _check_sequence() -> void:
	if not is_pressed and not is_pressed_desired:
		sequence_failed.emit()


## Emits when the input is released. Always alternates between [member pressed] and [member released].
signal released

func emit_released() -> void:
	if actuate_mode != Actuation.INSTANT:
		changed.emit(false)
		released.emit()

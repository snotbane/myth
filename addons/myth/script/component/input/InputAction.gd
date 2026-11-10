## Handles a single input action which can be pressed and/or released.
@icon("res://addons/myth/script/component/input/InputAction.svg")
class_name InputAction
extends InputComponent

enum {
	INVALID = -1,
	HOLD,
	TOGGLE,
	AUTO
}

enum {
	RELEASE_ON_PRESS,
	RELEASE_ON_RELEASE,
}

func _init() -> void:
	toggle_auto_timer = Timer.new()
	toggle_auto_timer.autostart = false
	toggle_auto_timer.one_shot = true
	toggle_auto_timer.wait_time = 0.5
	add_child(toggle_auto_timer, false, INTERNAL_MODE_FRONT)


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
var action: StringName:
	set(value):
		action = value
		validate_actions()


var _actuate_method: Callable = _actuate_hold
## Determines how the input is actuated. Hold and Toggle are self-explanatory; Auto is able to dynamically switch between both.
@export_enum("Hold", "Toggle", "Auto")
var actuate_mode: int = HOLD:
	get:
		match _actuate_method:
			_actuate_hold: return HOLD
			_actuate_toggle: return TOGGLE
			_actuate_auto: return AUTO

		return INVALID
	set(value):
		match value:
			HOLD: _actuate_method = _actuate_hold
			TOGGLE: _actuate_method = _actuate_toggle
			AUTO: _actuate_method = _actuate_auto


## If using [member actuate_mode] is [TOGGLE] or [AUTO], this will determine when the action will be released.
@export_enum("On Press", "On Release")
var toggle_release_mode: int = RELEASE_ON_PRESS


## Only used if [member actuate_mode] is set to Auto. If the player presses and releases in under this amount of time, it will count as a toggle.
@export_range(0.05, 2.0, 0.01)
var toggle_auto_delay: float = 0.5:
	get: return toggle_auto_timer.wait_time
	set(value): toggle_auto_timer.wait_time = 0.5


var toggle_auto_timer: Timer

var _actuate_sequence: int = 0

## Returns true if the action is currently actuated. This does NOT necessarily correlate directly to if the input button is pressed, e.g. see [member actuate_mode].
var is_pressed: bool:
	set(value):
		if is_pressed == value: return
		is_pressed = value

		if is_pressed:
			emit_pressed()
		else:
			emit_released()


var is_pressed_desired: bool:
	get: return _get_is_pressed_desired()
	set(value): _set_is_pressed_desired(value)

func _get_is_pressed_desired() -> bool:
	return is_pressed


func _set_is_pressed_desired(value: bool) -> void:
	is_pressed = value


func _component_input(event: InputEvent) -> bool:
	if event.is_action(action):
		_actuate_method.call(event)

		return true

	return false


func _validate_actions() -> bool:
	return validate_action_name(action)


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
				if toggle_release_mode == RELEASE_ON_PRESS:
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
				if toggle_release_mode == RELEASE_ON_PRESS:
					is_pressed_desired = false
					_actuate_sequence = 0
				else:
					_actuate_sequence = 3
		3:
			if event.is_released():
				is_pressed_desired = false
				_actuate_sequence = 0

## Simple stopwatch keeps track of the amount of time that has passed since it has started. Use [member start_stopwatch] and [member stop] to make it go! Operates using microseconds ([member Time.get_ticks_usec()]) and can be used for very short time amounts.
@tool
class_name Clock
extends RefCounted

enum {
	STOPPED,
	PLAYING_WATCH,
	PLAYING_TIMER,
}


const SECONDS_IN_MINUTE := 60
const MINUTES_IN_HOUR := 60
const HOURS_IN_DAY := 24
const SECONDS_IN_HOUR := SECONDS_IN_MINUTE * MINUTES_IN_HOUR
const SECONDS_IN_DAY := SECONDS_IN_HOUR * HOURS_IN_DAY


static var NOW_USEC: int:
	get: return Time.get_ticks_usec()


## Creates a string based on a [param time_seconds] duration. [param minimum_elements] and [param maximum_elements] determines how many denominations are shown. [param seconds_format] is a format string to control the seconds display, which also controls displaying milliseconds.
static func duration_string(time_seconds: float, seconds_format: String = "%02d", minimum_elements: int = 2, maximum_elements: int = 4) -> String:
	assert(minimum_elements <= maximum_elements, "duration_string() minimum_elements must be less than maximum_elements.")
	var result: String

	if maximum_elements == 1:
		result = seconds_format % time_seconds
	elif minimum_elements >= 1:
		result = seconds_format % fmod(time_seconds, SECONDS_IN_MINUTE)

	if maximum_elements == 2:
		result = ("%02d:" % floori(time_seconds / SECONDS_IN_MINUTE)) + result
		return result
	elif minimum_elements >= 2 or time_seconds > SECONDS_IN_MINUTE:
		result = ("%02d:" % (floori(time_seconds / SECONDS_IN_MINUTE) % MINUTES_IN_HOUR)) + result

	if maximum_elements == 3:
		result = ("%02d:" % floori(time_seconds / SECONDS_IN_HOUR)) + result
		return result
	elif minimum_elements >= 3 or time_seconds > SECONDS_IN_HOUR:
		result = ("%02d:" % (floori(time_seconds / SECONDS_IN_HOUR) % HOURS_IN_DAY)) + result

	if maximum_elements == 4:
		result = ("%02d:" % (floori(time_seconds / SECONDS_IN_DAY))) + result
		return result
	if minimum_elements >= 4 or time_seconds > SECONDS_IN_DAY:
		result = ("%02d:" % (floori(time_seconds / SECONDS_IN_DAY))) + result

	return result


## Emitted after the set duration passes, after [member start_timer()] is called. This signal can ONLY emit when calling [member poll_timer()], so be sure to do that as often as needed (usually every frame or physics frame). This can be triggered multiple times if [member timer_repeat] is true, and if the timer duration since the last poll has overflowed.
signal timeout


var _play_state: int

var _timer_ticks: int

var _when_started_ticks: int

var _when_stopped_ticks: int

var timer_repeat: bool = false


var playing: bool:
	get: return _play_state != STOPPED

var time_elapsed_ticks: int:
	get: return (NOW_USEC if _play_state > STOPPED else _when_stopped_ticks) - _when_started_ticks

var time_remaining_ticks: int:
	get: return _timer_ticks - time_elapsed_ticks

var time_elapsed_seconds: float:
	get: return float(time_elapsed_ticks) * 0.00_000_1

var time_remaining_seconds: float:
	get: return float(time_remaining_ticks) * 0.00_000_1


func _init() -> void:
	_when_started_ticks = NOW_USEC
	_when_stopped_ticks = NOW_USEC


func start_stopwatch() -> void:
	_play_state = PLAYING_WATCH
	_when_started_ticks = NOW_USEC


func start_timer(time_seconds: float, repeat: bool = timer_repeat) -> void:
	timer_repeat = repeat
	_timer_ticks = floori(time_seconds * 1_000_000)
	_play_state = PLAYING_TIMER
	_when_started_ticks = NOW_USEC


## Stops the clock, regardless of its current action.
func stop() -> void:
	_play_state = STOPPED
	_when_stopped_ticks = NOW_USEC


## Call this function during [member Node._process()] or [member Node._physics_process()]. This is the only way to trigger [member timeout].
func poll_timer() -> void:
	if _play_state != PLAYING_TIMER or _timer_ticks == -1: return

	var ticks := time_elapsed_ticks
	while ticks >= _timer_ticks:
		timeout.emit()

		if timer_repeat:
			_when_started_ticks += _timer_ticks
			ticks -= _timer_ticks

		else:
			stop()
			break


## Gets the [member time_elapsed_seconds] as a formatted time string.
func get_time_elapsed_string(seconds_format: String = "%02d", minimum_elements: int = 2, maximum_elements: int = 4) -> String:
	return duration_string(time_elapsed_seconds, seconds_format, minimum_elements, maximum_elements)


## Gets the [member time_remaining_seconds] as a formatted time string.
func get_time_remaining_string(seconds_format: String = "%02d", minimum_elements: int = 2, maximum_elements: int = 4) -> String:
	return duration_string(time_remaining_seconds, seconds_format, minimum_elements, maximum_elements)

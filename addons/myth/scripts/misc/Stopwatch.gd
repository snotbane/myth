## Simple stopwatch keeps track of the amount of time that has passed since it has started. Use [member start] and [member stop] to make it work!
@tool
class_name Stopwatch
extends RefCounted

static var NOW: int:
	get: return Time.get_ticks_msec()


static func duration_string(time_seconds: float, minimum_elements: int = 2, seconds_format: String = "%02d") -> String:
	var result: String

	if minimum_elements >= 1:
		result = seconds_format % fmod(time_seconds, 60)

	if minimum_elements >= 2 or time_seconds > 60:
		result = ("%02d:" % (floori(time_seconds / 60) % 60)) + result

	if minimum_elements >= 3 or time_seconds > 3600:
		result = ("%02d:" % (floori(time_seconds / 3600) % 24)) + result

	if minimum_elements >= 4 or time_seconds > 86400:
		result = ("%02d:" % (floori(time_seconds / 86400))) + result

	return result


var _playing: bool

var when_started_ticks: int

var when_stopped_ticks: int


var time_elapsed_ticks: int:
	get: return (NOW if _playing else when_stopped_ticks) - when_started_ticks

var time_elapsed_seconds: float:
	get: return float(time_elapsed_ticks) * 0.00_1


func _init() -> void:
	when_started_ticks = NOW
	when_stopped_ticks = NOW


func start() -> void:
	_playing = true
	when_started_ticks = NOW


func stop() -> void:
	_playing = false
	when_stopped_ticks = NOW


func get_time_elapsed_string(minimum_elements: int = 2, seconds_format: String = "%02d") -> String:
	return duration_string(time_elapsed_seconds)

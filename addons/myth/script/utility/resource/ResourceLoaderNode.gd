## Allows you to load a [Resource] asynchronously.
@icon("res://addons/myth/script/utility/resource/ResourceLoaderNode.svg")
class_name ResourceLoaderNode
extends Node

signal load_suceeded(resource: Resource)
signal load_failed
signal load_canceled

## The path to load.
@export_file
var resource_path: String

var load_state: int = ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE
var load_progress: float = 0.0
var resource: Resource

var is_loading : bool:
	get: return load_state == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS
	set(value):
		load_state = (
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS
			if value
			else ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE
		)

func _process(delta: float) -> void:
	if not is_loading:
		return

	var progress := []
	load_state = ResourceLoader.load_threaded_get_status(resource_path, progress)
	load_progress = progress[0]

	match load_state:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			resource = ResourceLoader.load_threaded_get(resource_path)
			load_suceeded.emit(resource)

		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			load_failed.emit()


func load_blocked(path: String = resource_path) -> void:
	resource_path = path
	resource = ResourceLoader.load(resource_path)

## Sets [member resource_path] and loads it. This function is awaitable and will finish once loading is complete, or fails. [member resource] will be set to null until successfully loaded.
func load_threaded(path: String = resource_path):
	resource = null
	resource_path = path

	ResourceLoader.load_threaded_request(resource_path)
	is_loading = true

	return await Async.which([load_suceeded, load_failed, load_canceled])


## Stops loading if started.
func cancel() -> void:
	if is_loading:
		is_loading = false
		load_canceled.emit()

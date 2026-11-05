## Handles instantiation of any [Node]s which are loaded as placeholder.
@icon("res://addons/myth/script/component/misc/PlaceholderSpawner.svg")
class_name PlaceholderSpawner
extends Component


signal instantiated(node: Node)

@export
var order := AudioStreamRandomizer.PlaybackMode.PLAYBACK_RANDOM_NO_REPEATS:
	set(value):
		order = value
		if placeholders_idx >= placeholders.size(): placeholders_idx = 0

@export
var replace: bool = false


var placeholders: Array[InstancePlaceholder]:
	set(value):
		placeholders = value
		if placeholders_idx >= placeholders.size(): placeholders_idx = 0

var placeholders_idx: int = 0

var placeholder_most_recently_used: InstancePlaceholder


func _ready() -> void:
	for child in parent.get_children():
		if child is not InstancePlaceholder: continue
		placeholders.push_back(child)


func instantiate() -> Node:
	if not enabled: return

	match placeholders.size():
		0:
			printerr("PlaceholderSpawner '%s' does not have any sibling scenes to instantiate." % self)
			return null

		1: return _instantiate_specific(placeholders[0])

	var placeholder: InstancePlaceholder
	match order:
		AudioStreamRandomizer.PlaybackMode.PLAYBACK_RANDOM_NO_REPEATS:
			var idx := randi() % placeholders.size()
			while placeholders[idx] == placeholder_most_recently_used:
				idx = randi() % placeholders.size()

			placeholder = placeholders[idx]

		AudioStreamRandomizer.PlaybackMode.PLAYBACK_RANDOM:
			placeholder = placeholders[randi() % placeholders.size()]

		AudioStreamRandomizer.PlaybackMode.PLAYBACK_SEQUENTIAL:
			placeholders_idx += 1
			if placeholders_idx >= placeholders.size(): placeholders_idx = 0
			placeholder = placeholders[placeholders_idx]

	return _instantiate_specific(placeholder)


func _instantiate_specific(placeholder: InstancePlaceholder) -> Node:
	placeholder_most_recently_used = placeholder

	if replace:
		placeholders.erase(placeholder)
		placeholders.erase(placeholder)

	var result: Node = placeholder.create_instance(replace)
	instantiated.emit(result)

	return result

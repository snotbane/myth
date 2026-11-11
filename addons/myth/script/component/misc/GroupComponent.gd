## A [Component] that can enable and disable all of its members.
@icon("res://addons/myth/script/component/misc/GroupComponent.svg")
class_name GroupComponent
extends Component

@export
var members: Array[Component]


func _init() -> void:
	enabled_changed.emit(_enabled_changed)


func _enabled_changed() -> void:
	for member in members:
		member.enabled = enabled

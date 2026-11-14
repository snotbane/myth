## Allows you to explicitly define [InputEvent]s that will trigger this action.
## @experimental: This class is intended for testing/debug purposes only. In a production environment, best practice is to use [InputAction] with a standard [ProjectSettings] input setting.
class_name InputActionExplicit
extends InputAction

@export
var explicit_events: Array[InputEvent] = []:
	set(value):
		explicit_events = value
		validate_actions()

@export
var exact_match: bool = true


func _validate_actions() -> bool:
	return true


func _component_input(event: InputEvent) -> bool:
	if event.is_echo():
		return false

	for e in explicit_events:
		if event.is_match(e, exact_match):
			_actuate_method.call(event)
			return true

	return false

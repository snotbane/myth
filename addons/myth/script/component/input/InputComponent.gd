## Base class for a node that handles one or more input events and sends signals when they change.
@abstract
@icon("res://addons/myth/script/component/input/InputComponent.svg")
class_name InputComponent
extends Component

static func validate_action_name(action: StringName) -> bool:
	return ProjectSettings.get_setting("input/" + action) != null

## Determines which input method is used to process this event.
@export_enum("Unhandled Input", "Any Input")
var input_callback: int = 0


## If enabled, this will handle viewport input after it is triggered.
@export
var consume: bool = true


var actions_are_valid: bool
func validate_actions() -> void:
	actions_are_valid = _validate_actions()
## Returns true if the actions are valid. When actions are set, this is called. If it returns false, the component is automatically disabled.
@abstract
func _validate_actions() -> bool


func component_input(event) -> void:
	if consume:
		if _component_input(event):
			get_viewport().set_input_as_handled()

	else:
		_component_input(event)

## Override this method to handle an input. Return true if the input was handled.
@abstract
func _component_input(event: InputEvent) -> bool


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not actions_are_valid or input_callback != 0:
		return

	component_input(event)


func _input(event: InputEvent) -> void:
	if not enabled or not actions_are_valid or input_callback != 1:
		return

	component_input(event)

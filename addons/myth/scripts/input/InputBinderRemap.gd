## Default implementation for an [InputBinder] remap.
extends Node

signal opened
signal committed(new_event)
signal staged(new_event)
signal reverted


var button: InputBinderButton


func open(__button__: InputBinderButton, parent: Node = __button__) -> void:
	button = __button__
	parent.add_child(self )


func commit(event: InputEvent) -> void:
	button.commit()
	committed.emit(event)


func stage(event: InputEvent) -> void:
	button.stage(event)
	staged.emit(event)


func revert() -> void:
	button.revert()
	reverted.emit()


func _input(event: InputEvent) -> void:
	if button.disabled or event.get_class() not in InputBinderButton.ALLOWED_INPUT_CLASSES: return
	if not button.button_pressed: return

	if event.is_pressed():
		if InputLocalization.is_escape(event):
			revert()
		else:
			stage(event)

	if button._event_staged and (
		not button.input.events_allow_modifiers
		or event is not InputEventKey
		or (
			event.is_released()
			and button.get_literal_or_physical_keycode(event) == button.get_literal_or_physical_keycode(button.event_staged)
		)
	):
		commit(event)

	get_viewport().set_input_as_handled()

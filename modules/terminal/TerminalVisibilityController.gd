
class_name TerminalVisibility extends Node

static var inst : TerminalVisibility

## If enabled, the game will pause when the terminal is visible.
@export var pause_when_visible : bool = false

## Determines which features are available in the terminal. Features can be cycled through using [member MythPlugin_Terminal.INPUT_CLI_TOGGLE].
@export_flags("Mini:1","Full:2") var features : int = 2


@onready var parent : CanvasLayer = get_parent()
@onready var mini_panel : Control = %mini_panel
@onready var full_panel : Control = %full_panel


var _active_panel : int
var active_panel : int :
	get: return _active_panel
	set(value):
		if features == 0:
			_active_panel = 0
			full_panel.visible = false
			mini_panel.visible = false
			parent.visible = not parent.visible
		else:
			value = wrapi(value, 0, 3)
			while value != 0 and value & features == 0:
				value = wrapi(value + 1, 0, 3)

			_active_panel = value
			full_panel.visible = active_panel & 2 != 0
			mini_panel.visible = active_panel != 0
			parent.visible = mini_panel.visible

		get_tree().paused = parent.visible and pause_when_visible


func _ready() -> void:
	inst = self


func _input(event: InputEvent) -> void:
	if event.is_action(MythPlugin_Terminal.INPUT_TERMINAL_TOGGLE):
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			active_panel += 1
	elif parent.visible and event.is_action(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			active_panel = 0

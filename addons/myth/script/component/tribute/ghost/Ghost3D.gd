@icon("res://addons/myth/script/component/tribute/ghost/Ghost3D.svg")
extends Camera3D

const PITCH_RANGE := Vector2(-89.999, +89.999)
const HANDLED_KEYS := [
	KEY_A, KEY_D, KEY_Q, KEY_E, KEY_S, KEY_W, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SHIFT
]

var handler: Ghost
var mouse_component: MouseComponent
var light: OmniLight3D


var sprint_count: int:
	set(value):
		sprint_count = maxi(value, 0)
var mouse_vector: Vector2

@onready
var parent: Node3D = get_parent()

func _init() -> void:
	mouse_component = MouseComponent.new()
	mouse_component.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED
	mouse_component.priority = Ghost.DEFAULT_PRIORITY
	add_child(mouse_component)

	light = OmniLight3D.new()
	add_child(light)


func _ready() -> void:
	light.visible = handler.light_enabled
	light.light_color = handler.light_color
	light.light_energy = handler.light_energy
	light.omni_range = handler.light_radius


func _process(delta: float) -> void:
	if Myth.is_gui_focused(self): return

	var move_basis := (
		Basis.looking_at(-global_basis.z.slide(parent.global_basis.y).normalized(), parent.global_basis.y)
		if handler.move_relative_to_parent else
		global_basis
	)
	var move_input_vector := Vector3(
		+ Ghost.get_axis(KEY_A, KEY_D, JOY_AXIS_LEFT_X),
		+ Ghost.get_axis(KEY_Q, KEY_E, JOY_AXIS_TRIGGER_RIGHT) - Ghost.get_axis(KEY_NONE, KEY_NONE, JOY_AXIS_TRIGGER_LEFT),
		- Ghost.get_axis(KEY_S, KEY_W, JOY_AXIS_LEFT_Y),
	) * handler.move_speed
	var move_sprint_scalar := handler.move_sprint_scalar if sprint_count else 1.0

	global_position += move_basis * move_input_vector * move_sprint_scalar * delta

	var turn_input_vector := Vector3(
		+ Ghost.get_axis(KEY_DOWN, KEY_UP, JOY_AXIS_RIGHT_Y),
		- Ghost.get_axis(KEY_LEFT, KEY_RIGHT, JOY_AXIS_RIGHT_X),
		0.0
	) * handler.turn_speed_degrees

	var turn_input_mouse_vector := Vector3(
		- mouse_vector.y,
		- mouse_vector.x,
		0.0
	) * handler.turn_speed_mouse_degrees

	var new_rotation_degrees = rotation_degrees + ((turn_input_vector + turn_input_mouse_vector) * delta)

	new_rotation_degrees.x = Myth.range_clampf(new_rotation_degrees.x, PITCH_RANGE)
	rotation_degrees = new_rotation_degrees

	mouse_vector = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if Myth.is_gui_focused(self): return

	if event is InputEventMouseMotion:
		mouse_vector = event.screen_relative
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if Myth.is_gui_focused(self) or event.is_echo(): return

	elif event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

	elif event is InputEventJoypadButton:
		if event.button_index == JoyButton.JOY_BUTTON_LEFT_STICK:
			sprint_count += 1 if event.is_pressed() else -1
			get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		if event.physical_keycode == KEY_SHIFT:
			sprint_count += 1 if event.is_pressed() else -1
			get_viewport().set_input_as_handled()

		elif event.physical_keycode in HANDLED_KEYS:
			get_viewport().set_input_as_handled()

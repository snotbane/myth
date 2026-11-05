@icon("res://addons/myth/script/component/tribute/ghost/Ghost2D.svg")
extends Camera2D

const MULTIPLIER_2D := 100.0
const HANDLED_KEYS := [
	KEY_A, KEY_D, KEY_S, KEY_W, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SHIFT
]
const LIGHT_TEXTURE := preload("res://addons/myth/asset/texture/RadialGradientTexture2D.res")


var move_speed: float:
	get: return handler.move_speed * MULTIPLIER_2D


var sprint_count: int = 0:
	set(value):
		sprint_count = maxi(value, 0)


var zoom_factor: float = 0.0:
	set(value):
		zoom_factor = value
		zoom = Vector2.ONE * pow(2.0, value) * 0.5


var handler: Ghost
var light: PointLight2D


func _init() -> void:
	light = PointLight2D.new()
	light.texture = LIGHT_TEXTURE
	light.height = 2.0
	add_child(light)


func _ready() -> void:
	ignore_rotation = handler.turn_increment_degrees == 0.0

	light.visible = handler.light_enabled
	light.color = handler.light_color
	light.energy = handler.light_energy
	light.texture_scale = handler.light_radius * MULTIPLIER_2D


func _process(delta: float) -> void:
	var move_input_vector := Vector2(
		+ Ghost.get_axis(KEY_A, KEY_D, JOY_AXIS_LEFT_X),
		+ Ghost.get_axis(KEY_W, KEY_S, JOY_AXIS_LEFT_Y),
	).rotated(global_rotation) * move_speed
	var move_sprint_scalar := handler.move_sprint_scalar if sprint_count else 1.0

	global_position += move_input_vector * move_sprint_scalar * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

	elif event is InputEventJoypadButton:
		if event.button_index == JoyButton.JOY_BUTTON_LEFT_STICK:
			sprint_count += 1 if event.is_pressed() else -1
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					zoom_factor += handler.zoom_increment
					get_viewport().set_input_as_handled()

				MOUSE_BUTTON_WHEEL_DOWN:
					zoom_factor -= handler.zoom_increment
					get_viewport().set_input_as_handled()


	elif event is InputEventKey:
		if event.is_pressed():
			match event.physical_keycode:
				KEY_RIGHT, KEY_E:
					global_rotation_degrees += handler.turn_increment_degrees
					get_viewport().set_input_as_handled()

				KEY_LEFT, KEY_Q:
					global_rotation_degrees -= handler.turn_increment_degrees
					get_viewport().set_input_as_handled()

				KEY_UP:
					zoom_factor += handler.zoom_increment
					get_viewport().set_input_as_handled()

				KEY_DOWN:
					zoom_factor -= handler.zoom_increment
					get_viewport().set_input_as_handled()


		match event.physical_keycode:
			KEY_SHIFT:
				sprint_count += 1 if event.is_pressed() else -1
				get_viewport().set_input_as_handled()

			_ when event.physical_keycode in HANDLED_KEYS:
				get_viewport().set_input_as_handled()

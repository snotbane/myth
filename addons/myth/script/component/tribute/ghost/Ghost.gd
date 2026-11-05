## Creates a debug camera in either a 2D or 3D space which can be accessed and controlled during runtime.
@icon("res://addons/myth/script/component/tribute/ghost/Ghost.svg")
class_name Ghost
extends TributeComponent

const DEFAULT_PRIORITY := 127

static var INPUT_TOGGLE: Shortcut

static var ghost: Node


static var autoload_inst: Ghost:
	get: return Global.find(&"myth_ghost_handler")


static func _static_init() -> void:
	var command_ghost := Myth.Terminal.add_command([ "ghost", "noclip" ], (func() -> void:
		var current_ghost: Ghost = Ghost.get_current(&"Ghost")
		if current_ghost:
			current_ghost.toggle_ghost()
	))
	command_ghost.description = "Enters ghost mode."


	var default_event := InputEventKey.new()
	default_event.physical_keycode = KEY_G
	default_event.shift_pressed = true

	INPUT_TOGGLE = Shortcut.new()
	INPUT_TOGGLE.events = [
		default_event
	]


static func get_axis(key_negative: Key, key_positive: Key, joy_axis: JoyAxis, joy_device: int = 0, joy_deadzone: float = 0.2) -> float:
	var result := (1.0 if Input.is_physical_key_pressed(key_positive) else 0.0) - (1.0 if Input.is_physical_key_pressed(key_negative) else 0.0)

	var joy := Input.get_joy_axis(joy_device, joy_axis)
	if absf(joy) > joy_deadzone:
		result += joy

	result = Myth.range_clampf(result, Vector2(-1.0, 1.0))
	return result





## If enabled, this Ghost will be usable in all builds. If disabled, it will be destroyed in non-debug builds.
@export
var release_enabled: bool = false

## If enabled, will try to spawn a ghost on ready.
@export
var auto_activate: bool = false

## Custom input used to activate this ghost. If null, the default shortcut (Shift+G) will be used. A ghost can always be spawned using the Terminal.
@export
var toggle_event: Shortcut

@export_group("Transform")

@export_subgroup("Movement", "move_")

## Speed of the ghost. Ghost2D will move at 100x this move_speed.
@export_range(0.0, 100.0, 0.1, "or_greater")
var move_speed: float = 5.0

## Multiplier for move_speed while the sprint input is held.
@export_range(0.0, 10.0, 0.01, "or_greater")
var move_sprint_scalar: float = 4.0

## [3D Only] If enabled, the Ghost3D will move without considering its rotation (similar to Minecraft creative mode). Otherwise, move normally (as editor).
@export
var move_relative_to_parent: bool = false


@export_subgroup("Rotation", "turn_")

## Turning speed via key input, in degrees per second.
@export_range(0.0, 360.0, 0.1, "or_greater")
var turn_speed_degrees: float = 90.0

## [3D Only] Turning speed via [InputEventMouseMotion].
@export_range(0.0, 360.0, 0.1, "or_greater")
var turn_speed_mouse_degrees: float = 10.0

## [2D Only] Discrete amount to rotate the camera. If set to 0.0, [member Camera2D.ignore_rotation will be true].
@export_range(0.0, 90.0, 0.5, "or_greater")
var turn_increment_degrees: float = 0.0

@export_subgroup("Zoom", "zoom_")

## [2D Only] Discrete amount to zoom the camera.
@export_range(0.0, 2.0, 0.05, "or_greater")
var zoom_increment: float = 0.25

@export_group("Light", "light_")

## Toggles visibility of the ghost's light.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only")
var light_enabled: bool = false:
	set(value):
		light_enabled = value
		if ghost and ghost.handler == self:
			ghost.light.visible = light_enabled

## Ghost light color.
@export
var light_color: Color = Color.WHITE

## Ghost light energy.
@export_range(0.0, 16.0, 0.01, "or_greater")
var light_energy: float = 1.0

## Ghost light range. Ghost2D's value will be 100x this value.
@export_range(0.0, 10.0, 0.01, "or_greater")
var light_radius: float = 5.0


var indicator_canvas: CanvasLayer
var light_button: Button

func _init() -> void:
	if release_enabled or OS.is_debug_build():
		super._init()

		indicator_canvas = CanvasLayer.new()
		indicator_canvas.layer = 128
		indicator_canvas.visible = false
		add_child(indicator_canvas)

		var buttons_hbox := HBoxContainer.new()
		buttons_hbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
		buttons_hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
		buttons_hbox.position.y = 8.0
		buttons_hbox.focus_mode = Control.FOCUS_NONE
		indicator_canvas.add_child(buttons_hbox)

		var toggle_button := Button.new()
		toggle_button.icon = preload("res://addons/myth/script/component/tribute/ghost/Ghost.svg")
		toggle_button.focus_mode = Control.FOCUS_NONE
		toggle_button.pressed.connect(destroy_ghost)
		buttons_hbox.add_child(toggle_button)

		light_button = Button.new()
		light_button.icon = preload("res://addons/myth/script/component/tribute/ghost/Light.svg")
		light_button.toggle_mode = true
		light_button.focus_mode = Control.FOCUS_NONE
		buttons_hbox.add_child(light_button)

	else:
		queue_free()


func _ready() -> void:
	if toggle_event == null:
		toggle_event = INPUT_TOGGLE

	super._ready()


func _get_static_key() -> StringName:
	return &"Ghost"


func _became_current() -> void:
	if ghost == null: return

	destroy_ghost()
	current_node.create_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and toggle_event.matches_event(event):
		if toggle_ghost():
			get_viewport().set_input_as_handled()


func toggle_ghost() -> bool:
	if ghost and ghost.handler == self:
		destroy_ghost()
		return true

	elif current:
		create_ghost()
		return true

	return false

func create_ghost() -> void:
	if ghost:
		destroy_ghost()

	var ghost_parent: Node = parent

	if ghost_parent is not Node2D and ghost_parent is not Node3D:
		ghost_parent = get_tree().current_scene

	if ghost_parent is Node3D:
		if get_viewport().get_camera_3d() == null: return

		ghost = get_viewport().get_camera_3d().duplicate(DUPLICATE_DEFAULT & ~DUPLICATE_SIGNALS)
		ghost.set_script(preload("res://addons/myth/script/component/tribute/ghost/Ghost3D.gd"))

	elif ghost_parent is Node2D:
		if get_viewport().get_camera_2d() == null: return

		ghost = get_viewport().get_camera_2d().duplicate(DUPLICATE_DEFAULT & ~DUPLICATE_SIGNALS)
		ghost.set_script(preload("res://addons/myth/script/component/tribute/ghost/Ghost2D.gd"))

	else:
		assert(false, "Parent is not a Node3D or Node2D")

	ghost.handler = self
	light_button.toggled.connect(ghost.light.set_visible)

	if ghost_parent == parent:
		add_sibling(ghost)
	else:
		ghost_parent.add_child(ghost)

	ghost.make_current()

	indicator_canvas.show()


func destroy_ghost() -> void:
	ghost.queue_free()
	ghost = null

	indicator_canvas.hide()

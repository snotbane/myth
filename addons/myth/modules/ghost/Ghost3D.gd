## Allows the user to freely move around 3D scenes for debugging purposes.
class_name Ghost3D extends Node3D

static var DEFAULT_SCENE : PackedScene :
	get: return load("uid://cwcqawp5x05vt")

static var inst : Ghost3D


static func instantiate_from_camera(parent: Node, camera: Camera3D = parent.get_viewport().get_camera_3d(), tform: Transform3D = camera.global_transform) -> Ghost3D:
	var result : Ghost3D = DEFAULT_SCENE.instantiate()
	parent.add_child(result)

	result.global_transform = tform
	var new_camera := camera.duplicate(0)
	new_camera.transform = Transform3D.IDENTITY
	result.add_child(new_camera)
	new_camera.make_current()

	return result


## Movement speed.
@export var speed : float = 5.0
## Speed multiplier while sprinting.
@export var sprint_multiplier : float = 5.0

## If enabled, camera will always move up along the global gravity up vector and laterally relative to that (Minecraft creative controls).
@export var global_move_axis : bool = false

## If enabled, the camera will always stay right side up. Otherwise, the camera may be turned upside down.
@export var turn_clamp_pitch : bool = true
## Turn speed (degrees per second) via keyboard/gamepad.
@export var turn_speed : float = 90.0
## Turn speed via mouse.
@export var turn_speed_mouse : float = 10.0

var move_input_vector : Vector3
var turn_input_vector : Vector2
var turn_input_vector_mouse : Vector2
var is_sprinting : bool


func _init() -> void:
	if inst: inst.queue_free()

	inst = self


func _unhandled_input(event: InputEvent) -> void:
	if InputNode.is_input_restricted(self):
		move_input_vector = Vector3.ZERO
		turn_input_vector = Vector2.ZERO
		is_sprinting = false
		return
	elif event.is_action_pressed(MythPlugin_Ghost.INPUT_GHOST_TOGGLE):
		queue_free()
		get_viewport().set_input_as_handled()
	elif (
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_LEFT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_RIGHT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_DOWN) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_UP) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_FORWARD) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_BACK)
	):
		move_input_vector = Vector3(Input.get_axis(MythPlugin_Ghost.INPUT_GHOST_MOVE_LEFT, MythPlugin_Ghost.INPUT_GHOST_MOVE_RIGHT), Input.get_axis(MythPlugin_Ghost.INPUT_GHOST_MOVE_DOWN, MythPlugin_Ghost.INPUT_GHOST_MOVE_UP), Input.get_axis(MythPlugin_Ghost.INPUT_GHOST_MOVE_FORWARD, MythPlugin_Ghost.INPUT_GHOST_MOVE_BACK))
		get_viewport().set_input_as_handled()
	elif (
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_LEFT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_RIGHT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_DOWN) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_UP)
	):
		turn_input_vector = Input.get_vector(MythPlugin_Ghost.INPUT_GHOST_CAMERA_LEFT, MythPlugin_Ghost.INPUT_GHOST_CAMERA_RIGHT, MythPlugin_Ghost.INPUT_GHOST_CAMERA_DOWN, MythPlugin_Ghost.INPUT_GHOST_CAMERA_UP)
		get_viewport().set_input_as_handled()
	elif event.is_action(MythPlugin_Ghost.INPUT_GHOST_SPRINT):
		is_sprinting = event.is_pressed()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MouseMode.MOUSE_MODE_CAPTURED: return

		turn_input_vector_mouse += event.screen_relative
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var gravity_up : Vector3 = -ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	var is_upsidedown := not turn_clamp_pitch and self.global_basis.y.dot(gravity_up) < 0.0

	#region Rotation

	var turn_rotation_degrees := Vector3.ZERO

	var turn_vector := Vector3(turn_input_vector.y, -turn_input_vector.x, 0.0)
	turn_rotation_degrees += turn_vector * turn_speed


	var turn_vector_mouse := Vector3(-turn_input_vector_mouse.y, -turn_input_vector_mouse.x, 0.0)
	turn_rotation_degrees += turn_vector_mouse * turn_speed_mouse

	if is_upsidedown:
		turn_rotation_degrees *= -1.0

	turn_rotation_degrees *= delta
	turn_rotation_degrees += self.global_rotation_degrees

	if turn_clamp_pitch:
		turn_rotation_degrees.x = clamp(turn_rotation_degrees.x, -90.0, +90.0)

	self.global_rotation_degrees = turn_rotation_degrees

	turn_input_vector_mouse = Vector2.ZERO

	#endregion
	#region Movement

	var move_quat : Quaternion
	if global_move_axis:
		var forward := gravity_up.cross(self.global_basis.x)
		move_quat = Basis(-gravity_up.cross(forward), gravity_up, -forward).get_rotation_quaternion()
		if is_upsidedown:
			move_input_vector *= Vector3(1, -1, -1)
	else:
		move_quat = self.global_basis.get_rotation_quaternion()


	self.global_position += move_quat * move_input_vector * speed * (sprint_multiplier if is_sprinting else 1.0) * delta

	#endregion

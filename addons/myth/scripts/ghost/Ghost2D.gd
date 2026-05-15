## Allows the user to freely move around 2D scenes for debugging purposes.
class_name Ghost2D extends Node2D

static var DEFAULT_SCENE : PackedScene :
	get: return load("uid://cv3vrsaxhhhkb")

static var inst : Ghost2D


static func instantiate_from_camera(parent: Node, camera: Camera2D = parent.get_viewport().get_camera_2d(), tform: Transform2D = camera.global_transform) -> Ghost2D:
	var result : Ghost2D = DEFAULT_SCENE.instantiate()
	parent.add_child(result)

	result.global_transform = tform
	var new_camera : Camera2D = camera.duplicate(0)
	new_camera.transform = Transform2D.IDENTITY
	result.add_child(new_camera)
	new_camera.make_current()

	return result


## Movement speed via keyboard/gamepad.
@export var speed : float = 500.0
## Movement speed via mouse.
@export var speed_mouse : float = 50.0
## Speed multiplier while sprinting.
@export var sprint_multiplier : float = 5.0

## Turn speed (degrees per second). Has no effect if [member turn_interval_degrees] is greater than 0.0
@export var turn_speed_degrees : float = 90.0
## If greater than 0.0, rotation will be locked to a turn this many degrees on each distinct input (rather than continuously rotating)
@export_range(0.0, 90.0, 5.0, "or_greater") var turn_interval_degrees : float = 0.0


var move_input_vector : Vector2
var move_input_vector_mouse : Vector2
var is_sprinting : bool


var use_turn_interval : bool :
	get: return not is_zero_approx(turn_interval_degrees)



func _init() -> void:
	if inst: inst.queue_free()

	inst = self


func _unhandled_input(event: InputEvent) -> void:
	if InputNode.is_input_restricted(self):
		move_input_vector = Vector2.ZERO
		is_sprinting = false
		return
	elif event.is_action_pressed(MythPlugin_Ghost.INPUT_GHOST_TOGGLE):
		queue_free()
		get_viewport().set_input_as_handled()
	elif (
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_LEFT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_RIGHT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_FORWARD) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_BACK) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_LEFT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_RIGHT) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_DOWN) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_CAMERA_UP)
	):
		get_viewport().set_input_as_handled()
		move_input_vector = (
			Input.get_vector(
				MythPlugin_Ghost.INPUT_GHOST_MOVE_LEFT,
				MythPlugin_Ghost.INPUT_GHOST_MOVE_RIGHT,
				MythPlugin_Ghost.INPUT_GHOST_MOVE_FORWARD,
				MythPlugin_Ghost.INPUT_GHOST_MOVE_BACK
			) +	Input.get_vector(
				MythPlugin_Ghost.INPUT_GHOST_CAMERA_LEFT,
				MythPlugin_Ghost.INPUT_GHOST_CAMERA_RIGHT,
				MythPlugin_Ghost.INPUT_GHOST_CAMERA_UP,
				MythPlugin_Ghost.INPUT_GHOST_CAMERA_DOWN
			)
		)
	elif (
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_DOWN) or
		event.is_action(MythPlugin_Ghost.INPUT_GHOST_MOVE_UP)
	):
		get_viewport().set_input_as_handled()
		if use_turn_interval:
			if event.is_action_pressed(MythPlugin_Ghost.INPUT_GHOST_MOVE_UP):
				self.global_rotation_degrees += turn_interval_degrees
			elif event.is_action_pressed(MythPlugin_Ghost.INPUT_GHOST_MOVE_DOWN):
				self.global_rotation_degrees -= turn_interval_degrees
	elif event.is_action(MythPlugin_Ghost.INPUT_GHOST_SPRINT):
		is_sprinting = event.is_pressed()
		get_viewport().set_input_as_handled()

	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MouseMode.MOUSE_MODE_CAPTURED: return

		move_input_vector_mouse += event.screen_relative
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not use_turn_interval:
		var turn_axis := Input.get_axis(MythPlugin_Ghost.INPUT_GHOST_MOVE_UP, MythPlugin_Ghost.INPUT_GHOST_MOVE_DOWN)
		self.global_rotation_degrees += turn_axis * turn_speed_degrees * delta

	var move_vector := move_input_vector * speed + move_input_vector_mouse * speed_mouse
	move_input_vector_mouse = Vector2.ZERO

	self.global_position += move_vector.rotated(self.global_rotation) * (sprint_multiplier if is_sprinting else 1.0) * delta

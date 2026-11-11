## Standard walking motion for 1st person characters. Also handles sprinting and crouching.
@icon("res://addons/myth/script/component/character/CharacterWalkMotion.svg")
class_name CharacterWalkMotion3D
extends CharacterMotionComponent3D

enum {
	CROUCHING,
	WALKING,
	SPRINTING,
	MAX
}

static var SPEED_BY_ANGLE_DEFAULT: Curve

static func _static_init() -> void:
	SPEED_BY_ANGLE_DEFAULT = Curve.new()
	SPEED_BY_ANGLE_DEFAULT.add_point(Vector2.DOWN)

signal speed_state_changed(new_state: int)

## Emitted at the moment a footstep is taken. This only occurs when the player is on the ground, and while actively trying to walk (not sliding). Use this to implement footstep audio.
signal footstepped


## The maximum speed reachable speed.
@export_range(0.0, 8.0, 0.01, "or_greater")
var normal_max_speed: float = 4.0

## The amount of time to wait between footsteps.
@export
var normal_footstep_interval: float = 0.4

## Whether the character is walking, sprinting, or crouching
var speed_state_desired: int = WALKING

func _refresh_speed_state_desired() -> void:
	speed_state_desired = (
		CROUCHING if crouch_is_desired else
		SPRINTING if sprint_is_desired else
		WALKING
	)

var speed_state: int = WALKING:
	set(value):
		value = clampi(value, 0, MAX - 1)
		if speed_state == value:
			return

		speed_state = value
		match speed_state:
			WALKING:
				current_max_speed = normal_max_speed
				current_footstep_interval = normal_footstep_interval

			SPRINTING:
				current_max_speed = sprint_max_speed
				current_footstep_interval = sprint_footstep_interval

			CROUCHING:
				current_max_speed = crouch_max_speed
				current_footstep_interval = crouch_footstep_interval


		if crouch_shrink_shape:
			if not pawn.air_is_airborne:
				(
					create_tween()
					.tween_property(
						crouch_shrink_shape, "position:y",
						((crouch_shrink_height - pawn_shape_height_onready) * 0.5)
							if speed_state == CROUCHING
							else 0.0,
						crouch_shrink_time
					)
					.set_ease(Tween.EASE_IN)
					.set_trans(Tween.TRANS_SINE)
				)
			(
				create_tween()
				.tween_property(
					crouch_shrink_shape.shape, "height",
					crouch_shrink_height
						if speed_state == CROUCHING
						else pawn_shape_height_onready,
					crouch_shrink_time
				)
				.set_ease(Tween.EASE_IN)
				.set_trans(Tween.TRANS_SINE)
			)

		speed_state_changed.emit(speed_state)


## This controls the precise speed of the character compared to the ground angle. This has no effect if [member pawn.floor_constant_speed] is false, as that automatically handles this very same thing.
@export
var speed_by_angle: Curve


## This is the amount of control the character will have while airborne.
@export_range(0.0, 1.0, 0.01)
var air_friction: float = 0.0


## The amount of time it takes to get from stopped to [member normal_max_speed].
@export
var accel_time: float = 0.15

## The amount of time it takes to stop from [member normal_max_speed].
@export
var decel_time: float = 0.25


@export_group("Sprint", "sprint_")

## Enables sprinting. You'll need to connect an input to [member set_sprint_desired].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var sprint_enabled: bool = true:
	set(value):
		sprint_enabled = value

		if not sprint_enabled:
			sprint_is_desired = false

@export_range(0.0, 8.0, 0.01, "or_greater")
var sprint_max_speed: float = 6.0

var _sprint_direction_dot: float = -1.0

## This enforces a maximum allowed input angle which will limit when we can sprint. At [180.0] you can sprint regardless of the direction you're moving. At [0.0], you can sprint only if you're moving straight forward.
@export_range(0.0, 180.0, 0.1)
var sprint_direction_angle_degrees: float = 180.0:
	get: return rad_to_deg(acos(_sprint_direction_dot))
	set(value): _sprint_direction_dot = cos(deg_to_rad(value))


## Keep at zero to use the proportion of sprint speed to normal speed.
@export_range(0.0, 1.0, 0.01, "or_greater")
var sprint_footstep_interval: float = 0.0:
	set(value):
		if value <= 0.0:
			value = normal_footstep_interval * normal_max_speed / sprint_max_speed

		if sprint_footstep_interval == value:
			return

		sprint_footstep_interval = value


func set_sprint_desired(value: bool) -> void:
	sprint_is_desired = value
var sprint_is_desired: bool = false:
	set(value):
		value = value and sprint_enabled
		if sprint_is_desired == value:
			return

		sprint_is_desired = value
		_refresh_speed_state_desired()


@export_group("Crouch", "crouch_")

## This uses identical logic to Sprinting, but is for use at speeds slower than [member normal_max_speed]. Can be used for handling crouching speed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var crouch_enabled: bool = true:
	set(value):
		crouch_enabled = value

		if not crouch_enabled:
			crouch_is_desired = false


@export_range(0.0, 8.0, 0.01, "or_greater")
var crouch_max_speed: float = 2.0


## Keep at zero to use the proportion of crouch speed to normal speed.
@export_range(0.0, 1.0, 0.01, "or_greater")
var crouch_footstep_interval: float = 0.0:
	set(value):
		if value <= 0.0:
			value = normal_footstep_interval * normal_max_speed / crouch_max_speed

		if crouch_footstep_interval == value:
			return

		crouch_footstep_interval = value

func set_crouch_desired(value: bool) -> void:
	crouch_is_desired = value
var crouch_is_desired: bool = false:
	set(value):
		value = value and crouch_enabled
		if crouch_is_desired == value:
			return

		crouch_is_desired = value
		_refresh_speed_state_desired()

@export_subgroup("Shrink", "crouch_shrink_")

## This shape's position and height will be shortened (from the bottom up) when crouching is enabled. If not set, shrinking will be disabled. NOTE: this will also make the shape unique.
@export
var crouch_shrink_shape: CollisionShape3D

## The minimum height to shrink to.
@export
var crouch_shrink_height: float = 1.0

@export
var crouch_shrink_time: float = 0.25

var pawn_shape_height_onready: float

# @export_range(0.0, 1.0, 0.001)
var friction_scalar: float = 1.0


var footstep_time_accum: float

var input_vector: Vector2

@onready
var current_max_speed: float = normal_max_speed

@onready
var current_footstep_interval: float = normal_footstep_interval


func _ready() -> void:
	super._ready()

	sprint_footstep_interval = sprint_footstep_interval
	crouch_footstep_interval = crouch_footstep_interval

	if crouch_shrink_shape:
		crouch_shrink_shape.shape = crouch_shrink_shape.shape.duplicate()
		pawn.ground_sensor.shape = crouch_shrink_shape.shape

		pawn_shape_height_onready = crouch_shrink_shape.shape.height

	if speed_by_angle == null:
		speed_by_angle = SPEED_BY_ANGLE_DEFAULT

	pawn.ground_physics_material_changed.connect((func(mat: PhysicsMaterial) -> void:
		friction_scalar = mat.friction if mat else 1.0
	))

	pawn.became_grounded.connect(_start_footstep_timer)


func _physics_process(delta: float) -> void:
	match speed_state_desired:
		WALKING, CROUCHING:
			speed_state = speed_state_desired

		SPRINTING:
			speed_state = (
				SPRINTING
				if input_vector.dot(Vector2.UP) >= _sprint_direction_dot
				else WALKING
			)

	if pawn.air_is_airborne and is_zero_approx(air_friction):
		return

	var target_velocity := Myth.xy2_to_xz3(input_vector)

	target_velocity = pawn.global_basis * target_velocity

	if pawn.floor_constant_speed:
		target_velocity *= speed_by_angle.sample_baked(rad_to_deg(pawn.get_ground_angle_signed()))

	target_velocity *= current_max_speed

	var is_accelerating := target_velocity.length_squared() > pawn.velocity.length_squared()
	var t := (accel_time if is_accelerating else decel_time) / friction_scalar

	if pawn.air_is_airborne:
		t /= air_friction

	var v : Vector3
	if t <= 0.0:
		v = target_velocity
	else:
		var w := 1.0 - exp(-delta / (t / 3.0))
		v = pawn.velocity.lerp(target_velocity, w)

	pawn.velocity = v * (Vector3.ONE - pawn.up_direction) + pawn.velocity * pawn.up_direction

	if pawn.air_is_airborne:
		return

	if pawn.get_real_velocity().length_squared() < 0.125:
		_start_footstep_timer()
	else:
		footstep_time_accum += delta * pawn.get_real_velocity().length() / current_max_speed
		if footstep_time_accum > current_footstep_interval:
			_take_footstep()


func _start_footstep_timer() -> void:
	footstep_time_accum = current_footstep_interval * 0.5


func _take_footstep() -> void:
	footstep_time_accum = fmod(footstep_time_accum, current_footstep_interval)
	footstepped.emit()


func _on_input_axis_2d_desired_input(vector: Vector2) -> void:
	input_vector = vector

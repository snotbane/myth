@icon("res://addons/myth/script/component/character/CharacterJumpMotion.svg")
class_name CharacterJumpMotion3D
extends CharacterMotionComponent3D

signal jumped

@export_range(0.0, 8.0, 0.01, "or_greater")
var jump_strength: float = 1.0

## The number of additional jumps which can be performed while in the air.
@export
var airborne_jumps: int = 0

@onready
var jumps_left = airborne_jumps

## When performing a jump, this determines when the velocity along the jump direction should be canceled.
@export_enum("Never", "Vertical when Grounded", "Always")
var cancel_velocity_mode: int = 0

## The proportion which the ground affects the jump direction.
@export_range(0.0, 2.0, 0.01, "or_greater")
var ground_bias: float = 0.0


var can_jump: bool:
	get: return not pawn.air_is_airborne or jumps_left


func _ready() -> void:
	pawn.became_grounded.connect(reset_airborne_jumps)


func reset_airborne_jumps() -> void:
	jumps_left = airborne_jumps


func cancel_vertical_velocity(normal: Vector3) -> void:
	pawn.velocity = pawn.velocity.slide(pawn.up_direction)


func jump() -> void:
	if pawn.air_is_airborne:
		jumps_left -= 1

	pawn.make_airborne()

	var jump_direction := pawn.up_direction.lerp(pawn.ground_normal, ground_bias)

	match cancel_velocity_mode:
		1 when pawn.is_on_floor():
			cancel_vertical_velocity(jump_direction)
		2:
			cancel_vertical_velocity(jump_direction)

	pawn.velocity += jump_direction * jump_strength

	jumped.emit()

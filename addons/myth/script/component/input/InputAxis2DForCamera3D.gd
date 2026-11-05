## Handles common 1st-person and 3rd-person [Camera3D] rotation configurations.
class_name InputAxis2DForCamera3D
extends InputAxis2D

## If unset, use the parent.
@export var pitch_node: Node3D

## If unset, use the parent.
@export var yaw_node: Node3D


@export var pitch_limit: Vector2 = Vector2(-89.999, 89.999)


func _ready() -> void:
	super._ready()

	if yaw_node == null:
		yaw_node = parent

	if pitch_node == null:
		pitch_node = parent


func _process(delta: float) -> void:
	super._process(delta)

	yaw_node.rotation_degrees.y += input_vector.x * delta

	var new_head_pitch_degrees := pitch_node.rotation_degrees.x
	new_head_pitch_degrees += input_vector.y * delta
	new_head_pitch_degrees = Myth.range_clampf(new_head_pitch_degrees, pitch_limit)
	pitch_node.rotation_degrees.x = new_head_pitch_degrees

	input_vector = Vector2.ZERO

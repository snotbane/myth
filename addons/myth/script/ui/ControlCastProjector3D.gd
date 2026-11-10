## Pushes a [Control] [member source]'s center position to a [RayCast3D] or [ShapeCast3D] [member target], using a [Camera3D] as a reference. This allows you to, for example, offset the player's reticle such that they do not aim in the center of the screen.
class_name ControlCastProjector3D
extends Component

@export
var source: Control

@export_custom(PROPERTY_HINT_NODE_TYPE, "RayCast3D,ShapeCast3D")
var target: Node3D

@export
var camera: Camera3D


func _process(delta: float) -> void:
	target.target_position = (
		camera.project_local_ray_normal(
			source.get_global_rect().get_center()
		)
		* target.target_position.length()
	)

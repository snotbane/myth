## Pushes a [Control] [member source]'s center position to a [RayCast3D] or [ShapeCast3D] [member target], using a [Camera3D] as a reference. This allows you to, for example, offset the player's reticle such that they do not aim in the center of the screen.
@icon("res://addons/myth/script/ui/ReticleProjector3D.svg")
class_name ReticleProjector3D
extends Component

@export
var source: Control:
	set(value):
		if source == value:
			return

		if source and source.item_rect_changed.is_connected(_update_target_position):
			source.item_rect_changed.disconnect(_update_target_position)

		source = value

		if source and not source.item_rect_changed.is_connected(_update_target_position):
			source.item_rect_changed.connect(_update_target_position)



@export_custom(PROPERTY_HINT_NODE_TYPE, "RayCast3D,ShapeCast3D")
var target: Node3D

@export
var camera: Camera3D


func _update_target_position() -> void:
	target.target_position = (
		(
			camera.project_local_ray_normal(
				source.get_global_rect().get_center()
			) if source
			else Vector3.FORWARD
		) * target.target_position.length()
	)

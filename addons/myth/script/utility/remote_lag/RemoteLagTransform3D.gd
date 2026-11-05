class_name RemoteLagTransform3D
extends RemoteTransform3D

@onready
var parent: Node3D = get_parent()

@onready
var remote: Node3D = get_node(remote_path)

var stored_position: Vector3
var stored_rotation: Vector3
var stored_rotation_quaternion: Quaternion

func _ready() -> void:
	remote_path = ^""
	stored_position = global_position
	stored_rotation = global_rotation
# 	top_level = true
# 	remote.top_level = true


func _process(delta: float) -> void:
	if update_position:
		stored_position = stored_position.lerp(global_position, 20.0 * delta)
		remote.global_position = stored_position

	if update_rotation:
		stored_rotation = Myth.lerp_angle_3d(stored_rotation, global_rotation, 30.0 * delta)
		remote.global_rotation = stored_rotation
		# stored_rotation_quaternion = stored_rotation_quaternion.slerpni(Myth.get_global_quaternion(self), 20.0 * delta)
		# Myth.set_global_quaternion(remote, stored_rotation_quaternion)

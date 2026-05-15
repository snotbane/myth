extends RootMotionView

@onready var character : CharacterBody3D = self.get_parent()
@onready var anim_mixer : AnimationMixer = self.get_node(animation_path)

var root_velocity_global : Vector3

func _process(delta: float) -> void:
	var root_rotation := anim_mixer.get_root_motion_rotation()
	character.quaternion *= root_rotation

	var root_position := anim_mixer.get_root_motion_position()
	root_velocity_global = Quaternion.from_euler(character.global_rotation) * root_position / delta


func _physics_process(delta: float) -> void:
	if root_velocity_global:
		character.velocity = root_velocity_global
		# character.move_and_collide(root_velocity_global)


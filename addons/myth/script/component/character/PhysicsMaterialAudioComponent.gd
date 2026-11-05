class_name PhysicsMaterialAudioComponent
extends Component

var physics_material: PhysicsMaterial
func set_physics_material(value: PhysicsMaterial) -> void:
	physics_material = value


func _ready() -> void:
	assert(parent is AudioStreamPlayer or parent is AudioStreamPlayer2D or parent is AudioStreamPlayer3D, "Parent must be an AudioStreamPlayer of some kind.")


func play(property_name: StringName) -> void:
	if property_name.is_empty() or physics_material == null:
		return

	parent.stream = physics_material.get(property_name)
	if parent.stream == null:
		return

	parent.play()

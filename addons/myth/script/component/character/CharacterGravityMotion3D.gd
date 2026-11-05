@icon("res://addons/myth/script/component/character/CharacterGravityMotion.svg")
class_name CharacterGravityMotion3D
extends CharacterMotionComponent3D


func _physics_process(delta: float) -> void:
	if not pawn.is_on_floor():
		pawn.velocity += pawn.get_gravity() * delta

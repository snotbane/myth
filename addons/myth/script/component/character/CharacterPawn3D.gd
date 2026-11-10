@icon("res://addons/myth/script/component/character/CharacterPawn3D.svg")
class_name CharacterPawn3D
extends CharacterBody3D


func _init() -> void:
	_air_timer = Timer.new()
	_air_timer.wait_time = 0.125
	_air_timer.one_shot = true
	add_child(_air_timer, false, Node.INTERNAL_MODE_FRONT)

	_air_timer.timeout.connect(make_airborne)

	ground_sensor = ShapeCast3D.new()
	ground_sensor.max_results = 1
	ground_sensor.add_exception(self)


## Ground is slightly different from floor. It measures the flat normal of the floor (as if the pawn is always a cylinder), and updates every frame, whereas the floor only updates the first time it collides.
@export_group("Ground", "ground_")

var ground_sensor: ShapeCast3D

## This is the most recently valid floor normal.
@onready
var ground_normal: Vector3 = up_direction

var ground_physics_material: PhysicsMaterial:
	set(value):
		if ground_physics_material == value:
			return

		ground_physics_material = value
		ground_physics_material_changed.emit(ground_physics_material)
signal ground_physics_material_changed(mat: PhysicsMaterial)

## Similar to [member get_floor_angle], but calculates using [member ground_normal]. The result is radians.
func get_ground_angle() -> float:
	return asin(ground_normal.dot(up_direction))


## Returns a vector which points downward along the ground slope. It is coplanar with [member ground_normal] and [member up_direction].
func get_slope_normal() -> Vector3:
	return ground_normal.cross(up_direction).cross(ground_normal)


## This returns the angle of the ground when compared against the current real velocity. Used to calculate the slope-based movement.
func get_ground_angle_signed() -> float:
	if air_is_airborne or ground_normal.is_equal_approx(up_direction):
		return 0.0

	return get_ground_angle() * get_slope_normal().dot(get_real_velocity().normalized())



@export_group("Ceiling", "ceiling_")

## Use this to manually define an area. This will be used for things like checking if the pawn can stand up after crouching. If unset, a default will be created from the first child [CollisionShape3D].
@export
var ceiling_sensor: SensorArea3D

@export_group("Air", "air_")

## Emits when the pawn becomes airborne.
signal became_airborne
## Emits when the pawn stops being airborne.
signal became_grounded

var _air_timer: Timer
## How long the pawn must be not touching the floor before being considered airborne; see also [coyote time](https://school.gdquest.com/glossary/coyote_time).
@export
var air_delay: float = 0.125:
	get: return _air_timer.wait_time
	set(value): _air_timer.wait_time = value

var air_is_airborne: bool:
	set(value):
		if air_is_airborne == value:
			return

		air_is_airborne = value
		(became_airborne if air_is_airborne else became_grounded).emit()

## Forces the character to be considered airborne. Call this before the character jumps or gets launched, otherwise, they may stay glued to the ground.
func make_airborne() -> void:
	air_is_airborne = true


func _ready() -> void:
	var collision_shape: CollisionShape3D = Myth.find_child_of_type(self, "CollisionShape3D")

	if collision_shape:
		ground_sensor.target_position = -up_direction * floor_snap_length
		ground_sensor.margin = safe_margin
		ground_sensor.shape = collision_shape.shape

		collision_shape.add_child(ground_sensor, false, Node.INTERNAL_MODE_FRONT)

	if ceiling_sensor == null:
		ceiling_sensor = SensorArea3D.new()
		add_child(ceiling_sensor, false, INTERNAL_MODE_FRONT)

		if collision_shape:
			var ceiling_shape := collision_shape.duplicate()
			Myth.clear_children(ceiling_shape)
			ceiling_shape.shape = ceiling_shape.shape.duplicate()
			ceiling_shape.position.y += ceiling_shape.shape.radius + floor_snap_length
			ceiling_shape.shape.height -= ceiling_shape.shape.radius * 2.0
			ceiling_sensor.add_child(ceiling_shape)

	ceiling_sensor.collision_mask = collision_mask
	ceiling_sensor.add_exception(self)




func _physics_process(delta: float) -> void:
	move_and_slide()

	# ground_sensor.target_position = -up_direction * floor_snap_length
	# up_direction = global_basis.y

	if is_on_floor():
		ground_normal = get_floor_normal()
		ground_physics_material = get_ground_physics_material()
		air_is_airborne = false
		_air_timer.start()

	elif air_is_airborne:
		ground_normal = up_direction


func get_ground_physics_material() -> PhysicsMaterial:
	for i in ground_sensor.get_collision_count():
		var result := _get_collider_physics_material(ground_sensor.get_collider(i))
		if result:
			return result

	return null


## Defines the method for acquiring the physics material from an object. Use this to override which property should get the physics material. The default is [member StaticBody3D.physics_material_override	]
func _get_collider_physics_material(collider: Object) -> PhysicsMaterial:
	return collider.get(&"physics_material_override")


var speed: float:
	get: return get_real_velocity().length()

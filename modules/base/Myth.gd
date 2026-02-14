
@tool class_name Myth

#region FileAccess

static func get_parent_folder(path: String, levels: int = 1) -> String:
	if path.is_empty(): return String()
	if levels <= 0: return path
	return get_parent_folder(path.substr(0, path.rfind("/")), levels - 1)

#endregion
#region Nodes

## Creates an [AudioStreamPlayer] that destroys itself after playing one sound. The kind of player it creates depends on the parent node. 3D parent will be a [AudioStreamPlayer3D], 2D parent will be a [AudioStreamPlayer2D], anything else will be [AudioStreamPlayer].
static func create_one_shot_audio(parent: Node, stream: AudioStream, from_position: float = 0.0) -> Node:
	var result : Node

	if parent is Node3D: result = AudioStreamPlayer3D.new()
	elif parent is Node2D: result = AudioStreamPlayer2D.new()
	else: result = AudioStreamPlayer.new()

	result.set_script(preload("uid://bvnerwx0x15br"))	## RescueAudioStreamPlayer.gd
	result.stream = stream
	result.finished.connect(result.queue_free)
	parent.add_child(result)
	result.play(from_position)

	return result


static func is_object_of_type(obj: Object, type: String) -> bool:
	if obj.get_class() == type: return true

	var script : Script = obj.get_script()
	while script != null:
		if script.get_global_name() == type: return true
		script = script.get_base_script()

	return false

## Searches up the parental hierarchy until it finds a [Node] whose class or script matches the specified [type].
static func find_ancestor_of_type(node: Node, type: String) -> Node:
	node = node.get_parent()
	while node != null:
		if is_object_of_type(node, type): return node
		node = node.get_parent()
	return null

## Searches down the child hierarchy until it finds a [Node] whose class or script matches the specified [type].
static func find_child_of_type(node: Node, type: String, include_internal: bool = false) -> Node:
	for child in node.get_children(include_internal):
		if is_object_of_type(child, type): return child
	return null

## Searches down the child hierarchy until it finds a [Node] whose class or script matches the specified [type].
static func find_descendant_of_type(node: Node, type: String, include_internal: bool = false) -> Node:
	for child in node.get_children(include_internal):
		if is_object_of_type(child, type): return child

		var grandchild := find_descendant_of_type(child, type, include_internal)
		if grandchild == null: continue

		return grandchild
	return null

## Searches among this node's siblings until it finds a [Node] whose class or script matches the specified [type]. This will never return itself unless [allow_self] is true.
static func find_sibling_of_type(node: Node, type: String, include_internal: bool = false, allow_self: bool = false) -> Node:
	for child in node.get_parent().get_children(include_internal):
		if child == node and not allow_self: continue
		if is_object_of_type(child, type):
			return child
	return null


## For use in editor with an export_tool_button. Use this to make all of a node's children owned by the edited scene root.
static func manifest_node_children(node: Node, manifested := true, recursive := true) -> void:
	if not OS.has_feature(&"editor_hint"): return

	for child in node.get_children():
		child.owner = EditorInterface.get_edited_scene_root() if manifested else null
		if recursive: manifest_node_children(child, manifested, true)

#endregion
#region Physics

## Teleports a [PhysicsBody3D] to the specified [transform]. Only intended to be used in special situations; do NOT use every frame.
static func teleport_transform_3d(body: PhysicsBody3D, transform: Transform3D) -> void:
	PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, transform)

## Teleports a [PhysicsBody3D] to the specified [position]. Only intended to be used in special situations; do NOT use every frame.
static func teleport_position_3d(body: PhysicsBody3D, position: Vector3) -> void:
	PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(body.global_basis, position))

## Teleports a [PhysicsBody3D] to the specified [rotation]. Only intended to be used in special situations; do NOT use every frame.
static func teleport_rotation_3d(body: PhysicsBody3D, rotation: Vector3) -> void:
	PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis.from_euler(rotation), body.global_position))


#endregion
#region Input

static func get_position_on_plane_from_camera(camera: Camera3D, plane: Plane) -> Vector3:
	var mouse_pos := camera.get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_normal := camera.project_ray_normal(mouse_pos)

	var distance := plane.intersects_ray(ray_origin, ray_normal)
	if distance == null: return camera.global_position

	return ray_origin + ray_normal * distance

static func cast_mouse(camera: Camera3D, collision_mask: int, max_distance: float = 1000.0) -> Dictionary:
	var mouse_position := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * max_distance, collision_mask)

	return camera.get_world_3d().direct_space_state.intersect_ray(query)

#endregion
#region Time

static var NOW_MILLI : float :
	get: return Time.get_ticks_msec() * 0.00_1

static var NOW_MICRO : float :
	get: return Time.get_ticks_usec() * 0.00_000_1

#endregion
#region Math

static func clamp_range(x: float, __range__: Vector2) -> float:
	return clampf(x, __range__.x, __range__.y)

static func random_sign(random: RandomNumberGenerator = null) -> int:
	return +1 if random.randi() % 2 else -1


static func random_float(__range__: Vector2, random: RandomNumberGenerator = null) -> float:
	if random:
		return random.randf_range(__range__.x, __range__.y)
	else:
		return randf_range(__range__.x, __range__.y)


static func random_unit_vector1(random: RandomNumberGenerator = null) -> float:
	return randf_range(-1.0, +1.0)


static func random_unit_vector2(random: RandomNumberGenerator = null) -> Vector2:
	return Vector2.RIGHT.rotated(random_float(Vector2(-PI, +PI), random))


## https://math.stackexchange.com/a/44691
static func random_unit_vector3(random: RandomNumberGenerator = null) -> Vector3:
	var t := random_float(Vector2(0, 2 * PI))
	var z := random_float(Vector2(-1, +1))
	var s := sqrt(1.0 - (z * z))
	return Vector3(s * cos(t), s * sin(t), z)


## Returns a [float] with a random sign within the specified [range]
static func random_vector1(__range__: Vector2, random: RandomNumberGenerator = null) -> float:
	return random_float(__range__, random) * random_sign(random)


## Returns a [Vector2] in a random direction with a length within the specified [Vector2] range.
static func random_vector2(__range__: Vector2, random: RandomNumberGenerator = null) -> Vector2:
	return random_unit_vector2(random) * random_float(__range__, random)


## Returns a [Vector3] in a random direction with a length within the specified [Vector2] range.
static func random_vector3(__range__: Vector2, random: RandomNumberGenerator = null) -> Vector3:
	return random_unit_vector3(random) * random_float(__range__, random)

## Returns the given [vector] flattened and normalized along plane [up].
static func flatten(vector: Vector3, normalize := false, up := Vector3.UP) -> Vector3:
	var result := vector * (Vector3.ONE - up)
	return result.normalized() if normalize else result

static func expanded(vector: Vector2) -> Vector3:
	return Vector3(vector.x, vector.y, vector.x)

static func condensed(vector: Vector3) -> Vector2:
	return Vector2(xz(vector).length(), vector.y)

static func clamp_length2(vector: Vector2, max_length: float) -> Vector2:
	if vector.length_squared() <= max_length * max_length: return vector
	return vector.normalized() * max_length

static func clamp_length3(vector: Vector3, max_length: float) -> Vector3:
	if vector.length_squared() <= max_length * max_length: return vector
	return vector.normalized() * max_length


static func is_in_range(x: float, __range__: Vector2) -> bool:
	return x >= __range__.x and x <= __range__.y


static func xy(v: Vector3) -> Vector2:
	return Vector2(v.x, v.y)
static func xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
static func yz(v: Vector3) -> Vector2:
	return Vector2(v.y, v.z)

static func x_y(v: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(v.x, y, v.y)
static func xy_(v: Vector2, z: float = 0.0) -> Vector3:
	return Vector3(v.x, v.y, z)

#endregion
#region Strings

static var REGEX_STRING_FORMAT_CHECKER := RegEx.create_from_string(r"(?<!%)%[0-9\.]*[sdifv]")

static func get_format_count(s: String) -> int:
	return REGEX_STRING_FORMAT_CHECKER.search_all(s).size()

#endregion

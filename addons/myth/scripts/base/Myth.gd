@tool class_name Myth

#region Objects

## Changes the script of an object while keeping desired properties intact.
static func change_script(obj: Object, new_script: Script, preserve_usage_flags: PropertyUsageFlags = PROPERTY_USAGE_STORAGE, ignore_prop_names: Array = []) -> void:
	var old_script := obj.get_script()
	if old_script == new_script: return
	if old_script == null or new_script == null:
		obj.set_script(new_script)
		return

	var preserve: Dictionary[StringName, Variant]
	for prop in obj.get_property_list():
		if prop[&"name"] == &"script": continue
		if prop[&"name"] in ignore_prop_names: continue
		if prop[&"usage"] & preserve_usage_flags:
			preserve[prop[&"name"]] = obj.get(prop[&"name"])

	obj.set_script(new_script)
	assert(obj.get_script() != null, "Attempted to change the script of an object, but couldn't set the script. Make sure that it has an _init() method with 0 *required* arguments.")

	for k: StringName in preserve:
		obj.set(k, preserve[k])


#endregion
#region FileAccess

static func get_parent_folder(path: String, levels: int = 1) -> String:
	if levels <= 0: return path
	if path.is_empty(): return String()

	var end := path.rfind("/")
	if end == -1: return ""

	return get_parent_folder(path.left(end), levels - 1)


static func get_paths_in_folder(root := "res://", include: RegEx = null, exclude: RegEx = null) -> PackedStringArray:
	var dir := DirAccess.open(root)
	if not dir: return []

	var result: PackedStringArray = []

	if include == null or include.search(root) != null:
		result.push_back(root)

	dir.list_dir_begin()
	var file: String = dir.get_next()
	while file:
		var next := root.path_join(file)
		if (include == null or include.search(file) != null) \
			and (exclude == null or exclude.search(file) == null):
			result.push_back(next)

		if dir.current_is_dir():
			result.append_array(get_paths_in_folder(next, include))

		file = dir.get_next()
	return result

#endregion
#region Nodes

## Creates an [AudioStreamPlayer] that destroys itself after playing one sound. The kind of player it creates depends on the parent node. 3D parent will be a [AudioStreamPlayer3D], 2D parent will be a [AudioStreamPlayer2D], anything else will be [AudioStreamPlayer].
static func create_one_shot_audio(parent: Node, stream: AudioStream, from_position: float = 0.0) -> Node:
	var result: Node

	if parent is Node3D: result = AudioStreamPlayer3D.new()
	elif parent is Node2D: result = AudioStreamPlayer2D.new()
	else: result = AudioStreamPlayer.new()

	result.set_script(preload("uid://bvnerwx0x15br")) ## RescueAudioStreamPlayer.gd
	result.stream = stream
	result.finished.connect(result.queue_free)
	parent.add_child(result)
	result.play(from_position)

	return result


## Returns the property in a preexisting property list that matches the given [param name]
static func find_prop(name: StringName, props: Array[Dictionary]) -> Dictionary:
	var idx := props.find_custom(func(e: Dictionary) -> bool:
		return e[&"name"] == name
	)
	return props[idx] if idx > -1 else {}


## Returns true if the property with the given [param name] matches the [param type] within a preexisting property list. Returns false if the property does not exist in the list.
static func is_prop_of_type(name: StringName, type: String, props: Array[Dictionary]) -> bool:
	var prop := find_prop(name, props)
	if prop.is_empty(): return false

	match prop[&"type"]:
		TYPE_OBJECT:
			for subtype in prop[&"hint_string"].split(","):
				if type == subtype or ClassDB.is_parent_class(type, subtype): return true
			return false
		_:
			return type_string(prop[&"type"]) == type


static func is_value_of_type(value, type: String) -> bool:
	match typeof(value):
		TYPE_OBJECT:
			if value == null or type.is_empty(): return false
			if ClassDB.is_parent_class(value.get_class(), type): return true

			var script: Script = value.get_script()
			while script != null:
				if script.get_global_name() == type: return true
				script = script.get_base_script()

			return false
		_:
			return type_string(typeof(value)) == type


## Searches up the parental hierarchy until it finds a [Node] whose class or script matches the specified [type].
static func find_ancestor_of_type(node: Node, type: String) -> Node:
	node = node.get_parent()
	while node != null:
		if is_value_of_type(node, type): return node
		node = node.get_parent()
	return null


## Searches up the parental hierarchy, and any siblings of parents, and returns a [Node] matching the class or script matching the specified [param type].
static func find_ancestor_sibling_of_type(node: Node, type: String, include_internal: bool = false, include_self_sibling: bool = false) -> Node:
	if include_self_sibling:
		var self_sibling := find_sibling_of_type(node, type, include_internal)
		if self_sibling: return self_sibling

	node = node.get_parent()
	while node != null:
		if is_value_of_type(node, type): return node

		var sibling := find_sibling_of_type(node, type, include_internal)
		if sibling: return sibling

		node = node.get_parent()

	return null


## Searches down the child hierarchy until it finds a [Node] whose class or script matches the specified [type].
static func find_child_of_type(node: Node, type: String, include_internal: bool = false) -> Node:
	if node == null: return null

	for child in node.get_children(include_internal):
		if is_value_of_type(child, type): return child
	return null


## Searches down the child hierarchy until it finds a [Node] whose class or script matches the specified [type].
static func find_descendant_of_type(node: Node, type: String, include_internal: bool = false) -> Node:
	if node == null: return null

	for child in node.get_children(include_internal):
		if is_value_of_type(child, type): return child

		var grandchild := find_descendant_of_type(child, type, include_internal)
		if grandchild == null: continue

		return grandchild
	return null


static func find_children_of_type(node: Node, type: String, include_internal: bool = false) -> Array:
	if node == null: return []

	var result: Array
	for child in node.get_children(include_internal):
		if is_value_of_type(child, type): result.push_back(child)
	return result


static func find_descendants_of_type(node: Node, type: String, include_internal: bool = false) -> Array:
	if node == null: return []

	var result: Array
	for child in node.get_children(include_internal):
		if is_value_of_type(child, type): result.push_back(child)

		result.append_array(find_descendants_of_type(child, type, include_internal))
	return result


## Searches among this node's siblings until it finds a [Node] whose class or script matches the specified [type]. This will never return itself unless [allow_self] is true.
static func find_sibling_of_type(node: Node, type: String, include_internal: bool = false, allow_self: bool = false) -> Node:
	if node == null or node.get_parent() == null: return null

	for child in node.get_parent().get_children(include_internal):
		if child == node and not allow_self: continue
		if is_value_of_type(child, type):
			return child
	return null


## For use in editor with an export_tool_button. Use this to make all of a node's children owned by the edited scene root.
static func manifest_node_children(node: Node, manifested := true, recursive := true) -> void:
	if not OS.has_feature(&"editor_hint"): return

	for child in node.get_children():
		child.owner = EditorInterface.get_edited_scene_root() if manifested else null
		if recursive: manifest_node_children(child, manifested, true)


## Queues free all children of a given [param type] from a [Node].
static func clear_children(node: Node, type: String = "") -> void:
	for child in node.get_children():
		if not (is_value_of_type(child, type) or type.is_empty()): continue

		child.queue_free()


## Removes all children of a given [param type] from a [Node] and returns a new array with them inside. Useful for reordering children.
static func cache_children(node: Node, type: String = "") -> Array[Node]:
	var result: Array[Node]
	for child in node.get_children():
		if not (is_value_of_type(child, type) or type.is_empty()): continue

		result.push_back(child)
		node.remove_child(child)
	return result


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

static var NOW_MILLI: float:
	get: return Time.get_ticks_msec() * 0.00_1

static var NOW_MICRO: float:
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

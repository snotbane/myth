## The main autoload node for the Myth plugin. Also contains a library of static helper functions.
@tool
@icon("res://addons/myth/script/Myth.svg")
class_name Myth
extends Node

const Terminal := preload("res://addons/myth/script/terminal/MythTerminal.gd")
const WindowModeHandler := preload("res://addons/myth/script/utility/window_mode/WindowModeHandler.gd")

#region Static Utilities

#region Objects

## Returns true if the [param value] matches [param type], accounting for custom GDScript classes (established via `class_name`).
static func is_value_of_type(value, type: String, null_ok: bool = true) -> bool:
	match typeof(value):
		TYPE_NIL:
			return null_ok

		TYPE_OBJECT:
			if type.is_empty(): return false
			if ClassDB.is_parent_class(value.get_class(), type): return true

			var script: Script = value.get_script()
			while script != null:
				if script.get_global_name() == type: return true
				script = script.get_base_script()

			return false

		_:
			return type_string(typeof(value)) == type


## Compares the order of [param a] and [param b] for use in [Array.sort_custom]. If either is an [Object] with its own method `compare(other: Variant) -> bool`, that method will be used. If neither fit the criteria, it will simply return `a < b`.
static func compare(a, b) -> bool:
	if a is Object and a.has_method(&"compare"):
		return a.compare(b)
	elif b is Object and b.has_method(&"compare"):
		return not b.compare(a)
	elif a is not Object and b is not Object:
		return a < b
	else:
		return false


## Changes the script of an object while keeping desired properties intact.
static func change_script(obj: Object, new_script: Script, preserve_usage_flags: PropertyUsageFlags = PROPERTY_USAGE_STORAGE, ignore_prop_names: Array = []) -> void:
	var old_script := obj.get_script()
	if old_script == new_script: return
	if old_script == null or new_script == null:
		obj.set_script(new_script)
		return

	var preserve: Dictionary[StringName, Variant]
	for prop in obj.get_property_list():
		if (
				prop[&"name"] == &"script"
			or prop[&"name"] in ignore_prop_names
			or prop[&"usage"] & preserve_usage_flags
		): continue

		preserve[prop[&"name"]] = obj.get(prop[&"name"])

	obj.set_script(new_script)
	assert(obj.get_script() != null, "Attempted to change the script of an object, but couldn't set the script. Make sure that it has an _init() method with 0 *required* arguments.")

	for k: StringName in preserve:
		obj.set(k, preserve[k])

#endregion


#region FileSystem

## Returns the global file path, regardless of whether we are in the editor or release. Why is this not a built-in function??? The example is literally in the documentation???
static func get_global_path(path: String) -> String:
	return (
		ProjectSettings.globalize_path(path)
		if OS.has_feature("editor")
		else OS.get_executable_path().get_base_dir().path_join(path)
	)


## Returns an array of paths in the [param root] folder. Use [param glob] to filter files. [param glob] can be a [String], [PackedStringArray], or [null].
static func get_paths_in_folder(root := "res://", glob = null) -> PackedStringArray:
	var dir := DirAccess.open(root)
	if not dir: return []

	var result : PackedStringArray = []
	dir.list_dir_begin()
	var file : String = dir.get_next()
	while file:
		var next := root.path_join(file)
		if dir.current_is_dir():
			result.append_array(get_paths_in_folder(next, glob))

		else:
			if glob == null:
				pass

			elif glob is String:
				if next.match(glob):
					result.push_back(next)

			elif glob is Array:
				if glob.is_empty():
					result.push_back(next)
				else:
					for g in glob:
						if next.match(g):
							result.push_back(next)
							break

			else:
				assert(false, "glob '%s' must be a String or PackedStringArray." % glob)
				return []

		file = dir.get_next()
	return result


## Returns true if the given [param query] path exists inside the folder [param dir].
static func is_path_inside(query: String, dir: String) -> bool:
	query = get_global_path(query).simplify_path().get_base_dir()
	dir = get_global_path(
		dir.left(-1) if dir.ends_with("/") else dir
	).simplify_path()

	if query.length() > dir.length():
		return false

	while query != "" and query != "/":
		if query == dir:
			return true
		query = query.get_base_dir()

	return false

#endregion

#endregion


#region SceneTree

## Creates a [NodePath] from any Node to any value. [param from] is the host [Node] which will
static func get_node_path_to_any(from: Node = null, to: Object = null, end: Variant = null) -> NodePath:
	return ^""


## Gets the path value relative to [param node]. Why is this not vanilla?
static func get_node_path_value(node: Node, path: NodePath) -> Variant:
	return node.get_node(path).get_indexed(path.slice(path.get_name_count()))


## Sets the path value relative to [param node]. Why is this not vanilla?
static func set_node_path_value(node: Node, path: NodePath, value: Variant) -> void:
	if path.is_empty():
		return

	node.get_node(path).set_indexed(path.slice(path.get_name_count()), value)

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


#region Input

## Returns true if any GUI elements on the [param tree_context]'s viewport are focused. Useful for restricting input while menues are open.
static func is_gui_focused(tree_context: Node) -> bool:
	return tree_context.get_viewport().gui_get_focus_owner() != null

#endregion

#region Range


## Clamps a [float] value within a [Vector2] range. (Default will clamp between 0.0 and 1.0).
static func range_clampf(value: float, range := Vector2.DOWN) -> float:
	return clampf(value, range.x, range.y)

## Clamps an [int] value within a [Vector2i] range.
static func range_clampi(value: float, range: Vector2i) -> int:
	return clampi(value, range.x, range.y)


## Ensures that a [Vector2] range's x <= y. [param limit] can be used to set a hard limit on the range, e.g. for and exported property setter.
static func range_formatf(value: Vector2, limit = null) -> Vector2:
	var result := Vector2(
		minf(value.x, value.y),
		maxf(value.x, value.y)
	)
	if limit == null: return result
	assert(limit is Vector2 or limit is Vector2i, "Parameter 'limit' must be a Vector2.")

	result = Vector2(
		maxf(result.x, limit.x),
		minf(result.y, limit.y)
	)
	return result

## Ensures that a [Vector2i] range's x <= y. [param limit] can be used to set a hard limit on the range, e.g. for and exported property setter.
static func range_formati(value: Vector2i, limit = null) -> Vector2i:
	var result := Vector2i(
		mini(value.x, value.y),
		maxi(value.x, value.y)
	)
	if limit == null: return result
	assert(limit is Vector2 or limit is Vector2i, "Parameter 'limit' must be a Vector2i.")

	result = Vector2i(
		maxi(result.x, limit.x),
		mini(result.y, limit.y)
	)
	return result


## Linearly interpolates a value within a [Vector2] [param range]. If [param clamp] is true, the result will be clamped within [param range]. See [member @GlobalScope.lerpf].
static func range_lerpf(value: float, range: Vector2, clamp: bool = false) -> float:
	return (
		clampf(lerpf(range.x, range.y, value), range.x, range.y)
		if clamp
		else lerpf(range.x, range.y, value)
	)


## Inverse lerp between a [Vector2] [param range]. If [param clamp] is true, the result will be clamped between [0.0] and [1.0]. See [member @GlobalScope.inverse_lerp].
static func range_lerpf_inverse(value: float, range := Vector2.DOWN, clamp: bool = false) -> float:
	return (
		clampf(inverse_lerp(range.x, range.y, value), 0.0, 1.0)
		if clamp
		else inverse_lerp(range.x, range.y, value)
	)


## Generates a random [float] within a [Vector2] [param range]. If [param random] is set, it will use that generator to generate the result. See [member RandomNumberGenerator.randf_range].
static func range_randf(range: Vector2, random: RandomNumberGenerator = null) -> float:
	return (
		random.randf_range(range.x, range.y)
		if random
		else randf_range(range.x, range.y)
	)

## Generates a random [int] within a [Vector2i] [param range]. If [param random] is set, it will use that generator to generate the result. See [member RandomNumberGenerator.randi_range].
static func range_randi(range: Vector2i, random: RandomNumberGenerator = null) -> float:
	return (
		random.randi_range(range.x, range.y)
		if random
		else randi_range(range.x, range.y)
	)


## Remaps a float value to a new range. If [param clamp] is true, the result will be clamped within [param range_out].
static func range_remapf(value: float, range_in : Vector2, range_out : Vector2, clamp: bool = false) -> float:
	return (
		clampf(lerpf(range_out.x, range_out.y, inverse_lerp(range_in.x, range_in.y, value)), range_out.x, range_out.y)
		if clamp
		else lerpf(range_out.x, range_out.y, inverse_lerp(range_in.x, range_in.y, value))
	)


## Wraps a [float] value around a [param range]. See [@GlobalScope.wrapf].
static func range_wrapf(value: float, range := Vector2.DOWN) -> float:
	return wrapf(value, range.x, range.y)

## Wraps an [int] value around a [param range]. See [@GlobalScope.wrapi].
static func range_wrapi(value: float, range: Vector2i) -> int:
	return wrapi(value, range.x, range.y)


#endregion

#region Math

static func gcdi(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


static func lcdi(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return absi(a * b) / gcdi(a, b)


static func xy2_to_xy3(v: Vector2, z: float = 0.0) -> Vector3:
	return Vector3(
		v.x,
		v.y,
		z,
	)

static func xy2_to_xz3(v: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(
		v.x,
		y,
		v.y,
	)

static func xy3_to_xy2(v: Vector3) -> Vector2:
	return Vector2(
		v.x,
		v.y
	)

static func xz3_to_xy2(v: Vector3) -> Vector2:
	return Vector2(
		v.x,
		v.z,
	)


## Performs [member @GlobalScope.lerp_angle] on each component of two [Vector2]s.
static func lerp_angle_2d(from: Vector2, to: Vector2, weight: float) -> Vector2:
	return Vector2(
		lerp_angle(from.x, to.x, weight),
		lerp_angle(from.y, to.y, weight),
	)

## Performs [member @GlobalScope.lerp_angle] on each component of two [Vector3]s.
static func lerp_angle_3d(from: Vector3, to: Vector3, weight: float) -> Vector3:
	return Vector3(
		lerp_angle(from.x, to.x, weight),
		lerp_angle(from.y, to.y, weight),
		lerp_angle(from.z, to.z, weight),
	)


static func get_global_quaternion(node: Node3D) -> Quaternion:
	return node.global_basis.get_rotation_quaternion()


static func set_global_quaternion(node: Node3D, quat: Quaternion) -> void:
	node.global_basis = Basis(quat).scaled(node.global_basis.get_scale())


#endregion

#endregion


static var inst: Myth

## Template-safe reference to the [EditorInterface]. This will only be valid in the editor, but it won't generate errors in an exported build.
static var editor_interface_safe: Object

func _init() -> void:
	inst = self

	var mouse_component := MouseComponent.new()
	mouse_component.name = &"myth_mouse_default"
	mouse_component.priority = -129
	mouse_component.mouse_mode = MouseComponent.DEFAULT_MOUSE_MODE
	add_child(mouse_component)
	mouse_component._became_current()

## Creates a visual graphic for a property on the parent node. The kind of properties available are determined by what the parent is.
@icon("res://addons/myth/script/debug_draw/property_drawer/PropertyDrawer3D.svg")
@tool
class_name PropertyDrawer3D
extends Node3D

const SCENE_ARROW : PackedScene = preload("res://addons/myth/script/debug_draw/property_drawer/scene/VisualArrow3D.tscn")
const SCENE_AXIS : PackedScene = preload("res://addons/myth/script/debug_draw/property_drawer/scene/VisualAxis3D.tscn")
const SCENE_LINE : PackedScene = preload("res://addons/myth/script/debug_draw/property_drawer/scene/VisualLine3D.tscn")
const SCENE_POINT : PackedScene = preload("res://addons/myth/script/debug_draw/property_drawer/scene/VisualPoint3D.tscn")
const SCENE_SPIKE : PackedScene = preload("res://addons/myth/script/debug_draw/property_drawer/scene/VisualSpike3D.tscn")

const FONT_SYSTEM_MONO: Font = preload("res://addons/myth/asset/font/myth_mono_system_font.tres")


static func get_visual_shape_scene(idx: int) -> PackedScene:
	match idx:
		1:	return SCENE_SPIKE
		2:	return SCENE_LINE
		3:	return SCENE_ARROW
		4:	return SCENE_AXIS
		_:	return SCENE_POINT


@export
var property_set: PropertyDrawerSet

@export
var fixed_size: bool = true:
	set(value):
		fixed_size = value

		label_template.fixed_size = value
		for label in prop_labels.values():
			label.fixed_size = value

		visual_template.set_instance_shader_parameter(&"fixed_size", value)
		for visual in prop_visuals.values():
			visual.set_instance_shader_parameter(&"fixed_size", value)

@export_group("Text", "text_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var text_enabled: bool = true:
	get: return label_root.visible
	set(value): label_root.visible = value


@export_range(0, 3)
var text_line_breaks: int = 1


@export_group("Visual", "visual_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var visual_enabled: bool = true:
	get: return visual_root.visible
	set(value): visual_root.visible = value


@export_range(0.0, 10.0, 0.01, "or_greater")
var visual_size: float = 1.0:
	set(value):
		visual_size = value
		# visual_template.set_instance_shader_parameter(&"size", value)
		for prop in prop_visuals:
			prop_visuals[prop].size = value * prop.visual_size


var root: Node3D
var label_root: Node3D
var label_template: Label3D
var visual_root: Node3D
var visual_template: Node3D

var prop_labels: Dictionary[PropertyDrawer, Label3D] = {}
var prop_visuals: Dictionary[PropertyDrawer, Node3D] = {}

func _init() -> void:
	root = Node3D.new()
	add_child(root, false, INTERNAL_MODE_FRONT)

	label_root = Node3D.new()
	root.add_child(label_root)

	label_template = Label3D.new()
	label_template.visible = false

	label_template.no_depth_test = true
	label_template.pixel_size = 0.001
	label_template.offset = Vector2(15.0, -15.0)
	label_template.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_template.double_sided = false
	label_template.fixed_size = true

	label_template.font = FONT_SYSTEM_MONO
	label_template.font_size = 32
	label_template.outline_size = 18
	label_template.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_template.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label_template.autowrap_trim_flags = 0

	label_root.add_child(label_template)

	visual_root = Node3D.new()
	root.add_child(visual_root)



func _ready() -> void:
	if not Engine.is_editor_hint():
		var present_flags := ProjectSettings.get_setting("myth/debug/property_drawer/present_in", 3)
		var show_flags := ProjectSettings.get_setting("myth/debug/property_drawer/show_in", 1)
		if OS.has_feature(&"editor_runtime"):
			if not present_flags & 1:
				queue_free()
				return
			elif not show_flags & 1:
				hide()
		elif OS.has_feature(&"debug"):
			if not present_flags & 2:
				queue_free()
				return
			elif not show_flags & 2:
				hide()
		elif OS.has_feature(&"release"):
			if not present_flags & 4:
				queue_free()
				return
			elif not show_flags & 1:
				hide()

		_refresh_nodes()


func _get_configuration_warnings() -> PackedStringArray:
	var result := PackedStringArray()

	if get_child_count(false) > 0:
		result.push_back("PropertyDrawer3D should not have any non-internal children.")

	return result


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_nodes()
	_refresh()


func _refresh_nodes() -> void:
	if property_set:
		for prop: PropertyDrawer in property_set.properties:
			if prop == null:
				continue

			var label: Label3D = prop_labels.get(prop)
			if label == null and prop.text_enabled:
				label = label_template.duplicate()
				label.visible = true
				label_template.add_sibling(label)
				prop_labels[prop] = label

			elif label != null and not prop.text_enabled:
				label.queue_free()
				prop_labels.erase(prop)

			if label:
				label.modulate = prop.color

			var visual: Node3D = prop_visuals.get(prop)
			if (visual == null or visual.get_meta(&"idx", -1) != prop.visual_shape) and prop.visual_enabled:
				if visual:
					visual.queue_free()
				visual = get_visual_shape_scene(prop.visual_shape).instantiate()
				visual.set_meta(&"idx", prop.visual_shape)
				visual_root.add_child(visual)
				prop_visuals[prop] = visual

			elif visual != null and not prop.visual_enabled:
				visual.queue_free()
				prop_visuals.erase(prop)

			if visual:
				visual.fixed_size = fixed_size
				visual.size = visual_size * prop.visual_size
				visual.color = prop.color




	else:
		for label in prop_labels.values():
			label.queue_free()
		prop_labels.clear()

		for visual in prop_visuals.values():
			visual.queue_free()
		prop_visuals.clear()



func _refresh() -> void:
	if not (is_inside_tree() and visible):
		return

	if property_set == null:
		return

	var lines: int = 0
	for prop: PropertyDrawer in property_set.properties:
		if prop == null or prop.path.is_empty():
			continue

		var node := self.get_node(prop.path)
		var value = node.get_indexed(prop.path.slice(prop.path.get_name_count()))

		var label: Label3D = prop_labels.get(prop)
		if label:
			var s := prop.get_value_string(value)
			label.text = "\n".repeat(lines) + s
			lines += s.count("\n") + text_line_breaks + 1

		var visual: Node3D = prop_visuals.get(prop)
		if visual:
			if value is Vector3 or value is Vector3i:
				visual.global_basis = Basis.IDENTITY
				visual.global_position = value if prop.visual_global_space else node.get_parent().to_global(value)

			elif value is Basis:
				visual.position = Vector3.ZERO
				if prop.visual_global_space:
					visual.global_basis = value
				else:
					visual.basis = value

			elif value is Transform3D:
				visual.global_position = value.origin if prop.visual_global_space else node.get_parent().to_global(value.origin)
				if prop.visual_global_space:
					visual.global_basis = value.basis
				else:
					visual.basis = value.basis


			# match prop.visual_shape:
			# 	1, 3, 4:
			# 		var up : Vector3
			# 		# if

			# 		visual.global_basis == Basis.looking_at()

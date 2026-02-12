
@tool class_name Draw3D extends Node3D

const POINT_MESH := preload("uid://cnkvd3t13kcod")
const ARROW_MESH := preload("uid://bak40cp1rwhko")

const DEFAULT_MATERIAL := preload("uid://bdosbg5iohx24")

const DEFAULT_COLOR := Color.WHITE_SMOKE


func _init() -> void: pass

@export var color : Color = DEFAULT_COLOR :
	get: return _get_color()
	set(value): _set_color(value)
func _get_color() -> Color: return DEFAULT_COLOR
func _set_color(value: Color) -> void: pass


var _visibility_by_feature : int = 7
@export_flags("Editor", "Player", "Debug", "Release") var visibility_by_feature : int = 7 :
	get: return _visibility_by_feature
	set(value):
		_visibility_by_feature = value

		if Engine.is_editor_hint():
			visible = _visibility_by_feature & 1
		elif OS.has_feature(&"editor_runtime"):
			visible = _visibility_by_feature & 2
		elif OS.has_feature(&"debug"):
			visible = _visibility_by_feature & 4
		elif OS.has_feature(&"release"):
			visible = _visibility_by_feature & 8


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

	if not Engine.is_editor_hint():
		visibility_by_feature = visibility_by_feature

	if not OS.has_feature(&"release") or visible: return

	queue_free()


func _on_visibility_changed() -> void:
	if Engine.is_editor_hint():
		visibility_by_feature = (visibility_by_feature | (1 << 0)) if visible else (visibility_by_feature & ~(1 << 0))
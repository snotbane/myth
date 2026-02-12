
@tool class_name Draw3D_Text extends Draw3D

var label : Label3D

func _init() -> void:
	super._init()

	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.double_sided = false
	label.fixed_size = true
	label.pixel_size = 0.0025
	add_child(label)

func _get_color() -> Color:
	return label.modulate
func _set_color(value: Color) -> void:
	label.modulate = value


@export var text : String :
	get: return label.text
	set(value): label.text = value

@export var billboard : bool = true :
	get: return label.billboard == BaseMaterial3D.BILLBOARD_ENABLED
	set(value):
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED if value else BaseMaterial3D.BILLBOARD_DISABLED
		label.double_sided = not value

@export var fixed_size : bool = true :
	get: return label.fixed_size
	set(value): label.fixed_size = value

@export_range(0.0005, 0.01, 0.0005, "or_greater") var pixel_size : float = 0.0025 :
	get: return label.pixel_size
	set(value): label.pixel_size = value

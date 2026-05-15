
@tool class_name SettingCheck extends Setting


var button : BaseButton


func _get_value() -> Variant:
	return button.button_pressed


func _set_value(new_value: Variant) -> void:
	button.button_pressed = new_value


func _init() -> void:
	super._init()

	button = CheckBox.new()
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(button)


func _ready() -> void:
	super._ready()

	button.toggled.connect(_value_changed.unbind(1))


@export_enum("Check Box", "Check Button") var button_type : int = 0 :
	get:
		if button is CheckBox:		return 0
		if button is CheckButton:	return 1
		return -1

	set(new_value):
		if button_type == new_value: return

		var new_button : BaseButton
		match new_value:
			0: new_button = CheckBox.new()
			1: new_button = CheckButton.new()
			_: return

		new_button.size_flags_vertical = button.size_flags_vertical
		new_button.button_pressed = button.button_pressed
		if button.toggled.is_connected(_value_changed):
			new_button.toggled.connect(_value_changed.unbind(1))

		hbox_panel.add_child(new_button)
		button.queue_free()
		button = new_button


@export var button_pressed : bool :
	get: return value
	set(new_value): value = new_value

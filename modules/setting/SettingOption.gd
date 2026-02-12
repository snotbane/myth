
@tool class_name SettingOption extends Setting


@export var options : PackedStringArray :
	get:
		var result := PackedStringArray()
		result.resize(option.item_count)
		for i in result.size():
			result[i] = option.get_item_text(i)
		return result

	set(new_value):
		while option.item_count > new_value.size():
			option.remove_item(new_value.size())
		while option.item_count < new_value.size():
			option.add_item("")
		for i in new_value.size():
			option.set_item_text(i, new_value[i])
			option.set_item_id(i, i)


@export var selected : int :
	get: return value
	set(new_value): value = new_value


@export var handle_minimum_width : float = 100.0 :
	get: return option.custom_minimum_size.x
	set(new_value): option.custom_minimum_size.x = new_value


var option : OptionButton


func _get_value() -> Variant:
	return option.selected


func _set_value(new_value: Variant) -> void:
	option.select(new_value)
	_value_changed()


func _init() -> void:
	super._init()

	option = OptionButton.new()
	option.custom_minimum_size.x = 100.0
	option.selected = 0
	option.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(option)


func _ready() -> void:
	super._ready()

	option.item_selected.connect(_value_changed.unbind(1))

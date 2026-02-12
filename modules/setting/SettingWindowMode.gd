##
@tool class_name SettingWindowMode extends Setting


@export var labels : PackedStringArray = [
	"Windowed",
	"Minimized",
	"Maximized",
	"Fullscreen",
	"Fullscreen (Exclusive)"
]


var _selectable_modes : int = 17
## Available [Window.Mode]s.
@export_flags("Windowed:1", "Minimized:2", "Maximized:4", "Fullscreen:8", "Exclusive:16") var selectable_modes : int = 17 :
	get: return _selectable_modes
	set(new_value):
		_selectable_modes = new_value
		while option.item_count > 0:
			option.remove_item(0)

		if _selectable_modes & 1:
			option.add_item(labels[Window.Mode.MODE_WINDOWED])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_WINDOWED)
		if _selectable_modes & 2:
			option.add_item(labels[Window.Mode.MODE_MINIMIZED])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_MINIMIZED)
		if _selectable_modes & 4:
			option.add_item(labels[Window.Mode.MODE_MAXIMIZED])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_MAXIMIZED)
		if _selectable_modes & 8:
			option.add_item(labels[Window.Mode.MODE_FULLSCREEN])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_FULLSCREEN)
		if _selectable_modes & 16:
			option.add_item(labels[Window.Mode.MODE_EXCLUSIVE_FULLSCREEN])
			option.set_item_id(option.item_count - 1, Window.Mode.MODE_EXCLUSIVE_FULLSCREEN)


@export var selected : int :
	get: return value
	set(new_value): value = clampi(new_value, 0, option.item_count)


@export var handle_minimum_width : float = 100.0 :
	get: return option.custom_minimum_size.x
	set(new_value): option.custom_minimum_size.x = new_value


var selected_mode : Window.Mode :
	get: return option.get_item_id(selected)
	set(new_value):
		for i in option.item_count:
			if option.get_item_id(i) != new_value: continue

			selected = i
			break


var option : OptionButton


func _get_value() -> Variant:
	return option.selected


func _set_value(new_value: Variant) -> void:
	option.select(new_value)
	_value_changed()


func _init() -> void:
	super._init()

	# reset_button_enabled = false

	option = OptionButton.new()
	option.custom_minimum_size.x = 100.0
	option.selected = 0
	option.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(option)

	selectable_modes = selectable_modes


func _ready() -> void:
	super._ready()

	option.item_selected.connect(_value_changed.unbind(1))


func _value_changed() -> void:
	super._value_changed()

	if Engine.is_editor_hint() or get_window() == null: return

	get_window().mode = selected_mode


func _notification(what: int) -> void:
	if Engine.is_editor_hint() or get_window() == null: return

	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if 2 ** get_window().mode & _selectable_modes:
				selected_mode = get_window().mode

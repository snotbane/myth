
extends LineEdit

const HISTORY_PATH := "user://logs/terminal_history.cfg"

@export_range(0, 256, 1, "or_greater") var history_max_size : int = 256

var history_file : ConfigFile
var history : PackedStringArray

var _history_index : int = -1
var history_index : int :
	get: return _history_index
	set(value):
		value = clampi(value, -history.size(), -1)
		if _history_index == value: return

		_history_index = value
		text = history[_history_index]
		set.call_deferred(&"caret_column", text.length())


func _init() -> void:
	history_file = ConfigFile.new()
	history_file.load(HISTORY_PATH)
	history = history_file.get_value("", "history", [ "" ])

	visibility_changed.connect(_visibility_changed)
	text_submitted.connect(_text_submitted)
	text_changed.connect(_text_changed)


func _gui_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey:
		if not event.is_pressed(): return

		match event.keycode:
			KEY_UP:		history_index -= 1
			KEY_DOWN:	history_index += 1


func _visibility_changed() -> void:
	if not visible: return

	grab_focus()


func _text_changed(new_text: String) -> void:
	if history_index == -1: history[-1] = new_text


func _text_submitted(new_text: String) -> void:
	_history_index = -1
	history[-1] = new_text
	history.push_back(String())

	text = String()

	while history.size() > history_max_size:
		history.remove_at(0)

	history_file.set_value("", "history", history)
	history_file.save(HISTORY_PATH)

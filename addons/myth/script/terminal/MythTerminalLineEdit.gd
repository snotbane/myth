extends LineEdit

var history_index_set_in_progress: bool
var history: PackedStringArray = [ "" ]
var history_index : int = 0:
	set(value):
		value = clampi(value, 0, history.size() - 1)
		if history_index == value:
			return

		history_index = value
		history_index_set_in_progress = true
		text = history[value]
		history_index_set_in_progress = false
		set_caret_to_end.call_deferred()


func _init() -> void:
	visibility_changed.connect(_visibility_changed)
	text_submitted.connect(clear.unbind(1), CONNECT_DEFERRED)
	text_changed.connect(_text_changed)

func _ready() -> void:
	text_submitted.connect(_text_submitted)


func _visibility_changed() -> void:
	if visible:
		grab_focus()


func _input(event: InputEvent) -> void:
	if not has_focus(): return

	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_UP:
				history_index -= 1
				get_viewport().set_input_as_handled()

			KEY_DOWN:
				history_index += 1
				get_viewport().set_input_as_handled()

		if event.is_echo():
			return

		match event.keycode:
			KEY_QUOTELEFT when Myth.Terminal.window:
				Myth.Terminal.window.toggle_visibility()
				get_viewport().set_input_as_handled()


func _text_submitted(text: String) -> void:
	Myth.Terminal.inst._on_line_edit_text_submitted(text)

	if history[-1] != "":
		history.push_back("")
	history_index = history.size() - 1


func _text_changed(text: String) -> void:
	if history_index_set_in_progress:
		return

	history[history_index] = text


func set_caret_to_end() -> void:
	caret_column = text.length()

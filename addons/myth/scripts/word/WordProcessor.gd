## Generic class for word processing. Supports only plain text.
@tool class_name WordProcessor extends Control


const LB := "[lb]"
const RB := "[rb]"


static var REGEX_BBCODE := RegEx.create_from_string(r"\[.*?\]")
static var REGEX_BRACKETS := RegEx.create_from_string(r"[\[\]]")


class ShaperLine extends RefCounted:
	var line_idx: int
	var bbcode_start: int
	var bbcode_end: int

	var bbcode_line: String

	var prefix_text: String

	var text: String:
		get: return prefix_text + bbcode_line

	func _init(__line_idx__: int, __bbcode_start__: int, bbcode_full_text: String) -> void:
		line_idx = __line_idx__

		bbcode_start = __bbcode_start__
		bbcode_end = bbcode_full_text.find("\n", bbcode_start)

		prefix_text = "\n".repeat(line_idx)
		for i in line_idx:
			for rm in WordProcessor.REGEX_BBCODE.search_all(bbcode_full_text, bbcode_start, bbcode_end):
				if rm.get_string() == LB or rm.get_string() == RB: continue
				prefix_text += rm.get_string()

		bbcode_line = bbcode_full_text.substr(bbcode_start, bbcode_end - bbcode_start if bbcode_end != -1 else -1)

		print("self : %s" % [ self ])


	func _to_string() -> String:
		return bbcode_line


	func snippet(column_index: int) -> String:
		return prefix_text + bbcode_line.left(column_index)


	func snippet_index(column_index: int) -> int:
		return prefix_text.length() + column_index


var display: RichTextLabel
var caret: ColorRect

var shaped: RichTextLabel
var editor: TextEdit

var shaper_lines: Array[ShaperLine]
@export_multiline var text: String:
	get: return editor.text
	set(value):
		editor.text = value
		_refresh_text()
func _refresh_text() -> void:
	display.text = get_bbcode_text(text)
	shaped.text = display.text

	assert(editor.text == display.get_parsed_text())

	var editor_lines := text.split("\n")
	# var bbcode_lines := display.text.split("\n")

	shaper_lines.resize(display.get_line_count())
	var start := 0
	for i in shaper_lines.size():
		shaper_lines[i] = ShaperLine.new(i, start, display.text)
		start += shaper_lines[i].bbcode_line.length() + 1


func get_bbcode_text(raw: String) -> String:
	var result: String
	var search := 0

	var rm_brackets := REGEX_BRACKETS.search(raw)
	while rm_brackets:
		var br := LB if rm_brackets.get_string() == "[" else RB
		result += raw.substr(search, rm_brackets.get_start() - search) + br
		search = rm_brackets.get_end()
		rm_brackets = REGEX_BRACKETS.search(raw, search)

	result += raw.substr(search)
	search = 0

	print("result : %s" % [result])
	return result


var caret_index: int:
	get: return get_index_at_column_line(editor.get_caret_column(), editor.get_caret_line())
# 	set(value):
# 		var coord := get_editor_column_line_at_index(clampi(value, 0, text.length()))
# 		editor.set_caret_column(coord.x)
# 		editor.set_caret_line(coord.y)
# 		_refresh_caret()
func _refresh_caret() -> void:
	caret.position = await get_caret_position_for_index(caret_index)


func get_caret_position_for_index(__caret_index__: int) -> Vector2:
	var line_idx: int = display.get_character_line(caret_index) if caret_index < text.length() else (display.get_line_count() - 1)
	shaped.text = shaper_lines[line_idx].text
	shaped.visible_characters = shaper_lines[line_idx].snippet_index(editor.get_caret_column())

	await get_tree().process_frame

	return Vector2(shaped.get_visible_content_rect().size.x, shaped.get_line_offset(line_idx))


func _init() -> void:
	display = RichTextLabel.new()
	display.bbcode_enabled = true
	display.fit_content = true
	display.focus_mode = FOCUS_NONE
	display.mouse_filter = MOUSE_FILTER_STOP
	display.set_anchors_preset(PRESET_FULL_RECT)
	add_child(display)

	shaped = display.duplicate(DUPLICATE_DEFAULT)
	shaped.mouse_filter = MOUSE_FILTER_IGNORE
	shaped.modulate = Color.RED
	add_child(shaped)

	editor = TextEdit.new()
	editor.mouse_filter = MOUSE_FILTER_IGNORE
	# editor.modulate = Color.TRANSPARENT
	editor.modulate = Color(0.0, 0.0, 1.0, 0.5)
	editor.set_anchors_preset(PRESET_FULL_RECT)
	add_child(editor)

	caret = ColorRect.new()
	add_child(caret)

	display.gui_input.connect(_display_gui_input)
	editor.caret_changed.connect(_refresh_caret)
	editor.text_changed.connect(_refresh_text)


func _ready() -> void:
	caret.size.x = editor.get_theme_constant(&"caret_width")
	caret.size.y = 10.0


func _display_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		set_caret_to_local_position(event.position)


func get_index_at_column_line(column: int, line: int) -> int:
	var result := column
	for i in line:
		result += editor.get_line(i).length() + 1
	return result


func get_editor_column_line_at_index(idx: int) -> Vector2i:
	return Vector2i(0, 0)


func set_caret_to_local_position(pos: Vector2) -> void:
	editor.grab_focus.call_deferred()

	editor.set_caret_column(0)
	editor.set_caret_line(0)

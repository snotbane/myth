## Generic class for word processing. Supports only plain text.
@tool class_name WordProcessor extends Control


const LB := "[lb]"
const RB := "[rb]"


static var REGEX_BBCODE := RegEx.create_from_string(r"\[.*?\]")
static var REGEX_BRACKETS := RegEx.create_from_string(r"[\[\]]")


class ShaperLine extends RefCounted:
	var idx: int

	var bbcode_start: int
	var bbcode_end: int
	var shaped_start: int

	var text_prefix: String
	var text_line: String
	var text: String:
		get: return text_prefix + text_line


	func _init(full_bbcode_text: String, __text_line__: String, line_idx: int, previous_end: int) -> void:
		idx = line_idx

		bbcode_start = previous_end + 1 if line_idx > 0 else 0
		bbcode_end = bbcode_start + __text_line__.length()

		text_prefix = "\n".repeat(idx)
		for j in idx:
			for rm in WordProcessor.REGEX_BBCODE.search_all(full_bbcode_text, bbcode_start, bbcode_end):
				text_prefix += rm.get_string()

		text_line = __text_line__


	func _to_string() -> String:
		return str({
			&"idx": idx,
			&"bbcode_start": bbcode_start,
			&"bbcode_end": bbcode_end,
			&"shaped_start": shaped_start,
			&"text": text
		})


	func get_partial_text_at_bbcode_idx(bbcode_idx: int) -> String:
		return text_prefix + text_line.left(bbcode_idx - bbcode_start)


var display: RichTextLabel
var caret: ColorRect

var shaped: RichTextLabel
var editor: TextEdit


var parsed_text: String
var shaper_lines: Array[ShaperLine]
@export_multiline var text: String:
	get: return editor.text
	set(value):
		editor.text = value
		_refresh_text()
func _refresh_text() -> void:
	var bbcode_text := text
	var rm_brackets := REGEX_BRACKETS.search(text)
	while rm_brackets:
		var bracket_bbcode := LB if rm_brackets.get_string() == "[" else RB
		bbcode_text = bbcode_text.left(rm_brackets.get_start()) + bracket_bbcode + bbcode_text.right(-rm_brackets.get_end())
		print("bbcode_text : %s" % [bbcode_text])
		rm_brackets = REGEX_BRACKETS.search(bbcode_text, rm_brackets.get_start() + bracket_bbcode.length())

	display.text = bbcode_text
	shaped.text = bbcode_text
	parsed_text = display.get_parsed_text()

	var raw_lines := bbcode_text.split("\n")
	shaper_lines.resize(display.get_line_count())
	for i in shaper_lines.size():
		shaper_lines[i] = ShaperLine.new(bbcode_text, raw_lines[i], i, shaper_lines[i - 1].bbcode_end if i > 0 else 0)

	print("shaper_lines : %s" % [shaper_lines])

@export var caret_index: int:
	set(value):
		caret_index = clampi(value, 0, parsed_text.length())
		caret.position = await get_position_at_bbcode_index(caret_index)


func _init() -> void:
	display = RichTextLabel.new()
	# display.fit_content = true
	display.bbcode_enabled = true
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


func set_caret_to_local_position(pos: Vector2) -> void:
	editor.grab_focus.call_deferred()

	editor.set_caret_column(0)
	editor.set_caret_line(0)


var caret_prev: int
func _refresh_caret() -> void:
	var editor_idx := get_index_at_column_line(editor.get_caret_column(), editor.get_caret_line())
	# var dir := signi(editor_idx - caret_prev)
	# var changed := false
	# var parsed_idx := editor_to_bbcode_indeces[editor_idx]
	# while parsed_idx < 0:
	# 	changed = true
	# 	editor_idx += dir
	# 	parsed_idx = editor_to_bbcode_indeces[editor_idx]
	# editor_idx += (dir if changed else 0)
	# parsed_idx += (dir if changed else 0)
	# editor.set_caret_column(editor_idx)
	# caret_prev = editor_idx
	caret.position = await get_position_at_bbcode_index(editor_idx)
	# shaped.visible_characters = get_index_at_column_line(editor.get_caret_column(), editor.get_caret_line())


func get_position_at_bbcode_index(idx: int):
	var line_idx: int = display.get_character_line(idx) if idx < parsed_text.length() else (display.get_line_count() - 1)
	shaped.text = shaper_lines[line_idx].get_partial_text_at_bbcode_idx(idx)

	await get_tree().process_frame

	return Vector2(shaped.get_visible_content_rect().size.x, shaped.get_line_offset(line_idx))


func get_index_at_column_line(column: int, line: int) -> int:
	var result := column
	for i in line:
		result += editor.get_line(i).length() + 1
	return result


func get_position_at_column_line(column: int, line: int):
	return await get_position_at_bbcode_index(get_index_at_column_line(column, line))


## Generic class for word processing. Supports only plain text.
# @tool class_name WordProcessor extends Control

# static var REGEX_BBCODE := RegEx.create_from_string(r"\[.*?\]")
# static var REGEX_BRACKET_L := RegEx.create_from_string(r"\[")
# static var REGEX_BRACKET_R := RegEx.create_from_string(r"\]")


# var display: RichTextLabel
# var caret: ColorRect

# var shaped: RichTextLabel
# var editor: TextEdit


# var parsed_text: String
# var editor_to_bbcode_indeces: PackedInt32Array
# @export_multiline var text: String:
# 	get: return editor.text
# 	set(value):
# 		editor.text = value
# 		_refresh_text()
# func _refresh_text() -> void:
# 	var display_text := text
# 	var rm := REGEX_BRACKET_L.search(text)
# 	while rm:
# 		display_text = text.left(rm.get_start()) + "[lb]" + text.right(rm.get_end())
# 		rm = REGEX_BRACKET_L.search(text, rm.get_end())

# 	rm = REGEX_BRACKET_R.search(text)
# 	while rm:
# 		display_text = text.left(rm.get_start()) + "[rb]" + text.right(rm.get_end())
# 		rm = REGEX_BRACKET_R.search(text, rm.get_end())


# 	display.text = display_text
# 	shaped.text = display_text
# 	parsed_text = display.get_parsed_text()

# 	editor_to_bbcode_indeces.resize(display_text.length() + 1)


# @export var caret_index: int:
# 	set(value):
# 		caret_index = clampi(value, 0, parsed_text.length())
# 		caret.position = await get_position_at_bbcode_index(caret_index)


# func _init() -> void:
# 	display = RichTextLabel.new()
# 	# display.fit_content = true
# 	display.bbcode_enabled = true
# 	display.focus_mode = FOCUS_NONE
# 	display.mouse_filter = MOUSE_FILTER_STOP
# 	display.set_anchors_preset(PRESET_FULL_RECT)
# 	add_child(display)

# 	shaped = display.duplicate(DUPLICATE_DEFAULT)
# 	shaped.mouse_filter = MOUSE_FILTER_IGNORE
# 	shaped.modulate = Color.RED
# 	add_child(shaped)

# 	editor = TextEdit.new()
# 	editor.mouse_filter = MOUSE_FILTER_IGNORE
# 	# editor.modulate = Color.TRANSPARENT
# 	editor.modulate = Color(0.0, 0.0, 1.0, 0.5)
# 	editor.set_anchors_preset(PRESET_FULL_RECT)
# 	add_child(editor)

# 	caret = ColorRect.new()
# 	add_child(caret)

# 	display.gui_input.connect(_display_gui_input)
# 	editor.caret_changed.connect(_refresh_caret)
# 	editor.text_changed.connect(_refresh_text)


# func _ready() -> void:
# 	caret.size.x = editor.get_theme_constant(&"caret_width")
# 	caret.size.y = 10.0


# func _display_gui_input(event: InputEvent) -> void:
# 	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
# 		set_caret_to_local_position(event.position)


# func set_caret_to_local_position(pos: Vector2) -> void:
# 	editor.grab_focus.call_deferred()

# 	editor.set_caret_column(0)
# 	editor.set_caret_line(0)


# var caret_prev: int
# func _refresh_caret() -> void:
# 	caret.position = await get_position_at_bbcode_index(get_index_at_column_line(editor.get_caret_column(), editor.get_caret_line()))


# func get_position_at_bbcode_index(idx: int):
# 	var line_idx: int = display.get_character_line(idx) if idx < parsed_text.length() else (display.get_line_count() - 1)

# 	var line_start := display.get_line_range(line_idx).x
# 	var line_text := display.text.substr(line_start, idx - line_start)
# 	var leadin_text := "\n".repeat(line_idx)
# 	for rm in REGEX_BBCODE.search_all(display.text, 0, line_start):
# 		leadin_text += rm.get_string()
# 	shaped.text = leadin_text + line_text

# 	await get_tree().process_frame

# 	return Vector2(shaped.get_visible_content_rect().size.x, shaped.get_line_offset(line_idx))


# func get_index_at_column_line(column: int, line: int) -> int:
# 	var result := column
# 	for i in line:
# 		result += editor.get_line(i).length() + 1
# 	return result


# func get_position_at_column_line(column: int, line: int):
# 	return await get_position_at_bbcode_index(get_index_at_column_line(column, line))

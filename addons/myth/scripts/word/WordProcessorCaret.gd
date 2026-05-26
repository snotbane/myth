class_name WordProcessorCaret extends Panel

var shaper: RichTextLabel


var _bbcode_index_prev: int = -1
var bbcode_index: int


@onready var word: WordProcessor = get_parent()

func _ready() -> void:
	assert(word is WordProcessor)

	add_theme_stylebox_override(&"panel", word.caret_style_box)

	size.x = word.editor.get_theme_constant(&"caret_width")

	shaper = word.display.duplicate()
	shaper.mouse_filter = MOUSE_FILTER_IGNORE
	shaper.modulate = Color.TRANSPARENT
	shaper.set_anchors_preset(PRESET_TOP_LEFT)
	_refresh_shaper()
	add_child(shaper)


func _refresh_shaper() -> void:
	shaper.size = word.display.size
	_refresh_position()


func _refresh_position() -> void:
	bbcode_index = get_bbcode_index()
	if bbcode_index == _bbcode_index_prev: return
	_bbcode_index_prev = bbcode_index

	var line := word.display.get_character_line(bbcode_index) if bbcode_index < word.text.length() else (word.display.get_line_count() - 1)
	shaper.text = word.shaper_lines[line].text
	shaper.visible_characters = word.shaper_lines[line].snippet_index(word.editor.get_caret_column(get_index()))

	await get_tree().process_frame

	position = Vector2(
		shaper.get_visible_content_rect().size.x,
		shaper.get_line_offset(line)
	)

	var line_height := shaper.get_line_height(line)
	if line_height == 0: return

	size.y = line_height


func get_bbcode_index() -> int:
	var result := word.editor.get_caret_column(get_index())
	for i in word.editor.get_caret_line(get_index()):
		result += word.editor.get_line(i).length() + 1
	return result

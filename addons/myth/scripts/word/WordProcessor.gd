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


	func _to_string() -> String:
		return bbcode_line


	func snippet(column_index: int) -> String:
		return prefix_text + bbcode_line.left(column_index)


	func snippet_index(column_index: int) -> int:
		return prefix_text.length() + column_index


static func get_bbcode_text(raw: String) -> String:
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

	return result


var display: RichTextLabel
var editor: TextEdit
var carets: Array[WordProcessorCaret]


var shaper_lines: Array[ShaperLine]
@export_multiline var text: String:
	get: return editor.text
	set(value):
		editor.text = value
		_refresh_text()
func _refresh_text() -> void:
	display.text = get_bbcode_text(text)

	assert(editor.text == display.get_parsed_text())

	shaper_lines.resize(display.get_line_count())
	var start := 0
	for i in shaper_lines.size():
		shaper_lines[i] = ShaperLine.new(i, start, display.text)
		start += shaper_lines[i].bbcode_line.length() + 1

	# _refresh_carets()


@export_group("Caret", "caret_")

@export var caret_multiple: bool = false:
	get: return editor.caret_multiple
	set(value): editor.caret_multiple = value


@export var caret_style_box: StyleBox


@export_subgroup("Blink", "caret_blink_")

var caret_blink_tween: Tween
var caret_blink_opacity: float = 1.0:
	set(value):
		caret_blink_opacity = value
		for caret in carets:
			caret.self_modulate = Color(1, 1, 1, caret_blink_opacity)

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var caret_blink_enabled: bool = true:
	set(value):
		caret_blink_enabled = value
		_caret_blink_tween_refresh()


@export_range(0.0, 1.0, 0.01) var caret_blink_transition: float = 0.0:
	set(value):
		caret_blink_transition = value
		_caret_blink_tween_refresh()


var _caret_blink_interval_third: float = 0.333333
var _caret_blink_interval_half: float = 0.5
@export_range(0.01, 1.0, 0.01, "or_greater") var caret_blink_interval: float = 1.0:
	set(value):
		caret_blink_interval = value
		_caret_blink_tween_refresh()


func _caret_blink_tween_refresh() -> void:
	_caret_blink_interval_third = caret_blink_interval * 0.333333
	_caret_blink_interval_half = caret_blink_interval * 0.5
	var caret_hold_duration = maxf(0.0, caret_blink_interval - caret_blink_transition * 2.0) * 0.5

	if caret_blink_tween and caret_blink_tween.is_running():
		caret_blink_tween.kill()

	if not caret_blink_enabled: return

	caret_blink_tween = create_tween()
	caret_blink_tween.set_loops()
	caret_blink_tween.set_ease(Tween.EASE_IN_OUT)
	caret_blink_tween.set_trans(Tween.TRANS_LINEAR)

	if caret_blink_transition > 0.0:
		caret_blink_tween.tween_property(self , ^"caret_blink_opacity", 0.0, caret_blink_transition)

		caret_blink_tween.tween_interval(caret_hold_duration)

		caret_blink_tween.tween_property(self , ^"caret_blink_opacity", 1.0, caret_blink_transition)

		caret_blink_tween.tween_interval(caret_hold_duration)

	else:
		caret_blink_tween.tween_property(self , ^"caret_blink_opacity", 0.0, 0.0)

		caret_blink_tween.tween_interval(_caret_blink_interval_half)

		caret_blink_tween.tween_property(self , ^"caret_blink_opacity", 1.0, 0.0)

		caret_blink_tween.tween_interval(_caret_blink_interval_half)


@export_subgroup("Slide", "caret_slide_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var caret_slide_enabled: bool = false:
	set(value):
		caret_slide_enabled = value

@export var caret_slide_duration: float = 0.1:
	set(value):
		caret_slide_duration = value

@export var caret_slide_trans: Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC:
	set(value):
		caret_slide_trans = value


func _init() -> void:
	display = RichTextLabel.new()
	display.bbcode_enabled = true
	display.fit_content = true
	display.focus_mode = FOCUS_NONE
	display.mouse_filter = MOUSE_FILTER_STOP
	display.set_anchors_preset(PRESET_FULL_RECT)
	add_child(display, false, INTERNAL_MODE_BACK)

	editor = TextEdit.new()
	editor.caret_blink = false
	editor.mouse_filter = MOUSE_FILTER_IGNORE
	editor.modulate = Color(0.0, 0.0, 1.0, 0.5)
	editor.set_anchors_preset(PRESET_FULL_RECT)
	add_child(editor, false, INTERNAL_MODE_BACK)

	editor.caret_changed.connect(_refresh_carets)
	editor.text_changed.connect(_refresh_text)
	display.gui_input.connect(_display_gui_input)


func _ready() -> void:
	if caret_style_box == null: caret_style_box = StyleBoxFlat.new()

	_caret_blink_tween_refresh()

	resized.connect.call_deferred(_refresh_carets)


func _refresh_carets() -> void:
	while carets.size() < editor.get_caret_count():
		var caret := WordProcessorCaret.new()
		add_child(caret)
		carets.push_back(caret)

	while carets.size() > editor.get_caret_count():
		carets.pop_back().queue_free()

	for caret in carets:
		caret._refresh_position()


func _display_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		set_caret_to_local_position(event.position)


func set_caret_to_local_position(pos: Vector2) -> void:
	editor.grab_focus.call_deferred()

	print("pos : %s" % [pos])

	editor.set_caret_column(0)
	editor.set_caret_line(0)

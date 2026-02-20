
class_name Typewriter extends RichTextLabel


static var REGEX_SHAPE_MARKER := RegEx.create_from_string(r"$|(?<=\s)\S")
static var REGEX_STRIP_BBCODE := RegEx.create_from_string(r"\\[.*?\\]")


static func strip_bbcode_tags(s: String) -> String:
	return REGEX_STRIP_BBCODE.sub(s, "", true)


signal completed


var time_prepped : float
var time_elapsed : float
var time_reseted : float
var time_per_char : PackedFloat32Array

var visible_text : String

var _visible_characters_partial : float
var visible_characters_partial : float :
	get: return _visible_characters_partial
	set(value):
		_visible_characters_partial = value
		visible_characters_rich = floori(_visible_characters_partial)

var visible_characters_completed : bool :
	get: return visible_characters_rich == visible_characters_max




var _visible_characters_target : int
var visible_characters_rich : int :
	get: return visible_characters
	set (value):
		value = clampi(value, 0, visible_characters_max)
		if visible_characters == value: return
		_visible_characters_target = value

		var increment := signi(value - visible_characters)
		while visible_characters != value:
			time_per_char[visible_characters] = time_elapsed
			visible_characters += increment

			if increment <= 0: continue

			_handle_elements()

		var shape_marker_match := REGEX_SHAPE_MARKER.search(visible_text, visible_characters)
		shaper.visible_characters = shape_marker_match.get_start() if shape_marker_match else visible_characters
		# if visible_characters > 0:
		# 	encounter_char(visible_text[mini(visible_characters, visible_text.length()) - 1])

		if not visible_characters_completed:
			_visible_characters_partial = visible_characters + fmod(_visible_characters_partial, 1.0)

		# visible_message_changed.emit()

var visible_characters_max : int

var shaper : RichTextLabel
var message : Variant = text

var is_user_scroll_enabled : bool
var is_locked : bool
var is_user_scroll_override : bool

enum {
	READY,
	PLAYING,
	PAUSED,
	COMPLETED,
	RESETTING,
}
var _play_state := READY
var play_state := READY :
	get: return _play_state
	set(value):
		if _play_state == value: return
		_play_state = value

		is_user_scroll_enabled = _play_state == PAUSED or _play_state == COMPLETED

		match _play_state:
			READY, COMPLETED:
				_visible_characters_partial = 0
				is_locked = false
				is_user_scroll_override = false

		match _play_state:
			READY:
				time_reseted = INF
			RESETTING:
				time_reseted = Myth.NOW_MICRO
			COMPLETED:
				completed.emit()


var is_typing : bool :
	get: return play_state == PLAYING and not visible_characters_completed

@export var autostart : bool

@export var base_speed : float = 30.0
var current_speed : float :
	get: return base_speed * _get_speed_modifier()
func _get_speed_modifier() -> float: return 1.0


func _init() -> void:
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

	shaper = self.duplicate(DUPLICATE_DEFAULT & ~DUPLICATE_SCRIPTS)
	shaper.name = "shaper"
	shaper.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	shaper.visibility_layer = 0
	shaper.self_modulate = Color.RED
	shaper.focus_mode = Control.FOCUS_NONE
	shaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shaper.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shaper)


func _ready() -> void:
	if autostart:
		present(text)
	else:
		prep(text)


func _process(delta: float) -> void:
	time_elapsed = Myth.NOW_MICRO - time_prepped

	if is_typing:
		visible_characters_partial += current_speed * delta
		print(visible_characters)

	if play_state != COMPLETED and visible_characters_completed and _check_completed():
		play_state = COMPLETED


func _check_completed() -> bool: return true


func clear_message() -> void:
	visible_characters = 0
	_visible_characters_partial = 0.0


func prep(__message__: Variant):
	message =__message__

	text = _get_bbcode_string(message)
	shaper.text = text

	visible_characters_max = get_total_character_count()
	time_per_char.resize(visible_characters_max + 1)
	time_per_char.fill(INF)

	clear_message()

	play_state = READY
	time_prepped = Myth.NOW_MICRO


func present(__message__: Variant = null) -> void:
	await prep(__message__ if __message__ else message)

	play_state = PLAYING


func complete() -> void:
	visible_characters_rich = visible_characters_max


func _get_bbcode_string(message) -> String:
	match typeof(message):
		TYPE_STRING, TYPE_STRING_NAME:
			return message

		TYPE_OBJECT when message.has_method(&"_get_bbcode_string"):
			return message._get_bbcode_string()

	return str(message)


func _handle_elements() -> void:
	pass


func encounter_char() -> void:
	pass
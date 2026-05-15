extends ScrollContainer

var scroll_max_previous : float

func _ready() -> void:
	get_v_scroll_bar().changed.connect(keep_at_end)


func keep_at_end() -> void:
	if scroll_vertical >= scroll_max_previous:
		scroll_vertical = get_v_scroll_bar().max_value

	scroll_max_previous = get_v_scroll_bar().max_value - size.y

class_name TerminalLog extends RichTextLabel

enum {
	NORMAL,
	WARNING,
	ERROR,
	QUIET,
}


static var inst : TerminalLog


static func print(message: String, message_type : int = NORMAL, new_line: bool = true) -> void:
	match message_type:
		QUIET:	pass
		ERROR:	printerr(message)
		_:		print(message)

	if inst == null: return

	if new_line: message += "\n"

	var message_color : Color
	match message_type:
		NORMAL: message_color = inst.get_theme_color(&"message_color_normal", &"TerminalLog")
		WARNING: message_color = inst.get_theme_color(&"message_color_warning", &"TerminalLog")
		ERROR: message_color = inst.get_theme_color(&"message_color_error", &"TerminalLog")
		QUIET: message_color = inst.get_theme_color(&"message_color_quiet", &"TerminalLog")

	inst.push_color(message_color)
	inst.append_text(message)
	inst.pop()


static func cls() -> void:
	inst.text = String()


func _init() -> void:
	inst = self

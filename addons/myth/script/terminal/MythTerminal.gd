extends Control

const COLOR_ERROR := Color.INDIAN_RED
const COLOR_INPUT := Color.CYAN
const COLOR_QUIET := Color(1, 1, 1, 0.4)
const COLOR_WARNING := Color.YELLOW


class Command \
extends Resource:
	@export
	var ids: PackedStringArray

	@export
	var method: Callable

	@export
	var description: String

	# @export
	var arg_descriptions: PackedStringArray


	func _init() -> void:
		ids = []
		description = ""
		arg_descriptions = []


	func add_argument(id: String, desc: String = "", optional: bool = false) -> void:
		arg_descriptions.push_back("[%s] %s :: %s" % [
			arg_descriptions.size(),
			("(%s)" % id) if optional else (" %s " % id),
			desc,
		])


	func execute(args: Array):
		args.resize(mini(method.get_argument_count(), args.size()))
		await method.callv(args)


	func get_help_long() -> String:
		if arg_descriptions:
			return get_help_short() + "\n\t" + "\n\t".join(arg_descriptions)
		else:
			return get_help_short()


	func get_help_short() -> String:
		return "%s :: %s" % [
			", ".join(ids),
			description
		]


static var inst: Myth.Terminal
static var window: Window

func _init() -> void:
	inst = self


	var command_clear := add_command([ "clear", "cls" ], Myth.Terminal.clear)
	command_clear.description = "Clears this terminal."


	var command_help := add_command("help", (func(id: String = "") -> void:
		if id:
			var command: Command = find_command(id)
			if command:
				Myth.Terminal.log_quiet(command.get_help_long())
			else:
				Myth.Terminal.log_error("No such command '%s' exists." % id)
		else:
			for command in commands:
				Myth.Terminal.log_quiet(command.get_help_short())
	))
	command_help.description = "Prints info about available commands in this terminal."
	command_help.add_argument(
		"command",
		"Specify a single command to log more information about.",
		true
	)


	var command_quit := add_command("quit", (func() -> void:
		get_tree().quit()
	))
	command_quit.description = "Quits the game."


@onready
var label: RichTextLabel = %log


static var commands: Array[Command]


static func _static_init() -> void:
	commands = []


static func add_command(id, method) -> Command:
	var result := Command.new()
	if id is PackedStringArray or id is Array:
		result.ids = id
	elif id is String:
		result.ids.push_back(id)

	for i in result.ids:
		for j in commands:
			if i in j.ids:
				printerr("A command with the id '%s' already exists." % [
					i
				])
				return

	if method is Callable:
		result.method = method

	commands.push_back(result)
	commands.sort_custom((func(a: Command, b: Command) -> bool:
		return a.ids[0] < b.ids[0]
	))
	return result


static func find_command(id: String) -> Command:
	for command in commands:
		if id in command.ids:
			return command
	return null


static func clear() -> void:
	inst.label.text = ""


static func colorize_text(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [
		color.to_html(),
		text,
	]


static func log(bbcode: String = "") -> void:
	inst.label.append_text(bbcode + "\n")


static func log_color(bbcode: String, color: Color) -> void:
	Myth.Terminal.log(colorize_text(bbcode, color))


static func log_error(bbcode: String) -> void:
	log_color(bbcode, COLOR_ERROR)


static func log_input(bbcode: String) -> void:
	log_color("> " + bbcode, COLOR_INPUT)


static func log_quiet(bbcode: String) -> void:
	Myth.Terminal.log(bbcode)
	# log_color(bbcode, COLOR_QUIET)


static func log_warning(bbcode: String) -> void:
	log_color(bbcode, COLOR_WARNING)


static var execute_in_progress: bool

static func execute(text: String, timeout: float = 10.0):
	var args := text.split(" ", false)
	if args.is_empty():
		return

	var command: Command = find_command(args[0])

	if command == null:
		Myth.Terminal.log_error("No such command '%s' exists." % args[0])
		return

	args.remove_at(0)

	var err : int = await Async.which([command.execute.bind(args), inst.get_tree().create_timer(timeout, true, false, true).timeout])
	match err:
		1: Myth.Terminal.log_error("Command timed out.")


func _ready() -> void:
	window = get_parent()


func _on_line_edit_text_submitted(new_text: String) -> void:
	Myth.Terminal.log()

	if new_text:
		Myth.Terminal.log_input(new_text)
		Myth.Terminal.execute(new_text)


class_name TerminalCommandHost extends Node

static var RX_ARG_PARSE := RegEx.create_from_string(r"(?:([\"'`]{3}|[\"'`])(.*)\1)|(\S+)")

class TerminalCommand extends Object:
	static func get_effective_arguments(callable: Callable, args: Array):
		assert(args.size() - callable.get_unbound_arguments_count() >= 0)
		var result = args.slice(0, args.size() - callable.get_unbound_arguments_count())
		result.append_array(callable.get_bound_arguments())
		return result

	var method : Callable
	var default_arg_count : int
	var description : String
	var hide_terminal : bool

	var name : StringName :
		get: return TerminalCommandHost.registry.find_key(self)
	var help_string : String :
		get: return "%s : %s args%s" % [
			name,
			method.get_argument_count() if default_arg_count == 0 else "%s-%s" % [method.get_argument_count() - default_arg_count, method.get_argument_count()],
			(" : %s" % description) if description else ""
		]

	func _init(__name__: StringName, __method__: Callable, __default_arg_count__: int, __hide_terminal__ : bool, __description__ : String) -> void:
		method = __method__
		default_arg_count = __default_arg_count__
		description = __description__
		hide_terminal = __hide_terminal__

		assert(not TerminalCommandHost.registry.has(__name__), "The TerminalCommand with the name \"%s\" already exists. This will replace the original one." % __name__)
		TerminalCommandHost.registry[__name__] = self

	func invoke(args: Array) -> void:
		if args.size() + default_arg_count < method.get_argument_count():
			TerminalLog.print("Too few arguments for '%s'. Expected at least %s, received %s." % [ name, method.get_argument_count() - default_arg_count, args.size() ], TerminalLog.ERROR)

		var error = await method.callv(args)

		if error == null:
			if hide_terminal:
				TerminalVisibility.inst.active_panel = 0
			return

		if error is Array:
			for e in error:
				TerminalLog.print(str(e), TerminalLog.ERROR)
		else:
			TerminalLog.print(str(error), TerminalLog.ERROR)


static var registry : Dictionary


static func create_command(__name__: StringName, __method__: Callable, __default_arg_count__: int = 0, __hide_terminal__ : bool = true, __description__: String = "") -> void:
	TerminalCommand.new(__name__, __method__, __default_arg_count__, __hide_terminal__, __description__)


func _init() -> void:
	create_command(&"help", command_help, 1, false, "Prints a description of available command(s).")
	create_command(&"cls", TerminalLog.cls, 0, false, "Clears the TerminalLog.")
	create_command(&"quit", command_quit, 0, false, "Quits the game.")


func command_quit():
	get_tree().quit()


func command_help(command_name: StringName = &""):
	if command_name.is_empty():
		for cmd : TerminalCommand in registry.values():
			TerminalLog.print(cmd.help_string, TerminalLog.QUIET)
	elif registry.has(command_name):
		TerminalLog.print(registry[command_name].help_string, TerminalLog.QUIET)
	else:
		return "No such command '%s' exists." % command_name


func receive_invocation(text: String) -> void:
	var arg_parse_matches : Array[RegExMatch] = RX_ARG_PARSE.search_all(text)
	if arg_parse_matches.is_empty(): return

	var command_name : StringName = arg_parse_matches[0].get_string()
	if command_name not in registry:
		TerminalLog.print("No such command '%s' exists." % command_name, TerminalLog.ERROR)
		return

	arg_parse_matches.remove_at(0)
	var args : Array
	for arg_parse_match in arg_parse_matches:
		var arg : Variant = arg_parse_match.get_string(2) + arg_parse_match.get_string(3)

		if arg.to_lower() == "true": arg = true
		elif arg.to_lower() == "false": arg = false
		elif arg.is_valid_int(): arg = int(arg)
		elif arg.is_valid_float(): arg = float(arg)

		args.push_back(arg)

	registry[command_name].invoke(args)

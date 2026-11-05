## Allows you to control [SystemPrefs] via input.
extends Node

static func _static_init() -> void:
	var command_window_mode := Myth.Terminal.add_command([ "windowmode", "wm" ], (func(mode: int = -1) -> void:
		print("mode :: %s" % [ mode ])
		match mode:
			-1:
				toggle_fullscreen()
			0, 1, 2, 3, 4:
				window_mode = mode
			_:
				Myth.Terminal.log_error("Window mode must be between 0 - 4.")
	))
	command_window_mode.description = "Sets the window mode."
	command_window_mode.add_argument(
		"mode",
		"
		\t(None) : toggle between most recent fullscreen/windowed modes
		\t(0) : Windowed
		\t(1) : Minimized
		\t(2) : Maximized
		\t(3) : Fullscreen
		\t(4) : Exclusive Fullscreen",
		true
	)

static var window_mode: Window.Mode:
	get: return SystemPrefs.inst.window_mode
	set(value): SystemPrefs.inst.window_mode = value

static func toggle_fullscreen() -> void:
	if SystemPrefs.inst == null:
		return

	SystemPrefs.inst.is_fullscreen = not SystemPrefs.inst.is_fullscreen

## Defines the initial mode to use in editor runtime.
@export
var initial_mode_editor : Window.Mode = Window.MODE_WINDOWED

@export
var initial_mode_debug : Window.Mode = Window.MODE_FULLSCREEN

@export
var initial_mode_release: Window.Mode = Window.MODE_EXCLUSIVE_FULLSCREEN



func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_POSITION_CHANGED:
			print("The window was moved to %s." % DisplayServer.window_get_position())
			print("New display: %s" % DisplayServer.window_get_current_screen())


func _on_system_prefs_loaded(prefs: Resource) -> void:
	if not is_node_ready():
		await ready
		await get_tree().process_frame


	if prefs is SystemPrefs:
		window_mode = prefs.window_mode
	else:
		if OS.has_feature("editor_runtime"):
			window_mode = initial_mode_editor
		elif OS.has_feature("debug"):
			window_mode = initial_mode_debug
		elif OS.has_feature("release"):
			window_mode = initial_mode_release

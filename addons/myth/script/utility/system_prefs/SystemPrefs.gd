## Defines a list of very commonly used system preferences, typically ones for single-window applications, which differ between systems and are not synced.
@icon("res://addons/myth/script/utility/system_prefs/SystemPrefs.svg")
@tool
class_name SystemPrefs
extends Resource

static var inst: SystemPrefs

static var screen_size: Vector2i:
	get: return DisplayServer.screen_get_size()

static var screen_aspect_ratio: Vector2i:
	get: return screen_size / Myth.gcdi(screen_size.x, screen_size.y)


func _init() -> void:
	pass


func populate(host: Node) -> void:
	inst = self
	tree = host.get_tree()

	if Engine.is_editor_hint():
		return

	for action in input_bindings:
		set_action_in_input_map(action, input_bindings[action])


var tree: SceneTree:
	set(value):
		tree = value
		viewport = tree.root.get_viewport()

		tree.root.mode = window_mode

		viewport.scaling_3d_scale = render_resolution_percent
		viewport.scaling_3d_mode = render_upscaling_mode
		viewport.fsr_sharpness = render_upscaling_sharpness
		viewport.msaa_3d = render_msaa
		RenderingServer.viewport_set_screen_space_aa(viewport.get_viewport_rid(), int(render_ssaa))
		viewport.screen_space_aa = render_ssaa
		viewport.use_taa = render_taa


var viewport: Viewport

#region Graphics
@export_category("Graphics")

@export_storage
var screen_target: int = -1:
	set(value):
		DisplayServer.window_set_current_screen(value, tree.root.get_window_id())

@export_storage
var window_mode: Window.Mode = ProjectSettings.get_setting("display/window/size/mode", ):
	set(value):
		value = clampi(value, 0, 4)
		if window_mode == value:
			return

		window_mode = value

		if tree:
			tree.root.mode = value
			Myth.Terminal.log("Set window mode to %s." % value)

		if value < 3:
			most_recent_windowed_mode = value
		else:
			most_recent_fullscreen_mode = value

		window_mode_changed.emit()
		emit_changed()
signal window_mode_changed

var is_fullscreen: bool:
	get: return window_mode >= 3
	set(value): window_mode = most_recent_fullscreen_mode if value else most_recent_windowed_mode


@export_storage
var most_recent_windowed_mode: Window.Mode

@export_storage
var most_recent_fullscreen_mode: Window.Mode


@export_storage
var window_ui_scale: float = ProjectSettings.get_setting("display/window/stretch/scale"):
	set(value):
		if window_ui_scale == value:
			return

		window_ui_scale = value

		if tree:
			tree.root.content_scale_factor = value

		window_ui_scale_changed.emit()
		emit_changed()
signal window_ui_scale_changed


@export_storage
var display_size : Vector2i:
	set(value):
		display_size = value

		if tree:
			tree.root.size = display_size

		emit_changed()

var display_aspect_ratio: Vector2i:
	get: return display_size / Myth.gcdi(display_size.x, display_size.y)

@export_storage
var render_resolution_percent: float = ProjectSettings.get_setting("rendering/scaling_3d/scale", 1.0):
	set(value):
		if render_resolution_percent == value:
			return

		render_resolution_percent = value

		if viewport:
			viewport.scaling_3d_scale = render_resolution_percent
		# refresh_quality()

		render_resolution_percent_changed.emit()
		emit_changed()
signal render_resolution_percent_changed


@export_storage
var render_upscaling_mode: Viewport.Scaling3DMode = ProjectSettings.get_setting("rendering/scaling_3d/mode"):
	set(value):
		value = clampi(value, 0, Viewport.Scaling3DMode.SCALING_3D_MODE_MAX - 1)

		if render_upscaling_mode == value:
			return

		render_upscaling_mode = value

		if viewport:
			viewport.scaling_3d_mode = value
		# refresh_quality()

		render_upscaling_mode_changed.emit()
		emit_changed()

signal render_upscaling_mode_changed


@export_storage
var render_upscaling_sharpness: float = ProjectSettings.get_setting("rendering/scaling_3d/fsr_sharpness"):
	set(value):
		if render_upscaling_sharpness == value:
			return

		render_upscaling_sharpness = value

		if viewport:
			viewport.fsr_sharpness = value
			print("viewport.fsr_sharpness :: %s" % [ viewport.fsr_sharpness ])
		# refresh_quality()

		render_upscaling_sharpness_changed.emit()
		emit_changed()

signal render_upscaling_sharpness_changed


var render_msaa: Viewport.MSAA = ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"):
	set(value):
		value = clampi(value, 0, Viewport.MSAA_MAX - 1)

		if render_msaa == value:
			return

		render_msaa = value

		if viewport:
			viewport.msaa_3d = value
		# refresh_quality()

		render_msaa_changed.emit()
		emit_changed()
signal render_msaa_changed


@export_storage
var render_ssaa: Viewport.ScreenSpaceAA = ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa"):
	set(value):
		value = clampi(value, 0, Viewport.SCREEN_SPACE_AA_MAX - 1)

		if render_msaa == value:
			return

		render_ssaa = value

		if viewport:
			viewport.screen_space_aa = value
		# refresh_quality()

		render_ssaa_changed.emit()
		emit_changed()
signal render_ssaa_changed


@export_storage
var render_taa: bool = ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa"):
	set(value):
		if render_taa == value:
			return

		render_taa = value

		if viewport:
			viewport.use_taa = value
		# refresh_quality()

		render_taa_changed.emit()
		emit_changed()
signal render_taa_changed


@export_storage
var render_vsync: DisplayServer.VSyncMode = ProjectSettings.get_setting("display/window/vsync/vsync_mode"):
	set(value):
		if render_vsync == value:
			return

		render_vsync = value

		DisplayServer.window_set_vsync_mode(render_vsync)
		# refresh_quality()

		render_vsync_changed.emit()
		emit_changed()
signal render_vsync_changed


func refresh_quality() -> void:
	if viewport == null:
		return

	await RenderingServer.frame_pre_draw

	viewport.scaling_3d_scale = render_resolution_percent

	viewport.msaa_3d = render_msaa

	RenderingServer.viewport_set_screen_space_aa(viewport.get_viewport_rid(), int(render_ssaa))
	viewport.screen_space_aa = render_ssaa

	viewport.use_taa = render_taa

	DisplayServer.window_set_vsync_mode(render_vsync)
#endregion


#region Input

## Stores the user's custom input bindings. This is handled differently from other settings in that it only stores the data. This is because different games will have different actions, but we will always want to store some set of actions.
@export_storage
var input_bindings: Dictionary:
	set(value):
		input_bindings = value

		input_bindings_changed.emit()
		emit_changed()
signal input_bindings_changed


static func set_action_in_input_map(action: StringName, data: Dictionary) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)

	for event: InputEvent in data["events"]:
		if event == null:
			continue

		InputMap.action_add_event(action, event)

	if data.has("deadzone"):
		InputMap.action_set_deadzone(action, data["deadzone"])


#endregion

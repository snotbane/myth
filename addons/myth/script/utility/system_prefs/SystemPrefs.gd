## Defines a list of very commonly used system preferences, typically ones for single-window applications, which differ between systems and are not synced.
@icon("res://addons/myth/script/utility/system_prefs/SystemPrefs.svg")
class_name SystemPrefs
extends Resource

static var inst: SystemPrefs

static var screen_size: Vector2i:
	get: return DisplayServer.screen_get_size()

static var screen_aspect_ratio: Vector2i:
	get: return screen_size / Myth.gcdi(screen_size.x, screen_size.y)


func populate(__tree__: SceneTree) -> void:
	inst = self
	tree = __tree__


var tree: SceneTree:
	set(value):
		tree = value
		viewport = tree.root.get_viewport()

		tree.root.mode = window_mode

		viewport.scaling_3d_scale = render_resolution_percent
		viewport.scaling_3d_mode = render_upscaling_mode
		viewport.fsr_sharpness = render_upscaling_sharpness
		viewport.msaa_3d = render_msaa
		RenderingServer.viewport_set_screen_space_aa(viewport.get_viewport_rid(), render_ssaa)
		viewport.screen_space_aa = render_ssaa
		viewport.use_taa = render_taa


var viewport: Viewport


@export_category("Graphics")

@export
var screen_target: int = -1:
	set(value):
		DisplayServer.window_set_current_screen(value, tree.root.get_window_id())

@export
var window_mode: Window.Mode = ProjectSettings.get_setting("display/window/size/mode"):
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


@export
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


# @export
# var target_resolution: Vector2i = Vector2i(1280, 720):
# 	set(value):
# 		target_resolution = value
# 		emit_changed()

# var target_resolution: Vector2i:
# 	set(value):
# 		if root:
# 			root.get_window().size
# 		pass

@export
var display_size := Vector2i(1280, 720):
	set(value):
		display_size = value

		if tree:
			tree.root.size = display_size

		emit_changed()

var display_aspect_ratio: Vector2i:
	get: return display_size / Myth.gcdi(display_size.x, display_size.y)

@export
var render_resolution_percent: float = ProjectSettings.get_setting("rendering/scaling_3d/scale"):
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


@export
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


@export
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


@export
var render_msaa: int = ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"):
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


@export
var render_ssaa: int = ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa"):
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


@export
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


@export
var render_vsync: int = ProjectSettings.get_setting("display/window/vsync/vsync_mode"):
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

	RenderingServer.viewport_set_screen_space_aa(viewport.get_viewport_rid(), render_ssaa)
	viewport.screen_space_aa = render_ssaa

	viewport.use_taa = render_taa

	DisplayServer.window_set_vsync_mode(render_vsync)

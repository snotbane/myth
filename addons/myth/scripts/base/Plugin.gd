@tool
class_name MythPlugin
extends EditorPlugin

const INPUT_QUIT := &"quit"
const SETTING_INPUT_QUIT := "input/" + INPUT_QUIT


static func add_default_input_binding(binding_name: String, events: Array = [], deadzone := 0.2) -> void:
	if ProjectSettings.get_setting(binding_name) != null: return

	ProjectSettings.set_setting(binding_name, {
		"deadzone": deadzone,
		"events": events,
	})


func _enable_plugin() -> void:
	if not ProjectSettings.has_setting(MouseModeUser.PROJECT_SETTING_HINT[&"name"]):
		ProjectSettings.set_setting(MouseModeUser.PROJECT_SETTING_HINT[&"name"], Input.MOUSE_MODE_VISIBLE)
		ProjectSettings.add_property_info(MouseModeUser.PROJECT_SETTING_HINT)
		ProjectSettings.set_initial_value(MouseModeUser.PROJECT_SETTING_HINT[&"name"], Input.MOUSE_MODE_VISIBLE)
		ProjectSettings.save()

	configure_input()


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	_enable_screenshots()


func _exit_tree() -> void:
	_disable_screenshots()


func configure_input() -> void:
	var quit_0 := InputEventKey.new()
	quit_0.physical_keycode = KEY_Q
	quit_0.ctrl_pressed = true
	MythPlugin.add_default_input_binding(SETTING_INPUT_QUIT, [
		quit_0,
	])

	var fullscreen_0 := InputEventKey.new()
	fullscreen_0.physical_keycode = KEY_F11
	var fullscreen_1 := InputEventKey.new()
	fullscreen_1.physical_keycode = KEY_F
	fullscreen_1.ctrl_pressed = true
	fullscreen_1.command_or_control_autoremap = true
	MythPlugin.add_default_input_binding(WindowModeSelector.SETTING_INPUT_FULLSCREEN, [
		fullscreen_0,
		fullscreen_1,
	])


#region Screenshots

static var scene_screenshot_file_name: String:
	get: return "scene_screenshot_" + Time.get_datetime_string_from_system().remove_char(ord(":"))


func _enable_screenshots() -> void:
	EditorInterface.get_command_palette().add_command(
		"Take Screenshot from Selected Camera",
		"myth/screenshot/from_cameras",
		func() -> void:
			var root := get_editor_interface().get_edited_scene_root()

			var selected_cameras: Array = get_editor_interface().get_selection().get_selected_nodes().filter(func(node: Node) -> bool:
				return node is Camera3D or node is Camera2D
			)

			if selected_cameras.is_empty():
				take_scene_screenshot_from(get_editor_interface().get_edited_scene_root(), null, Vector2i(1920, 1080))
				return

			take_scene_screenshot_from(get_editor_interface().get_edited_scene_root(), selected_cameras[0], Vector2i(1920, 1080))
	)

	EditorInterface.get_command_palette().add_command(
		"Take Screenshot from Current Camera",
		"myth/screenshot/from_scene",
		func() -> void:
			take_scene_screenshot_from(get_editor_interface().get_edited_scene_root(), null, Vector2i(1920, 1080))
	)

	EditorInterface.get_command_palette().add_command(
		"Take Screenshot from View",
		"myth/screenshot/from_view",
		func() -> void:
			var root := get_editor_interface().get_edited_scene_root()
			var camera: Node

			if root is Node3D:
				camera = get_editor_interface().get_editor_viewport_3d().get_camera_3d()
			if root is Node2D:
				camera = get_editor_interface().get_editor_viewport_2d().get_camera_2d()

			take_scene_screenshot_from(root, camera.duplicate(), Vector2i(1920, 1080))
	)


func _disable_screenshots() -> void:
	EditorInterface.get_command_palette().remove_command("myth/screenshot/from_cameras")
	EditorInterface.get_command_palette().remove_command("myth/screenshot/from_scene")
	EditorInterface.get_command_palette().remove_command("myth/screenshot/from_view")


func take_scene_screenshot_from(scene_root: Node, camera: Node, size: Vector2i, idx := -1):
	var scene_orphan := scene_root.duplicate(DUPLICATE_DEFAULT & DUPLICATE_INTERNAL_STATE)

	if camera:
		if scene_root.is_ancestor_of(camera):
			camera = scene_orphan.get_node(scene_root.get_path_to(camera))

		elif camera.get_parent() == null:
			scene_orphan.add_child(camera)

		camera.make_current()

	await take_scene_screenshot(scene_orphan, size, scene_screenshot_file_name + (("_%s" % idx) if idx >= 0 else ""))


func take_scene_screenshot(scene_orphan: Node, size: Vector2i, save_name: String = scene_screenshot_file_name):
	var sub_viewport := Myth.create_subviewport_from_project_settings()
	sub_viewport.own_world_3d = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	sub_viewport.size = size

	get_tree().root.add_child(sub_viewport)
	sub_viewport.add_child(scene_orphan)

	await get_tree().process_frame
	await get_tree().process_frame

	save_viewport_to_image.call_deferred(sub_viewport, save_name)
	sub_viewport.remove_child(scene_orphan)
	sub_viewport.queue_free()


static func save_viewport_to_image(viewport: Viewport, save_name: String = scene_screenshot_file_name) -> void:
	if viewport is not Viewport:
		printerr("Couldn't save image, node '%s' is not a Viewport." % viewport)

	var image: Image = viewport.get_texture().get_image()

	var dir := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	var path := dir.path_join(save_name + ".png")

	var err := image.save_png(path)
	if err:
		printerr("Failed saving screenshot to: %s: %s" % [path, error_string(err)])
	else:
		print("Saved screenshot to: %s" % path)
		OS.shell_open(path)

#endregion

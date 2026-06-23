## A menu bar which can be initialized by implementing [member _create_data]. See just below in this script for an example of what it should look like.

##	func _create_data() -> Array[Dictionary]:
##		return {
##			"title": "PopupMenu title",
##			"items": [
##				{
##					"event": (func() -> void:	## This is called when the item is clicked.
##						print("Hello, world!")
##						),
##					"id": 0,
##					"input": (func() -> InputEventKey:	## This should create a valid InputEventKey.
##						var result := InputEventKey.new()
##						result.keycode = KEY_WHATEVER
##						result.command_or_control_autoremap = true
##						return true
##						),
##					"macos_id": 0 ## Optional. Specifies that the menu item should appear in a different location on the Mac desktop platform.
##					"macos_slot": MACOS_APPLE ## Optional.
##					"title": "PopupMenu item title",
##				},
##			],
##		}

@abstract
class_name AuxiliaryMenuBar
extends MenuBar

enum {
	MACOS_MAIN,
	MACOS_DOCK,
	MACOS_APPLE,
	MACOS_WINDOW,
	MACOS_HELP,
	MACOS_MAX
}
static var MACOS_MENU_NAMES: PackedStringArray = [
	"_main",
	"_dock",
	"_apple",
	"_window",
	"_help",
]
static func get_macos_menu_name(idx: int) -> String:
	assert(idx >= 0 and idx < MACOS_MAX, "Mac OS menu slot must exist. See DisplayServer.global_menu_add_item()")
	return MACOS_MENU_NAMES[idx]


static var inst: AuxiliaryMenuBar


static func register_window(window: Window) -> void:
	if inst == null: return

	if window.get_window_id() == DisplayServer.MAIN_WINDOW_ID: return

	window.set_meta(&"ever_shown", window.visible)
	if not window.visible:
		window.visibility_changed.connect(func() -> void:
			window.set_meta(&"ever_shown", true)
		, CONNECT_ONE_SHOT
		)

	window.window_input.connect(inst.auxiliary_window_input)


var data: Array[Dictionary]
var menu_events: Dictionary[PopupMenu, Dictionary]


@abstract func _create_data() -> Array[Dictionary]


func _ready() -> void:
	inst = self

	for popup_menu in menu_events:
		popup_menu.queue_free()
	menu_events.clear()

	data = _create_data()

	for menu in data:
		for item in menu.items:
			item.input = item.input.call()

		add_menu(menu)


func add_menu(data: Dictionary) -> void:
	var menu := PopupMenu.new()
	menu.title = data.title

	for item in data.items:
		add_menu_item(menu, item)

	menu.id_pressed.connect(menu_callback.bind(menu))

	add_child(menu)


func add_menu_item(menu: PopupMenu, data: Dictionary) -> void:
	if data.has("macos_id") and OS.has_feature("macos"):
		var method := menu.id_pressed.emit.bind(data.id).unbind(1)
		DisplayServer.global_menu_add_item(
			AuxiliaryMenuBar.get_macos_menu_name(data.macos_slot),
			data.title,
			method,
			method,
			null,
			data.input.get_keycode_with_modifiers(),
			data.macos_id
		)
	else:
		menu.add_item(
			data.title,
			data.id,
			data.input.get_keycode_with_modifiers()
		)

	if not menu_events.has(menu):
		menu_events[menu] = {}

	menu_events[menu][data.id] = data.event


func menu_callback(id: int, menu: PopupMenu) -> void:
	menu_events[menu][id].call()


func auxiliary_window_input(event: InputEvent) -> void:
	if event is not InputEventKey: return
	if not event.is_pressed(): return

	for menu in menu_events:
		for idx in menu.item_count:
			if event.get_keycode_with_modifiers() != menu.get_item_accelerator(idx): continue

			menu_events[menu][menu.get_item_id(idx)].call()
			# menu.id_pressed.emit(menu.get_item_id(idx))
			return

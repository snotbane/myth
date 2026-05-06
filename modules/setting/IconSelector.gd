@tool class_name IconSelector extends Button

const BUTTON_MINIMUM_SIZE_DEFAULT := Vector2(32.0, 32.0)

signal icon_changed(new_icon: Texture2D)

var popup_panel: PopupPanel
var scroll_container: ScrollContainer
var grid: GridContainer


@export var collection: ResourceCollection:
	set(value):
		collection = value

		Myth.clear_children(grid)
		if collection == null: return

		for i in collection.resources.size():
			var texture: Texture2D = collection.resources[i]
			if texture == null: continue

			var button := Button.new()
			button.icon = texture
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_FILL
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_FILL
			button.custom_minimum_size = button_size_min
			button.pressed.connect(_grid_button_pressed.bind(i))
			grid.add_child(button)


var collection_size: int:
	get: return collection.resources.size() if collection else 0


@export var button_size_min := BUTTON_MINIMUM_SIZE_DEFAULT:
	set(value):
		button_size_min = value

		custom_minimum_size = value
		_refresh_scroll_container_size()

		for child: Button in grid.get_children():
			child.custom_minimum_size = button_size_min

var _grid_rows: int = 5
@export var grid_size := Vector2i(5, 5):
	get: return Vector2i(
		grid.columns,
		_grid_rows
	)
	set(value):
		value = value.maxi(1)
		if grid_size == value: return

		grid.columns = value.x
		_grid_rows = value.y

		_refresh_scroll_container_size()


func _init() -> void:
	self.custom_minimum_size = BUTTON_MINIMUM_SIZE_DEFAULT
	self.expand_icon = true
	self.icon_alignment = HORIZONTAL_ALIGNMENT_FILL
	self.vertical_icon_alignment = VERTICAL_ALIGNMENT_FILL
	self.toggle_mode = true

	popup_panel = PopupPanel.new()
	popup_panel.transient = true
	popup_panel.visibility_changed.connect(func() -> void:
		if not popup_panel.visible: return

		popup_panel.content_scale_factor = get_window().content_scale_factor
	)
	self.add_child(popup_panel, false, INTERNAL_MODE_BACK)

	scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = BUTTON_MINIMUM_SIZE_DEFAULT
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup_panel.add_child(scroll_container)

	grid = GridContainer.new()
	grid.columns = 5
	scroll_container.add_child(grid)

	popup_panel.visibility_changed.connect(func() -> void:
		set_pressed_no_signal(popup_panel.visible)
	)


func _toggled(toggled_on: bool) -> void:
	popup_panel.visible = toggled_on
	popup_panel.position = global_position

	self_modulate = Color.TRANSPARENT if toggled_on else Color.WHITE


func _grid_button_pressed(idx: int) -> void:
	popup_panel.hide()
	icon = collection.resources[idx]
	icon_changed.emit(icon)


func _refresh_scroll_container_size() -> void:
	var __collection_size__ := collection_size
	scroll_container.custom_minimum_size = button_size_min * Vector2(
		mini(grid_size.x, maxi(__collection_size__, 1)),
		mini(grid_size.y, (__collection_size__ / grid_size.x) + 1)
	)
	scroll_container.custom_minimum_size = button_size_min * Vector2(grid_size)

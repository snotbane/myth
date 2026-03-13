
@tool class_name SettingImage extends Setting

const BUTTON_MINIMUM_SIZE_DEFAULT := Vector2(32.0, 32.0)

var image_label : Label
var image_button : Button

var image_panel : PanelContainer
var image_scroll_container : ScrollContainer
var image_grid : GridContainer


func _get_value() -> Variant:
	return image_button.icon


func _set_value(new_value: Variant) -> void:
	image_button.icon = new_value


func _init() -> void:
	super._init()

	image_label = Label.new()
	image_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(image_label)

	image_button = Button.new()
	image_button.custom_minimum_size = BUTTON_MINIMUM_SIZE_DEFAULT
	image_button.expand_icon = true
	image_button.icon_alignment = HORIZONTAL_ALIGNMENT_FILL
	image_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_FILL
	image_button.toggle_mode = true
	image_button.z_index = +2
	hbox_panel.add_child(image_button)

	image_panel = PanelContainer.new()
	image_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	image_panel.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	image_panel.z_index = -1
	image_panel.visible = false
	image_button.add_child(image_panel)

	image_scroll_container = ScrollContainer.new()
	image_scroll_container.custom_minimum_size.y = BUTTON_MINIMUM_SIZE_DEFAULT.y * 5
	image_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	image_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	image_panel.add_child(image_scroll_container)

	image_grid = GridContainer.new()
	image_grid.columns = 5
	image_scroll_container.add_child(image_grid)

	image_button.toggled.connect(_image_button_toggled)
	image_panel.visibility_changed.connect(_image_panel_visibility_changed)


@export var collection : ResourceCollection

var _image : Texture2D
@export_storage var image : Texture2D :
	get: return _image
	set(value):
		_image = value
		image_button.icon = value

		_value_changed()


var _button_size_min := BUTTON_MINIMUM_SIZE_DEFAULT
@export var button_size_min := BUTTON_MINIMUM_SIZE_DEFAULT :
	get: return _button_size_min
	set(value):
		_button_size_min = value

		image_button.custom_minimum_size = _button_size_min
		image_scroll_container.custom_minimum_size.y = button_size_min.y * _grid_rows

		for child: Button in image_grid.get_children():
			child.custom_minimum_size = _button_size_min

@export var grid_columns : int = 5 :
	get: return image_grid.columns
	set(value): image_grid.columns = value

var _grid_rows : int = 5
@export var grid_rows : int = 5 :
	get: return _grid_rows
	set(value):
		_grid_rows = value
		image_scroll_container.custom_minimum_size.y = button_size_min.y * value

func _ready() -> void:
	refresh()

func refresh() -> void:
	if collection:

		for i in collection.resources.size():
			var texture : Texture2D = collection.resources[i]
			if texture == null: continue

			var button := Button.new()
			button.icon = texture
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_FILL
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_FILL
			button.custom_minimum_size = _button_size_min
			button.pressed.connect(_image_grid_button_pressed.bind(i))
			image_grid.add_child(button)


func _image_button_toggled(new_value: bool) -> void:
	image_panel.visible = new_value
	image_panel.global_position = image_button.global_position

	image_button.icon = PlaceholderTexture2D.new() if new_value else image
	image_button.self_modulate = Color.TRANSPARENT if new_value else Color.WHITE
	# image_panel.position = image_button.get_screen_position()


func _image_panel_visibility_changed() -> void:
	image_button.set_pressed_no_signal(image_panel.visible)


func _image_grid_button_pressed(idx: int) -> void:
	image = collection.resources[idx]
	image_panel.hide()



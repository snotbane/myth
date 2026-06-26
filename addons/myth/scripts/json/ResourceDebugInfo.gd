## Helper node that displays information about a specific [ResourceComponent], or a sibling or ancestor's [ResourceComponent].
class_name ResourceDebugInfo extends PanelContainer

## The [ResourceComponent] which we will watch and update. If unassigned, we will look for siblings, ancestors, and ancestor's siblings to find a [ResourceComponent] to fallback to.
@export var resource_node: ResourceComponent:
	set(value):
		if resource_node:
			resource_node.resource_changed.disconnect(_resource_changed)

		resource_node = value if value else _child_resource_node

		resource_node.resource_changed.connect(_resource_changed)


## If enabled, we will fit to the size of the text content. Otherwise, vertical scrolling will be enabled and we will fit to our own [member custom_minimum_size].
@export var fit_content: bool = true:
	set(value):
		fit_content = value
		_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if value else ScrollContainer.SCROLL_MODE_AUTO


var _child_resource_node: ResourceComponent
var _scroll_container: ScrollContainer
var _margin_container: MarginContainer
var _rich_text_label: RichTextLabel


func _init() -> void:
	_child_resource_node = ResourceComponent.new()
	_child_resource_node.fallback_type = 1
	add_child(_child_resource_node)

	var feature_node := FeatureDependency.new()
	feature_node.features = ["editor_hint", "editor_runtime"]
	add_child(feature_node)

	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll_container)

	_margin_container = MarginContainer.new()
	_margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margin_container.add_theme_constant_override(&"margin_left", 8)
	_margin_container.add_theme_constant_override(&"margin_top", 8)
	_margin_container.add_theme_constant_override(&"margin_right", 8)
	_margin_container.add_theme_constant_override(&"margin_bottom", 8)
	_scroll_container.add_child(_margin_container)

	var font := SystemFont.new()
	font.font_names = ["Noto Sans Mono", "Monospace"]

	_rich_text_label = RichTextLabel.new()
	_rich_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rich_text_label.fit_content = true
	_rich_text_label.scroll_active = false
	_rich_text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_rich_text_label.context_menu_enabled = true
	_rich_text_label.selection_enabled = true
	_rich_text_label.deselect_on_focus_loss_enabled = false
	_rich_text_label.add_theme_font_override(&"mono_font", font)
	_margin_container.add_child(_rich_text_label)


func _ready() -> void:
	resource_node = resource_node
	fit_content = fit_content

	_resource_changed()


func _resource_changed() -> void:
	_rich_text_label.clear()
	_rich_text_label.push_mono()

	if resource_node.resource == null:
		_rich_text_label.push_color(Color.INDIAN_RED)
		_rich_text_label.append_text("Resource info cannot be retrieved; `resource` is null.")
	else:
		_rich_text_label.append_text(
			("\"%s\": " % resource_node.resource.file_path)
			if resource_node.resource is JsonResource else
			("%s: " % str(resource_node.resource))
		)
		_rich_text_label.append_text(JSON.stringify(Serialization.serialize(resource_node.resource), "\t", true))

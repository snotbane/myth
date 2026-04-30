## Helper node that displays information about a specific [ResourceNode], or a sibling or ancestor's [ResourceNode].
class_name ResourceDebugInfo extends PanelContainer

@export var resource_node: ResourceNode

@export var expand_to_text_size: bool = true:
	set(value):
		expand_to_text_size = value
		_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if value else ScrollContainer.SCROLL_MODE_AUTO

var _rich_text_label: RichTextLabel
var _scroll_container: ScrollContainer
var _margin_container: MarginContainer
var _child_resource_node: ResourceNode

func _init() -> void:
	_child_resource_node = ResourceNode.new()
	_child_resource_node.fallback_type = 1
	add_child(_child_resource_node)

	var feature_node := FeatureDependentNode.new()
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
	expand_to_text_size = expand_to_text_size

	if resource_node == null:
		resource_node = _child_resource_node

	resource_node.resource_changed.connect(_resource_changed)
	_resource_changed()


func _resource_changed() -> void:
	_rich_text_label.clear()
	_rich_text_label.push_mono()

	_rich_text_label.append_text(
		("\"%s\": " % resource_node.resource.file_path_absolute)
		if resource_node.resource is JsonResource else
		("%s: " % resource_node.resource.to_string())
	)
	_rich_text_label.append_text(JSON.stringify(JsonResource.serialize(resource_node.resource), "\t", true))

## Filters the children of a [member target] node according to a custom [member _filter] method. Must be the child of a [LineEdit], [TextEdit], or similar.
class_name StringFilterComponent extends Component

## The [Node] whose children should be filtered. If this is an [ArrayComponent], the [member ArrayComponent.elements] will be filtered and applied to their associated children.
@export var target: Node:
	set(value):
		if not is_node_ready():
			await ready

		filter_target(String())

		target = value

		filter_target(parent.text)


## If enabled, this will ensure all children are visible if the filter text is empty. Otherwise, all children will be invisible if the filter text is empty.
@export var show_all_if_empty: bool = true:
	set(value):
		show_all_if_empty = value
		filter_target(parent.text)


func filter_target(text: String) -> void:
	if target is ArrayComponent:
		target.filter_elements(filter.bind(text))
	elif target != null:
		for child in target.get_children():
			if child.get(&"visible") == null: continue
			child.visible = filter(text, child)


func filter(text: String, value) -> bool:
	if not enabled: return true
	if text.is_empty(): return show_all_if_empty

	return _filter(text, value)

## Custom method for filtering values. The default method filters by returning true if `str(value)` contains [member text].
func _filter(text: String, value) -> bool:
	return str(value).contains(text)


func _ready() -> void:
	super._ready()

	assert(parent.get(&"text") != null, "Filter parent (%s) must have a property `text` ." % parent)
	assert(parent.has_signal(&"text_changed"), "Filter parent (%s) must have a signal `text_changed`." % parent)

	parent.text_changed.connect(filter_target)

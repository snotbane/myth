## [Component] that does something based on the current OS features.  See [member OS.has_feature] and [url=https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html]Feature Tags[/url] docs. This is evaluated and processed on [member ready], after which this Node should be destroyed. If not [member enabled], this node is still destroyed.
@abstract
@icon("res://addons/myth/script/component/feature/FeatureComponent.svg")
class_name FeatureComponent
extends Component

enum {
	ANY_PRESENT,
	ALL_PRESENT,
	NANY_PRESENT,
	NONE_PRESENT,
}


## Determines if this [Component]'s parent should be active
@export_enum("Any present", "All present", "Any not present", "All not present")
var active_when: int = ANY_PRESENT

## This determines which action to perform on [member parent], if the feature criteria are not met.
@export_enum("Queue Free", "Hide", "Do Nothing")
var inactive_action: int = 0


func _activate(active: bool) -> void:
	match inactive_action:
		0 when not active:
			parent.queue_free()
		1:
			assert(parent.get(&"visible") is bool, "The parent must have a [visible: bool] property.")
			parent.visible = active


func _ready() -> void:
	if enabled and _features_are_valid():
		_activate(_features_are_active())

	queue_free()


@abstract
func _features_are_valid() -> bool


@abstract
func _features_are_active() -> bool

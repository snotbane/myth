## Ensures that the parent [Node] only exists when certain engine features are present. See [member OS.has_feature] and [url=https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html]Feature Tags[/url] docs. This is evaluated and processed on [member ready], after which this Node is always destroyed.
class_name FeatureDependency
extends Component

## This determines which action to perform on [member parent], if the criteria is NOT met. (If the criteria is met, nothing will happen.)
@export_enum("Queue Free", "Hide") var discard_action: int = 0

## Determines if this node should be kept, if the contents of [member features] match this rule.
@export_enum("Any features present", "All features present", "No features present") var retain_when: int = 0

## List of features to check for. See [url=https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html]the feature tags documentation[/url] for a list of viable values. If this list is empty, this node will not be modified.
@export var features: PackedStringArray


func _ready() -> void:
	if not enabled or features.is_empty():
		queue_free()
		return

	var should_retain: bool = retain_when != 0
	for feature in features:
		if feature.is_empty(): continue
		if OS.has_feature(feature):
			match retain_when:
				0: should_retain = true; break
				1: continue
				2: should_retain = false; break
		else:
			match retain_when:
				1: should_retain = false; break

	match discard_action:
		0:
			(self if should_retain else parent).queue_free()
		1:
			assert(parent.get(&"visible") is bool, "The parent must have a [visible: bool] property.")
			parent.visible = should_retain
			queue_free()

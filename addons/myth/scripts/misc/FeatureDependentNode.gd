## This node (or its parent, if desired) will only exist (or be visible) if certain feature tags are present.
class_name FeatureDependentNode extends Node

## If enabled, this node's parent will be affected AND this node will be deleted after [member _ready], regardless of the result.
@export var affect_parent: bool = true

## If enabled, this node will not be destroyed but it will be kept and made invisible. Only works for nodes that have the [member visible] property.
@export var keep_invisible: bool = false

## Determines if this node should be kept, if the feature tags match this rule.
@export_enum("Any present", "All present", "None present") var keep_when: int = ANY
enum {ANY, ALL, NONE}

## List of features to check for. See [url=https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html]the feature tags documentation[/url] for a list of viable values. If this list is empty, this node will not be modified.
@export var features: PackedStringArray

var affected_node: Node:
	get: return get_parent() if affect_parent else self

func _ready() -> void:
	if features.is_empty(): return

	var should_keep: bool = keep_when != ANY
	for feature in features:
		if OS.has_feature(feature):
			match keep_when:
				ANY: should_keep = true; break
				ALL: continue
				NONE: should_keep = false; break
		else:
			match keep_when:
				ALL: should_keep = false; break

	if keep_invisible:
		if affected_node.get(&"visible") != null:
			affected_node.visible = should_keep
	elif not should_keep:
		affected_node.queue_free()

	if affect_parent: self.queue_free()

## Removes or hides the parent [Node], depending on the current OS features.
@icon("res://addons/myth/script/component/feature/FeatureDependency.svg")
class_name FeatureDependency
extends FeatureComponent


## List of features to check for. See [url=https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html]the feature tags documentation[/url] for a list of viable values. If this list is empty, this node will not be modified.
@export
var features: PackedStringArray


func _features_are_valid() -> bool:
	return not features.is_empty()


func _features_are_active() -> bool:
	for feature in features:
		if feature.is_empty() or not OS.has_feature(feature): continue

		match active_when:
			ANY_PRESENT: return true
			ALL_PRESENT, NANY_PRESENT: continue
			NONE_PRESENT: return false

	return active_when & ALL_PRESENT # or NONE_PRESENT

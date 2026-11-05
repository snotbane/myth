@icon("res://addons/myth/script/component/feature/FeatureDependency.svg")
class_name ProjectSettingDependency
extends FeatureComponent


@export
var settings: Dictionary[String, Variant] = {}


func _features_are_valid() -> bool:
	return not settings.is_empty()


func _features_are_active() -> bool:
	for setting in settings:
		if setting.is_empty() or ProjectSettings.get_setting(setting) != settings[setting]: continue

		match active_when:
			ANY_PRESENT: return true
			ALL_PRESENT, NANY_PRESENT: continue
			NONE_PRESENT: return false

	return active_when & ALL_PRESENT # or NONE_PRESENT

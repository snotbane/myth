class_name WindowFocusAudioBusMuter extends CheckButton

@export var bus: int = 0

@export_group("Tween", "tween_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var tween_enabled: bool = true:
	set(value): tween_enabled = value

@export_range(0.0, 1.0, 0.001, "or_greater") var tween_duration: float = 0.1

@export var tween_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var tween_trans: Tween.TransitionType = Tween.TRANS_CUBIC

var volume_linear: float:
	get: return AudioServer.get_bus_volume_linear(bus)
	set(value): AudioServer.set_bus_volume_linear(bus, value)


var focused: bool:
	set(value):
		focused = value

		if not button_pressed: return

		if tween_enabled:
			var tween := create_tween()
			tween.tween_property(self ,
				^"volume_linear",
				1.0 if focused else 0.0,
				tween_duration
			)
			tween.set_ease(tween_ease)
			tween.set_trans(tween_trans)
			tween.set_ignore_time_scale(true)

		else:
			AudioServer.set_bus_mute(bus, focused)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			focused = true

		NOTIFICATION_APPLICATION_FOCUS_OUT:
			focused = false

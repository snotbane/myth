## An audio player which can play many sounds using a [AudioStreamPolyphonic]. Primarily for use with [PhysicsMaterial]s but can use any [Object]. The default value of [member stream] will be set as the fallback stream, which will be played if a key or supply does not exist.
class_name KeyedAudioStreamPlayer3D
extends AudioStreamPlayer3D

@export
var fallbacks : Dictionary[StringName, AudioStream]

var playback : AudioStreamPlaybackPolyphonic

var supplier: Object

var last_used_key: StringName


var stream_fallback: AudioStream


func _ready() -> void:
	stream_fallback = stream

	stream = AudioStreamPolyphonic.new()
	stream.polyphony = max_polyphony

	play()
	playback = get_stream_playback()


func set_supplier(object: Object) -> void:
	supplier = object


func play_key(key: StringName, __volume_db__ := volume_db, __pitch_scale__ := pitch_scale, __playback_type__ := playback_type, __bus__ := bus) -> void:
	last_used_key = key

	var supply_stream : AudioStream = supplier.get(key) if supplier else fallbacks.get(key, stream_fallback)

	if supply_stream == null:
		return

	playback.play_stream(supply_stream, 0.0, __volume_db__, __pitch_scale__, __playback_type__, __bus__)

func play_last_key(__volume_db__ := volume_db, __pitch_scale__ := pitch_scale, __playback_type__ := playback_type, __bus__ := bus) -> void:
	play_key(last_used_key, __volume_db__, __pitch_scale__, __playback_type__, __bus__)

func play_fallback(__volume_db__ := volume_db, __pitch_scale__ := pitch_scale, __playback_type__ := playback_type, __bus__ := bus) -> void:
	if stream_fallback == null:
		return

	playback.play_stream(stream_fallback, 0.0, __volume_db__, __pitch_scale__, __playback_type__, __bus__)

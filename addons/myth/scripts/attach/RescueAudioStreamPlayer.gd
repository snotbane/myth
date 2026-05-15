## Special [RescueAttachment] intended for use with [AudioStreamPlayer]s. If not playing, this [Node] will instantly delete. Otherwise, it will be rescued until the audio is finished playing.
extends RescueAttachment

func _rescue() -> void:
	post_rescue.call_deferred()

func post_rescue() -> void:
	if node.playing:
		await node.finished

	node.queue_free()

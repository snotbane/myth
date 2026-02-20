
class_name TypewriterTextEffect extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.env.has(&"typewriter"): return true

	var typewriter : Typewriter = instance_from_id(char_fx.env[&"typewriter"])
	var duration_visible : float = typewriter.time_elapsed - typewriter.time_per_char[char_fx.relative_index]
	return _process_custom_fx_timed(char_fx, typewriter, duration_visible)


func _process_custom_fx_timed(char_fx: CharFXTransform, typewriter: Typewriter, duration_visible: float) -> bool:
	return true
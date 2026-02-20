
class_name TypewriterTextEffect extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.env.has(Typewriter.ENV_ID): return true

	var typewriter : Typewriter = instance_from_id(char_fx.env[Typewriter.ENV_ID])
	var duration_visible : float = maxf(0.0, typewriter.time_elapsed - typewriter.time_per_char[char_fx.relative_index])
	return _process_custom_fx_timed(char_fx, typewriter, duration_visible)


func _process_custom_fx_timed(char_fx: CharFXTransform, typewriter: Typewriter, duration_visible: float) -> bool:
	return true
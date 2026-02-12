shader_type spatial;
render_mode unshaded;

instance uniform vec4 color : source_color = vec4(1.0);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

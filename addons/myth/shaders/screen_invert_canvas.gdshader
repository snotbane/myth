shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D screen_texture : hint_screen_texture;
uniform bool grayscale = true;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;

	if (grayscale) {
		vec3 c = vec3(color.xyz);
		float max1 = max(c.r, c.g);
		float max2 = max(max1, c.b);
		color = vec3(max2, max2, max2);
	}
	
	COLOR = vec4(1.0 - color, 1.0);
}

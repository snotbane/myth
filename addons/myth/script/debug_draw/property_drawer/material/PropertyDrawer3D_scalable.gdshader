shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 fixed_size_per_axis = vec3(1);

instance uniform vec3 color = vec3(1);
instance uniform bool fixed_size = true;
instance uniform float size = 1.0;

void vertex() {
	float scale = 1.0;
	if (fixed_size) {
		scale = -distance(NODE_POSITION_WORLD, CAMERA_POSITION_WORLD) / PROJECTION_MATRIX[1][1];
	}
	VERTEX *= mix(vec3(1), vec3(scale * size), fixed_size_per_axis);
}

void fragment() {
	ALBEDO = COLOR.rgb * color;
	// Called for every pixel the material is visible on.
}
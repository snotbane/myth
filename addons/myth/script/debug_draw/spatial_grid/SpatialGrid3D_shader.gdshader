shader_type spatial;
render_mode depth_test_disabled, depth_draw_always, cull_front, skip_vertex_transform;

const float MARCH_THRESHOLD = 0.001;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

uniform int march_precision = 16;

instance uniform vec4 dot_color : source_color = vec4(vec3(0.333), 1.0);
instance uniform float dot_size = 0.1;
instance uniform float dot_spacing = 8.0;
instance uniform float dot_range = 40.0;


float sdf_sphere(vec3 p, float r) {
    return length(p) - r;
}

void fragment() { 
	vec3 ray_origin = CAMERA_POSITION_WORLD;

    vec2 ndc = SCREEN_UV * 2.0 - 1.0; // NDC [-1,1]
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0, 1.0);
    vec3 ray_direction = normalize((INV_VIEW_MATRIX * vec4(view.xyz, 0.0)).xyz);

	float scene_depth_percent = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float scene_depth = mix(dot_range, 0.0, scene_depth_percent);
	
    // 3. Raymarch
    float t = 0.0;
	bool render = false;
    for (int i = 0; i < march_precision; i++) {
        vec3 p = ray_origin + ray_direction * t;
        vec3 nearest_center = round(p / dot_spacing) * dot_spacing;
        float d = sdf_sphere(p - nearest_center, dot_size);
		
		if (sdf_sphere(ray_origin - nearest_center, dot_size) < 0.0) {
			discard;
			break;
		}
		
        if (d < MARCH_THRESHOLD) {
			NORMAL = (VIEW_MATRIX * vec4(CAMERA_POSITION_WORLD + p - nearest_center, 1.0)).xyz / dot_size;
            ALBEDO = dot_color.rgb;
			ALPHA = dot_color.a;
            render = true;
        }
		
        t += d;
        if (t > dot_range) discard;
		if (t > scene_depth) break;
    }
	if (!render) {
		discard;
	}
}
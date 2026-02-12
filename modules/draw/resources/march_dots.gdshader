shader_type spatial;
render_mode depth_test_disabled, depth_draw_always, skip_vertex_transform;

const float MARCH_THRESHOLD = 0.001;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

uniform int march_precision = 16;
instance uniform vec3 color : source_color = vec3(0.333);
instance uniform float radius = 0.01;
instance uniform float spacing = 1.0;
instance uniform float range = 10.0;

float sdf_sphere(vec3 p, float r) {
    return length(p) - r;
}

void fragment() { 
	float scene_depth_percent = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float scene_depth = (PROJECTION_MATRIX[3][2] / (scene_depth_percent + PROJECTION_MATRIX[2][2]));
	
	// 1. Camera origin (world space)
    vec3 ro = CAMERA_POSITION_WORLD;

    // 2. Ray direction (world space)
    vec2 ndc = (FRAGCOORD.xy / VIEWPORT_SIZE) * 2.0 - 1.0; // NDC [-1,1]
    vec4 clip = vec4(ndc, 1.0, 1.0);
    vec4 view = INV_PROJECTION_MATRIX * clip;
    view /= view.w;
    vec3 rd = normalize((INV_VIEW_MATRIX * vec4(view.xyz, 0.0)).xyz);

    // 3. Raymarch
    float t = 0.0;
	bool render = false;
    for (int i = 0; i < march_precision; i++) {
        vec3 p = ro + rd * t;
        vec3 nearest = round(p / spacing) * spacing;
        float d = sdf_sphere(p - nearest, radius);
		
		if (sdf_sphere(ro - nearest, radius) < 0.0) {
			discard;
			break;
		}
		
        if (d < MARCH_THRESHOLD) {
			vec3 camera_direction = abs(CAMERA_DIRECTION_WORLD);
            NORMAL = normalize(p - nearest);
            ALBEDO = color;
            render = true;
        }
		
        t += d;
        if (t > range) discard;
		if (t > scene_depth) break;
    }
	if (!render) {
		discard;
	}
}

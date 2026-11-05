shader_type canvas_item;
//render_mode skip_vertex_transform;

instance uniform vec4 dot_color : source_color = vec4(vec3(0.2), 1.0);
instance uniform float dot_size = 5.0;
instance uniform float dot_spacing = 128.0;
instance uniform vec2 camera_position_world;
instance uniform float camera_rotation_world;
instance uniform vec2 camera_scale;

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(
		vec2(sin(angle), -cos(angle)),
		vec2(cos(angle), sin(angle))
	);
    
    //uv -= pivot;
    uv = rotation * uv;
    //uv += pivot;
    return uv;
}

void fragment() {
	vec2 world_pos = SCREEN_UV - vec2(0.5);
	world_pos /= SCREEN_PIXEL_SIZE * camera_scale;
	world_pos = rotate(world_pos, vec2(0.0), camera_rotation_world);
	world_pos += vec2(camera_position_world.y, -camera_position_world.x);
	vec2 nearest_center = round(world_pos / dot_spacing) * dot_spacing;
	vec2 normal = world_pos - nearest_center;

	COLOR = dot_color * round(smoothstep(dot_size, 0.0, length(normal)));
	
	normal = vec2(-normal.y, normal.x) / dot_size * 2.0;
	NORMAL = vec3(normal, 1.0);
}

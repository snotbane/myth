
mat4 billboard_z(mat4 model_matrix, mat4 modelview_matrix) {
	vec3 scale = vec3(
		model_matrix[0][0],
		model_matrix[1][1],
		model_matrix[2][2]
	);
	return mat4(
		vec4(scale.x, 0.0, 0.0, 0.0),
		vec4(0.0, scale.y, 0.0, 0.0),
		vec4(0.0, 0.0, scale.z, 0.0),
		modelview_matrix[3]
	);
}
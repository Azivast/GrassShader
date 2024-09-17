shader_type spatial;
render_mode cull_disabled;

uniform float wind_speed = 0.2;
uniform float wind_strength = 2.0;

uniform sampler2D wind_noise :source_color;
uniform float wind_texture_tile_size = 20.0;
uniform float wind_vertical_strength = 0.3;
uniform vec2 wind_horizontal_direction = vec2(1.0,0.5);
varying float wind_noise_intensity;

uniform sampler2D color:source_color;
uniform float highlight_roughness_intensity = 1.0;

void vertex() {
	NORMAL = vec3(0, 1, 0);
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 normalized_wind_direction = normalize(wind_horizontal_direction);
	vec2 world_uv = world_vert.xz / wind_texture_tile_size + -normalized_wind_direction * TIME * wind_speed;
	float displacement_affect = (1.0 - UV.y); 	// Displace only the top part of the mesh.
	wind_noise_intensity = (textureLod(wind_noise, world_uv , 0.0).r - 0.5);


	// Convert the direction of the wind into vertex space from world space to account for rotated grass.
	vec2 vert_space_horizontal_dir = (inverse(MODEL_MATRIX) * vec4(wind_horizontal_direction, 0.0,0.0)).xy;
	vert_space_horizontal_dir = normalize(vert_space_horizontal_dir);

	vec3 bump_wind = vec3(
		wind_noise_intensity * vert_space_horizontal_dir.x,
		1.0 - wind_noise_intensity,
		wind_noise_intensity * vert_space_horizontal_dir.y
	);
	normalize(bump_wind);
	bump_wind *= vec3(
		wind_strength,
		wind_vertical_strength,
		wind_strength
	);
	VERTEX += bump_wind * displacement_affect;
}

void fragment() {
	float side = FRONT_FACING ? 1.0 : -1.0;
	NORMAL = NORMAL * side;
	ALBEDO = texture(color, vec2(1.0 - UV.y, 0)).rgb;
	SPECULAR = 0.5;
	ROUGHNESS = clamp(1.0 - (wind_noise_intensity * highlight_roughness_intensity), 0.0, 1.0);
}

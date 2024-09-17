shader_type spatial;

uniform vec2 windDirection = vec2(1.0, 0.0);

// "Random" function
vec2 random2(vec2 p) {
	return fract(sin(vec2(
		dot(p, vec2(142.45, 312.2)),
		dot(p, vec2(234.02, 42.11))
	)) * 54.1);
}

// Nosie function that finds minimum distance to points for every p
float worley2(vec2 p) {
	float dist = 1.0;
	vec2 i_p = floor(p);
	vec2 f_p = fract(p);
	for(int y = -1; y <= 1; y++) {
		for(int x = -1; x <= 1; x++){
			vec2 n = vec2(float(x), float(y));
			vec2 diff = n + random2(i_p + n) - f_p;
			dist = min(dist, length(diff));
		}
	}
	return dist;
}

void fragment() {
	ALBEDO = vec3(worley2((UV * 2.0) + (TIME * windDirection)));
}

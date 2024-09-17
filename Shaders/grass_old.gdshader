shader_type spatial;
render_mode cull_disabled; // disavle backface culling

uniform vec4 topColor:source_color = vec4(0,0,0,1);
uniform vec4 bottomColor:source_color = vec4(1,1,1,1);

uniform vec2 windDirection = vec2(0.0, -1.0);
uniform float windScale = 4.0;
uniform float windPower = 2.0;
uniform float windSpeed = 1.0;

varying float wind;

uniform float degSwayPitch = 80.0;
uniform float degSwayYaw = 45.0;

const vec3 UP = vec3(0, 1, 0);
const vec3 RIGHT = vec3(1, 0, 0);
const float DEG2RAD = (PI/180.0);

// Rodrigues' rotation formula
mat3 mat3FromAxisAngle(float angle, vec3 axis) {
	float s = sin(angle);
	float c = cos(angle);
	float t = 1.0 - c;
	float x = axis.x;
	float y = axis.y;
	float z = axis.z;
	
	return mat3(
		vec3(t*x*x+c, t*x*y-s*z, t*x*z+s*y),
		vec3(t*x*y+s*z, t*y*y+c, t*y*z-s*x),
		vec3(t*x*z-s*y, t*y*z+s*z, t*z*z+c)
	);
}

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

void vertex() {
	NORMAL = vec3(0, 1, 0);
	vec2 uv = (MODEL_MATRIX * vec4(VERTEX, -1)).xz * windScale;
	vec3 windDirectionNormalized = normalize(vec3(windDirection.x, 0, windDirection.y));
	float timeScaled = TIME * windSpeed;
	uv += windDirectionNormalized.xy * timeScaled;
	wind = pow(worley2(uv), windPower);// * UV2.y; not sure what uv2 does here
	
	mat3 toModel = inverse(mat3(MODEL_MATRIX));
	vec3 windForward = toModel * windDirectionNormalized;
	vec3 windRight = normalize(cross(windForward, UP));
	
	float swayPitch = ((degSwayPitch * DEG2RAD) * wind); //+ INSTANCE_CUSTOM.z
	float swayYaw = ((degSwayYaw * DEG2RAD) * sin(timeScaled) * wind); //+ INSTANCE_CUSTOM.w
	
	mat3 rotationRight = mat3FromAxisAngle(swayPitch, windRight);
	mat3 rotationForward = mat3FromAxisAngle(swayYaw, windForward);
	
	vec3 vertex = VERTEX;
	vertex = mat3FromAxisAngle(TIME, UP) * vertex;
	VERTEX = rotationRight * rotationForward * vertex;

	COLOR = mix(topColor, bottomColor, UV.y);
}

void fragment() {
	//// If pixel isn't front facing, flip normal
	//if (!FRONT_FACING) {
		//NORMAL = -NORMAL;
	//}
	//float side = FRONT_FACING ? 1.0 : -1.0;
	float side = FRONT_FACING ? 1.0 : -1.0;
	NORMAL = NORMAL * side;
	ALBEDO = COLOR.rgb;
	SPECULAR = 0.5;
	ROUGHNESS = clamp(1.0 - (wind * windPower), 0.0, 1.0);
}

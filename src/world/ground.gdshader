shader_type spatial;
// Dry valley floor with a packed-dirt street and wagon ruts, all from world position so the
// ground can be one big plane.

uniform vec3 dirt_color : source_color = vec3(0.6, 0.47, 0.33);
uniform vec3 dirt_dark : source_color = vec3(0.4, 0.3, 0.21);
uniform vec3 scrub_color : source_color = vec3(0.62, 0.52, 0.38);
uniform vec3 sage_color : source_color = vec3(0.52, 0.49, 0.35);
uniform float road_center_z = -8.4;
uniform float road_half_width = 6.0;
// Ground pixels per metre (matches the chunky texels on walls; PixelArt.texels_per_meter).
uniform float texels_per_meter = 40.0;

varying vec3 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += vnoise(p) * a;
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Snap to the texel grid so the ground reads as pixel art up close.
	vec2 p = (floor(world_pos.xz * texels_per_meter) + 0.5) / texels_per_meter;
	float n = fbm(p * 0.3);
	float fine = hash(floor(p * texels_per_meter));
	float dz = abs(p.y - road_center_z);
	float road = 1.0 - smoothstep(road_half_width - 1.0, road_half_width + 1.5, dz + (n - 0.5) * 3.0);
	vec3 wild = mix(scrub_color, sage_color, smoothstep(0.45, 0.7, fbm(p * 0.08 + 3.0)));
	vec3 col = mix(wild, dirt_color, road) * (0.82 + 0.36 * n);
	float wobble = (vnoise(vec2(p.x * 0.15, 0.0)) - 0.5) * 0.5;
	float ruts = 0.0;
	ruts += 1.0 - smoothstep(0.06, 0.28, abs(dz - 0.8 + wobble));
	ruts += 1.0 - smoothstep(0.06, 0.28, abs(dz - 2.4 + wobble));
	col = mix(col, dirt_dark, clamp(ruts, 0.0, 1.0) * 0.45 * road);
	col *= 0.88 + 0.24 * fine;
	// a few shades per colour, like a hand-made palette
	col = floor(col * 24.0 + 0.5) / 24.0;
	ALBEDO = col;
	ROUGHNESS = 0.95;
}

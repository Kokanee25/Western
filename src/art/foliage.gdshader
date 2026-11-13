shader_type spatial;
// The scatter's trees' crowns (#891; ValleyTrees): blobs of needles or leaves, holed by 3D noise at
// their edges so they read as foliage, not balls; lit a little through (wrap), varied a tree at a time
// by the MultiMesh's instance colour (its rgb a tint, its a a seed). No textures.

render_mode cull_disabled;

uniform vec3 colour_a : source_color = vec3(0.20, 0.26, 0.13);
uniform vec3 colour_b : source_color = vec3(0.34, 0.38, 0.20);
// How finely the crown breaks up (holes a metre), and how much of a blob's edge is holed away.
uniform float leaf_scale = 5.0;
uniform float hole = 0.48;
uniform float wrap = 0.35;
// Fades out (dithered) between these distances (m), so a far tree can take over.
uniform float fade_from = 0.0;
uniform float fade_to = 0.0;

varying vec3 obj;
varying vec3 tint;
varying float seed;
varying float rim;

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}
float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1, 0, 0));
	float n010 = hash13(i + vec3(0, 1, 0));
	float n110 = hash13(i + vec3(1, 1, 0));
	float n001 = hash13(i + vec3(0, 0, 1));
	float n101 = hash13(i + vec3(1, 0, 1));
	float n011 = hash13(i + vec3(0, 1, 1));
	float n111 = hash13(i + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y), mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

void vertex() {
	obj = VERTEX;
	tint = INSTANCE_CUSTOM.rgb;
	seed = INSTANCE_CUSTOM.a;
	// COLOR.r: how far out on its blob a vertex is (1 the rim).
	rim = COLOR.r;
}

void fragment() {
	vec3 p = obj * leaf_scale + seed * 37.0;
	float n = noise3(p) * 0.6 + noise3(p * 2.7) * 0.4;
	// Holes at the blobs' rims, fewer inside.
	if (n < hole * rim) {
		discard;
	}
	if (fade_to > 0.0) {
		float d = length(VERTEX);
		float keep = 1.0 - smoothstep(fade_from, fade_to, d);
		float dither = fract(dot(FRAGCOORD.xy, vec2(0.5, 0.25)) + hash13(vec3(FRAGCOORD.xy, 1.0)) * 0.5);
		if (keep < dither) {
			discard;
		}
	}
	vec3 c = mix(colour_a, colour_b, noise3(p * 0.35));
	c *= 0.75 + n * 0.5;
	ALBEDO = c * (tint.r + tint.g + tint.b > 0.01 ? tint : vec3(1.0));
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	BACKLIGHT = vec3(0.25, 0.3, 0.15) * 0.6;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	DIFFUSE_LIGHT += w * ATTENUATION * LIGHT_COLOR / PI;
}

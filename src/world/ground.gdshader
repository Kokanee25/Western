shader_type spatial;
// Dry valley floor with a packed-dirt street and wagon ruts, all from world position so the
// ground can be one big plane. Lit tile by tile (src/render/tiles.gdshaderinc).

#include "res://src/render/tiles.gdshaderinc"

uniform vec3 dirt_color : source_color = vec3(0.6, 0.47, 0.33);
uniform vec3 dirt_dark : source_color = vec3(0.4, 0.3, 0.21);
uniform vec3 scrub_color : source_color = vec3(0.62, 0.52, 0.38);
uniform vec3 sage_color : source_color = vec3(0.52, 0.49, 0.35);
uniform float road_center_z = -8.4;
uniform float road_half_width = 6.0;
// Ground pixels per metre (matches the chunky texels on walls; PixelArt.texels_per_meter).
uniform float texels_per_meter = 40.0;
// The street's dirt from the texture factory (assets/textures/road.png, set by PixelArt.track);
// without it the street is painted here from noise.
uniform sampler2D road_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_road_tex = false;

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
	// Snap to the texel grid so the ground reads as pixel art up close; far off, to tiles of a few
	// texels, never smaller than min_square_px on screen (tiles.gdshaderinc).
	vec2 t = world_pos.xz * texels_per_meter;
	float b = tile_square(t);
	vec2 p = (floor(t / b) + 0.5) * b / texels_per_meter;
	float n = fbm(p * 0.3);
	float fine = hash(floor(p * texels_per_meter));
	float dz = abs(p.y - road_center_z);
	float road = 1.0 - smoothstep(road_half_width - 1.0, road_half_width + 1.5, dz + (n - 0.5) * 3.0);
	vec3 wild = mix(scrub_color, sage_color, smoothstep(0.45, 0.7, fbm(p * 0.08 + 3.0)));
	vec3 dirt = dirt_color;
	if (use_road_tex) {
		// Texel by texel from the factory's road, its repeats broken up by the broad noise below.
		dirt = textureLod(road_tex, p * texels_per_meter / vec2(textureSize(road_tex, 0)), 0.0).rgb;
	}
	vec3 col = mix(wild, dirt, road) * (use_road_tex ? mix(0.82 + 0.36 * n, 0.9 + 0.2 * n, road) : 0.82 + 0.36 * n);
	// Wagon ruts, as the painting has them: three wagon tracks down the street (the middle one
	// most used), each a pair of grooves 1.5 m apart worn by more than one wagon, so each groove is
	// two that drift apart and back along the street; dark in the bottom with a crisp edge, a lit
	// ridge of thrown-up dirt along the outside.
	float sz = p.y - road_center_z;
	float groove = 0.0;
	float ridge = 0.0;
	for (int track = 0; track < 3; track++) {
		float ft = float(track);
		float middle = ft == 0.0 ? 0.0 : (ft == 1.0 ? -2.6 : 2.5);
		float use = ft == 0.0 ? 1.0 : 0.7;
		for (int k = 0; k < 2; k++) {
			float fk = float(k) + ft * 2.0;
			float drift = (vnoise(vec2(p.x * (0.04 + 0.015 * fk), 7.0 * fk)) - 0.5) * (0.6 + 0.3 * float(k));
			float wear = use * (1.0 - 0.35 * float(k));
			for (int side = -1; side <= 1; side += 2) {
				float d = abs(sz - (middle + float(side) * 0.75 + drift));
				groove += (1.0 - smoothstep(0.05, 0.1, d)) * wear;
				ridge += (smoothstep(0.1, 0.13, d) - smoothstep(0.18, 0.28, d)) * wear;
			}
		}
	}
	groove = clamp(groove, 0.0, 1.0) * smoothstep(0.25, 0.75, road);
	ridge = clamp(ridge, 0.0, 1.0) * smoothstep(0.25, 0.75, road) * (1.0 - groove);
	// Hooves and boots churn the middle into darker patches; pebbles lie about, a light or a dark
	// texel here and there.
	float churn = smoothstep(0.55, 0.75, fbm(p * 0.9 + 11.0)) * (1.0 - smoothstep(0.0, 2.5, abs(sz))) * road;
	float pebble = hash(floor(p * texels_per_meter) + 17.0);
	col = mix(col, dirt_dark * 0.85, groove * 0.5 + churn * 0.2);
	col *= 1.0 + ridge * 0.22;
	col = mix(col, col * (pebble > 0.5 ? 1.32 : 0.62), step(0.965, hash(floor(p * texels_per_meter) + 3.0)) * road);
	col *= use_road_tex ? mix(0.88 + 0.24 * fine, 1.0, road) : 0.88 + 0.24 * fine;
	// a few shades per colour, like a hand-made palette
	col = floor(col * 24.0 + 0.5) / 24.0;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	LIGHT_VERTEX = tile_snap(VERTEX, tile_screen_offset(t, b > 1.0 ? (floor(t / b) + 0.5) * b : tile_centre(t)));
}

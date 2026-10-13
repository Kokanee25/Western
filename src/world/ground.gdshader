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
// The street as one painted 8 m tile seen from above (assets/textures/road_wide.png: ruts, hoof
// marks, stones and grass painted as real things, docs/ART_REVIEW.md §8.3), laid along the street
// with its middle on the road's centre line. Where it's in use, the ruts drawn below are left out
// (the painting has its own) and the 2 m tile is blended over it by a broad mask to break its
// repeat.
uniform sampler2D wide_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_wide_tex = false;
// A drawn wide tile (the bold look's: tools/textures/draw_road.py): its ruts and stones are kept
// where the 2 m tile shows through (they're darker than the dust round them), so the tracks run
// unbroken down the street as the painting's do.
uniform bool keep_tracks = false;
// The ground's own squares a metre when set (PixelArt.DRAWN_ROAD_TEXELS, with the drawn road: the
// street painting's near road squares are twice the world's), else texels_per_meter.
uniform float road_texels = 0.0;
// Far off the drawn road's squares dissolve, as the painting's far street does (nearly smooth,
// dimmed by haze): between these distances (metres from the eye) it eases toward its own mip.
uniform float dissolve_from = 16.0;
uniform float dissolve_to = 55.0;
// The ground faces the whole sky, and with the sun low the sky round it is bright: the sun's
// light on the ground is wrapped (a flat surface under a 15-degree sun got a quarter of it and
// drew at half the painting's brightness, docs/ART_REVIEW.md §3.1). Shadows still fall.
uniform float sun_wrap = 0.0;
// The sun's direct light on the ground, scaled: the painting's sunlit ground is barely brighter
// than its shadowed ground (sky light does most of it).
uniform float sun_direct = 0.7;
// And the sky's glow round a low sun lights the open ground in and out of the sun's shadows (the
// painting's road is lit ochre in the fronts' shadows too; Godot's ambient is one colour for
// every facing, and the ground faces all of it): a share of the sun's light, unshadowed.
uniform float sky_fill = 0.15;
// With the sun low the fill falls to this (the street painting's golden hour is deep in its
// shadows); eased by the sun's height as DayCycle's `golden` is (the road is flat, so `facing`
// is that height's sine).
uniform float sky_fill_low_sun = 0.05;
// The quantise-once trial (PixelArt.smooth): no per-texel dirt noise and no snap to 24 levels
// here; the screen mosaic is the only quantisation.
uniform bool smooth_source = false;

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
	float tpm = road_texels > 0.0 ? road_texels : texels_per_meter;
	vec2 t = world_pos.xz * tpm;
	bool soft = block_soft > 0.0;
	float b = soft ? 1.0 : tile_square(t);
	// Under soft edges the sample point slides across a texel's edge (tiles.gdshaderinc), so the
	// road's painted tiles blend there; the dirt's own per-texel noise stays hard.
	vec2 p = (soft ? tile_soft_point(t) : (floor(t / b) + 0.5) * b) / tpm;
	float n = fbm(p * 0.3);
	float fine = smooth_source ? 0.5 : hash(floor(p * tpm));
	float dz = abs(p.y - road_center_z);
	float road = 1.0 - smoothstep(road_half_width - 1.0, road_half_width + 1.5, dz + (n - 0.5) * 3.0);
	vec3 wild = mix(scrub_color, sage_color, smoothstep(0.45, 0.7, fbm(p * 0.08 + 3.0)));
	vec3 dirt = dirt_color;
	if (use_road_tex) {
		// Texel by texel from the factory's road, its repeats broken up by the broad noise below.
		vec2 rs = vec2(textureSize(road_tex, 0));
		dirt = soft ? tile_sample_soft(road_tex, p * tpm, rs, vec2(0.0), vec2(0.0)).rgb
				: textureLod(road_tex, p * tpm / rs, 0.0).rgb;
	}
	if (use_wide_tex) {
		// The 8 m painting along the street; every other 8 m the picture is mirrored end for end
		// (seamless, so the join holds), and the 2 m tile shows through in broad patches.
		float wide_metres = float(textureSize(wide_tex, 0).x) / tpm;
		vec2 w = vec2(p.x, p.y - road_center_z + 0.5 * wide_metres) / wide_metres;
		float cell = floor(w.x);
		w.x = mod(cell, 2.0) > 0.5 ? cell + 1.0 - fract(w.x) : w.x;
		vec2 ws = vec2(textureSize(wide_tex, 0));
		vec3 wide = soft ? tile_sample_soft(wide_tex, w * ws, ws, vec2(0.0), vec2(0.0)).rgb : textureLod(wide_tex, w, 0.0).rgb;
		if (keep_tracks) {
			float far = smoothstep(dissolve_from, dissolve_to, length(VERTEX));
			wide = mix(wide, textureLod(wide_tex, w, 3.0).rgb, far);
			dirt = mix(dirt, textureLod(road_tex, p * tpm / vec2(textureSize(road_tex, 0)), 2.0).rgb, far);
		}
		float patch = smoothstep(0.5, 0.7, fbm(p * 0.13 + 23.0));
		if (keep_tracks) {
			float lw = dot(wide, vec3(0.3, 0.59, 0.11));
			float ld = dot(dirt, vec3(0.3, 0.59, 0.11));
			patch *= smoothstep(0.78, 0.92, lw / max(ld, 1e-3));
		}
		dirt = mix(wide, use_road_tex ? dirt : wide, patch * 0.6);
	}
	vec3 col = mix(wild, dirt, road) * (use_road_tex || use_wide_tex ? mix(0.82 + 0.36 * n, 0.9 + 0.2 * n, road) : 0.82 + 0.36 * n);
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
	float drawn = use_wide_tex ? 0.0 : 1.0;
	groove = clamp(groove, 0.0, 1.0) * smoothstep(0.25, 0.75, road) * drawn;
	ridge = clamp(ridge, 0.0, 1.0) * smoothstep(0.25, 0.75, road) * (1.0 - groove) * drawn;
	// Hooves and boots churn the middle into darker patches; pebbles lie about, a light or a dark
	// texel here and there.
	float churn = smoothstep(0.55, 0.75, fbm(p * 0.9 + 11.0)) * (1.0 - smoothstep(0.0, 2.5, abs(sz))) * road;
	float pebble = hash(floor(p * tpm) + 17.0);
	col = mix(col, dirt_dark * 0.85, (groove * 0.5 + churn * 0.2) * drawn);
	col *= 1.0 + ridge * 0.22;
	col = mix(col, col * (pebble > 0.5 ? 1.32 : 0.62), step(0.965, hash(floor(p * tpm) + 3.0)) * road * drawn);
	col *= use_road_tex || use_wide_tex ? mix(0.88 + 0.24 * fine, 1.0, road) : 0.88 + 0.24 * fine;
	// a few shades per colour, like a hand-made palette (the drawn road has its own: snapping it
	// again merged its neighbouring tones)
	if (!smooth_source && !keep_tracks) {
		col = floor(col * 24.0 + 0.5) / 24.0;
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	LIGHT_VERTEX = tile_snap(VERTEX, tile_screen_offset(t, soft ? tile_soft_point(t) : (b > 1.0 ? (floor(t / b) + 0.5) * b : tile_centre(t))));
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	float lit = max(facing, 0.0);
	if (LIGHT_IS_DIRECTIONAL) {
		lit = mix(lit, 1.0, sun_wrap) * smoothstep(0.0, 0.05, facing) * sun_direct;
		// The sky's light is paler than the sun's: half way to grey.
		vec3 sky = mix(LIGHT_COLOR, vec3(dot(LIGHT_COLOR, vec3(0.2126, 0.7152, 0.0722))), 0.5);
		float fill = mix(sky_fill_low_sun, sky_fill, smoothstep(0.1, 0.6, facing));
		DIFFUSE_LIGHT += sky * fill * smoothstep(0.0, 0.05, facing);
	}
	// LIGHT_COLOR already carries the light's energy / PI; the albedo is applied after. Under
	// the surface-blocks look the light steps (tile_band).
	DIFFUSE_LIGHT += LIGHT_COLOR * tile_band(ATTENUATION * lit);
}

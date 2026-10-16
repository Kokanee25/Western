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
// Mipmapped (each mip a square's mean: the far road's calm). Plain filter_nearest had no mips, so
// the far dissolve below read level 0 whatever lod it asked for.
uniform sampler2D road_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_road_tex = false;
// The street as one painted 8 m tile seen from above (assets/textures/road_wide.png: ruts, hoof
// marks, stones and grass painted as real things, docs/ART_REVIEW.md §8.3), laid along the street
// with its middle on the road's centre line. Where it's in use, the ruts drawn below are left out
// (the painting has its own) and the 2 m tile is blended over it by a broad mask to break its
// repeat.
uniform sampler2D wide_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_wide_tex = false;
// A drawn wide tile (the bold look's: tools/textures/draw_road.py): its ruts and stones are kept
// where the 2 m tile shows through (they're darker than the dust round them), so the tracks run
// unbroken down the street as the painting's do.
uniform bool keep_tracks = false;
// The ground's own squares a metre when set (PixelArt.DRAWN_ROAD_TEXELS, with the drawn road: the
// street painting's near road squares are twice the world's), else texels_per_meter.
uniform float road_texels = 0.0;
// The smallest the ground's squares get on screen, render pixels each way (with min_square_px on;
// off under the looks that turn it off): far off they grow along the street and across it apart
// (tiles.gdshaderinc tile_square_screen), so they stay square on screen as the painting's (about
// 4 px a few metres off at 1280 wide), each one the mean of its texels, so the far road calms
// rather than drawing one texel's colour a square (2026-10-15, roadmap 1.4: the critic's "loud
// even static to the horizon"; by area alone they were thin strips 8 px wide and 1.5 tall).
uniform float square_px = 3.0;
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
// The main street (docs/briefs/road.md; roadmap 1.4, Sean's road, 2026-10-15): smooth painted
// earth to the boardwalks, no squares. Its map (street_map, tools/textures/draw_street.py: R how
// churned, G the wagon ruts' height, A the stones') over street_area (x0, z0, x1, z1 in metres)
// blends two painted earths, packed (compact_tex) and churned (loose_tex), 8 m tiles mirrored
// every other tile along the street, each with its relief (compact_h, loose_h); the ruts are the
// map's own, the whole street long. Each pixel is tilted to the slope of the earth's relief and the
// ruts together, so the low sun lights a rut's far wall and a clod's top and leaves the near wall
// dark; the hollows a little darker (relief_cavity); and the sun's light traced a little toward it
// over the heights (light()), so a rut's bottom lies in its lip's shadow, long with the sun low.
// Past the map the ground is as before (squares). relief_depth: metres of the earths' relief from
// black to white; the packed earth's at compact_relief of it.
uniform bool use_street = false;
// Anisotropic: the ruts run along the view, and plain mipmaps picked their level from the
// street's foreshortening and blurred the troughs away across it.
uniform sampler2D street_map : filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 street_area = vec4(-86.0, -22.0, 35.0, 5.0);
uniform float street_rut_range = 0.12;
uniform sampler2D compact_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D loose_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D compact_h : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D loose_h : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float earth_metres = 8.0;
uniform float relief_depth = 0.06;
uniform float compact_relief = 0.35;
// And the churned earth's (at 1 its clods read as a dark speckle over the near ground).
uniform float loose_relief = 0.6;
uniform float relief_cavity = 0.3;
// How dark a rut's bottom is at full depth (damp, shadowed earth), and how light its crumbled lip.
uniform float rut_dark = 0.45;
// How far toward the sun the shadow trace looks (metres) and how dark a fully hidden pixel goes
// (of the sun's light; the sky's fill still reaches it).
uniform float relief_shadow_reach = 0.5;
uniform float relief_shadow = 0.85;
varying vec2 v_earth;
varying float v_mirror;
varying vec2 v_muv;
varying float v_loose;
varying float v_on;
varying float v_h0;
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
	vec2 b = soft ? vec2(1.0) : tile_square_screen(t, min_square_px > 0.0 ? max(square_px, min_square_px) : 0.0);
	// The texels a square holds, as one mip level (the mean of its texels: tile_block_sample).
	float lod = log2(sqrt(b.x * b.y));
	// Under soft edges the sample point slides across a texel's edge (tiles.gdshaderinc), so the
	// road's painted tiles blend there; the dirt's own per-texel noise stays hard.
	vec2 p = (soft ? tile_soft_point(t) : (floor(t / b) + 0.5) * b) / tpm;
	float n = fbm(p * 0.3);
	// A square's own speck of difference, as the mean of the texels in it would have it (a big
	// far square of many texels is nearly their average, not one texel's loud colour).
	float fine = smooth_source ? 0.5 : mix(0.5, hash(floor(p * tpm)), inversesqrt(b.x * b.y));
	float dz = abs(p.y - road_center_z);
	float road = 1.0 - smoothstep(road_half_width - 1.0, road_half_width + 1.5, dz + (n - 0.5) * 3.0);
	vec3 wild = mix(scrub_color, sage_color, smoothstep(0.45, 0.7, fbm(p * 0.08 + 3.0)));
	vec3 dirt = dirt_color;
	if (use_road_tex) {
		// Texel by texel from the factory's road, its repeats broken up by the broad noise below.
		vec2 rs = vec2(textureSize(road_tex, 0));
		dirt = soft ? tile_sample_soft(road_tex, p * tpm, rs, vec2(0.0), vec2(0.0)).rgb
				: textureLod(road_tex, p * tpm / rs, lod).rgb;
	}
	if (use_wide_tex) {
		// The 8 m painting along the street; every other 8 m the picture is mirrored end for end
		// (seamless, so the join holds), and the 2 m tile shows through in broad patches.
		// Its size along the street: the painted road's own (wide_metres), else the drawn one's at
		// the ground's density.
		float wm = float(textureSize(wide_tex, 0).x) / tpm;
		vec2 w = vec2(p.x, p.y - road_center_z + 0.5 * wm) / wm;
		float cell = floor(w.x);
		w.x = mod(cell, 2.0) > 0.5 ? cell + 1.0 - fract(w.x) : w.x;
		vec2 ws = vec2(textureSize(wide_tex, 0));
		vec3 wide = soft ? tile_sample_soft(wide_tex, w * ws, ws, vec2(0.0), vec2(0.0)).rgb : textureLod(wide_tex, w, lod).rgb;
		if (keep_tracks) {
			// The mip levels a metre and half a metre across, whatever the road's density.
			float far = smoothstep(dissolve_from, dissolve_to, length(VERTEX));
			wide = mix(wide, textureLod(wide_tex, w, max(lod, log2(tpm * 0.5))).rgb, far);
			dirt = mix(dirt, textureLod(road_tex, p * tpm / vec2(textureSize(road_tex, 0)), max(lod, log2(tpm * 0.25))).rgb, far);
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
	bool smooth_road = false;
	if (use_street && !soft) {
		vec2 q = world_pos.xz;
		vec2 span = street_area.zw - street_area.xy;
		float inner = min(min(q.x - street_area.x, street_area.z - q.x), min(q.y - street_area.y, street_area.w - q.y));
		v_on = smoothstep(0.0, 2.0, inner);
		float on = v_on;
		if (on > 0.0) {
			smooth_road = v_on > 0.5;
			vec2 muv = (q - street_area.xy) / span;
			vec4 m = texture(street_map, muv);
			// The earths: 8 m tiles mirrored every other one along the street (seamless so), the
			// churned one shifted so their repeats never line up.
			vec2 e = vec2(q.x, q.y - street_area.y) / earth_metres;
			float cell = floor(e.x);
			float mirror = mod(cell, 2.0) > 0.5 ? -1.0 : 1.0;
			e.x = mirror < 0.0 ? cell + 1.0 - fract(e.x) : e.x;
			vec2 e2 = e + vec2(0.41, 0.23);
			float nq = fbm(q * 0.7 + 5.0);
			float loose = smoothstep(0.3, 0.7, m.r + (nq - 0.5) * 0.25);
			vec3 earth = mix(texture(compact_tex, e).rgb, texture(loose_tex, e2).rgb, loose);
			// The relief's slope: the earths' (a height texel either side, or what a pixel covers)
			// and the ruts' (a map texel either side), in metres per metre, x backward in mirrored
			// tiles for the earths.
			vec2 hs = vec2(textureSize(compact_h, 0));
			vec2 d = max(1.0 / hs, fwidth(e));
			float kc = compact_relief * (1.0 - loose);
			float hx = (texture(compact_h, e + vec2(d.x, 0.0)).r - texture(compact_h, e - vec2(d.x, 0.0)).r) * kc
					+ (texture(loose_h, e2 + vec2(d.x, 0.0)).r - texture(loose_h, e2 - vec2(d.x, 0.0)).r) * loose * loose_relief;
			float hz = (texture(compact_h, e + vec2(0.0, d.y)).r - texture(compact_h, e - vec2(0.0, d.y)).r) * kc
					+ (texture(loose_h, e2 + vec2(0.0, d.y)).r - texture(loose_h, e2 - vec2(0.0, d.y)).r) * loose * loose_relief;
			vec2 slope = vec2(mirror * hx / (2.0 * d.x), hz / (2.0 * d.y)) * relief_depth / earth_metres;
			vec2 ms = vec2(textureSize(street_map, 0));
			vec2 dm = max(1.0 / ms, fwidth(muv));
			float rx = texture(street_map, muv + vec2(dm.x, 0.0)).g - texture(street_map, muv - vec2(dm.x, 0.0)).g;
			float rz = texture(street_map, muv + vec2(0.0, dm.y)).g - texture(street_map, muv - vec2(0.0, dm.y)).g;
			slope += vec2(rx / (2.0 * dm.x * span.x), rz / (2.0 * dm.y * span.y)) * 2.0 * street_rut_range;
			float near = 1.0 - smoothstep(dissolve_from, dissolve_to, length(VERTEX));
			vec3 nw = normalize(vec3(-slope.x * near, 1.0, -slope.y * near));
			NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(nw, 0.0)).xyz, v_on));
			// The hollows darker; a rut's bottom darker still, its fresh lip a touch lighter.
			float h0 = mix(texture(compact_h, e).r, texture(loose_h, e2).r, loose);
			float rut = (m.g - 0.5) * 2.0 * street_rut_range;
			earth *= mix(1.0 - relief_cavity, 1.0, mix(1.0, h0, mix(compact_relief, loose_relief, loose)));
			// Most of a trough dark, not only its deepest line: with the sun down the street, along
			// the ruts, their walls take no raking light, and the target draws them as dark bands.
			earth *= 1.0 - rut_dark * smoothstep(0.004, 0.05, -rut);
			earth *= 1.0 + 0.18 * smoothstep(0.002, 0.012, rut);
			earth *= 0.94 + 0.12 * fbm(q * 0.25 + 9.0);
			v_earth = e;
			v_mirror = mirror;
			v_muv = muv;
			v_loose = loose;
			v_h0 = h0 * mix(compact_relief, loose_relief, loose) * relief_depth + rut;
			v_on *= near;
			col = mix(col, earth, on);
		}
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	if (!smooth_road) {
		LIGHT_VERTEX = tile_snap(VERTEX, tile_screen_offset(t, soft ? tile_soft_point(t) : (max(b.x, b.y) > 1.0 ? (floor(t / b) + 0.5) * b : tile_centre(t))));
	}
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
	if (use_street && LIGHT_IS_DIRECTIONAL && v_on > 0.0) {
		// The street's own shadow: along the sun's way over the earth's and the ruts' heights, is
		// anything above the ray from this pixel? Six steps to relief_shadow_reach.
		vec3 sun = normalize((INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).xyz);
		vec2 along = sun.xz / max(length(sun.xz), 1e-4);
		float rise = sun.y / max(length(sun.xz), 1e-4);
		vec2 span = street_area.zw - street_area.xy;
		float hidden = 0.0;
		for (int i = 1; i <= 6; i++) {
			float t = relief_shadow_reach * float(i) / 6.0;
			vec2 e = v_earth + vec2(v_mirror * along.x, along.y) * t / earth_metres;
			vec2 muv = v_muv + along * t / span;
			float he = mix(textureLod(compact_h, e, 1.0).r * compact_relief,
					textureLod(loose_h, e + vec2(0.41, 0.23), 1.0).r * loose_relief, v_loose) * relief_depth;
			float hr = (textureLod(street_map, muv, 0.0).g - 0.5) * 2.0 * street_rut_range;
			hidden = max(hidden, smoothstep(0.0, 0.012, he + hr - (v_h0 + t * rise)));
		}
		lit *= 1.0 - relief_shadow * hidden * v_on;
	}
	// LIGHT_COLOR already carries the light's energy / PI; the albedo is applied after. Under
	// the surface-blocks look the light steps (tile_band).
	DIFFUSE_LIGHT += LIGHT_COLOR * tile_band(ATTENUATION * lit);
}

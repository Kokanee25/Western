shader_type spatial;
// The material library's woods (#701; docs/briefs/material-library.md): scanned CC0 maps (Poly
// Haven, ambientCG: assets/textures/scans/) drawn board by board, for the real look.
//
// Every board is its own mesh in its own frame (SamplePanel.board_mesh): X along its length
// [0, L], Y across its face [-W/2, W/2], Z through it (the face it shows is +Z). Its vertices carry
//   CUSTOM0 = (seed in [0, 1), x / L, 2y / W, face: 0 a long face, 1 an end (end grain), 2 an edge)
//   CUSTOM1 = (L, W, T, warp: how far this board twists, cups, bows and crooks, 0 true .. 1 an old shed's)
//   CUSTOM2 = (nail rows: 0, 1 or 2; their place across the face, 0..1 of the half width; ground y;
//              role: 0 a board, 1 a bar's rail top: glass rings and elbow wear where it's varnished)
// so a batch of boards draws the same as the boards one by one (part 5: in the vertex shader, from a
// seed, not unique meshes). Its collision is still its plain box.
//
// Part 1, no repeats: each board takes its own place in the scan (an offset along and across), a
// flip either way, a variant scan where the wood has two, and a slight shift of hue, value and
// roughness, all from its seed; over them a large-scale layer in the world's space (sun-fade,
// grime from the ground up, water streaks) so a long wall doesn't tile.
// Age (0 new, 0.5 a few years, 1 old) blends toward the weathered scan, opens the joints' dirt,
// rusts the nails and (for varnished woods) ambers and wears the varnish where hands go.

#include "res://src/render/real_look.gdshaderinc"

// The fresh scan, its variant and the weathered scan. Each scan's `tile` is the metres it covers
// (along its grain, across it); `grain_v` when its grain runs down the image (V), not across (U).
uniform sampler2D albedo_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_a : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_a : hint_roughness_gray, filter_linear_mipmap, repeat_enable;
uniform vec2 tile_a = vec2(2.0, 2.0);
uniform bool grain_v_a = false;
uniform bool has_a2 = false;
uniform sampler2D albedo_a2 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_a2 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_a2 : hint_roughness_gray, filter_linear_mipmap, repeat_enable;
uniform vec2 tile_a2 = vec2(2.0, 2.0);
// The variant brought to the fresh scan's mean colour (MaterialLibrary, from the scans' meta).
uniform vec3 a2_gain = vec3(1.0);
uniform bool grain_v_a2 = false;
uniform bool has_b = false;
uniform sampler2D albedo_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_b : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_b : hint_roughness_gray, filter_linear_mipmap, repeat_enable;
uniform vec2 tile_b = vec2(2.0, 2.0);
uniform bool grain_v_b = false;
// A seamless noise (NoiseTexture2D) for the large-scale layer.
uniform sampler2D big_noise : filter_linear_mipmap, repeat_enable;

// The wood's colour: multiplied on the fresh scan new and at a few years (the amber pine goes
// before it greys), and on the weathered scan.
uniform vec3 tint_new : source_color = vec3(1.0);
uniform vec3 tint_mid : source_color = vec3(1.0);
uniform vec3 tint_old : source_color = vec3(1.0);
uniform float age : hint_range(0.0, 1.0) = 0.0;
// How far age goes toward the weathered scan (0: a wood indoors keeps its own grain and only
// ambers and wears).
uniform float weathering : hint_range(0.0, 1.0) = 1.0;
// Per board (part 1): value, hue and roughness shifts at most.
uniform float value_jitter = 0.08;
uniform float hue_jitter = 0.04;
uniform float rough_jitter = 0.12;
uniform float roughness_add = 0.0;
uniform float normal_strength = 1.0;
// The large-scale layer, each at full age (scaled by age; `*_new` the share left new).
uniform float grime = 0.6;
uniform float sun_fade = 0.5;
uniform float streaks = 0.5;
uniform float joint_dirt = 0.5;
uniform float layer_new = 0.25;
// Varnish (the fine woods): a clear coat, amber that deepens with age, worn dull and through
// where hands and feet go (`wear_band`: the heights in metres above the ground hands rub).
uniform float varnish : hint_range(0.0, 1.0) = 0.0;
uniform vec3 varnish_amber : source_color = vec3(0.85, 0.62, 0.38);
uniform vec2 wear_band = vec2(0.85, 1.15);
// The lab's before/after switches: 0 turns off part 1 (every board the scan's same place, no
// flips, no shifts, no large-scale layer) or part 5 (every board true).
uniform float variety : hint_range(0.0, 1.0) = 1.0;
uniform float warp_gain = 1.0;
// Rough-sawn: a circular saw's arcs across the face (a 48 in blade, ~5 mm a tooth), worn down by age.
uniform float saw_marks = 0.0;
// How much old varnish darkens (1: not at all).
uniform float varnish_dark = 0.72;
// A few years against old (the judge, #721: "few can hardly be told from old"). `age_split`: at a few
// years the weathered scan's cracks shallower and its grey lighter (silvered, not yet split); old, its
// darks deeper. `checks`: old boards' sun-splits, long cracks along the grain, widest where they start,
// the most of them run in from a board's end. `end_rot`: old boards' feet by the ground dark and
// ragged, where splash and damp sit.
uniform float age_split = 0.0;
uniform float checks = 0.0;
uniform float end_rot = 0.0;
// Joints as shadowed gaps (the judge: "not lines drawn on"): where a neighbour covers a board's edge
// (the lap above, a batten: UV2 = the metres covered at the -Y and +Y edges) the face just past it
// sits in the neighbour's lee, a soft contact shadow `contact` deep; `arris`: the long edges' last
// millimetres rounded over, as a handled, weathered edge is.
uniform float contact = 0.0;
uniform float arris = 0.0;
// The fresh grain's contrast against its own neighbourhood (a high mip): 1 the scan's, less to lose a
// figure that reads drawn on (Sean, #721: new pine "lose the drawn-on grain").
uniform float grain_contrast = 1.0;
// Weathering's shelter (Sean, #721: bare pine in desert sun goes silver-grey in a year or two; the
// orange survives only where sheltered): under the eaves (the top `eaves_m` of a wall `wall_top` m
// high) and beside battens and joints (`edge_shelter`), less of it as the years go on.
uniform float wall_top = 2.0;
uniform float eaves_m = 0.45;
uniform float edge_shelter = 0.8;
// The weathered scan sampled twice, the second turned half round and moved, blended along the board
// by noise, so no stretch of a board shows the scan's repeat (a short scan's knot came three times
// down one board). After Heitz and Neyret's stochastic texturing (HPG 2018): two decorrelated
// samples under a smooth blend, here without their histogram step (it's the same scan).
uniform float b_stochastic = 1.0;
// Planed wood takes a little sheen; rough-sawn none.
uniform float specular_wood = 0.35;
// The weave's bisect (#721, Sean 2026-11-10): the layers switched on one at a time, in order; 99 all.
// 0 a flat colour (the scan's mean), 1 the scan's colour, 2 + its grain contrast, 3 + the normal
// map, 4 + the roughness map, 5 + per-board variation, 6 + weathering, 7 + shelter, 8 + edge dirt
// (joints, splash), 9 + the rest (sun-fade, streaks, nails, varnish, end grain, lap shade).
uniform int bisect = 99;

// Paint (#721's paint round, 2026-11-11; config/material_library.json's `paint` entries): a coat over
// the wood, aged as house paint ages. Oil paint (white lead in linseed, or earth and chrome pigments in
// it) doesn't wear evenly: the binder breaks down in UV first, so the sunny faces chalk (a pale, matte
// powder) and fade while the shaded ones keep their colour; water gets in where it sits (the foot by
// the ground, a lap's drip edge, board ends, the edges' arrises) and the film lets go there, cracking
// along the grain first (wood moves across its grain, the film can't) and then peeling in strips
// to the primer and the bare wood, which greys as bare wood does. Thin paint shows the grain under it,
// and rough-sawn wood's fibres through any coat. Inside, no sun: it yellows, rubs through where hands
// go and is scuffed at the foot. Sources: USDA Forest Products Lab, "Wood Handbook" ch. 16 (finishing,
// paint failure on wood); FPL's "Painting Outside Wood Surfaces" and Williams, "Finishes for Exterior
// Wood" (chalking, cracking with the grain, intercoat peeling, mill glaze); National Park Service
// Preservation Brief 10, "Exterior Paint Problems on Historic Woodwork" (the failure patterns by
// place: sills, drip edges, the sunny elevations).
uniform float paint : hint_range(0.0, 1.0) = 0.0;
// A bead along one edge of each board (beaded tongue and groove).
uniform float bead = 0.0;
uniform vec3 paint_color : source_color = vec3(0.9, 0.89, 0.84);
// The coat under it (primer, or an older colour) seen in the ring round each peel.
uniform vec3 paint_under : source_color = vec3(0.86, 0.84, 0.78);
// 0 outside, 1 inside (no sun, no rain).
uniform float paint_inside : hint_range(0.0, 1.0) = 0.0;
// Each at full age (old); a few years is about a third of chalk, cracks and peeling.
uniform float paint_chalk = 0.7;
uniform float paint_fade = 0.5;
uniform float paint_peel = 0.6;
uniform float paint_crack = 0.6;
// How much the grain shows through: new, and the most when old (a thin, eroded film).
uniform float paint_thin_new = 0.08;
uniform float paint_thin = 0.45;
// The wood's relief through the coat (rough-sawn more), new and old.
uniform float paint_relief = 0.45;
uniform float paint_brush = 0.5;
uniform float paint_rough_new = 0.42;
uniform float paint_yellow = 0.0;
uniform vec3 paint_dust : source_color = vec3(0.58, 0.49, 0.39);
// Where the sun works hardest, in the world (south-west: the afternoon's heat; DayCycle's south is -Z).
uniform vec3 paint_sun = vec3(-0.6, 0.0, -0.8);

// Flat: the seed is one number a board, and the fragment shader hashes it into the board's place in
// each scan. Interpolated, its last bits differed from pixel to pixel (a perspective-interpolated
// constant isn't exact), and the hash turned that into jumps of many texels in the rasteriser's
// triangles and blocks: the "weave", blocks and smudge of #721/#763 (the fresh scans' too).
varying flat float v_seed;
varying float v_face;
varying vec2 v_m;        // metres along and across the face it shows
varying float v_across;  // -1..1 across a long face
varying vec3 v_world;
varying vec3 v_wnormal;
varying float v_ground;
varying vec2 v_nails;
varying float v_role;
varying float v_width;
varying vec3 v_axis;   // the board's length in the world
varying vec3 v_yaxis;  // across its face in the world
varying flat vec2 v_cover;
varying flat float v_length;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

// A signed random in [-1, 1] for this board, the i-th of its kind.
float rnd(float seed, float i) {
	return hash11(seed * 9173.0 + i * 37.0 + 1.0) * 2.0 - 1.0;
}

void vertex() {
	float seed = CUSTOM0.x;
	float a = CUSTOM0.y * 2.0 - 1.0;  // -1..1 along
	float w = clamp(CUSTOM0.z, -1.0, 1.0);
	float L = max(CUSTOM1.x, 0.01);
	float W = max(CUSTOM1.y, 0.01);
	float warp = CUSTOM1.w * warp_gain;
	// Part 5: a few millimetres of bow (along), cup (across), twist and crook (the edge's curve),
	// longer boards bowing more; now and then a corner lifted where a nail let go.
	float bow = warp * 0.0035 * rnd(seed, 1.0) * clamp(L / 2.0, 0.3, 2.0);
	float cup = warp * 0.0018 * rnd(seed, 2.0) * clamp(W / 0.15, 0.4, 2.0);
	float twist = warp * 0.0030 * rnd(seed, 3.0) * clamp(L / 2.0, 0.3, 2.0);
	float crook = warp * 0.0025 * rnd(seed, 4.0) * clamp(L / 2.0, 0.3, 2.0);
	float lift_on = step(0.55, rnd(seed, 5.0)) * warp;
	float lift_end = sign(rnd(seed, 6.0) + 0.001);
	float lift_side = sign(rnd(seed, 7.0) + 0.001);
	float lift = 0.009 * lift_on;
	float corner = smoothstep(0.6, 1.0, a * lift_end) * smoothstep(0.0, 1.0, w * lift_side);
	float dz = bow * (1.0 - a * a) + cup * (w * w) + twist * a * w + lift * corner;
	float dy = crook * (1.0 - a * a);
	VERTEX.z += dz;
	VERTEX.y += dy;
	// The long faces' normals from the displacement's slope (z = f(x, y)).
	if (CUSTOM0.w < 0.5) {
		float fx = (bow * -2.0 * a + twist * w) * 2.0 / L;
		float fy = (cup * 2.0 * w + twist * a) * 2.0 / W;
		NORMAL = normalize(vec3(-fx, -fy, 1.0) * sign(NORMAL.z));
	}
	vec3 t = CUSTOM0.w > 0.5 && CUSTOM0.w < 1.5 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	TANGENT = t;
	BINORMAL = cross(NORMAL, t);
	v_seed = seed;
	v_face = CUSTOM0.w;
	v_m = UV;
	v_across = w;
	v_width = W;
	v_axis = normalize((MODEL_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	v_yaxis = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_ground = CUSTOM2.z;
	v_nails = CUSTOM2.xy;
	v_role = CUSTOM2.w;
	v_cover = UV2;
	v_length = L;
}

// A scan sampled at metres `m` (along the grain, across it) with this board's offset and flips;
// returns the uv and the flips' signs for the normal.
vec2 scan_uv(vec2 m, vec2 tile, bool grain_v, float seed, float k, out vec2 flip) {
	vec2 off = vec2(hash11(seed * 311.0 + k), hash11(seed * 577.0 + k + 3.0)) * variety;
	flip = vec2(rnd(seed, 20.0 + k) < 0.0 && variety > 0.5 ? -1.0 : 1.0, rnd(seed, 21.0 + k) < 0.0 && variety > 0.5 ? -1.0 : 1.0);
	vec2 uv = vec2(m.x * flip.x / tile.x + off.x, m.y * flip.y / tile.y + off.y);
	return grain_v ? uv.yx : uv;
}

// Fine relief and roughness sampled a little softer: at a metre, full-detail scan normals came out as
// single-pixel speckle (the cheap judge, 2026-11-08); a whole mip blurred the grain (Sean, #721), so 0.4.
uniform float detail_bias = 1.2;
// The fresh scans' colour sampled softer by this many mips (0: sharp). The probe (#721, round 3):
// pixel noise at 1 m 10.6 with both sharp, 6.8 with relief 2.0 and colour 1.0; 1.2 / 0.6 between.
uniform float albedo_bias = 0.6;
// The weathered scan's colour: was a mip softer against round 2's burlap (the judge, 2026-11-08), which
// blurred it (Sean, #721); round 3 replaced the scans instead, so sharp again. Long silvered grain and
// checks along the board on top.
uniform float weathered_bias = 0.0;
// Off since round 3: stretched over a board the 512 noise showed its grid as a woven crosshatch at
// 2560x1440 (the burlap); the new weathered scans carry real grain and checks.
uniform float weathered_grain = 0.0;

vec3 scan_normal(sampler2D tex, vec2 uv, vec2 flip, bool grain_v) {
	vec3 n = texture(tex, uv, detail_bias).rgb * 2.0 - 1.0;
	// OpenGL maps: red along the image's U, green up it (-V). Grain along U: U is along the board, V
	// across it. Grain along V (the uv swapped): U is across, V along, so along = -green, across = red
	// (the swap with the same sign turned the relief half round: cracks lit as ridges).
	if (grain_v) {
		n.xy = vec2(-n.y, n.x);
	} else {
		n.y = -n.y;
	}
	n.xy *= flip;
	return n;
}

void fragment() {
	float seed = v_seed;
	// Part 5: on an old wall now and then a board replaced, years newer than the rest.
	float ag = age;
	if (age > 0.6 && rnd(seed, 70.0) > 0.85) {
		ag = age * 0.3;
	}
	float face = v_face;
	vec2 m = v_m;
	// End grain: the scan squeezed along the grain to the ends' tight rings, darker and dry.
	bool end_grain = face > 0.5 && face < 1.5;
	if (end_grain) {
		m = vec2(m.x * 6.0, m.y * 0.4);
	}
	vec2 fa;
	vec2 uva = scan_uv(m, tile_a, grain_v_a, seed, 0.0, fa);
	vec3 col = texture(albedo_a, uva, albedo_bias).rgb;
	if (bisect < 1) {
		col = textureLod(albedo_a, vec2(0.5), 12.0).rgb;
	}
	if (grain_contrast < 0.999 && bisect >= 2) {
		col = mix(textureLod(albedo_a, uva, 7.0).rgb, col, grain_contrast);
	}
	vec3 nrm = bisect >= 3 ? scan_normal(normal_a, uva, fa, grain_v_a) : vec3(0.0, 0.0, 1.0);
	float rough = bisect >= 4 ? texture(rough_a, uva, detail_bias).r : 0.6;
	// The fresh grain against its neighbourhood, for paint thin enough to show it.
	float grain_hp = 1.0;
	if (paint > 0.0) {
		grain_hp = dot(col, vec3(0.333)) / max(dot(textureLod(albedo_a, uva, 6.0).rgb, vec3(0.333)), 0.01);
	}
	if (has_a2 && rnd(seed, 30.0) > 0.0 && variety > 0.5 && bisect >= 5) {
		vec2 f2;
		vec2 uv2 = scan_uv(m, tile_a2, grain_v_a2, seed, 1.0, f2);
		col = texture(albedo_a2, uv2, albedo_bias).rgb * a2_gain;
		if (grain_contrast < 0.999) {
			col = mix(textureLod(albedo_a2, uv2, 7.0).rgb * a2_gain, col, grain_contrast);
		}
		nrm = scan_normal(normal_a2, uv2, f2, grain_v_a2);
		rough = texture(rough_a2, uv2, detail_bias).r;
		if (paint > 0.0) {
			grain_hp = dot(col, vec3(0.333)) / max(dot(textureLod(albedo_a2, uv2, 6.0).rgb * a2_gain, vec3(0.333)), 0.01);
		}
	}
	// Saw arcs: centred off one edge every ~0.9 m along the board, rings 5 mm apart.
	if (saw_marks > 0.0 && face < 0.5 && bisect >= 5) {
		float kseg = floor(v_m.x / 0.9);
		vec2 c = vec2((kseg + 0.5) * 0.9 + rnd(seed, 60.0 + kseg) * 0.15, -0.55 * sign(rnd(seed, 61.0) + 0.01));
		vec2 dv = vec2(v_m.x, v_m.y) - c;
		float d = length(dv);
		float pitch = 0.0055 + 0.001 * rnd(seed, 62.0);
		float fw = fwidth(d) / pitch;
		float amp = saw_marks * (1.0 - smoothstep(0.2, 0.55, fw)) * (1.0 - 0.9 * ag);
		float ph = d / pitch * 6.2831853;
		col *= 1.0 + 0.035 * amp * sin(ph);
		vec2 g = dv / max(d, 1e-4);
		nrm.xy += g * cos(ph) * 0.08 * amp;
	}
	col *= mix(tint_new, tint_mid, smoothstep(0.0, 0.5, ag));
	// Per board: value and a warm-cool shift.
	if (bisect >= 5) {
		col *= 1.0 + value_jitter * variety * rnd(seed, 31.0);
		float h = hue_jitter * variety * rnd(seed, 32.0);
		col *= vec3(1.0 + h, 1.0, 1.0 - h);
		rough *= 1.0 + rough_jitter * variety * rnd(seed, 33.0);
	}

	// The large-scale layer, in the world's space: a wall's (along it, up) or a floor's plane.
	bool floor_face = abs(v_wnormal.y) > 0.7;
	vec2 q = floor_face ? v_world.xz : vec2(v_world.x + v_world.z, v_world.y);
	float n1 = mix(0.5, texture(big_noise, q / 7.0).r, variety);
	float n2 = mix(0.5, texture(big_noise, q / 1.7 + 0.37).r, variety);
	float age_layer = mix(layer_new, 1.0, ag);

	// Weathering: toward the grey scan, first where the sun and rain reach (patchy, the top and the
	// sun faces), all of it when old.
	if (has_b && weathering > 0.0 && bisect >= 6) {
		// Exposed wood is mostly grey by a few years; sheltered wood keeps its colour longer.
		float hw = v_world.y - v_ground;
		float eaves = floor_face ? 0.0 : smoothstep(wall_top - eaves_m, wall_top - 0.08, hw);
		float by_edge = face < 0.5 ? smoothstep(0.55, 0.95, abs(v_across)) * edge_shelter : 0.0;
		float shelter = clamp(max(eaves, by_edge), 0.0, 1.0) * (1.0 - 0.6 * smoothstep(0.5, 1.0, ag));
		if (bisect < 7) {
			shelter = 0.0;
		}
		float exposed_age = smoothstep(0.0, 0.42, ag);
		float wx = clamp(exposed_age * (1.0 - 0.85 * shelter) + (n1 - 0.5) * 0.35 + (n2 - 0.5) * 0.2, 0.0, 1.0) * weathering;
		if (wx > 0.001) {
			vec2 fb;
			vec2 uvb = scan_uv(m, tile_b, grain_v_b, seed, 2.0, fb);
			vec3 colb = texture(albedo_b, uvb, weathered_bias).rgb * tint_old;
			vec3 nb2 = vec3(0.0);
			float rb2 = 0.0;
			float sw = 0.0;
			if (b_stochastic > 0.0) {
				// The second sample: turned half round and moved by the board's seed.
				vec2 uvb2 = -uvb + vec2(hash11(seed * 71.0 + 0.3), hash11(seed * 53.0 + 0.7)) * 7.0;
				sw = smoothstep(0.3, 0.7, texture(big_noise, vec2(v_m.x / 0.9 + seed * 3.7, v_m.y / 0.5 + seed)).r) * b_stochastic;
				colb = mix(colb, texture(albedo_b, uvb2, weathered_bias).rgb * tint_old, sw);
				nb2 = scan_normal(normal_b, uvb2, -fb, grain_v_b);
				rb2 = texture(rough_b, uvb2, detail_bias).r;
			}
			// Long grain lines and checks (drying cracks) along the board, faded before they alias.
			if (face < 0.5 && weathered_grain > 0.0) {
				float fade = 1.0 - smoothstep(0.3, 1.0, fwidth(v_m.y) / 0.003);
				float gl = texture(big_noise, vec2(v_m.x / 0.9 + seed * 7.0, v_m.y / 0.006)).r;
				colb *= mix(1.0, 0.82 + 0.36 * gl, weathered_grain * fade);
				float ck = smoothstep(0.86, 0.93, texture(big_noise, vec2(v_m.x / 0.5 + seed * 3.0, v_m.y / 0.0025) + 0.5).r);
				colb *= 1.0 - 0.45 * ck * weathered_grain * fade * wx;
			}
			float oldness = smoothstep(0.6, 1.0, ag);
			if (age_split > 0.0) {
				vec3 soft = textureLod(albedo_b, uvb, 5.0).rgb * tint_old;
				float lb = dot(colb, vec3(0.333)) / max(dot(soft, vec3(0.333)), 0.01);
				colb = mix(colb, mix(soft, colb, 0.5) * 1.22, age_split * (1.0 - oldness));
				colb *= mix(1.0, clamp(lb, 0.0, 1.0), 0.55 * age_split * oldness);
			}
			colb *= 1.0 + value_jitter * variety * rnd(seed, 34.0);
			vec3 nb = scan_normal(normal_b, uvb, fb, grain_v_b);
			nb.xy *= mix(1.0, 0.55, age_split * (1.0 - oldness));
			float rb = texture(rough_b, uvb, detail_bias).r;
			if (sw > 0.0) {
				nb = normalize(mix(nb, nb2, sw));
				rb = mix(rb, rb2, sw);
			}
			col = mix(col, colb, wx);
			nrm = normalize(mix(nrm, nb, wx * 0.5));
			rough = mix(rough, rb, wx);
		}
	}

	// Paint (the uniforms' note): the coat by where it is on the wall and how long it's been there.
	float pcov = 0.0;
	vec3 pcol = paint_color;
	if (paint > 0.0 && bisect >= 9) {
		float hp = v_world.y - v_ground;
		float outside = 1.0 - paint_inside;
		// The sun's share: a wall by its facing (the shaded side keeps its colour), a deck by facing up.
		float sunk = floor_face ? clamp(v_wnormal.y, 0.0, 1.0)
				: mix(0.3, 1.0, clamp(dot(normalize(v_wnormal.xz + vec2(1e-4)), normalize(paint_sun.xz)), 0.0, 1.0));
		sunk *= outside * (1.0 - 0.7 * (floor_face ? 0.0 : smoothstep(wall_top - eaves_m, wall_top - 0.08, hp)));
		// A few years ~0.37 of old's failure, old all of it.
		// (A board replaced on an old wall was painted with it at some later coat: most of the wall's age.)
		float pag = mix(ag, age, 0.75);
		float years = 0.35 * smoothstep(0.0, 0.5, pag) + 0.65 * smoothstep(0.45, 1.0, pag);
		// Where water sits: the foot, a horizontal board's lower (drip) edge, the arrises, the ends.
		float foot = 1.0 - smoothstep(0.04, 0.55, hp);
		float drip = 0.0;
		if (!floor_face && abs(v_axis.y) < 0.5 && face < 0.5) {
			drip = smoothstep(0.5, 0.97, -v_across * sign(v_yaxis.y + 1e-4));
		}
		float arr = face < 0.5 ? smoothstep(0.82, 1.0, abs(v_across)) : 1.0;
		float endz = face < 0.5 ? 1.0 - smoothstep(0.0, 0.14, min(v_m.x, v_length - v_m.x)) : 1.0;
		float olds = smoothstep(0.45, 1.0, pag);
		float drive = years * (outside * (0.45 * sunk * olds + 0.5 * foot + 0.4 * drip + 0.25 * arr + 0.35 * endz)
				+ paint_inside * (0.3 * arr * smoothstep(0.5, 1.0, ag) + 0.15 * foot));
		drive *= paint_peel;
		// The film's failure field, in the board's own metres (flat seed: its own place), strips along
		// the grain over blots; the peel's edge sharp but never thinner than a pixel.
		vec2 pm = face < 0.5 ? v_m : m;
		vec2 so = vec2(hash11(seed * 13.7 + 0.1), hash11(seed * 29.1 + 0.2)) * 5.0;
		float strip = texture(big_noise, vec2(pm.x / 1.2, pm.y / 0.16) + so).r;
		float blot = texture(big_noise, pm / 0.4 + so * 1.3 + 0.5).r;
		float flake = texture(big_noise, vec2(pm.x / 0.12, pm.y / 0.05) + so * 0.7).r;
		// Stretched to about a 0.2 spread, so nothing peels where nothing drives it (no stray flecks).
		float field = (strip * 0.45 + blot * 0.4 + flake * 0.15 - 0.5) * 2.2 + 0.5;
		float thr = 1.02 - 0.6 * drive;
		float fw = max(fwidth(field), 0.003);
		float bare_top = drive > 0.0 ? smoothstep(thr - fw, thr + fw, field) : 0.0;
		float bare_wood = drive > 0.0 ? smoothstep(thr + 0.03 - fw, thr + 0.03 + fw, field) : 0.0;
		// The film's lifted edge round each peel (lit), and its shadow on what's under it.
		float lip = drive > 0.0 ? smoothstep(thr - 0.018 - fw, thr - fw, field) * (1.0 - bare_top) : 0.0;
		float under = drive > 0.0 ? bare_top * (1.0 - smoothstep(thr + fw, thr + 0.012 + fw, field)) : 0.0;
		// Cracks with the grain (a few years on), and across it as well when old (alligatoring), faded
		// before they'd alias.
		float near_k = 1.0 - smoothstep(0.35, 1.0, fwidth(pm.y) / 0.0015);
		float crk = 0.0;
		if (paint_crack > 0.0 && years > 0.0 && near_k > 0.0) {
			float cf = texture(big_noise, vec2(pm.x / 0.45, pm.y / 0.05) + so * 2.0).r;
			float cw = fwidth(cf);
			float line = 1.0 - smoothstep(0.006, 0.006 + cw, abs(cf - 0.5));
			float where = smoothstep(0.45, 0.62, texture(big_noise, pm / 0.5 + so + 0.25).r + 0.15 * sunk);
			crk = line * where * smoothstep(0.0, 0.5, years);
			float af = texture(big_noise, pm / 0.06 + so * 3.0).r;
			float aw = fwidth(af);
			float cell = 1.0 - smoothstep(0.008, 0.008 + aw, abs(af - 0.5));
			crk = max(crk, cell * smoothstep(0.55, 1.0, years) * (0.35 + 0.65 * sunk) * where);
			crk *= paint_crack * near_k;
		}
		// Brush marks along the grain: the ridges oil paint dries with.
		float bn = texture(big_noise, vec2(pm.x / 0.5, pm.y / 0.012) + so * 3.0).r - 0.5;
		float bfade = 1.0 - smoothstep(0.35, 1.0, fwidth(pm.y) / 0.0025);
		// The coat's colour: one bucket (a whisker a board), faded and chalked by the sun, yellowed
		// indoors, the grain under it showing as the film thins.
		pcol *= 1.0 + 0.02 * variety * rnd(seed, 35.0);
		pcol *= mix(vec3(1.0), vec3(1.0, 0.92, 0.76), paint_yellow * ag);
		float pl = dot(pcol, vec3(0.3, 0.59, 0.11));
		// Faded: duller and a little lighter, keeping its hue (an iron red goes brown-pink, not grey).
		pcol = mix(pcol, (mix(vec3(pl), pcol, 0.45) * 1.1 + 0.03) * vec3(1.04, 1.0, 0.9), paint_fade * years * sunk);
		float chalk = clamp(paint_chalk * years * sunk * (0.75 + 0.5 * (n1 - 0.5) + 0.7 * (n2 - 0.5)), 0.0, 1.0);
		pcol = mix(pcol, vec3(0.86, 0.83, 0.76), chalk * 0.25);
		float thin = mix(paint_thin_new, paint_thin, years) * (0.6 + 0.4 * sunk + 0.4 * paint_inside);
		float ghp = clamp(grain_hp, 0.45, 1.6);
		pcol *= mix(1.0, ghp, thin);
		pcol *= 1.0 + paint_brush * 0.07 * bn * bfade;
		vec3 prim = paint_under * mix(1.0, ghp, thin * 0.7);
		vec3 c = mix(pcol, prim, bare_top);
		// Bare wood out from under the coat greys in the sun as any bare wood does.
		vec3 bare = mix(col, vec3(dot(col, vec3(0.3, 0.59, 0.11))) * 1.12, 0.2 + 0.4 * sunk);
		c = mix(c, bare, bare_wood);
		c *= 1.0 + 0.1 * lip;
		c *= 1.0 - 0.45 * under;
		c *= 1.0 - 0.55 * crk * (1.0 - bare_wood);
		// Inside: hands' grime and polish in the rub band, scuffs at the foot (boots, chairs).
		float rub = 0.0;
		if (paint_inside > 0.0) {
			float band = smoothstep(wear_band.x - 0.1, wear_band.x, hp) * (1.0 - smoothstep(wear_band.y, wear_band.y + 0.1, hp));
			rub = paint_inside * ag * band * (0.45 + 0.55 * n2);
			c = mix(c, c * vec3(0.8, 0.76, 0.7), rub * 0.55);
			float sc = smoothstep(0.62, 0.7, texture(big_noise, vec2(q.x / 0.25, hp / 0.05) + so).r) * (1.0 - smoothstep(0.06, 0.35, hp));
			c *= 1.0 - 0.3 * sc * paint_inside * (0.3 + 0.7 * ag);
		}
		// Dust splashed up from the street, speckled at the foot, a film higher (outside).
		if (!floor_face) {
			float spk = smoothstep(0.5, 0.62, texture(big_noise, q / 0.16 + 0.3).r);
			float dust = outside * (0.12 + 0.88 * smoothstep(0.0, 0.5, ag)) * (1.0 - smoothstep(0.0, 0.35 + 0.3 * n2, hp)) * (0.35 + 0.65 * spk);
			c = mix(c, paint_dust * mix(1.0, ghp, 0.3), dust * 0.6);
		}
		pcov = paint * (1.0 - bare_wood);
		col = mix(col, c, paint);
		// The wood's relief through the coat (more as it erodes), the brush's ridges, the cracks' and
		// the peels' edges.
		float relief = mix(paint_relief, min(paint_relief * 1.7, 1.0), years);
		nrm.xy *= mix(1.0, relief, pcov);
		nrm.y += pcov * paint_brush * 0.25 * bn * bfade * (1.0 - years);
		float g1 = texture(big_noise, vec2(pm.x / 0.7, (pm.y + 0.002) / 0.06) + so).r - strip;
		nrm.y -= paint * lip * clamp(g1 * 60.0, -1.0, 1.0) * 0.6;
		float pr = mix(paint_rough_new, 0.94, max(chalk, years * 0.55));
		pr = mix(pr, 0.3, rub * 0.6);
		rough = mix(rough, pr, pcov);
	}

	float old_k = smoothstep(0.6, 1.0, ag);
	if (checks > 0.0 && old_k > 0.0 && face < 0.5 && bisect >= 9) {
		float fw = fwidth(v_m.y);
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			if (hash11(seed * 131.0 + fi * 17.0) > 0.35 + 0.5 * checks) {
				continue;
			}
			// The first three run in from an end; the rest lie in the board's length.
			float len = (0.12 + 0.5 * hash11(seed * 211.0 + fi * 5.0)) * (i < 3 ? 1.0 : 0.6);
			float from_end = i < 3 ? (hash11(seed * 17.0 + fi) < 0.5 ? 0.0 : 1.0) : -1.0;
			float x0 = from_end < 0.0 ? hash11(seed * 419.0 + fi * 3.0) * max(v_length - len, 0.0) : (from_end < 0.5 ? 0.0 : v_length - len);
			float t = (v_m.x - x0) / len;
			if (t < 0.0 || t > 1.0) {
				continue;
			}
			// Widest where it starts (the end), tapering to nothing; in the length, a lens.
			float taper = from_end < 0.0 ? sin(t * 3.14159) : (from_end < 0.5 ? 1.0 - t : t);
			float yc = rnd(seed, 90.0 + fi) * 0.36 * v_width + (texture(big_noise, vec2(v_m.x / 1.1 + seed * 5.0 + fi * 0.37, seed * 3.0)).r - 0.5) * 0.03;
			float wdt = (0.0006 + 0.0016 * hash11(seed * 61.0 + fi * 7.0)) * sqrt(max(taper, 0.0)) * (0.5 + 0.5 * checks);
			float dy = v_m.y - yc;
			float mk = (1.0 - smoothstep(wdt - fw * 0.5, wdt + fw, abs(dy))) * old_k * step(0.02, taper);
			col *= 1.0 - 0.88 * mk;
			// Its lips: the face falls away into it.
			float lip = (1.0 - smoothstep(wdt, wdt * 3.0 + fw, abs(dy))) * (1.0 - mk) * old_k;
			nrm.y += sign(dy) * -0.5 * lip;
		}
	}
	if (end_rot > 0.0 && old_k > 0.0 && !floor_face && abs(v_axis.y) > 0.7 && bisect >= 9) {
		float hr = v_world.y - v_ground;
		float top = (0.05 + 0.2 * hash11(seed * 23.0)) * end_rot;
		float rag = (texture(big_noise, vec2(v_m.y / 0.11 + seed * 9.0, hr / 0.6 + seed)).r - 0.5) * 0.12;
		float rot = (1.0 - smoothstep(top * 0.3, top, hr + rag)) * old_k;
		col = mix(col, col * vec3(0.4, 0.34, 0.29), rot * 0.85);
		rough = mix(rough, 1.0, rot);
	}
	if (contact > 0.0 && face < 0.5 && bisect >= 8) {
		float ym = v_m.y + v_width * 0.5;
		float d_lo = ym - v_cover.x;
		float d_hi = (v_width - ym) - v_cover.y;
		float sh = 0.0;
		if (v_cover.x > 0.0005) {
			sh = max(sh, step(0.0, d_lo) * exp(-max(d_lo, 0.0) / 0.012));
		}
		if (v_cover.y > 0.0005) {
			sh = max(sh, step(0.0, d_hi) * exp(-max(d_hi, 0.0) / 0.012));
		}
		col *= 1.0 - 0.55 * contact * sh;
	}
	// Beaded boards (inside walls and ceilings): a quirk cut along one edge and the bead rounded
	// beside it, as a beading plane leaves (the doctor's office, #765).
	if (bead > 0.0 && face < 0.5) {
		float yb = v_width * 0.5 - 0.011;
		float d = v_m.y - yb;
		float quirk = 1.0 - smoothstep(0.0007, 0.0007 + fwidth(v_m.y), abs(d));
		float tb = clamp(d / 0.0095, 0.0, 1.0);
		nrm.y += bead * step(0.0, d) * (0.5 - tb) * 1.4;
		col *= 1.0 - 0.45 * quirk * bead;
	}
	if (arris > 0.0 && face < 0.5) {
		float e = smoothstep(v_width * 0.5 - 0.0035, v_width * 0.5, abs(v_m.y));
		nrm.y += sign(v_m.y) * e * 0.9 * arris;
		// Down in the joint it's dark (a tongue-and-groove's V most of all).
		col *= 1.0 - mix(0.25, 0.5, varnish) * e * e * arris;
	}
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	if (!floor_face && bisect >= 9) {
		// Sun-fade: paler and greyer in broad patches.
		float f = sun_fade * age_layer * smoothstep(0.35, 0.85, n1) * (1.0 - pcov);
		col = mix(col, vec3(luma) * 1.12, f * 0.45);
		// Water streaks: long dark runs down the wall.
		float s = mix(0.5, texture(big_noise, vec2(q.x / 0.3, q.y / 6.0) + 0.71).r, variety);
		col *= 1.0 - streaks * age_layer * smoothstep(0.58, 0.8, s) * 0.3;
	} else if (bisect >= 9) {
		// A floor's traffic: dirt in blotches, dulled.
		col *= 1.0 - grime * age_layer * smoothstep(0.45, 0.85, n2) * 0.25;
	}
	// Grime from the ground up (splash and dust), patchy.
	float hgt = v_world.y - v_ground;
	float g = grime * age_layer * (1.0 - smoothstep(0.0, 0.55, hgt)) * (0.55 + 0.45 * n2);
	if (!floor_face && bisect >= 8) {
		col = mix(col, col * vec3(0.62, 0.55, 0.47), g);
	}
	// Dirt in the joints (the long faces' edges).
	if (face < 0.5 && bisect >= 8) {
		col *= 1.0 - joint_dirt * age_layer * smoothstep(0.72, 1.0, abs(v_across)) * 0.45;
	}
	if (end_grain && bisect >= 9) {
		col *= mix(0.62, 0.85, pcov);
		rough = max(rough, 0.85);
	}

	// Varnish: amber deepening with age, worn dull and then through where hands rub (the hand band,
	// its edges most); old varnish darkened and crazed. A board's edge faces sit inside a tight joint:
	// dark, no coat (they caught the sky as pale dashes, the judge 2026-11-08).
	float wear = 0.0;
	bool edge_face = face > 1.5;
	float rings = 0.0;
	if (varnish > 0.0 && bisect >= 9) {
		float band = smoothstep(wear_band.x - 0.1, wear_band.x, hgt) * (1.0 - smoothstep(wear_band.y, wear_band.y + 0.1, hgt));
		float edge = face < 0.5 ? smoothstep(0.8, 1.0, abs(v_across)) : 0.0;
		wear = ag * band * (0.6 * (0.6 + 0.4 * n2) + 0.5 * edge);
		// The bar's rail top: elbows every stool's width, and glass rings.
		if (v_role > 0.5 && face < 0.5 && v_wnormal.y > 0.7) {
			float ek = fract(v_m.x / 0.75 + hash11(seed * 91.0));
			float elbow = (1.0 - smoothstep(0.0, 0.3, abs(ek - 0.5))) * (0.7 + 0.3 * n2);
			wear += elbow * (0.15 + 0.85 * ag);
			float kr = floor(v_m.x / 0.3);
			vec2 cr = vec2((kr + 0.5) * 0.3 + rnd(seed, 80.0 + kr) * 0.09, rnd(seed, 81.0 + kr) * 0.01);
			vec2 dr = v_m - cr;
			float rr = 0.03 + 0.008 * rnd(seed, 82.0 + kr);
			float arc = smoothstep(-0.4, 0.5, sin(atan(dr.y, dr.x) + rnd(seed, 83.0 + kr) * 3.0));
			float here = step(-0.2, rnd(seed, 84.0 + kr));
			rings = here * arc * (1.0 - smoothstep(0.0012, 0.003, abs(length(dr) - rr))) * (0.25 + 0.75 * ag);
		}
		wear = clamp(wear, 0.0, 1.0);
		col *= mix(vec3(1.0), varnish_amber, varnish * (0.35 + 0.65 * ag) * (1.0 - wear * 0.6));
		// Old varnish darkens, and crazes into fine cracks.
		col *= mix(1.0, varnish_dark, varnish * smoothstep(0.5, 1.0, ag));
		float cz = abs(texture(big_noise, v_m * 2.2 + seed * 5.0).r - 0.5);
		float czw = fwidth(texture(big_noise, v_m * 2.2 + seed * 5.0).r);
		float craze = (1.0 - smoothstep(0.0, 0.012 + czw, cz)) * smoothstep(0.6, 1.0, ag) * (1.0 - smoothstep(0.02, 0.08, czw));
		col *= 1.0 - 0.3 * craze * varnish;
		// Worn through: paler raw wood; glass rings a pale haze in the coat.
		col = mix(col, col * 1.35 + 0.02, varnish * smoothstep(0.55, 0.95, wear) * 0.6);
		col = mix(col, col * 1.45 + 0.03, rings * 0.55);
		wear = max(wear, craze * 0.5);
		if (edge_face) {
			col *= 0.55;
		}
	}

	// Nails: heads not quite in a line (the studs' 16 in), rusting and streaking with ag.
	float nail = 0.0;
	float rust = 0.0;
	if (v_nails.x > 0.5 && face < 0.5 && bisect >= 9) {
		// Along the board in the world, so a wall's nails fall on its studs or girts (16 in).
		float sp = 0.406;
		float along = dot(v_world, v_axis);
		float k = floor(along / sp + 0.5);
		float dx = along - (k * sp + rnd(seed, 40.0 + k) * 0.008);
		vec2 down = vec2(-v_axis.y, -v_yaxis.y);
		for (int r = 0; r < 2; r++) {
			if (float(r) >= v_nails.x) {
				break;
			}
			float side = (r == 0 || v_nails.x < 1.5) ? -1.0 : 1.0;
			// metres across from the row (v_m.y is metres across from the face's middle)
			float dy = v_m.y - side * v_nails.y * v_width * 0.5 + rnd(seed, 50.0 + k + float(r)) * 0.004;
			vec2 o = vec2(dx, dy);
			nail = max(nail, 1.0 - smoothstep(0.0035, 0.0048, length(o)));
			// A rust run below the head, down the wall.
			if (!floor_face && length(down) > 0.5) {
				vec2 dn = normalize(down);
				float t = dot(o, dn);
				float off = abs(dot(o, vec2(-dn.y, dn.x)));
				float run = 0.03 + 0.05 * hash11(k + seed * 13.0);
				rust = max(rust, ag * ag * (1.0 - smoothstep(0.0012, 0.0035, off)) * step(0.0, t) * (1.0 - smoothstep(0.0, run, t)));
			}
		}
	}
	col = mix(col, col * vec3(0.72, 0.5, 0.36), rust * 0.6);
	vec3 head = mix(vec3(0.16, 0.15, 0.14), vec3(0.28, 0.14, 0.07), ag);
	// Painted over with the wall, rust coming through it in a few years.
	head = mix(head, mix(pcol * 0.9, vec3(0.3, 0.15, 0.08), smoothstep(0.2, 0.9, ag) * 0.75), pcov);
	col = mix(col, head, nail);

	// The last millimetres beside a joint hold wax and dirt: no coat's gleam there (a cupped board's
	// raised edge caught the sky as a pale line along every joint, the judge's dashes).
	float by_joint = face < 0.5 ? smoothstep(0.8, 0.97, abs(v_across)) : 0.0;
	ALBEDO = clamp(col, 0.0, 1.0);
	ROUGHNESS = clamp(rough + (roughness_add + 0.18 * ag * (1.0 - varnish)) * (1.0 - pcov) - nail * 0.2, 0.05, 1.0);
	SPECULAR = mix(edge_face && varnish > 0.0 ? 0.15 : mix(specular_wood, 0.5, varnish) * (1.0 - 0.6 * by_joint * varnish), 0.5, pcov);
	vec3 n = normalize(vec3(nrm.xy * normal_strength * (1.0 + 0.2 * ag * (1.0 - varnish)), max(nrm.z, 0.2)));
	NORMAL_MAP = n * 0.5 + 0.5;
	CLEARCOAT = edge_face ? 0.0 : varnish * (1.0 - smoothstep(0.5, 1.0, wear)) * (1.0 - 0.85 * by_joint);
	CLEARCOAT_ROUGHNESS = mix(0.06, 0.55, clamp(wear + ag * 0.25 + rings, 0.0, 1.0));
}

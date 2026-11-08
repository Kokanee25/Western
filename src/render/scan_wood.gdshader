shader_type spatial;
// The material library's woods (#701; docs/briefs/material-library.md): scanned CC0 maps (Poly
// Haven, ambientCG: assets/textures/scans/) drawn board by board, for the real look.
//
// Every board is its own mesh in its own frame (SamplePanel.board_mesh): X along its length
// [0, L], Y across its face [-W/2, W/2], Z through it (the face it shows is +Z). Its vertices carry
//   CUSTOM0 = (seed in [0, 1), x / L, 2y / W, face: 0 a long face, 1 an end (end grain), 2 an edge)
//   CUSTOM1 = (L, W, T, warp: how far this board twists, cups, bows and crooks, 0 true .. 1 an old shed's)
//   CUSTOM2 = (nail rows: 0, 1 or 2; their place across the face, 0..1 of the half width; ground y; unused)
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
// Planed wood takes a little sheen; rough-sawn none.
uniform float specular_wood = 0.35;

varying float v_seed;
varying float v_face;
varying vec2 v_m;        // metres along and across the face it shows
varying float v_across;  // -1..1 across a long face
varying vec3 v_world;
varying vec3 v_wnormal;
varying float v_ground;
varying vec2 v_nails;
varying float v_width;
varying vec3 v_axis;   // the board's length in the world
varying vec3 v_yaxis;  // across its face in the world

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
	float lift = 0.006 * lift_on;
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
}

// A scan sampled at metres `m` (along the grain, across it) with this board's offset and flips;
// returns the uv and the flips' signs for the normal.
vec2 scan_uv(vec2 m, vec2 tile, bool grain_v, float seed, float k, out vec2 flip) {
	vec2 off = vec2(hash11(seed * 311.0 + k), hash11(seed * 577.0 + k + 3.0)) * variety;
	flip = vec2(rnd(seed, 20.0 + k) < 0.0 && variety > 0.5 ? -1.0 : 1.0, rnd(seed, 21.0 + k) < 0.0 && variety > 0.5 ? -1.0 : 1.0);
	vec2 uv = vec2(m.x * flip.x / tile.x + off.x, m.y * flip.y / tile.y + off.y);
	return grain_v ? uv.yx : uv;
}

vec3 scan_normal(sampler2D tex, vec2 uv, vec2 flip, bool grain_v) {
	vec3 n = texture(tex, uv).rgb * 2.0 - 1.0;
	if (grain_v) {
		n.xy = n.yx;
	}
	// OpenGL maps: green up the image, which is -across here.
	n.y = -n.y;
	n.xy *= flip;
	return n;
}

void fragment() {
	float seed = v_seed;
	float face = v_face;
	vec2 m = v_m;
	// End grain: the scan squeezed along the grain to the ends' tight rings, darker and dry.
	bool end_grain = face > 0.5 && face < 1.5;
	if (end_grain) {
		m = vec2(m.x * 6.0, m.y * 0.4);
	}
	vec2 fa;
	vec2 uva = scan_uv(m, tile_a, grain_v_a, seed, 0.0, fa);
	vec3 col = texture(albedo_a, uva).rgb;
	vec3 nrm = scan_normal(normal_a, uva, fa, grain_v_a);
	float rough = texture(rough_a, uva).r;
	if (has_a2 && rnd(seed, 30.0) > 0.0 && variety > 0.5) {
		vec2 f2;
		vec2 uv2 = scan_uv(m, tile_a2, grain_v_a2, seed, 1.0, f2);
		col = texture(albedo_a2, uv2).rgb * a2_gain;
		nrm = scan_normal(normal_a2, uv2, f2, grain_v_a2);
		rough = texture(rough_a2, uv2).r;
	}
	// Saw arcs: centred off one edge every ~0.9 m along the board, rings 5 mm apart.
	if (saw_marks > 0.0 && face < 0.5) {
		float kseg = floor(v_m.x / 0.9);
		vec2 c = vec2((kseg + 0.5) * 0.9 + rnd(seed, 60.0 + kseg) * 0.15, -0.55 * sign(rnd(seed, 61.0) + 0.01));
		vec2 dv = vec2(v_m.x, v_m.y) - c;
		float d = length(dv);
		float pitch = 0.0055 + 0.001 * rnd(seed, 62.0);
		float fw = fwidth(d) / pitch;
		float amp = saw_marks * (1.0 - smoothstep(0.25, 0.7, fw)) * (1.0 - 0.6 * age);
		float ph = d / pitch * 6.2831853;
		col *= 1.0 + 0.07 * amp * sin(ph);
		vec2 g = dv / max(d, 1e-4);
		nrm.xy += g * cos(ph) * 0.18 * amp;
	}
	col *= mix(tint_new, tint_mid, smoothstep(0.0, 0.5, age));
	// Per board: value and a warm-cool shift.
	col *= 1.0 + value_jitter * variety * rnd(seed, 31.0);
	float h = hue_jitter * variety * rnd(seed, 32.0);
	col *= vec3(1.0 + h, 1.0, 1.0 - h);
	rough *= 1.0 + rough_jitter * variety * rnd(seed, 33.0);

	// The large-scale layer, in the world's space: a wall's (along it, up) or a floor's plane.
	bool floor_face = abs(v_wnormal.y) > 0.7;
	vec2 q = floor_face ? v_world.xz : vec2(v_world.x + v_world.z, v_world.y);
	float n1 = mix(0.5, texture(big_noise, q / 7.0).r, variety);
	float n2 = mix(0.5, texture(big_noise, q / 1.7 + 0.37).r, variety);
	float age_layer = mix(layer_new, 1.0, age);

	// Weathering: toward the grey scan, first where the sun and rain reach (patchy, the top and the
	// sun faces), all of it when old.
	if (has_b && weathering > 0.0) {
		float up = floor_face ? 0.0 : smoothstep(0.3, 2.0, v_world.y - v_ground);
		float wx = clamp(age * 1.35 - 0.35 + (n1 - 0.5) * 0.7 + (n2 - 0.5) * 0.3 + up * 0.15, 0.0, 1.0) * weathering;
		if (wx > 0.001) {
			vec2 fb;
			vec2 uvb = scan_uv(m, tile_b, grain_v_b, seed, 2.0, fb);
			vec3 colb = texture(albedo_b, uvb).rgb * tint_old;
			colb *= 1.0 + value_jitter * variety * rnd(seed, 34.0);
			vec3 nb = scan_normal(normal_b, uvb, fb, grain_v_b);
			float rb = texture(rough_b, uvb).r;
			col = mix(col, colb, wx);
			nrm = normalize(mix(nrm, nb, wx));
			rough = mix(rough, rb, wx);
		}
	}

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	if (!floor_face) {
		// Sun-fade: paler and greyer in broad patches.
		float f = sun_fade * age_layer * smoothstep(0.35, 0.85, n1);
		col = mix(col, vec3(luma) * 1.12, f * 0.45);
		// Water streaks: long dark runs down the wall.
		float s = mix(0.5, texture(big_noise, vec2(q.x / 0.3, q.y / 6.0) + 0.71).r, variety);
		col *= 1.0 - streaks * age_layer * smoothstep(0.58, 0.8, s) * 0.3;
	} else {
		// A floor's traffic: dirt in blotches, dulled.
		col *= 1.0 - grime * age_layer * smoothstep(0.45, 0.85, n2) * 0.25;
	}
	// Grime from the ground up (splash and dust), patchy.
	float hgt = v_world.y - v_ground;
	float g = grime * age_layer * (1.0 - smoothstep(0.0, 0.55, hgt)) * (0.55 + 0.45 * n2);
	if (!floor_face) {
		col = mix(col, col * vec3(0.62, 0.55, 0.47), g);
	}
	// Dirt in the joints (the long faces' edges).
	if (face < 0.5) {
		col *= 1.0 - joint_dirt * age_layer * smoothstep(0.72, 1.0, abs(v_across)) * 0.45;
	}
	if (end_grain) {
		col *= 0.62;
		rough = max(rough, 0.85);
	}

	// Varnish: amber deepening with age, worn dull and then through where hands rub and at edges.
	float wear = 0.0;
	if (varnish > 0.0) {
		float band = smoothstep(wear_band.x - 0.1, wear_band.x, hgt) * (1.0 - smoothstep(wear_band.y, wear_band.y + 0.1, hgt));
		float edge = face < 0.5 ? smoothstep(0.8, 1.0, abs(v_across)) : 1.0;
		wear = clamp(age * (0.6 * band * (0.6 + 0.4 * n2) + 0.5 * edge * band + 0.25 * edge), 0.0, 1.0);
		col *= mix(vec3(1.0), varnish_amber, varnish * (0.35 + 0.65 * age) * (1.0 - wear * 0.6));
		// Worn through: paler raw wood.
		col = mix(col, col * 1.35 + 0.02, varnish * smoothstep(0.55, 0.95, wear) * 0.6);
	}

	// Nails: heads not quite in a line (the studs' 16 in), rusting and streaking with age.
	float nail = 0.0;
	float rust = 0.0;
	if (v_nails.x > 0.5 && face < 0.5) {
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
				rust = max(rust, age * age * (1.0 - smoothstep(0.0012, 0.0035, off)) * step(0.0, t) * (1.0 - smoothstep(0.0, run, t)));
			}
		}
	}
	col = mix(col, col * vec3(0.72, 0.5, 0.36), rust * 0.6);
	vec3 head = mix(vec3(0.16, 0.15, 0.14), vec3(0.28, 0.14, 0.07), age);
	col = mix(col, head, nail);

	ALBEDO = clamp(col, 0.0, 1.0);
	ROUGHNESS = clamp(rough + roughness_add + 0.18 * age * (1.0 - varnish) - nail * 0.2, 0.05, 1.0);
	SPECULAR = mix(specular_wood, 0.5, varnish);
	vec3 n = normalize(vec3(nrm.xy * normal_strength * (1.0 + 0.2 * age * (1.0 - varnish)), max(nrm.z, 0.2)));
	NORMAL_MAP = n * 0.5 + 0.5;
	CLEARCOAT = varnish * (1.0 - smoothstep(0.5, 1.0, wear));
	CLEARCOAT_ROUGHNESS = mix(0.06, 0.55, clamp(wear + age * 0.25, 0.0, 1.0));
}

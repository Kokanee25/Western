shader_type spatial;
// The material library's stone and lime (#860, #857; config/material_library.json `rubble_stone`,
// `plaster_whitewash`, `rubble_whitewash`; StoneFinish sets it): a stone building's walls drawn over
// the builder's stone pieces (stone.gd), whose members stay as they are.
//
// Coursed rubble, laid in the building's own space (`to_local`), not per piece, so the joints run
// across the pieces' seams and hide them: courses of uneven height whose beds wander a little, each
// course's hammer-squared stones of uneven length (the masonry lab's sizes, materials.json
// `rubble_stone`: 0.35 x 0.22 m, jitter 0.35, joints 0.03), each stone its own tone, its face domed
// and tilted, its arrises knocked round, set in thick recessed lime joints with spalls (pinnings) in
// the wide ones. Dressed stone (a vertex's COLOR.g: the lintels, sills, coping, steps, flags; and the
// quoins at `corners`, laid in the shader in alternating long and short courses) is larger, tooled,
// lighter, with fine joints at its piece's own edges (UV, UV2: where on the face, its size).
//
// Weathering in the building's space: damp and the street's dirt rising from the ground (`ground`,
// the spec's plane), a salt line at the damp's top; streaks under every drip line (`drips`: the sills'
// and coping's outer edges); old lime wash left in the joints and hollows. Inside (`regions`: a face
// looking into one), the region's finish instead: lime plaster whitewashed (1) or bare rubble
// whitewashed (2), a grimy band where men lean, scuffs low, soot high.
//
// Ideas, not code: coursed rubble's look from Rankine's "Manual of Civil Engineering" (1862) and
// Mitchell's "Building Construction" (1888) plates; the rounded-box distance from Inigo Quilez's
// articles on 2D distance functions; the bump from Mikkelsen 2010 (real_look.gdshaderinc).

#include "res://src/render/real_look.gdshaderinc"

uniform sampler2D big_noise : filter_linear_mipmap, repeat_enable;
// A scanned stone face (CC0) for the grain inside each stone, where the library has one.
uniform bool has_face = false;
uniform sampler2D face_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float face_tile = 1.0;
uniform vec3 face_mean = vec3(0.5);
// A scanned plaster (CC0) for the inside coat, where the library has one.
uniform bool has_plaster = false;
uniform sampler2D plaster_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float plaster_tile = 1.5;
uniform vec3 plaster_mean = vec3(0.5);

// --- the rubble -----------------------------------------------------------------------------------
uniform vec2 stone_size = vec2(0.35, 0.22);   // a stone's length and height (m)
uniform float size_jitter = 0.35;
uniform float joint = 0.03;                    // the joints' mean width (m)
uniform float joint_depth = 0.014;             // how far the mortar lies back of the faces (m)
uniform float stone_relief = 0.012;            // a stone's dome (m)
uniform float bed_wander = 0.018;              // how far a course's bed wanders up and down (m)
uniform float arris_round = 0.035;             // the stones' corners knocked round (m)
uniform vec3 tone_a : source_color = vec3(0.6, 0.54, 0.45);  // buff sandstone
uniform vec3 tone_b : source_color = vec3(0.55, 0.52, 0.47);  // grey limestone
uniform vec3 tone_c : source_color = vec3(0.58, 0.5, 0.41);  // warm tan
uniform vec3 tone_d : source_color = vec3(0.49, 0.43, 0.36);  // the odd dark brown stone
uniform float tone_spread = 0.12;              // a stone's own value shift
uniform vec3 mortar_color : source_color = vec3(0.72, 0.69, 0.62);
uniform vec3 dressed_color : source_color = vec3(0.7, 0.64, 0.54);
uniform float dressed_joint = 0.006;
uniform float age = 0.5;                       // 0 new .. 1 old
uniform float limewash = 0.25;                 // old lime wash left outside
uniform vec3 limewash_color : source_color = vec3(0.82, 0.8, 0.74);
uniform float roughness_stone = 0.86;
uniform float roughness_mortar = 0.95;
uniform float normal_strength = 1.0;
// The quoins: corners in the building's x, z (convex corners of its footprint), their stones' long
// and short faces and course height.
uniform int corner_count = 0;
uniform vec2 corners[16];
uniform vec3 quoin = vec3(0.45, 0.3, 0.3);

// --- weathering -----------------------------------------------------------------------------------
uniform mat4 to_local = mat4(1.0);             // world -> the building's space
uniform vec3 ground = vec3(-1000.0, 0.0, 0.0); // the ground's y = g.x + g.y x + g.z z (building space)
uniform float damp_height = 0.45;
uniform vec3 damp_tint : source_color = vec3(0.62, 0.58, 0.54);
uniform float dirt_height = 0.28;
uniform vec3 dirt_color : source_color = vec3(0.5, 0.42, 0.33);
uniform float streaks = 0.6;
uniform vec3 streak_color : source_color = vec3(0.32, 0.3, 0.28);
uniform int drip_count = 0;
uniform vec4 drips[96];                        // a drip line's ends (x0, z0, x1, z1)
uniform vec4 drip_at[96];                      // (its y, its out x, its out z, how far it streaks)

// --- inside ---------------------------------------------------------------------------------------
uniform int region_count = 0;
uniform vec4 regions[8];                       // (x0, z0, x1, z1) in the building's space
uniform vec4 region_at[8];                     // (floor y, ceiling y, finish: 1 plaster, 2 rubble whitewashed, 0)
uniform vec3 whitewash_color : source_color = vec3(0.86, 0.85, 0.8);
uniform vec3 plaster_color : source_color = vec3(0.74, 0.72, 0.67);
uniform float inside_age = 0.6;
uniform vec2 grime_band = vec2(0.85, 1.55);    // over the floor: where men lean and hands go
uniform vec3 grime_color : source_color = vec3(0.5, 0.45, 0.38);
uniform float soot = 0.25;

varying vec3 v_local;
varying vec3 v_lnormal;
varying flat float v_seed;
varying flat float v_dressed;
varying vec2 v_uv;
varying flat vec2 v_size;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_local = (to_local * vec4(w, 1.0)).xyz;
	v_lnormal = normalize(mat3(to_local) * (mat3(MODEL_MATRIX) * NORMAL));
	v_seed = COLOR.r;
	v_dressed = COLOR.g;
	v_uv = UV;
	v_size = UV2;
}

float h11(float n) { return fract(sin(n * 127.1 + 0.31) * 43758.5453); }
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + 0.17) * 43758.5453); }
float nz(vec2 p) { return texture(big_noise, p).r; }

// A rounded box's distance (Quilez): p from its centre, b its half size, r the rounding.
float rbox(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// A course's bed under stone row k at u (shared by the courses either side: they meet on it).
float bed(float k, float u) {
	float base = k * stone_size.y + stone_size.y * 0.32 * (h11(k) - 0.5);
	return base + bed_wander * (nz(vec2(u * 0.11, k * 0.173)) - 0.5) * 2.0;
}

// The rubble at (u along the face, v up): x the distance to the stone's edge (< 0 in a stone), y the
// stone's id, z its dome (0 at its edge .. 1 in its middle), w the local mortar width. A stone is its
// cell's box set in from its neighbours by its own joint, its sides out of plumb, its corners broken
// off unevenly (a convex outline from half-planes), the odd one split in two.
vec4 rubble(vec2 p, out vec2 local, out vec2 half_size) {
	float k = floor(p.y / stone_size.y);
	if (p.y < bed(k, p.x)) { k -= 1.0; }
	else if (p.y >= bed(k + 1.0, p.x)) { k += 1.0; }
	float y0 = bed(k, p.x);
	float y1 = bed(k + 1.0, p.x);
	// The course's stones: their length by the course, each joint jittered.
	float len = stone_size.x * mix(0.7, 1.45, h11(k * 3.7 + 1.3));
	float off = h11(k * 5.1 + 2.9) * len;
	float j = floor((p.x + off) / len);
	float a = (j + size_jitter * (h21(vec2(j, k)) - 0.5) * 1.4) * len - off;
	if (p.x < a) { j -= 1.0; }
	a = (j + size_jitter * (h21(vec2(j, k)) - 0.5) * 1.4) * len - off;
	float b = (j + 1.0 + size_jitter * (h21(vec2(j + 1.0, k)) - 0.5) * 1.4) * len - off;
	if (p.x >= b) {
		j += 1.0;
		a = b;
		b = (j + 1.0 + size_jitter * (h21(vec2(j + 1.0, k)) - 0.5) * 1.4) * len - off;
	}
	float id = h21(vec2(j * 1.37 + 0.5, k * 2.11 + 0.7));
	// The odd long stone split in two (a smaller one and its neighbour).
	if (h11(id * 3.3) < 0.22 && b - a > stone_size.x * 0.75) {
		float cut = mix(a, b, 0.32 + 0.36 * h11(id * 4.4));
		if (p.x < cut) { b = cut; id = fract(id * 7.13 + 0.21); } else { a = cut; id = fract(id * 3.71 + 0.47); }
	}
	// Each side's half joint its own: a stone set a little in from its neighbours, more on some sides.
	vec4 inset = joint * 0.5 * (0.35 + 1.5 * vec4(h11(id * 91.0), h11(id * 37.0), h11(id * 53.0), h11(id * 71.0)));
	vec2 lo = vec2(a + inset.x, y0 + inset.y);
	vec2 hi = vec2(b - inset.z, y1 - inset.w);
	vec2 c = (lo + hi) * 0.5;
	half_size = max((hi - lo) * 0.5, vec2(0.01));
	local = p - c;
	// Out of plumb sides, a bed and a top a little off level.
	vec4 slope = (vec4(h11(id * 11.0), h11(id * 17.0), h11(id * 19.0), h11(id * 23.0)) - 0.5) * vec4(0.3, 0.3, 0.12, 0.12);
	float dl = (lo.x + slope.x * local.y) - p.x;
	float dr = p.x - (hi.x + slope.y * local.y);
	float db = (lo.y + slope.z * local.x) - p.y;
	float dt = p.y - (hi.y + slope.w * local.x);
	float d = max(max(dl, dr), max(db, dt));
	// Its corners knocked off, each its own.
	float m = min(half_size.x, half_size.y);
	vec4 cuts = arris_round * (0.7 + 0.6 * age) * (0.2 + 1.6 * vec4(h11(id * 29.0), h11(id * 31.0), h11(id * 43.0), h11(id * 47.0)));
	cuts = min(cuts, vec4(m * 0.9));
	const float R2 = 0.70710678;
	d = max(d, ((p.x - hi.x) + (p.y - hi.y) + cuts.x) * R2);
	d = max(d, ((lo.x - p.x) + (p.y - hi.y) + cuts.y) * R2);
	d = max(d, ((p.x - hi.x) + (lo.y - p.y) + cuts.z) * R2);
	d = max(d, ((lo.x - p.x) + (lo.y - p.y) + cuts.w) * R2);
	// Hammer-dressed edges: the outline wobbles, coarse and fine.
	d += 0.007 * (nz(p * 0.9 + id * 7.0) - 0.5) * 2.0 + 0.003 * (nz(p * 3.7 + id) - 0.5) * 2.0;
	float dome = clamp(-d / max(m, 0.01), 0.0, 1.0);
	return vec4(d, id, dome, (inset.x + inset.z + inset.y + inset.w) * 0.5);
}

vec3 stone_tone(float id) {
	float t = h11(id * 17.0);
	vec3 c = t < 0.38 ? tone_a : (t < 0.7 ? tone_b : (t < 0.93 ? tone_c : tone_d));
	c *= 1.0 + tone_spread * (h11(id * 29.0) - 0.5) * 2.0;
	c = mix(c, c.gbr * 0.5 + c * 0.5, 0.15 * (h11(id * 41.0) - 0.5));
	return c;
}

// The region a face looks into (0 none): a point a little in front of it inside one's rect.
vec2 region_of(vec3 p, vec3 n) {
	vec3 q = p + n * 0.2;
	for (int i = 0; i < region_count; i++) {
		vec4 r = regions[i];
		vec4 at = region_at[i];
		if (q.x > r.x && q.x < r.z && q.z > r.y && q.z < r.w && q.y > at.x - 0.4 && q.y < at.y + 0.3) {
			return vec2(at.z, float(i));
		}
	}
	return vec2(0.0);
}

void fragment() {
	vec3 p = v_local;
	vec3 n = v_lnormal;
	bool top = abs(n.y) > 0.7;
	// The face's own plane: u along it, v up (a top: x and z).
	float u = top ? p.x : (abs(n.x) > abs(n.z) ? p.z * sign(n.x) * -1.0 : p.x * sign(n.z));
	vec2 fp = top ? p.xz : vec2(u, p.y);
	float gy = ground.x + ground.y * p.x + ground.z * p.z;
	float over = p.y - gy;
	vec2 reg = region_of(p, n);
	float finish = reg.x;

	vec3 col;
	float h = 0.0;
	float occl = 1.0;
	float rough = roughness_stone;
	float in_mortar = 0.0;
	float stone_mask = 1.0;
	float sid = v_seed;
	vec2 local = vec2(0.0);
	vec2 hs = vec2(0.5);
	// Quoins: within a corner's long or short face of a vertical face, a dressed stone.
	float quoin_here = 0.0;
	vec2 qlocal = vec2(0.0);
	vec2 qsize = vec2(0.0);
	if (!top && corner_count > 0 && finish < 0.5) {
		for (int i = 0; i < corner_count; i++) {
			vec2 c = corners[i];
			vec2 dxz = p.xz - c;
			bool on_x = abs(n.z) > abs(n.x);  // a face along x (front or back)
			float along = on_x ? abs(dxz.x) : abs(dxz.y);
			float across = on_x ? abs(dxz.y) : abs(dxz.x);
			if (across > 0.02 || along > quoin.x + 0.05) { continue; }
			float q = floor((p.y - gy) / quoin.z);
			// Long and short faces alternate, the other way round on the corner's other face.
			bool long_face = mod(q + (on_x ? 0.0 : 1.0) + floor(h21(c) * 2.0), 2.0) < 0.5;
			float ql = long_face ? quoin.x : quoin.y;
			ql *= 1.0 + 0.08 * (h21(vec2(q, c.x + c.y)) - 0.5);
			if (along < ql) {
				quoin_here = 1.0;
				sid = h21(vec2(q * 1.7, c.x * 3.1 + c.y));
				float qy0 = gy + q * quoin.z;
				qlocal = vec2(along, p.y - qy0);
				qsize = vec2(ql, quoin.z);
			}
		}
	}

	bool dressed = v_dressed > 0.5 || quoin_here > 0.5;
	if (finish > 0.5 && finish < 1.5) {
		// --- Lime plaster, whitewashed -----------------------------------------------------------
		vec2 pp = top ? p.xz : vec2(u, p.y);
		float und = nz(pp * 0.05) * 0.004 + nz(pp * 0.3 + 3.1) * 0.0012;
		h = und;
		vec3 base = plaster_color;
		if (has_plaster) {
			vec3 s = texture(plaster_albedo, pp / plaster_tile).rgb;
			base *= clamp(s / max(plaster_mean, vec3(0.05)), 0.7, 1.3);
		}
		// The wash: thick and fresh mostly, thin where it's worn, flaked in patches with age.
		float thin = smoothstep(0.55, 0.85, nz(pp * 0.4 + 7.7)) * (0.3 + 0.7 * inside_age);
		// Flaked where the coat let go (old), the plaster's grey a shade under the white, a lip at its edge.
		float fn = nz(pp * 0.7 + 1.9) + 0.08 * nz(pp * 6.0);
		float flake = smoothstep(0.84 - 0.06 * inside_age, 0.86 - 0.06 * inside_age, fn) * smoothstep(0.3, 0.8, inside_age);
		float lip = smoothstep(0.8 - 0.06 * inside_age, 0.84 - 0.06 * inside_age, fn) - flake;
		vec3 wash = whitewash_color * (0.95 + 0.07 * nz(pp * 2.3)) * (0.97 + 0.03 * nz(pp * 9.0));
		col = mix(wash, mix(wash, base, 0.6), clamp(thin * 0.4 + flake * 0.55, 0.0, 1.0));
		h += flake * -0.0007 + lip * 0.0004;
		rough = 0.92;
		stone_mask = 0.0;
	} else {
		// --- Stone ----------------------------------------------------------------------------------
		if (dressed) {
			// One stone: its piece's face (UV in 0..1 over UV2 metres) or the quoin's.
			vec2 m = quoin_here > 0.5 ? qlocal : v_uv * v_size;
			vec2 sz = quoin_here > 0.5 ? qsize : v_size;
			float edge = min(min(m.x, sz.x - m.x), min(m.y, sz.y - m.y));
			float jw = dressed_joint * (0.8 + 0.6 * nz(fp * 2.0));
			in_mortar = 1.0 - smoothstep(jw * 0.5, jw, edge);
			// Tooled: fine parallel batting, a margin drafted smoother, the arris bruised.
			float draft = smoothstep(0.03, 0.045, edge);
			float tool = sin((fp.x * 0.7 + fp.y) * 180.0 + nz(fp * 3.0) * 9.0) * 0.5 + 0.5;
			h = 0.00035 * tool * draft + 0.002 * (nz(fp * 1.7 + sid * 9.0) - 0.5) - in_mortar * 0.006
				- 0.003 * (1.0 - smoothstep(0.0, 0.025, edge)) * nz(fp * 6.0 + sid);
			col = dressed_color * (1.0 + 0.08 * (h11(sid * 23.0 + 1.0) - 0.5) * 2.0);
			col *= 0.88 + 0.2 * nz(fp * 0.6 + sid * 5.0);
			col *= 0.94 + 0.1 * nz(fp * 2.9 + sid);
			if (has_face) {
				vec3 sc = texture(face_albedo, (fp + vec2(h11(sid * 7.0), h11(sid * 11.0)) * 3.0) / (face_tile * 1.6)).rgb;
				vec3 ratio = clamp(sc / max(face_mean, vec3(0.05)), 0.7, 1.3);
				col *= mix(vec3(1.0), ratio, 0.6);
				h += 0.0015 * dot(sc - face_mean, vec3(0.333));
			}
			col *= mix(1.05, 0.88, age);
			col = mix(col, col * vec3(0.66, 0.6, 0.54), smoothstep(0.58, 0.85, nz(fp * 0.5 + sid * 3.0)) * age * 0.5);
			occl = mix(1.0, 0.55, in_mortar);
			col = mix(col, mortar_color * mix(0.95, 0.75, age), in_mortar);
			rough = mix(0.8, roughness_mortar, in_mortar);
			stone_mask = 1.0 - in_mortar;
			local = m - sz * 0.5;
			hs = sz * 0.5;
		} else {
			vec4 r = rubble(fp, local, hs);
			float aa = max(fwidth(r.x), 0.0005);
			stone_mask = 1.0 - smoothstep(-aa, aa, r.x);
			in_mortar = 1.0 - stone_mask;
			sid = r.y;
			// Pinnings: small spalls tapped into the wide joints.
			float pin = 0.0;
			if (r.x > 0.012) {
				vec2 pc = floor(fp / 0.06);
				vec2 pl = fp - (pc + 0.5) * 0.06 - (vec2(h21(pc), h21(pc + 7.0)) - 0.5) * 0.02;
				float pr = 0.012 + 0.01 * h21(pc + 3.0);
				float pd = max(abs(pl.x) * 0.8 + abs(pl.y) * 0.5, length(pl * vec2(0.9, 1.5))) + 0.004 * (nz(fp * 5.0) - 0.5);
				pin = h21(pc + 11.0) > 0.82 ? 1.0 - smoothstep(pr - aa, pr + aa, pd) : 0.0;
				pin *= smoothstep(0.012, 0.02, r.x);
			}
			// The stone's face: domed, tilted as it was set, pitted.
			vec2 tilt = vec2(h11(r.y * 61.0), h11(r.y * 67.0)) - 0.5;
			float face = stone_relief * (0.55 + 0.45 * h11(r.y * 5.0)) * sqrt(r.z)
				+ dot(local, tilt) * 0.05
				+ 0.003 * (nz(fp * 2.2 + r.y * 13.0) - 0.5) + 0.0012 * (nz(fp * 7.0 + r.y) - 0.5);
			vec3 st = stone_tone(r.y);
			st *= 0.9 + 0.2 * nz(fp * 0.8 + r.y * 3.0);
			if (has_face) {
				vec2 fo = vec2(h11(r.y * 7.0), h11(r.y * 11.0));
				vec3 sc = texture(face_albedo, (fp + fo * 3.0) / face_tile).rgb;
				st *= clamp(sc / max(face_mean, vec3(0.05)), 0.6, 1.4);
				face += 0.004 * (dot(sc - face_mean, vec3(0.333)));
			}
			float mort = -joint_depth * (0.45 + 0.9 * age) + 0.0025 * (nz(fp * 4.0 + 5.0) - 0.5) - 0.004 * smoothstep(0.0, 0.02, r.x);
			h = mix(mort, face, stone_mask);
			h = mix(h, -joint_depth * 0.5 + 0.002, pin);
			// Age: new stone fresh from the quarry, paler at its knocked arrises; with the years a grey-brown
			// patina over it, a dark crust in patches (desert varnish), the arrises dulled, grit in the pits.
			float rim = 1.0 - smoothstep(0.0, 0.02, -r.x);
			st = mix(st, st * 1.14, rim * 0.5 * (1.0 - age));
			st *= mix(1.06, 0.9, age);
			st = mix(st, vec3(dot(st, vec3(0.3, 0.4, 0.3))) * vec3(1.0, 0.96, 0.9), 0.3 * age);
			float crust = smoothstep(0.55, 0.8, nz(fp * 0.45 + r.y * 2.0) + 0.15 * nz(fp * 3.0)) * age;
			st = mix(st, st * vec3(0.62, 0.56, 0.5), crust * 0.6);
			st = mix(st, st * 0.82, (1.0 - smoothstep(0.0, 0.006, face - 0.003)) * 0.4 * age);
			vec3 mc = mortar_color * (0.92 + 0.12 * nz(fp * 3.0 + 1.0));
			mc = mix(mc * 1.06, mc * vec3(0.72, 0.69, 0.64), age);
			mc = mix(mc, mc * 0.8, smoothstep(0.4, 0.8, nz(fp * 1.3 + 3.0)) * age);
			col = mix(mc, st, stone_mask);
			col = mix(col, stone_tone(h21(floor(fp / 0.06))) * (0.85 + 0.2 * nz(fp * 4.0)), pin);
			// Deep joints and the stones' shadowed undersides.
			occl = mix(0.5 + 0.25 * smoothstep(0.01, 0.03, r.w), 1.0, stone_mask);
			occl *= 1.0 - 0.15 * (1.0 - smoothstep(0.0, 0.04, -r.x)) * stone_mask * smoothstep(0.0, -0.6, local.y / hs.y);
			rough = mix(roughness_mortar, roughness_stone, stone_mask);
		}
		if (finish > 1.5) {
			// --- Bare rubble whitewashed: the coat over stone and joint alike, thinner on the high
			// spots (the stone's tone just through), thick and pooled in the joints.
			float thin = (1.0 - in_mortar) * smoothstep(0.004, 0.012, h) * 0.35 + 0.15 * smoothstep(0.6, 0.9, nz(fp * 0.5 + 2.0)) * inside_age;
			vec3 wash = whitewash_color * (0.95 + 0.08 * nz(fp * 2.0));
			col = mix(wash, col, clamp(thin, 0.0, 0.6));
			rough = 0.93;
		} else {
			// Outside: the old lime wash left in the joints and the stones' hollows.
			float lw = limewash * smoothstep(0.45, 0.75, nz(fp * 0.35 + 4.4)) * smoothstep(0.1, 0.6, age);
			lw *= mix(0.5, 1.0, in_mortar) * smoothstep(0.004, -0.004, h - 0.002);
			col = mix(col, limewash_color, clamp(lw, 0.0, 0.8));
		}
	}

	if (finish < 0.5) {
		// --- Outside weathering ----------------------------------------------------------------------
		// Damp rising from the ground, ragged, a salt line at its top; the street's dirt splashed low.
		float dh = damp_height * (0.7 + 0.6 * nz(vec2(u * 0.25, 0.3)));
		float damp = 1.0 - smoothstep(dh - 0.12, dh + 0.04, over);
		float salt = smoothstep(dh - 0.05, dh, over) * (1.0 - smoothstep(dh, dh + 0.06, over)) * (0.4 + 0.6 * nz(vec2(u * 1.3, 2.0)));
		float dirt = 1.0 - smoothstep(dirt_height * (0.4 + 0.8 * nz(vec2(u * 0.9, 5.0))), dirt_height * 1.2, over);
		dirt *= 0.55 + 0.45 * nz(fp * 3.0);
		col = mix(col, col * damp_tint, damp * (0.45 + 0.35 * age));
		col = mix(col, vec3(0.78, 0.76, 0.7), salt * 0.35 * age);
		col = mix(col, col * 0.5 + dirt_color * (0.4 + 0.15 * nz(fp * 5.0)), dirt * (0.25 + 0.25 * age));
		rough = mix(rough, 1.0, dirt * 0.5);
		// Streaks under the drip lines: down from each sill and the coping's edge, fading.
		if (!top) {
			float sk = 0.0;
			for (int i = 0; i < drip_count; i++) {
				vec4 dl = drips[i];
				vec4 da = drip_at[i];
				if (p.y > da.x + 0.01 || p.y < da.x - da.w) { continue; }
				vec2 a = dl.xy;
				vec2 b = dl.zw;
				vec2 ab = b - a;
				float t = dot(p.xz - a, ab) / max(dot(ab, ab), 1e-5);
				vec2 onl = a + ab * clamp(t, 0.0, 1.0);
				vec2 off = p.xz - onl;
				// On the face under the line (not its sides), a hand's breadth past its ends at most.
				if (abs(dot(off, vec2(-da.z, da.y))) > 0.15 || abs(dot(off, da.yz)) > 0.12) { continue; }
				float past = length(ab) * (t < 0.0 ? -t : max(t - 1.0, 0.0));
				float down = (da.x - p.y) / max(da.w, 0.1);
				float runs = smoothstep(0.62, 0.85, nz(vec2(u * 0.9, da.x * 0.37)) + 0.12 * nz(vec2(u * 4.0, 1.0)));
				sk = max(sk, runs * (1.0 - smoothstep(0.05, 1.0, down + 0.25 * nz(vec2(u * 3.0, p.y * 0.5)))) * (1.0 - smoothstep(0.0, 0.12, past)));
			}
			col = mix(col, col * mix(vec3(1.0), streak_color * 2.2, 0.6), sk * streaks * (0.4 + 0.6 * age));
		}
		// Sun and years fade it all a little toward grey.
		col = mix(col, vec3(dot(col, vec3(0.33))), 0.12 * age);
	} else {
		// --- Inside wear, measured from the region's floor ----------------------------------------
		vec4 at = region_at[int(reg.y)];
		float hf = p.y - at.x;
		vec2 pp = vec2(u, p.y);
		float band = smoothstep(grime_band.x - 0.15, grime_band.x, hf) * (1.0 - smoothstep(grime_band.y, grime_band.y + 0.25, hf));
		band *= smoothstep(0.35, 0.75, nz(pp * vec2(0.6, 0.25) + 9.0)) * inside_age;
		float scuff = (1.0 - smoothstep(0.05, 0.3 + 0.1 * nz(vec2(u, 3.0)), hf)) * (0.5 + 0.5 * nz(pp * 4.0)) * (0.3 + 0.7 * inside_age);
		float high = smoothstep(at.y - 1.0, at.y, p.y) * soot * (0.6 + 0.4 * nz(pp * 0.5));
		col = mix(col, col * grime_color * 1.6, clamp(band * 0.55, 0.0, 1.0));
		col = mix(col, grime_color * 0.8, scuff * 0.45);
		col = mix(col, col * vec3(0.72, 0.7, 0.67), high);
	}

	ALBEDO = clamp(col, 0.0, 1.0);
	ROUGHNESS = clamp(rough, 0.05, 1.0);
	SPECULAR = 0.35;
	AO = clamp(occl, 0.0, 1.0);
	AO_LIGHT_AFFECT = 0.35;
	NORMAL = real_bump(VERTEX, NORMAL, h * normal_strength);
}

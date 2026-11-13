shader_type spatial;
// The valley's ground drawn real (#891; ValleyGroundArt sets it on ValleyGround's blocks and the dug
// tiles). Six CC0 scans from Poly Haven (assets/textures/scans/<id>/: albedo, normal, roughness), laid
// from world XZ (the ground has no UVs), each broken of its repeat; which shows where comes from the
// ground map (tools/textures/valley_ground_map.gd: the roads' across-offsets, the water, the pads, the
// town's lots, the rail bed) and the slope and height. The town's streets and the valley's roads are
// rutted from the map's across-offset: wheel ruts in lanes that wander, hoof prints between them,
// packed and darker where they're travelled, manure, straw and dried puddles, and loose dust gathered
// along the boardwalks; ragged at their edges, never ruled.

render_mode cull_back;

// --- The map (ValleyGroundArt): texel (i, j) is the bake point at map_origin + (i, j) * map_spacing.
uniform sampler2D map_a : filter_linear, repeat_disable;
uniform sampler2D map_b : filter_linear, repeat_disable;
uniform vec2 map_origin = vec2(-2000.0, -1400.0);
uniform vec2 map_size = vec2(2241.0, 1857.0);
uniform float map_spacing = 2.0;

// --- The scans: albedo, normal (OpenGL), roughness; metres a tile.
uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_rough : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float dirt_m = 2.0;
uniform sampler2D dry_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dry_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dry_rough : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float dry_m = 4.0;
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_rough : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float grass_m = 2.0;
uniform sampler2D trail_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trail_rough : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float trail_m = 2.0;
uniform sampler2D mud_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_rough : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float mud_m = 2.0;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_rough : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float rock_m = 3.0;

// --- Dials (config/valley_ground_art.tres, ValleyGroundArtTuning, sets them).
// Slope (degrees) where rock starts showing, and where it's all rock.
uniform float rock_from = 30.0;
uniform float rock_full = 44.0;
// Metres from a water bed's edge within which the grass is greener and the ground darker.
uniform float water_near = 25.0;
// The ground's colour graded: the scans' own, toward the valley's warm dry ochre.
uniform vec3 grade = vec3(1.04, 0.97, 0.88);
uniform float grade_sat = 0.9;
// The town's streets' dirt warmer (red-orange, churned), and the stony lots' and tracks' scan darker.
uniform vec3 street_tint = vec3(1.08, 0.95, 0.82);
uniform vec3 trail_tint = vec3(0.86, 0.8, 0.72);
// Packed: how much darker the travelled dirt is, and the ruts' bottoms.
uniform float packed_dark = 0.8;
uniform float rut_dark = 0.72;
// Ruts: depth (m), half-width (m), the wheels' gauge (m, centre to centre).
uniform float rut_depth = 0.05;
uniform float rut_half = 0.09;
uniform float gauge = 1.55;
// Main Street's wagon lanes: their middles each side of the street's (m), how far they wander.
uniform float street_lane = 2.4;
uniform float lane_wander = 0.45;
// Main Street's boardwalks' street edge, from the street's middle (m): the dust gathers against it.
uniform float walk_edge = 7.65;
// Hoof prints: how many a square metre in a lane, their depth (m).
uniform float hoof_density = 0.9;
uniform float hoof_depth = 0.018;
// Manure piles a hundred square metres of street, straw strands a square metre near the walks.
uniform float manure_density = 1.6;
uniform float straw_density = 6.0;
// Dried puddle stains: how much of the street they cover (0..1).
uniform float puddle_cover = 0.18;
// How far (m) the fine marks (prints, straw, the scans' normals) fade out.
uniform float detail_far = 60.0;
// The dug tiles (ValleyGroundArt's second material): fresh loose earth by COLOR.r (loose depth).
uniform bool dug_tile = false;

varying vec3 world_pos;
varying vec3 world_nrm;

// --- Noise (hash after Dave Hoskins, "Hash without Sine", shadertoy 4djSRW; value noise, fbm).
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return s / 0.9375;
}

// --- A scan without its repeat: two lookups at offsets chosen by a slow noise and blended
// (Inigo Quilez, "Texture repetition", technique 3, iquilezles.org/articles/texturerepetition).
struct Tap {
	vec2 a;
	vec2 b;
	float f;
	vec2 dx;
	vec2 dy;
};
Tap tap(vec2 xz, float metres) {
	vec2 uv = xz / metres;
	float k = vnoise(xz * 0.07) * 8.0;
	float i = floor(k);
	float f = fract(k);
	Tap t;
	t.a = uv + hash22(vec2(i, 3.7)) * 7.0;
	t.b = uv + hash22(vec2(i + 1.0, 3.7)) * 7.0;
	t.f = smoothstep(0.2, 0.8, f);
	t.dx = dFdx(uv);
	t.dy = dFdy(uv);
	return t;
}
// One per kind of map: Godot wants a sampler argument always given textures of the same hints.
vec4 look_a(sampler2D s, Tap t) {
	return mix(textureGrad(s, t.a, t.dx, t.dy), textureGrad(s, t.b, t.dx, t.dy), t.f);
}
vec4 look_n(sampler2D s, Tap t) {
	return mix(textureGrad(s, t.a, t.dx, t.dy), textureGrad(s, t.b, t.dx, t.dy), t.f);
}
vec4 look_r(sampler2D s, Tap t) {
	return mix(textureGrad(s, t.a, t.dx, t.dy), textureGrad(s, t.b, t.dx, t.dy), t.f);
}

struct Layer {
	vec3 albedo;
	vec2 nrm; // tangent-space x, y (OpenGL), unit length's share
	float rough;
	float height; // 0..1, the albedo's lightness as a stand-in for height (for blending)
};
Layer layer(sampler2D al, sampler2D nm, sampler2D rg, vec2 xz, float metres) {
	Tap t = tap(xz, metres);
	Layer l;
	l.albedo = look_a(al, t).rgb;
	l.nrm = look_n(nm, t).xy * 2.0 - 1.0;
	l.rough = look_r(rg, t).r;
	l.height = dot(l.albedo, vec3(0.3, 0.5, 0.2));
	return l;
}
void add(inout Layer acc, Layer l, float w) {
	acc.albedo += l.albedo * w;
	acc.nrm += l.nrm * w;
	acc.rough += l.rough * w;
	acc.height += l.height * w;
}

// The rock on steep ground, laid on the two vertical planes too (triplanar).
Layer rock_layer(vec3 p, vec3 n) {
	vec3 b = pow(abs(n), vec3(4.0));
	b /= (b.x + b.y + b.z);
	Layer l;
	l.albedo = vec3(0.0);
	l.nrm = vec2(0.0);
	l.rough = 0.0;
	l.height = 0.0;
	if (b.y > 0.02) add(l, layer(rock_albedo, rock_normal, rock_rough, p.xz, rock_m), b.y);
	if (b.x > 0.02) add(l, layer(rock_albedo, rock_normal, rock_rough, vec2(p.z, -p.y), rock_m), b.x);
	if (b.z > 0.02) add(l, layer(rock_albedo, rock_normal, rock_rough, vec2(p.x, -p.y), rock_m), b.z);
	return l;
}

// The map at a world point.
vec4 map_at(sampler2D m, vec2 xz) {
	vec2 uv = ((xz - map_origin) / map_spacing + 0.5) / map_size;
	return texture(m, uv);
}
float road_class(vec2 xz) {
	ivec2 ij = ivec2(round((xz - map_origin) / map_spacing));
	ij = clamp(ij, ivec2(0), ivec2(map_size) - 1);
	return texelFetch(map_a, ij, 0).b;
}

// A wheel rut's profile across it (0 at its middle's bottom ... 1 on the crown), churned along.
float rut(float d, float churn) {
	float w = rut_half * (0.8 + churn * 0.8);
	// The trench, and the dirt it pushed up either side (a berm half as high).
	float berm = exp(-pow((abs(d) - 1.9 * w) / (0.8 * w), 2.0)) * 0.35;
	return 1.0 - exp(-(d * d) / (w * w)) + berm;
}

// Prints in a lane: dents at random points in cells `cell` m across, kept where `keep` > the cell's
// die; returns how deep (0..1) at p.
float prints(vec2 p, float cell, float keep, float r) {
	vec2 c = floor(p / cell);
	float h = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 k = c + vec2(float(i), float(j));
			vec2 o = hash22(k);
			if (hash12(k + 91.3) > keep) continue;
			vec2 q = p - (k + o) * cell;
			// a hoof's oval, its long axis turned by the die
			float a = hash12(k + 7.1) * 6.2832;
			vec2 rq = vec2(cos(a) * q.x + sin(a) * q.y, -sin(a) * q.x + cos(a) * q.y);
			float e = length(rq / vec2(r, r * 1.25));
			// A hoof's wall cuts deep in a horseshoe; the frog in its middle less.
			float inner = length((rq - vec2(0.0, r * 0.35)) / vec2(r * 0.55, r * 0.7));
			h = max(h, (1.0 - smoothstep(0.6, 1.0, e)) * mix(0.35, 1.0, smoothstep(0.5, 1.0, inner)));
		}
	}
	return h;
}

// Blobs (manure) in cells `cell` m across, one in a cell with chance `chance`; .x cover, .y height.
vec2 blobs(vec2 p, float cell, float chance) {
	vec2 c = floor(p / cell);
	vec2 best = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 k = c + vec2(float(i), float(j));
			if (hash12(k + 13.7) > chance) continue;
			vec2 q = p - (k + hash22(k + 2.1)) * cell;
			float r = 0.08 + hash12(k + 5.5) * 0.14;
			float e = length(q) / r + (vnoise(p * 30.0) - 0.5) * 0.5;
			float cov = 1.0 - smoothstep(0.7, 1.0, e);
			best = max(best, vec2(cov, cov * (1.0 - e * e) * 0.04));
		}
	}
	return best;
}

// Straw strands: short bright lines in cells `cell` m across.
float straw(vec2 p, float cell, float chance) {
	vec2 c = floor(p / cell);
	float s = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 k = c + vec2(float(i), float(j));
			if (hash12(k + 41.0) > chance) continue;
			vec2 q = p - (k + hash22(k + 9.0)) * cell;
			float a = hash12(k + 3.0) * 3.1416;
			vec2 dir = vec2(cos(a), sin(a));
			float along = dot(q, dir);
			float across = abs(dot(q, vec2(-dir.y, dir.x)));
			float len = 0.05 + hash12(k + 4.0) * 0.07;
			s = max(s, (1.0 - smoothstep(0.0012, 0.003, across)) * (1.0 - smoothstep(len * 0.8, len, abs(along))));
		}
	}
	return s;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 xz = world_pos.xz;
	vec3 n = normalize(world_nrm);
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	float near = 1.0 - smoothstep(detail_far * 0.5, detail_far, dist);
	vec4 ma = map_at(map_a, xz);
	vec4 mb = map_at(map_b, xz);
	float across = ma.r;
	float half_w = ma.g;
	float cls = road_class(xz);
	float water = ma.a;
	float pad = mb.r;
	float lot = mb.g;
	float rail = mb.b;
	float ford = mb.a;

	// Slow variation over the land: patches, a slope's rock, the bottoms near water.
	float macro = fbm(xz * 0.013);
	float patch = fbm(xz * 0.06 + 3.1);
	float slope = degrees(acos(clamp(n.y, -1.0, 1.0)));
	float w_rock = smoothstep(rock_from - 6.0 * patch, rock_full, slope);
	float wet = 1.0 - smoothstep(0.0, water_near, water);

	// The road here: inside it by its ragged edge (noise along it, wider roads more ragged).
	float on_road = 0.0;
	float travel = 0.0;
	float rut_h = 0.0;
	float lane_mid = 0.0;
	float gather = 0.0;
	float crown = 0.0;
	if (cls > 0.5 && half_w > 0.1) {
		float rag = (vnoise(xz * 0.45) - 0.5) * (0.35 + half_w * 0.08) + (vnoise(xz * 2.3) - 0.5) * 0.25;
		float e = half_w + rag;
		float a = abs(across);
		on_road = 1.0 - smoothstep(e - 0.5, e + 0.35, a);
		float churn = vnoise(xz * 1.7);
		float wander = (vnoise(xz * 0.045 + 11.0) - 0.5) * 2.0 * lane_wander;
		if (cls < 2.5) {
			// The town's streets: lanes each side of the middle (and a third down it on Main Street),
			// each two ruts; several sets so it's churned, not ruled.
			float lanes = cls < 1.5 ? street_lane : street_lane * 0.6;
			float rr = 1.0;
			for (int s = 0; s < 5; s++) {
				float fs = float(s);
				float off = s == 0 ? lanes : (s == 1 ? -lanes : (s == 2 ? 0.15 * lanes : (s == 3 ? 1.75 * lanes : -1.6 * lanes)));
				float depth = s < 2 ? 1.0 : (s == 2 ? 0.6 : 0.45);
				// Each set comes and goes along the street (wheels leave a line and join another).
				float there = smoothstep(0.25, 0.55, vnoise(xz * 0.035 + fs * 13.1));
				depth *= mix(0.35, 1.0, there);
				float wv = wander * (s >= 2 ? 1.6 : 1.0) + (vnoise(xz * 0.11 + fs * 7.0) - 0.5) * 0.6
					+ (vnoise(xz * 0.021 + fs * 3.3) - 0.5) * 1.4;
				float c = across - off - wv;
				float g = gauge * 0.5 + (vnoise(xz * 0.3 + fs) - 0.5) * 0.1;
				rr = min(rr, 1.0 - (1.0 - rut(c - g, churn)) * depth);
				rr = min(rr, 1.0 - (1.0 - rut(c + g, churn)) * depth);
				lane_mid = max(lane_mid, (1.0 - smoothstep(0.25, 0.6, abs(c))) * depth);
				travel = max(travel, (1.0 - smoothstep(g + 0.2, g + 1.4, abs(c))) * depth);
			}
			// Churned between the ruts: clods and hollows where hooves and wheels have worked it.
			rr += (fbm(xz * 2.6) - 0.5) * 0.6 * travel + (fbm(xz * 0.9 + 4.0) - 0.5) * 1.2 * travel;
			rut_h = (rr - 1.0);
			if (cls < 1.5) {
				// The boardwalks' edge: dust and litter gathered against it.
				gather = smoothstep(walk_edge - 1.4, walk_edge - 0.1, a) * (1.0 - smoothstep(walk_edge + 0.2, walk_edge + 0.8, a));
			}
		} else if (cls < 5.5) {
			// A wagon road, lane or track: one pair of ruts with a crown of grass between them.
			float c = across - wander * min(1.0, half_w * 0.25);
			float g = gauge * 0.5;
			float rr = min(rut(c - g, churn), rut(c + g, churn));
			float depth = cls < 3.5 ? 1.0 : (cls < 4.5 ? 0.8 : 0.6);
			rut_h = (rr - 1.0) * depth;
			lane_mid = 1.0 - smoothstep(0.2, 0.5, abs(c));
			travel = (1.0 - smoothstep(g + 0.25, g + 0.9, abs(c))) * depth;
			crown = (1.0 - smoothstep(0.15, 0.45, abs(c))) * (cls < 3.5 ? 0.35 : 0.8);
		} else {
			// A path: one trodden line.
			travel = 1.0 - smoothstep(0.15, 0.55, abs(across - wander * 0.3));
		}
		travel *= on_road;
		rut_h *= on_road;
	}
	bool street = cls > 0.5 && cls < 2.5 && (on_road > 0.01 || lot > 0.5);

	// The layers' weights.
	float w_grass = clamp(0.55 + (macro - 0.5) * 1.2 + wet * 0.6 - patch * 0.3, 0.0, 1.0);
	float w_dry = 1.0 - w_grass;
	float w_trail = 0.0;
	float w_dirt = 0.0;
	float w_mud = 0.0;
	// The town's lots, pads and the rail bed: trodden, stony, little grass.
	float worked = max(max(lot * 0.85, pad * 0.75), rail * 0.9);
	// A lot right by a town street carries the street's dirt up to the fronts; the rest of the lots
	// stony and trodden; pads and the rail bed bared dirt.
	float by_street = (cls > 0.5 && cls < 2.5) ? 1.0 - smoothstep(half_w + 2.0, half_w + 5.0, abs(across)) : 0.0;
	w_trail = lot * (0.5 + patch * 0.5) * (1.0 - by_street);
	w_dirt = max(max(pad * 0.75, rail * 0.9), lot * by_street);
	w_grass *= 1.0 - worked * 0.85;
	w_dry *= 1.0 - worked * 0.4;
	// On the roads: packed dirt where they're travelled, stony at the edges, grass on a crown.
	if (on_road > 0.0) {
		float packed = street ? 1.0 : clamp(travel * 1.3 + 0.15, 0.0, 1.0);
		w_dirt = max(w_dirt, on_road * packed * (1.0 - crown * 0.7));
		w_trail = max(w_trail, on_road * (1.0 - packed) * 0.8 + gather * 0.6);
		w_grass *= 1.0 - on_road * (1.0 - crown);
		w_dry *= 1.0 - on_road * 0.9;
	}
	// The water's beds and banks, and a ford: cracked mud and stones.
	float bed = 1.0 - smoothstep(0.0, 3.0, water);
	w_mud = max(bed * 0.8, ford * 0.6);
	// Dried puddles in the streets' low spots (where the slow noise is lowest).
	float puddle = 0.0;
	if (street) {
		float pn = fbm(xz * 0.09 + 5.0);
		puddle = (1.0 - smoothstep(puddle_cover * 0.55, puddle_cover * 0.55 + 0.08, pn)) * on_road * (1.0 - gather);
		w_mud = max(w_mud, puddle * 0.85);
	}
	float sum = w_grass + w_dry + w_trail + w_dirt + w_mud + 1e-4;
	w_grass /= sum;
	w_dry /= sum;
	w_trail /= sum;
	w_dirt /= sum;
	w_mud /= sum;
	w_grass *= 1.0 - w_rock;
	w_dry *= 1.0 - w_rock;
	w_trail *= 1.0 - w_rock;
	w_dirt *= 1.0 - w_rock;
	w_mud *= 1.0 - w_rock;

	Layer g;
	g.albedo = vec3(0.0);
	g.nrm = vec2(0.0);
	g.rough = 0.0;
	g.height = 0.0;
	if (w_grass > 0.01) add(g, layer(grass_albedo, grass_normal, grass_rough, xz, grass_m), w_grass);
	if (w_dry > 0.01) add(g, layer(dry_albedo, dry_normal, dry_rough, xz, dry_m), w_dry);
	if (w_trail > 0.01) {
		Layer tl = layer(trail_albedo, trail_normal, trail_rough, xz, trail_m);
		tl.albedo *= trail_tint;
		add(g, tl, w_trail);
	}
	if (w_dirt > 0.01) {
		Layer dl = layer(dirt_albedo, dirt_normal, dirt_rough, xz, dirt_m);
		// A country road's dirt is the land's own, bared and dusty: lighter than the town's churned street.
		if (!(cls > 0.5 && cls < 1.5)) {
			dl.albedo *= vec3(1.42, 1.34, 1.24);
		}
		add(g, dl, w_dirt);
	}
	if (w_mud > 0.01) add(g, layer(mud_albedo, mud_normal, mud_rough, xz, mud_m), w_mud);
	if (w_rock > 0.01) {
		Layer r = rock_layer(world_pos, n);
		add(g, r, w_rock);
	}
	float wsum = w_grass + w_dry + w_trail + w_dirt + w_mud + w_rock;
	g.albedo /= max(wsum, 1e-3);
	g.nrm /= max(wsum, 1e-3);
	g.rough /= max(wsum, 1e-3);

	vec3 col = g.albedo;
	if (street) {
		col *= mix(vec3(1.0), street_tint, on_road);
	}
	float rough = g.rough;
	float h = 0.0;
	// Travelled: packed, darker, smoother (the town's streets; a country road's bare dirt is as light as
	// the land round it); ruts' bottoms darker still.
	float town_road = cls > 0.5 && cls < 1.5 ? 1.0 : 0.35;
	col *= mix(1.0, packed_dark, travel * 0.8 * town_road);
	rough = mix(rough, rough * 0.85, travel);
	h += rut_h * rut_depth * (0.7 + vnoise(xz * 0.6) * 0.6);
	col *= mix(1.0, rut_dark, clamp(-rut_h, 0.0, 1.0) * mix(0.3, 1.0, town_road));
	// Hoof prints between the ruts, boot prints toward the walks.
	if (on_road > 0.05 && near > 0.0) {
		float hp = prints(xz, 0.38, hoof_density * 0.3 * lane_mid * on_road, 0.065);
		h -= hp * hoof_depth * near;
		col *= 1.0 - hp * 0.12 * near;
		if (street) {
			float boots = smoothstep(walk_edge - 3.5, walk_edge - 0.6, abs(across)) * (cls < 1.5 ? 1.0 : 0.4);
			float bp = prints(xz * vec2(1.0, 1.0) + 31.0, 0.3, 0.35 * boots, 0.05);
			h -= bp * 0.008 * near;
			col *= 1.0 - bp * 0.08 * near;
		}
	}
	// Manure in the lanes and by the walks (where the horses stand), straw by the walks.
	if (street) {
		float chance = manure_density * 0.0004 * 4.0 * (lane_mid * 0.6 + gather * 1.8 + 0.1);
		vec2 mb2 = blobs(xz, 2.0, chance);
		col = mix(col, vec3(0.16, 0.12, 0.07) * (0.8 + vnoise(xz * 40.0) * 0.4), mb2.x * 0.9);
		h += mb2.y;
		rough = mix(rough, 0.75, mb2.x);
		if (near > 0.0) {
			float st = straw(xz, 0.18, straw_density * 0.0324 * (gather + mb2.x * 2.0 + 0.04)) * near;
			col = mix(col, vec3(0.62, 0.52, 0.30), st * 0.85);
		}
		// Mottled: damp-dark and dusty-light patches a metre or two across, loose pale dust off the lanes.
		float mott = fbm(xz * 0.45 + 2.0);
		col *= 0.82 + mott * 0.36;
		float loose = smoothstep(0.4, 0.7, fbm(xz * 0.09 + 8.0)) * (1.0 - travel * 0.7);
		col = mix(col, col * vec3(1.32, 1.22, 1.08), loose * 0.75);
		// Dust kicked out of the lanes, streaked along them.
		float streak = smoothstep(0.55, 0.85, vnoise(vec2(xz.x * 0.08, across * 2.2) + 3.0)) * travel;
		col = mix(col, col * vec3(1.18, 1.12, 1.04), streak * 0.5);
		rough = mix(rough, 1.0, loose * 0.5);
		// Dust and litter gathered against the walks, darkest right at their edge (the shade under them).
		col *= 1.0 - gather * 0.18;
		float contact = 1.0 - smoothstep(0.0, 0.45, abs(abs(across) - walk_edge));
		col *= 1.0 - contact * 0.35 * (cls < 1.5 ? 1.0 : 0.0);
		// Dried puddle stains: a darker rim, a smoother middle.
		col *= 1.0 - puddle * 0.12;
		rough = mix(rough, rough * 0.8, puddle);
	}
	// Grassland reads as straw from afar, the blades too small to see apart.
	float grassland = w_grass * (1.0 - on_road) * (1.0 - w_rock);
	col = mix(col, vec3(0.62, 0.53, 0.34) * (0.85 + patch * 0.3), grassland * (0.25 + 0.4 * smoothstep(15.0, 120.0, dist)));
	// Wet ground near water: darker.
	col *= 1.0 - wet * 0.12;
	// The land's slow variation and the valley's grade.
	col *= 0.84 + macro * 0.32;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, grade_sat) * grade;
	if (dug_tile) {
		float loose = clamp(COLOR.r * 4.0, 0.0, 1.0);
		col = mix(col, col * vec3(0.78, 0.72, 0.66), loose);
		rough = mix(rough, 1.0, loose);
	}

	ALBEDO = clamp(col, 0.0, 1.0);
	ROUGHNESS = clamp(rough, 0.35, 1.0);
	SPECULAR = 0.3;
	// The scans' normals laid on the ground's own (x east, the image's up north), fading with distance.
	vec2 tn = g.nrm * mix(0.35, 1.0, near);
	vec3 t = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b = normalize(cross(t, n));
	vec3 wn = normalize(n + t * tn.x - b * tn.y);
	vec3 vn = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	// And the ruts, prints and piles as a height, by the screen's derivatives (Mikkelsen 2010).
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhdx = dFdx(h);
	float dhdy = dFdy(h);
	vec3 r1 = cross(dpdy, vn);
	vec3 r2 = cross(vn, dpdx);
	float det = dot(dpdx, r1);
	if (abs(det) > 1e-12) {
		vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
		vn = normalize(abs(det) * vn - grad);
	}
	NORMAL = vn;
}

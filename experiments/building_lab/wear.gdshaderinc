// The lived-in pass drawn (docs/briefs/lived-in.md; the building lab's, not the game's): a
// structure's marks, baked by wear_paint.gd into a wear volume in its own space (R worn by feet, G
// polished by hands and boots, B dirt: soot, spills, grime, splash, streaks, rings; A fresh: new
// wood, a pale patch, a scrubbed floor) and, finer, a map per floor level, laid on the wood's own
// colour in the opaque pass (texel_grid.gdshaderinc's WEAR hook: wear_wood.gdshader defines WEAR
// and includes this before it). Each change is relative to the wood it's on (boots wear any wood
// paler, dirt darkens any), sampled in squares and stepped into a few tones, as the weathering
// layer's stains are: painted in squares, not airbrushed.

uniform sampler3D wear_vol : filter_linear, repeat_disable;
uniform sampler2DArray floor_maps : filter_linear, repeat_disable;
// The mesh's space to the structure's the marks were baked in (identity for the building's own
// batches; a kit prop's batches are in the prop's space).
uniform mat4 wear_to_structure = mat4(1.0);
uniform vec3 wear_vol_origin;
uniform vec3 wear_vol_size = vec3(1.0);
uniform vec2 wear_floor_origin;
uniform vec2 wear_floor_size = vec2(1.0);
uniform vec4 wear_floor_levels = vec4(-99.0);
uniform int wear_floor_count = 0;
uniform float wear_squares = 32.0;
uniform float wear_tones = 4.0;
// How far each goes: worn toward a dusty, paler wood (at least this pale, and at least `wear_pale`
// times as light as the stain it wore through), polished warmer, dirt darker, fresh wood.
uniform vec3 wear_worn : source_color = vec3(0.52, 0.41, 0.28);
uniform float wear_pale = 2.2;
uniform float wear_polish = 0.9;
uniform float wear_dirt = 0.78;
uniform vec3 wear_fresh : source_color = vec3(0.70, 0.55, 0.36);
uniform vec4 wear_amounts = vec4(1.0, 1.0, 1.0, 0.8);

// Value noise over cells of a few squares: wear fades unevenly across a board, not speckled square
// by square.
float wear_hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float wear_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = wear_hash(i), n100 = wear_hash(i + vec3(1, 0, 0)), n010 = wear_hash(i + vec3(0, 1, 0)), n110 = wear_hash(i + vec3(1, 1, 0));
	float n001 = wear_hash(i + vec3(0, 0, 1)), n101 = wear_hash(i + vec3(1, 0, 1)), n011 = wear_hash(i + vec3(0, 1, 1)), n111 = wear_hash(i + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y), mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

// The first tone needs a real mark (no lone squares where a faint one is nudged over by the noise).
float wear_tone(float v) {
	return clamp(floor(v * wear_tones + 0.1) / wear_tones, 0.0, 1.0);
}

// The marks where this fragment is (mesh space): r worn, g polished, b dirt, a fresh, toned.
vec4 wear_at(vec3 p_mesh, vec3 n_mesh) {
	vec3 sp = (wear_to_structure * vec4(p_mesh, 1.0)).xyz;
	vec3 sn = normalize(mat3(wear_to_structure) * n_mesh);
	// The square this fragment's in (nudged inward off the face so a face isn't on a cell's edge).
	vec3 q = (floor((sp - sn * 0.004) * wear_squares) + 0.5) / wear_squares;
	vec4 m = vec4(0.0);
	bool floor_face = false;
	if (sn.y > 0.7) {
		for (int i = 0; i < 4; i++) {
			if (i < wear_floor_count && abs(sp.y - wear_floor_levels[i]) < 0.03) {
				m = texture(floor_maps, vec3((q.xz - wear_floor_origin) / wear_floor_size, float(i)));
				floor_face = true;
			}
		}
	}
	if (!floor_face) {
		vec3 uvw = (q - wear_vol_origin) / wear_vol_size;
		if (any(lessThan(uvw, vec3(0.0))) || any(greaterThan(uvw, vec3(1.0)))) {
			return vec4(0.0);
		}
		m = texture(wear_vol, uvw);
	}
	m *= 0.7 + 0.6 * wear_noise(q * wear_squares / 5.0);
	return vec4(wear_tone(m.r), wear_tone(m.g), wear_tone(m.b), wear_tone(m.a)) * wear_amounts;
}

vec3 wear_colour(vec3 albedo, vec4 a) {
	float luma = dot(albedo, vec3(0.3, 0.55, 0.15));
	// Boots take the stain and the grime off: paler, a little greyer, the grain showing.
	albedo = mix(albedo, max(mix(albedo, vec3(luma), 0.35) * (1.0 + wear_pale), wear_worn), min(a.r * 1.1, 1.0));
	// Hands polish: warmer and a touch lighter (and glossier: ROUGHNESS, below).
	albedo = mix(albedo, albedo * vec3(1.0 + wear_polish * 1.3, 1.0 + wear_polish, 1.0 + wear_polish * 0.6), a.g);
	// Dirt darkens what it's on.
	albedo *= mix(1.0, 1.0 - wear_dirt, a.b);
	// New wood, a pale patch, a scrubbed floor: lighter and warmer than what's round them, not a glow.
	albedo = mix(albedo, albedo * vec3(1.45, 1.35, 1.2) + wear_fresh * 0.04, a.a);
	return albedo;
}

// The hook in texel_grid.gdshaderinc's fragment, after its colour and finish are written.
#define WEAR_FRAGMENT vec4 wear_m = wear_at(local_pos, weather_n); ALBEDO = wear_colour(ALBEDO, wear_m); ROUGHNESS = mix(ROUGHNESS, 0.3, wear_m.g); SPECULAR = mix(SPECULAR, 0.55, wear_m.g);

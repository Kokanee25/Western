// A person's skin and clothes: the pixel texture laid on in the mesh's own space (like the rest of
// the body parts) or by its UVs (the generated body: BodyMesh), opened where wounds have torn it
// (see wounds.gdshaderinc). Included by body_skin.gdshader (one-sided) and
// body_skin_double.gdshader (open garments seen from inside: vests, brims, bandanas).
// Lit tile by tile like every surface (src/render/tiles.gdshaderinc; P switches it).

#include "res://src/bodies/shaders/wounds.gdshaderinc"
#include "res://src/render/tiles.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float uv_scale = 5.0;
uniform float roughness_value = 0.8;
// The generated body: texture by UV (uv_scale per UV unit), and wounds placed by the rest-pose
// position in the segment's own space, carried in CUSTOM0 (the mesh itself is skinned).
uniform bool use_uv = false;
uniform bool use_custom_pos = false;
// The eyes are wet: within eye_radius of either eyeball's centre (same space as local_pos) the
// surface is glossy, so a lamp puts a glint in them. The head's pieces only; radius 0 = none.
uniform vec3 eye_r_pos = vec3(0.0);
uniform vec3 eye_l_pos = vec3(0.0);
uniform float eye_radius = 0.0;
// How much brighter the whites and glint drawn in a painted eye are (the pale texels inside the
// wet-eye sphere: light, with little colour; the lids and iris round them don't count), so a man's
// eyes read clear and bright under a brim as the painting's do. 1 = as painted; set per man from
// his model's report ("eye_gain", PeopleBodies.report()).
uniform float eye_gain = 1.0;
// A weathered, stern face drawn over his painted one, placed from the eyes (eye_r_pos, eye_l_pos:
// head-centred, y up; the head's pieces only), so it stays on him as he turns and moves (Sean,
// 2026-10-12: the saloon painting's man is weathered and frowning, eyes in shadow under heavy
// brows, where ours was a pale mask with big white eyes). Each 0 = off; set per man from his
// model's report ("weathered", PeopleBodies.report()). face_skin: his skin's colour times this where
// the texture is skin (warm, mid, not the hair or the whites); face_brows: heavy dark brows over
// each eye, their inner ends pulled down (face_frown also draws the two creases between them);
// face_sockets: the lids and sockets round each eye shaded, so the eyes sit back in shadow;
// face_whites: the painted whites dimmed and narrowed to the eye's middle (1 = to the iris's
// colour at the corners).
uniform vec3 face_skin = vec3(1.0);
uniform float face_brows = 0.0;
uniform float face_frown = 0.0;
uniform float face_sockets = 0.0;
uniform float face_whites = 0.0;
// Light in flat steps, not a smooth ramp: the painting's faces and cloth are blocks of colour with
// hard edges between light and shade. Steps per unit of (gamma-space) light; 0 = smooth.
uniform float light_steps = 4.0;
// A painted texture (tools/paint_bake.gd): it covers this rect of the piece's UVs (x, y, w, h;
// w 0 = not painted, UV × uv_scale as before). Its colours are the painting's as seen on screen,
// light, shade and the lamps' warmth painted in, so they're turned back into what the game's grade
// (ACES, then paint_contrast) shows as those colours. self_lit of that glows as painted; the rest
// is lit by the scene's lights × paint_gain, by their brightness only (their colour is painted in
// already), each light easing off towards paint_limit × painted, wrapped round him (paint_wrap: light reaches that far past side-on, as the shading is
// painted in too; a lamp behind him still only lights his back), and not by the sky or ambient
// (self_lit stands in for it).
uniform vec4 uv_rect = vec4(0.0);
uniform float self_lit = 0.0;
uniform float paint_gain = 1.0;
uniform float paint_wrap = 0.6;
uniform float paint_limit = 1.3;
// How much of each light's own colour reaches a painted part (0: its brightness only, as the
// painted colours already hold the lamps' warmth; 1: its full colour, as an unpainted part).
// The painted-light brief (the characters session, 2026-10-15): a painterly man's painting stays
// how he looks and each light only changes his colour and amount, so the campfire warms the side
// facing it and the night round him darkens and cools him. Eased channel by channel towards
// paint_limit, so a hot orange lamp warms him without driving his face to flat orange.
uniform float paint_tint = 0.0;
// The most all the lights together make a person, × his own colour (painted or not; its top
// channel). paint_limit
// holds each light alone on a painted part, and nothing held an unpainted one: 2026-10-14, the
// characters session's portrait men (unpainted, their Rodin skins) in the saloon's lamps lit
// their faces to 2.4-2.7x at the 90th percentile and clipped a quarter to two fifths of them.
// Up to light_knee of it the lights add as they come; past that they ease off towards light_cap.
// 0 = no cap.
uniform float light_cap = 1.35;
uniform float light_knee = 0.6;
uniform float paint_contrast = 1.08;
// How much of the scene's ambient light a painted part takes (0: none, self_lit stands in for
// it; 1: lit like everything else, the hybrid finish's way).
uniform float paint_ambient = 0.0;
// For tools/face_light.py only (screenshots.gd --face-probe; 0 in the game): > 0 shows the piece
// as painted, unlit (its colour ÷ this exposure, so the grade gives back the paint); < 0 black.
uniform float paint_probe = 0.0;
// Texels a side in one of the painted texture's squares (lit as one): 1, or 3 on the face, whose
// eyes are drawn finer than its squares.
uniform float square_texels = 1.0;
// The surface-blocks look: what the lower bands of light lean toward (skin's half-light warm).
uniform vec3 shade_tint : source_color = vec3(1.0);

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = use_custom_pos ? CUSTOM0.xyz : VERTEX;
	local_normal = NORMAL;
}

vec3 plane_sample(vec2 uv) {
	if (block_soft > 0.0) {
		vec2 size = vec2(textureSize(albedo_tex, 0));
		return tile_sample_soft(albedo_tex, tile_soft_point(uv * size), size, dFdx(uv), dFdy(uv)).rgb;
	}
	return texture(albedo_tex, uv).rgb;
}

vec3 triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return plane_sample(p.zy * uv_scale) * w.x + plane_sample(p.xz * uv_scale) * w.y + plane_sample(p.xy * uv_scale) * w.z;
}

#include "res://src/render/aces.gdshaderinc"

// A painted colour (linear, as sampled) → the scene colour the grade shows as that colour.
vec3 painted_to_scene(vec3 c) {
	vec3 s = clamp(0.5 + (to_srgb(c) - 0.5) / paint_contrast, 0.0, 1.0);
	return aces_inverse(from_srgb(s));
}

// How much of a box (half sizes) the point is inside, 1 inside, 0 out, hard edged (the painting
// draws a brow as a block of dark, not a soft smudge).
float face_box(vec2 p, vec2 half_size) {
	return step(abs(p.x), half_size.x) * step(abs(p.y), half_size.y);
}

// face_skin, face_brows, face_frown, face_sockets and face_whites on the head's texture colour.
vec3 weathered_face(vec3 base, vec3 p) {
	// Nothing asked for (every man without a "weathered" report): his face as painted.
	if (face_brows + face_frown + face_sockets + face_whites == 0.0 && face_skin == vec3(1.0)) {
		return base;
	}
	vec3 mid = 0.5 * (eye_r_pos + eye_l_pos);
	vec3 across = normalize(eye_r_pos - eye_l_pos);
	float s = 0.5 * distance(eye_r_pos, eye_l_pos);  // half the eyes' spacing: the face's unit
	// Forward: from the head's centre (this space's origin) out through the eyes.
	vec3 fwd = normalize(vec3(mid.x, 0.0, mid.z));
	vec3 d = p - mid;
	// Only the front of the face, near the eyes.
	if (dot(d, fwd) < -0.9 * s || length(d) > 3.2 * s) {
		return base;
	}
	float top = max(max(base.r, base.g), base.b);
	float low = min(min(base.r, base.g), base.b);
	// Skin: warm (red over blue), mid bright, not pale (the whites) or dark (hair, brows).
	float skin = step(0.12, top) * step(top, 0.95) * smoothstep(0.08, 0.2, (base.r - base.b) / max(top, 1e-3))
			* step(low / max(top, 1e-3), 0.82);
	// The texture's own baked highlights (a hot forehead and nose) pressed toward the skin's mid
	// tone, then his colour: the light on him is the scene's, not the photo's.
	float lum = dot(base, vec3(0.2126, 0.7152, 0.0722));
	vec3 flat_skin = base * clamp(mix(1.0, 0.11 / max(lum, 1e-3), 0.6), 0.5, 1.6);
	base = mix(base, flat_skin * face_skin, skin);
	float x = dot(d, across) / s;  // + toward his right eye
	float y = d.y / s;
	float shade = 1.0;
	for (int k = 0; k < 2; k++) {
		float side = k == 0 ? 1.0 : -1.0;
		// In the eye's own frame: u out from the nose, v up.
		vec2 e = vec2(x * side - 1.0, y);
		float inner = clamp(-e.x, 0.0, 1.0);  // 1 at the eye's inner end
		// The brow: a band above the eye, its inner end lower (the frown) and thicker.
		float b0 = 0.62 - 0.22 * face_frown * (e.x < 0.0 ? inner * 1.6 : -0.1 * e.x);
		float brow = face_box(vec2(e.x + 0.05, e.y - b0), vec2(0.85, 0.15 + 0.06 * inner)) * face_brows;
		shade = min(shade, mix(1.0, 0.22, brow));
		// The socket and lids: the eye's ellipse and a band above it, the outside of the eyeball.
		float sock = step(length(vec2(e.x / 0.78, (e.y - 0.08) / 0.5)), 1.0);
		float in_eye = step(length(vec2(e.x / 0.5, e.y / 0.24)), 1.0);
		shade = min(shade, mix(1.0, 0.55, sock * (1.0 - in_eye) * face_sockets));
		// The whites: dimmed, and toward the corners turned to the lids' colour.
		float pale = smoothstep(0.55, 0.8, low / max(top, 1e-4)) * step(0.2, top) * in_eye;
		float corner = smoothstep(0.18, 0.42, abs(e.x));
		base = mix(base, base * mix(0.45, 0.25, corner), pale * face_whites);
	}
	// The frown's two creases between the brows.
	float crease = (face_box(vec2(x - 0.16, y - 0.42), vec2(0.045, 0.22)) + face_box(vec2(x + 0.16, y - 0.42), vec2(0.045, 0.22)));
	shade = min(shade, mix(1.0, 0.6, min(crease, 1.0) * face_frown));
	return base * shade;
}

void fragment() {
	bool painted = uv_rect.z > 0.0;
	vec2 tuv = painted ? (UV - uv_rect.xy) / uv_rect.zw : UV * uv_scale;
	// The tile this fragment is in (tiles.gdshaderinc), counted in tiles: by UV (a painted
	// texture's squares are square_texels a side: the face's eyes are drawn finer than its
	// squares), or by the plane the triplanar texture mostly comes from. Light is worked out once,
	// at the tile's centre. All before any discard, since it takes screen derivatives.
	vec2 tsize = vec2(textureSize(albedo_tex, 0));
	float per_tile = painted ? max(square_texels, 1.0) : 1.0;
	vec2 t;
	if (use_uv) {
		t = tuv * tsize / per_tile;
	} else {
		vec3 an = abs(local_normal);
		vec3 p = local_pos * uv_scale;
		t = (an.x > an.y && an.x > an.z ? p.zy : (an.y > an.z ? p.xz : p.xy)) * tsize;
	}
	bool soft = block_soft > 0.0;
	vec2 centre = soft ? tile_soft_point(t) : tile_centre(t);
	vec2 tuv_dx = dFdx(tuv);
	vec2 tuv_dy = dFdy(tuv);
	tile_light_at(t, centre, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, 0.05);
	vec3 base;
	if (!use_uv) {
		base = triplanar(local_pos, local_normal);
	} else if (soft) {
		// Soft block edges: the texture's own texels (the face's finer eyes included) blended
		// only across their edges.
		base = tile_sample_soft(albedo_tex, tile_soft_point(tuv * tsize), tsize, tuv_dx, tuv_dy).rgb;
	} else if (per_tile > 1.0) {
		base = texture(albedo_tex, tuv).rgb;
	} else {
		// One colour a tile: its own texel's (ragged tiles move only the edges between them).
		base = textureGrad(albedo_tex, centre / tsize, tuv_dx, tuv_dy).rgb;
	}
	base *= tint.rgb;
	float glow = 0.0;
	if (painted) {
		base = painted_to_scene(base);
		glow = self_lit;
	}
	float reach = wound_reach(local_pos);
	ROUGHNESS = roughness_value;
	float eye_boost = 1.0;
	if (eye_radius > 0.0 && min(distance(local_pos, eye_r_pos), distance(local_pos, eye_l_pos)) < eye_radius) {
		ROUGHNESS = 0.12;
		SPECULAR = 0.9;
		float top = max(max(base.r, base.g), base.b);
		float pale = smoothstep(0.55, 0.8, min(min(base.r, base.g), base.b) / max(top, 1e-4)) * step(0.2, top);
		eye_boost = mix(1.0, eye_gain, pale);
	}
	if (eye_radius > 0.0) {
		base = weathered_face(base, local_pos);
	}
	if (reach < 1.0) {
		if (!reduced_gore) {
			discard;
		}
		base = vec3(0.16, 0.02, 0.02);
		ROUGHNESS = 0.35;
	} else if (reach < 1.4) {
		// Torn edge: raw flesh at the lip, then soaked cloth or skin.
		float lip = step(reach, 1.15);
		base = mix(vec3(0.3, 0.03, 0.03), vec3(0.55, 0.12, 0.1), lip * (reduced_gore ? 0.0 : 1.0));
		ROUGHNESS = 0.4;
	} else if (reach < 2.2) {
		base = mix(base * vec3(0.45, 0.12, 0.1), base, (reach - 1.4) / 0.8);
	}
	ALBEDO = base * (1.0 - glow) * (painted ? paint_gain : 1.0) * eye_boost;
	EMISSION = base * glow;
	if (paint_probe != 0.0) {
		ALBEDO = vec3(0.0);
		EMISSION = paint_probe > 0.0 ? base / paint_probe : vec3(0.0);
	}
	if (painted) {
		AO = paint_ambient;
		// Painted matt: no sheen of the sky or the room on him (a night sky turned his shirt blue).
		SPECULAR = 0.0;
	}
}

void light() {
	// Lambert, stepped in gamma space so the steps look even; shadows are in ATTENUATION.
	float w = uv_rect.z > 0.0 ? paint_wrap : 0.0;
	float k = clamp((dot(NORMAL, LIGHT) + w) / (1.0 + w), 0.0, 1.0);
	k *= ATTENUATION;
	// The surface-blocks look's bands win over the material's own steps.
	float steps = light_bands > 0.0 ? light_bands : light_steps;
	if (steps > 0.0) {
		float g = pow(k, 1.0 / 2.2);
		k = pow(floor(g * steps + 0.5) / steps, 2.2);
	}
	vec3 add;
	if (uv_rect.z > 0.0) {
		// How much brighter than painted this light makes him (ALBEDO carries paint_gain), eased
		// off towards paint_limit so a lamp at his elbow doesn't burn the painted colours out.
		vec3 col = mix(vec3(dot(LIGHT_COLOR, vec3(0.2126, 0.7152, 0.0722))), LIGHT_COLOR, paint_tint);
		vec3 m = k * col / PI * paint_gain;
		add = m / (1.0 + m / paint_limit) / paint_gain;
	} else {
		add = k * LIGHT_COLOR * (light_bands > 0.0 ? mix(shade_tint, vec3(1.0), k) : vec3(1.0)) / PI;
	}
	if (light_cap > 0.0) {
		// The lights so far (DIFFUSE_LIGHT, already eased) un-eased, this one added, the whole
		// eased again: held under light_cap whatever order the lights come in. Measured on his
		// colour's top channel (a warm lamp on warm skin lifts the red far more than the whole:
		// the clipping was the red), so no channel passes light_cap × his own.
		float top = max(max(ALBEDO.r, ALBEDO.g), max(ALBEDO.b, 1e-4));
		vec3 sum = DIFFUSE_LIGHT + add;
		float so_far = max(max(DIFFUSE_LIGHT.r * ALBEDO.r, DIFFUSE_LIGHT.g * ALBEDO.g), DIFFUSE_LIGHT.b * ALBEDO.b) / top;
		float a = max(max(add.r * ALBEDO.r, add.g * ALBEDO.g), add.b * ALBEDO.b) / top;
		float whole = max(max(sum.r * ALBEDO.r, sum.g * ALBEDO.g), sum.b * ALBEDO.b) / top;
		float c = light_cap;
		float kn = c * light_knee;
		float s0 = min(so_far, c * 0.9999);
		float raw = s0 <= kn ? s0 : kn - (c - kn) * log(1.0 - (s0 - kn) / (c - kn));
		float t = raw + a;
		float held = t <= kn ? t : kn + (c - kn) * (1.0 - exp(-(t - kn) / (c - kn)));
		DIFFUSE_LIGHT = sum * (held / max(whole, 1e-5));
	} else {
		DIFFUSE_LIGHT += add;
	}
	// Only wet things shine (the eyes): a small hard glint.
	if (ROUGHNESS < 0.3) {
		vec3 h = normalize(VIEW + LIGHT);
		float s = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 120.0) * ATTENUATION;
		SPECULAR_LIGHT += step(0.5, s) * LIGHT_COLOR * 0.35;
	}
}

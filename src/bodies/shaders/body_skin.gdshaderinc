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
uniform float paint_contrast = 1.08;
// Texels a side in one of the painted texture's squares (lit as one): 1, or 3 on the face, whose
// eyes are drawn finer than its squares.
uniform float square_texels = 1.0;

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = use_custom_pos ? CUSTOM0.xyz : VERTEX;
	local_normal = NORMAL;
}

vec3 triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(albedo_tex, p.zy * uv_scale).rgb * w.x
			+ texture(albedo_tex, p.xz * uv_scale).rgb * w.y
			+ texture(albedo_tex, p.xy * uv_scale).rgb * w.z;
}

// Godot 4.7's ACES (servers/rendering/renderer_rd/shaders/effects/tonemap.glsl, white 1.0), inverted:
// the scene-linear colour it maps to `c` (linear, 0..1).
vec3 aces_inverse(vec3 c) {
	const float KA = 0.0245786;
	const float KB = 0.000090537;
	const float KC = 0.983729;
	const float KD = 0.432951;
	const float KE = 0.238081;
	const float WHITE = 0.781071;  // the curve at 1.8 (white 1.0 × the exposure bias)
	const mat3 RGB_TO_RRT = mat3(
			vec3(0.59719 * 1.8, 0.35458 * 1.8, 0.04823 * 1.8),
			vec3(0.07600 * 1.8, 0.90834 * 1.8, 0.01566 * 1.8),
			vec3(0.02840 * 1.8, 0.13383 * 1.8, 0.83777 * 1.8));
	const mat3 ODT_TO_RGB = mat3(
			vec3(1.60475, -0.53108, -0.07367),
			vec3(-0.10208, 1.10813, -0.00605),
			vec3(-0.00327, -0.07276, 1.07602));
	vec3 t = clamp((c * WHITE) * inverse(ODT_TO_RGB), vec3(0.0), vec3(1.0));
	// (u² + Au − B) / (Cu² + Du + E) = t, for u.
	vec3 a = 1.0 - t * KC;
	vec3 b = KA - t * KD;
	vec3 u = (-b + sqrt(b * b + 4.0 * a * (KB + t * KE))) / (2.0 * a);
	return max(u * inverse(RGB_TO_RRT), vec3(0.0));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

vec3 from_srgb(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// A painted colour (linear, as sampled) → the scene colour the grade shows as that colour.
vec3 painted_to_scene(vec3 c) {
	vec3 s = clamp(0.5 + (to_srgb(c) - 0.5) / paint_contrast, 0.0, 1.0);
	return aces_inverse(from_srgb(s));
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
	vec2 centre = tile_centre(t);
	vec2 tuv_dx = dFdx(tuv);
	vec2 tuv_dy = dFdy(tuv);
	tile_light_at(t, centre, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, 0.05);
	vec3 base;
	if (!use_uv) {
		base = triplanar(local_pos, local_normal);
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
	if (eye_radius > 0.0 && min(distance(local_pos, eye_r_pos), distance(local_pos, eye_l_pos)) < eye_radius) {
		ROUGHNESS = 0.12;
		SPECULAR = 0.9;
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
	ALBEDO = base * (1.0 - glow) * (painted ? paint_gain : 1.0);
	EMISSION = base * glow;
	if (painted) {
		AO = 0.0;
		// Painted matt: no sheen of the sky or the room on him (a night sky turned his shirt blue).
		SPECULAR = 0.0;
	}
}

void light() {
	// Lambert, stepped in gamma space so the steps look even; shadows are in ATTENUATION.
	float w = uv_rect.z > 0.0 ? paint_wrap : 0.0;
	float k = clamp((dot(NORMAL, LIGHT) + w) / (1.0 + w), 0.0, 1.0);
	k *= ATTENUATION;
	if (light_steps > 0.0) {
		float g = pow(k, 1.0 / 2.2);
		k = pow(floor(g * light_steps + 0.5) / light_steps, 2.2);
	}
	if (uv_rect.z > 0.0) {
		// How much brighter than painted this light makes him (ALBEDO carries paint_gain), eased
		// off towards paint_limit so a lamp at his elbow doesn't burn the painted colours out.
		float m = k * dot(LIGHT_COLOR, vec3(0.2126, 0.7152, 0.0722)) / PI * paint_gain;
		DIFFUSE_LIGHT += vec3(m / (1.0 + m / paint_limit) / paint_gain);
	} else {
		DIFFUSE_LIGHT += k * LIGHT_COLOR / PI;
	}
	// Only wet things shine (the eyes): a small hard glint.
	if (ROUGHNESS < 0.3) {
		vec3 h = normalize(VIEW + LIGHT);
		float s = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 120.0) * ATTENUATION;
		SPECULAR_LIGHT += step(0.5, s) * LIGHT_COLOR * 0.35;
	}
}

// The shader-paint trial (the characters session, Sean's go, 2026-10-12; off everywhere, put on a
// man by tools/characters/shader_paint.gd): a man's look made here, not baked into his texture.
// His model's own colour (no repaint) is cut into squares of a set size on his body, each square
// one colour of his palette (tools/characters/shader_paint.py), a shade of its own, and lit as
// one, the light in a few steps that lean warm-dark in shade. Every man drawn by the same rules,
// so a new man is his shape and his palette.
shader_type spatial;
render_mode cull_back;

#include "res://src/bodies/shaders/wounds.gdshaderinc"
#include "res://src/render/tiles.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
// His palette: palette_size colours in a row (sRGB in the file).
uniform sampler2D palette_tex : source_color, filter_nearest;
uniform int palette_size = 0;
// Squares on him, metres a side (the painting's man: ~8 mm), finer round his eyes.
uniform float cell_m = 0.008;
uniform float eye_cell_m = 0.0028;
uniform float eye_zone = 0.022;
// How much each square's shade wanders from its neighbours' (lightness, ±).
uniform float jitter = 0.07;
// How far a square's colour is pulled to his palette (1: snapped).
uniform float snap = 1.0;
// Light in this many steps (gamma space); what the shade leans toward.
uniform float light_steps = 4.0;
// The top of the light eased off (a shoulder: k / (1 + k * shoulder)), so a lamp at his elbow
// doesn't burn his lit cheek white; 0 = none.
uniform float shoulder = 0.0;
// How much of a square his colour is averaged over (1: the whole square, the mip its size; 0:
// the one texel at its middle, crisp but noisy).
uniform float average = 1.0;
uniform vec3 shade_tint : source_color = vec3(0.62, 0.5, 0.52);
uniform float roughness_value = 1.0;
// Eyes (the head piece's own space, as body_skin's): the whites brightened, wet.
uniform vec3 eye_r_pos = vec3(0.0);
uniform vec3 eye_l_pos = vec3(0.0);
uniform float eye_radius = 0.0;
uniform float eye_gain = 1.0;
// The eye drawn for every man (one template, placed on his eyes): an opening eye_w by eye_h, its
// white, an iris and pupil looking at you, a glint, a dark upper lid. Metres; 0 eye_w = his own.
uniform float eye_w = 0.026;
uniform float eye_h = 0.0095;
uniform float iris_r = 0.0052;
uniform float lid_m = 0.0024;
uniform vec3 eye_white : source_color = vec3(0.86, 0.80, 0.70);
uniform vec3 eye_iris : source_color = vec3(0.16, 0.10, 0.06);
uniform vec3 eye_lid : source_color = vec3(0.07, 0.045, 0.035);

varying vec3 local_pos;
varying vec3 shade_mix;

void vertex() {
	local_pos = CUSTOM0.xyz;
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

vec3 to_g(vec3 c) {
	return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 nearest_colour(vec3 c) {
	vec3 g = to_g(c);
	vec3 best = c;
	float bd = 1e9;
	for (int i = 0; i < 32; i++) {
		if (i >= palette_size) {
			break;
		}
		vec3 p = texelFetch(palette_tex, ivec2(i, 0), 0).rgb;
		vec3 d = (to_g(p) - g) * vec3(1.0, 1.25, 0.8);
		float dd = dot(d, d);
		if (dd < bd) {
			bd = dd;
			best = p;
		}
	}
	return best;
}

void fragment() {
	// The square: a cube of cell_m in the rest pose's space (CUSTOM0, so the squares stay on him
	// as he moves), cut by the plane the surface mostly faces (its rest-space facet normal).
	vec3 fn = normalize(cross(dFdx(local_pos), dFdy(local_pos)));
	vec3 an = abs(fn);
	int axis = an.x > an.y && an.x > an.z ? 0 : (an.y > an.z ? 1 : 2);
	bool near_eye = eye_radius > 0.0 && min(distance(local_pos, eye_r_pos), distance(local_pos, eye_l_pos)) < eye_zone;
	float cell = near_eye ? eye_cell_m : cell_m;
	vec2 plane = axis == 0 ? local_pos.zy : (axis == 1 ? local_pos.xz : local_pos.xy);
	vec2 t = plane / cell;
	vec2 centre = floor(t) + 0.5;
	// His colour at the square's middle: the UV there, from how UV moves across the screen.
	vec2 s = tile_step(t, centre);
	vec2 uvc = UV + dFdx(UV) * s.x + dFdy(UV) * s.y;
	if (length(uvc - UV) > 0.02) {
		uvc = UV;  // across a seam of his atlas: his own texel
	}
	// The mip about a square's size: the square's average, then pulled to his palette.
	float per_m = length(dFdx(UV)) * float(textureSize(albedo_tex, 0).x) / max(length(dFdx(local_pos)), 1e-7);
	float lod = log2(max(cell * per_m, 1.0)) * average;
	vec3 base = textureLod(albedo_tex, uvc, lod).rgb;
	base = mix(base, nearest_colour(base), snap);
	// Each square a shade of its own, steady (hashed on the square and the plane it's cut in).
	float h = hash3(vec3(floor(t), float(axis)) + (near_eye ? 7.0 : 0.0));
	base *= 1.0 + (h - 0.5) * 2.0 * jitter;
	// The drawn eye, square by square (each square's centre decides), on the face's front.
	if (near_eye && eye_w > 0.0 && an.z > 0.35 && local_pos.z < (eye_r_pos.z + eye_l_pos.z) * 0.5) {
		vec3 q = local_pos;
		// The square's centre in the plane it's cut in, with the depth it has here.
		if (axis == 2) {
			q.xy = centre * cell;
		}
		bool right = distance(local_pos, eye_r_pos) < distance(local_pos, eye_l_pos);
		vec3 e = right ? eye_r_pos : eye_l_pos;
		vec2 d = q.xy - e.xy;
		float out_dir = sign(e.x);  // the outer corner's side
		float ex = d.x / (eye_w * 0.5);
		// The opening: an almond, fuller toward the inner corner.
		float half_h = eye_h * 0.5 * sqrt(max(1.0 - ex * ex, 0.0)) * (1.0 - 0.15 * ex * out_dir);
		bool in_open = abs(ex) < 1.0 && abs(d.y) < half_h;
		bool lid = abs(ex) < 1.12 && d.y >= half_h - cell * 0.25 && d.y < half_h + lid_m && d.y > -0.001;
		if (in_open) {
			float r = length(d);
			base = r < iris_r ? (r < iris_r * 0.45 ? eye_iris * 0.4 : eye_iris) : eye_white;
			if (r < iris_r && distance(d, vec2(-iris_r * 0.35, iris_r * 0.4)) < cell * 0.75) {
				base = vec3(0.95, 0.92, 0.85);
			}
		} else if (lid) {
			base = eye_lid;
		}
	}
	tile_light_at(t, centre, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, 0.05);
	float reach = wound_reach(local_pos);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.0;
	float eye_boost = 1.0;
	if (eye_radius > 0.0 && min(distance(local_pos, eye_r_pos), distance(local_pos, eye_l_pos)) < eye_radius) {
		ROUGHNESS = 0.12;
		SPECULAR = 0.9;
		float top = max(max(base.r, base.g), base.b);
		float pale = smoothstep(0.55, 0.8, min(min(base.r, base.g), base.b) / max(top, 1e-4)) * step(0.2, top);
		eye_boost = mix(1.0, eye_gain, pale);
	}
	if (reach < 1.0) {
		if (!reduced_gore) {
			discard;
		}
		base = vec3(0.16, 0.02, 0.02);
	} else if (reach < 1.4) {
		base = mix(vec3(0.3, 0.03, 0.03), vec3(0.55, 0.12, 0.1), step(reach, 1.15) * (reduced_gore ? 0.0 : 1.0));
	} else if (reach < 2.2) {
		base = mix(base * vec3(0.45, 0.12, 0.1), base, (reach - 1.4) / 0.8);
	}
	ALBEDO = base * eye_boost;
	shade_mix = shade_tint;
}

void light() {
	float k = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	if (light_steps > 0.0) {
		float g = pow(k, 1.0 / 2.2);
		k = pow(floor(g * light_steps + 0.5) / light_steps, 2.2);
	}
	k /= 1.0 + k * shoulder;
	DIFFUSE_LIGHT += k * LIGHT_COLOR * mix(shade_mix, vec3(1.0), k) / PI;
	if (ROUGHNESS < 0.3) {
		vec3 hv = normalize(VIEW + LIGHT);
		float sp = pow(clamp(dot(NORMAL, hv), 0.0, 1.0), 120.0) * ATTENUATION;
		SPECULAR_LIGHT += step(0.5, sp) * LIGHT_COLOR * 0.35;
	}
}

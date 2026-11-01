// A realistic test man's hair, beard, brow and lash cards (#547 step 3). Two passes, so the cards'
// edges come out soft without multisampling (the game draws none): realistic_hair.gdshader draws
// each card's near-solid core, cut by its alpha and writing depth (it casts the shadows);
// realistic_hair_fringe.gdshader, its next pass, blends the thin strands round it over what's
// behind, without writing depth. Lit by Kajiya-Kay with Scheuermann's two highlights along the
// strands (realistic_light.gdshaderinc), wrapped diffuse, and light through the hair against the
// light.

#include "res://src/bodies/shaders/realistic_light.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
// Where the core ends: alpha at and over it is drawn solid by the first pass, under it by the fringe.
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
// Under this the fringe draws nothing (the card's empty space).
uniform float alpha_floor : hint_range(0.0, 1.0) = 0.03;
uniform float roughness : hint_range(0.0, 1.0) = 0.55;
// Wrapped diffuse: hair is lit past its terminator (light scatters through the strands).
uniform float wrap = 0.5;
// The strands run along the card's v (Human Generator's cards); false: along u.
uniform bool strand_along_v = true;
// The two highlights: how sharp, how strong, how far each is shifted along the strand (root-ward
// the white one, tip-ward the coloured one), and how much each strand's own shift varies.
uniform float spec_sharp = 80.0;
uniform float spec_strength = 0.35;
uniform float spec2_sharp = 24.0;
uniform float spec2_strength = 0.5;
uniform float shift1 = -0.08;
uniform float shift2 = 0.12;
uniform float shift_vary = 0.15;
// Light through the hair against the light.
uniform float backlight = 0.3;
uniform vec3 scatter_tint : source_color = vec3(1.0, 0.8, 0.6);

float rl_hash(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void fragment() {
	vec4 a = texture(albedo_tex, UV);
#ifdef RL_FRINGE
	if (a.a >= alpha_cut || a.a < alpha_floor) {
		discard;
	}
	// Continuous with the core at the cut.
	ALPHA = a.a / alpha_cut;
#else
	if (a.a < alpha_cut) {
		discard;
	}
#endif
	ALBEDO = a.rgb;
	ROUGHNESS = roughness;
	SPECULAR = 0.0;
	vec3 n = normalize(NORMAL) * (FRONT_FACING ? 1.0 : -1.0);
	NORMAL = n;
	// The strand's direction: how the surface moves along the card's v (or u), from screen-space
	// derivatives as the skin's cotangent frame (realistic_person.gdshader).
	vec3 dp1 = dFdx(VERTEX);
	vec3 dp2 = dFdy(VERTEX);
	vec2 duv1 = dFdx(UV);
	vec2 duv2 = dFdy(UV);
	vec3 dp2perp = cross(dp2, n);
	vec3 dp1perp = cross(n, dp1);
	vec3 along = strand_along_v ? dp2perp * duv1.y + dp1perp * duv2.y : dp2perp * duv1.x + dp1perp * duv2.x;
	rl_strand = normalize(along + n * 1e-6);
	// Each strand its own shift: where it sits across the card, in steps of about a strand.
	float across = strand_along_v ? UV.x : UV.y;
	rl_shift = (rl_hash(floor(across * 512.0)) - 0.5) * shift_vary;
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float d = clamp((nl + wrap) / (1.0 + wrap), 0.0, 1.0);
	DIFFUSE_LIGHT += d * ATTENUATION * LIGHT_COLOR / RL_PI;
	if (backlight > 0.0) {
		DIFFUSE_LIGHT += rl_through(NORMAL, LIGHT, VIEW, 0.2, 2.0, scatter_tint) * backlight * ATTENUATION * LIGHT_COLOR / RL_PI;
	}
	vec3 h = normalize(LIGHT + VIEW);
	// The strand tilted towards the root (its cuticle's scales), each highlight a little more.
	vec3 t1 = normalize(rl_strand + NORMAL * (shift1 + rl_shift));
	vec3 t2 = normalize(rl_strand + NORMAL * (shift2 + rl_shift));
	float lit = clamp(nl * 0.5 + 0.5, 0.0, 1.0) * ATTENUATION;
	vec3 s = vec3(rl_strand_spec(t1, h, spec_sharp)) * spec_strength
			+ ALBEDO * rl_strand_spec(t2, h, spec2_sharp) * spec2_strength;
	SPECULAR_LIGHT += s * lit * LIGHT_COLOR * SPECULAR_AMOUNT / RL_PI;
}

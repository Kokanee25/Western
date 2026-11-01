// A realistic test man's surfaces (Sean, 2026-11-01, issue #522: "see what real looking characters
// will look like in game", a possible change of art style). Used only for the shapes a man's report
// lists under "realistic" (PeopleBodies._realistic_material); every other man keeps the game's
// people shader. Colour, a tangent-space normal map, roughness; his hair, beard and brow cards are
// realistic_hair.gdshader's.
//
// The body pieces carry no tangents (BodyMesh.split_pieces), so the normal map's frame is made per
// pixel from screen-space derivatives of position and UV: the "cotangent frame" of Christian
// Schueler, "Normal Mapping Without Precomputed Tangents" (ShaderX5, 2006; blog 2013).
//
// Its own light() (realistic_light.gdshaderinc, #547 step 3): the usual microfacet shine, and on
// skin (soft_skin) light wrapped round red furthest and a little light through thin parts, so skin
// reads soft, not as painted plaster.
//
// Not here (a look test): wounds, blood and the wound openings the people shader cuts.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://src/bodies/shaders/realistic_light.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform bool use_normal = false;
uniform bool use_rough = false;
uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float normal_strength = 1.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform bool use_alpha = false;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
// Light through thin parts seen against the light (ears): how much, in the scatter colour.
uniform float backlight = 0.0;
// Soft skin: each channel's light wrapped past the terminator (red furthest), and the colour light
// takes through him.
uniform bool soft_skin = false;
uniform vec3 skin_wrap = vec3(0.2, 0.08, 0.05);
uniform vec3 scatter_tint : source_color = vec3(0.95, 0.32, 0.22);
// The material's SPECULAR, for light() (which can't read it).
varying float rl_specular_amount;
uniform float through_distortion = 0.3;
uniform float through_power = 3.0;

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	if (use_alpha && a.a < alpha_cut) {
		discard;
	}
	ALBEDO = a.rgb;
	ROUGHNESS = use_rough ? texture(rough_tex, UV).r : roughness;
	SPECULAR = specular;
	rl_specular_amount = specular;
	vec3 n_geo = normalize(NORMAL) * (FRONT_FACING ? 1.0 : -1.0);
	if (use_normal) {
		vec3 t = texture(normal_tex, UV).xyz * 2.0 - 1.0;
		// Baked by Blender (OpenGL: green up the texture); Godot's UV v runs down the image.
		t.y = -t.y;
		t.xy *= normal_strength;
		vec3 dp1 = dFdx(VERTEX);
		vec3 dp2 = dFdy(VERTEX);
		vec2 duv1 = dFdx(UV);
		vec2 duv2 = dFdy(UV);
		vec3 dp2perp = cross(dp2, n_geo);
		vec3 dp1perp = cross(n_geo, dp1);
		vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
		vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
		float inv = inversesqrt(max(max(dot(T, T), dot(B, B)), 1e-20));
		NORMAL = normalize(mat3(T * inv, B * inv, n_geo) * normalize(t));
	} else {
		NORMAL = n_geo;
	}
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	vec3 d = soft_skin ? rl_wrapped(nl, skin_wrap) : vec3(clamp(nl, 0.0, 1.0));
	DIFFUSE_LIGHT += d * ATTENUATION * LIGHT_COLOR / RL_PI;
	if (backlight > 0.0) {
		DIFFUSE_LIGHT += rl_through(NORMAL, LIGHT, VIEW, through_distortion, through_power, scatter_tint)
				* backlight * ATTENUATION * LIGHT_COLOR / RL_PI;
	}
	SPECULAR_LIGHT += rl_specular(NORMAL, LIGHT, VIEW, ROUGHNESS, rl_specular_amount) * ATTENUATION * LIGHT_COLOR * SPECULAR_AMOUNT;
}

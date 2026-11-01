// A realistic test man's surfaces (Sean, 2026-11-01, issue #522: "see what real looking characters
// will look like in game", a possible change of art style). Used only for the shapes a man's report
// lists under "realistic" (PeopleBodies._realistic_material); every other man keeps the game's
// people shader. Lit by Godot's own physically based lighting: colour, a tangent-space normal map,
// roughness, and hair and beard cards cut out by their alpha.
//
// The body pieces carry no tangents (BodyMesh.split_pieces), so the normal map's frame is made per
// pixel from screen-space derivatives of position and UV: the "cotangent frame" of Christian
// Schueler, "Normal Mapping Without Precomputed Tangents" (ShaderX5, 2006; blog 2013).
//
// Not here (a look test): wounds, blood and the wound openings the people shader cuts.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

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
// Light through thin parts (ears, hair cards): Godot's backlight, in the albedo's colour.
uniform float backlight = 0.0;

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	if (use_alpha && a.a < alpha_cut) {
		discard;
	}
	ALBEDO = a.rgb;
	ROUGHNESS = use_rough ? texture(rough_tex, UV).r : roughness;
	SPECULAR = specular;
	BACKLIGHT = a.rgb * backlight;
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

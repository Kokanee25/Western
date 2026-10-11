// The character-sheet style trial (SheetStyle, --sheet-style; docs/concept/style_candidates/
// character_sheet.png): a man's own colour cut into squares in his body's space
// (tools/sheet_style.py), drawn nearest, his normal map smooth, and Godot's ordinary light (no
// light() of our own, no per-texel light), so the light runs across the squares.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform bool use_normal = true;
uniform float normal_depth = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_depth;
	}
	ROUGHNESS = roughness;
	SPECULAR = specular;
}

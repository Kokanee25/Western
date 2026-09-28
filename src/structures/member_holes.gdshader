shader_type spatial;
// A structure member's wood (same look as its StandardMaterial3D) with bullet holes cut in it.
// Holes that went right through are cut out (discard), so you see — and the sun shines —
// through them; the ones that stopped inside are dark pits. Fresh splintered wood rings each.
// Tested on the texel grid, so holes are pixel-sized and pixel-edged like everything else.

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(0.625);
uniform vec2 uv_offset = vec2(0.0);
uniform float texels_per_meter = 40.0;
uniform int hole_count = 0;
uniform vec4 hole_a[16]; // entry.xyz (member space), radius
uniform vec4 hole_b[16]; // exit.xyz (member space), 1 = went through

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float seg_dist(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-8), 0.0, 1.0);
	return length(p - (a + ab * t));
}

void fragment() {
	vec3 col = texture(albedo_tex, UV * uv_scale + uv_offset).rgb * tint.rgb;
	// Snap to the texel grid so holes are drawn in whole texels.
	vec3 p = (floor(local_pos * texels_per_meter) + 0.5) / texels_per_meter;
	float min_r = 1.05 / texels_per_meter;
	for (int i = 0; i < hole_count; i++) {
		float r = max(hole_a[i].w, min_r);
		bool through = hole_b[i].w > 0.5;
		float d = through ? seg_dist(p, hole_a[i].xyz, hole_b[i].xyz) : length(p - hole_a[i].xyz);
		if (d < r) {
			if (through) {
				discard;
			}
			col *= 0.12;
		} else if (d < r * 2.2) {
			// raw splintered wood round the hole, much paler than the weathered surface
			col = mix(col, vec3(0.78, 0.66, 0.48), 0.8);
		}
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}

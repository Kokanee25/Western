shader_type canvas_item;
// Final pass on the low-res frame as it is scaled to the window. Optional "pixel shading": colours
// snap to a limited number of levels, and smooth gradients (fog, lamp falloff, shadow edges,
// sky) break into an ordered dither, like hand-shaded pixel art. The lighting itself stays modern.

uniform bool shading_enabled = false;
// Levels per channel: fewer = stronger banding.
uniform float levels = 12.0;
uniform float dither_strength = 1.0;
// Size of the low-res frame, so the dither lands on its pixels, not the window's.
uniform vec2 source_size = vec2(640.0, 360.0);

float bayer4(ivec2 p) {
	int x = p.x & 3;
	int y = p.y & 3;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (shading_enabled) {
		ivec2 p = ivec2(floor(UV * source_size));
		float d = (bayer4(p) - 0.5) * dither_strength;
		vec3 v = c.rgb * (levels - 1.0) + d;
		c.rgb = clamp(floor(v + 0.5) / (levels - 1.0), 0.0, 1.0);
	}
	COLOR = c;
}

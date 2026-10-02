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
// The finish (docs/ART_REVIEW.md §8.7, Settings.finish): where a render pixel sits on a hard edge
// between two blocks (a big jump to a neighbour), it takes this share of its four neighbours'
// mean, so block edges soften by about one render pixel and the frame stops reading as a grid
// of hard squares. Smooth areas and fine lines (a jump on one side only) are left alone.
uniform float finish_soften = 0.0;

float bayer4(ivec2 p) {
	int x = p.x & 3;
	int y = p.y & 3;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (finish_soften > 0.0) {
		vec2 px = 1.0 / source_size;
		vec3 l = texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb;
		vec3 r = texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb;
		vec3 u = texture(TEXTURE, UV - vec2(0.0, px.y)).rgb;
		vec3 d = texture(TEXTURE, UV + vec2(0.0, px.y)).rgb;
		// An edge: a jump across this pixel in x or in y (both sides differ from it the same way).
		float jx = min(length(l - c.rgb), length(r - c.rgb)) * step(0.0, dot(l - c.rgb, r - c.rgb));
		float jy = min(length(u - c.rgb), length(d - c.rgb)) * step(0.0, dot(u - c.rgb, d - c.rgb));
		float edge = smoothstep(0.03, 0.12, max(jx, jy));
		c.rgb = mix(c.rgb, (l + r + u + d) * 0.25, edge * finish_soften);
	}
	if (shading_enabled) {
		ivec2 p = ivec2(floor(UV * source_size));
		float d = (bayer4(p) - 0.5) * dither_strength;
		vec3 v = c.rgb * (levels - 1.0) + d;
		c.rgb = clamp(floor(v + 0.5) / (levels - 1.0), 0.0, 1.0);
	}
	COLOR = c;
}

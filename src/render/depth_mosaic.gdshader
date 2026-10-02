shader_type spatial;
// A trial (item 3 of the look list, judged against texel_grid's min_square_px): the finished frame
// cut into screen squares that grow with distance, so far surfaces never show texels smaller than
// `min_px` render pixels. Where a surface's texels (texels_per_meter, the world's) would be smaller
// on screen than that, the frame there is drawn in squares of 2, 4 or 8 pixels on a fixed screen
// grid, each the average of what's under it; a square only takes its colour from its own distance
// band (a near thing in front keeps its own pixels). Past `far` (the backdrop, the sky) nothing
// changes: they're squares already. A full-screen quad a camera carries (DepthMosaic).
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float min_px = 5.0;
uniform float texels_per_meter = 32.0;
uniform float far = 200.0;
// Render pixels per metre at 1 m (set each frame by DepthMosaic from the camera).
uniform float focal = 600.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

float band(float d, float f) {
	if (d > far) {
		return 1.0;
	}
	float texel_px = f / (texels_per_meter * max(d, 0.01));
	return exp2(clamp(ceil(log2(min_px / texel_px)), 0.0, 3.0));
}

void fragment() {
	float d = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float p = band(d, focal);
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	if (p > 1.0) {
		vec2 origin = floor(FRAGCOORD.xy / p) * p;
		vec2 c = (origin + p * 0.5) / VIEWPORT_SIZE;
		if (band(linear_depth(c, INV_PROJECTION_MATRIX), focal) == p) {
			vec3 sum = vec3(0.0);
			for (int j = 0; j < 2; j++) {
				for (int i = 0; i < 2; i++) {
					vec2 q = (origin + p * (vec2(float(i), float(j)) * 0.5 + 0.25)) / VIEWPORT_SIZE;
					sum += texture(screen_tex, q).rgb;
				}
			}
			col = sum * 0.25;
		}
	}
	ALBEDO = col;
}

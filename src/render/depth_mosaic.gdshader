shader_type spatial;
// The painting's mosaic in screen space: the finished, lit frame cut into blocks that shrink with
// distance (about `block_k` / depth render pixels a side: 3 or 4 px on the man at the table, 2 at
// the far bar at 1280 wide, as the saloon painting measures: its blocks are nearly one size), each block one colour, the sample at
// its centre (an average reads plain; the painting's blocks are flat, deliberate colours), its
// light posterised into `steps` tones so shading jumps block to block. Silhouettes go
// stair-stepped at the block size, as the painting's are, and a model's facets hide under the
// blocks. A block takes its colour only from its own distance band (a near thing in front keeps
// its own blocks). A full-screen quad a camera carries (DepthMosaic), drawn after the 3D frame and
// before the screen pass (run with the finish's softening off: it would blur the block edges).
//
// The first trial of this (2026-10-02, judged by the old judge that rewarded noise) only chunked
// far surfaces (2/4/8 px where a texel would be smaller than min_px) and averaged each block.
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
// Block size in render pixels = block_k / depth in metres, between min_block and max_block, at a
// 1280-wide frame (scaled with the frame's width).
uniform float block_k = 5.0;
uniform float min_block = 2.0;
uniform float max_block = 4.0;
// Tones of light: the block's luminance snapped to this many steps (gamma space); 0 = smooth.
uniform float steps = 14.0;
// Past this the frame is left alone (the backdrop and the sky are painted squares already).
uniform float far = 200.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

// `scale`: the frame's width over 1280 (VIEWPORT_SIZE is only to hand in fragment()).
float block_size(float d, float scale) {
	if (d > far) {
		return 1.0;
	}
	return floor(clamp(block_k * scale / max(d, 0.05), min_block * scale, max_block * scale) + 0.5);
}

vec3 posterise(vec3 col) {
	if (steps <= 0.0) {
		return col;
	}
	float lum = max(dot(col, vec3(0.299, 0.587, 0.114)), 1e-4);
	float g = pow(lum, 1.0 / 2.2);
	float q = pow(floor(g * steps + 0.5) / steps, 2.2);
	return col * (q / lum);
}

void fragment() {
	float scale = VIEWPORT_SIZE.x / 1280.0;
	float d = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float p = block_size(d, scale);
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	if (p > 1.0) {
		vec2 origin = floor(FRAGCOORD.xy / p) * p;
		vec2 c = (origin + p * 0.5) / VIEWPORT_SIZE;
		// The block's own colour: its centre's, if the centre is in the same band; else the
		// nearest corner sample that is (so a block on a silhouette stays one colour).
		if (block_size(linear_depth(c, INV_PROJECTION_MATRIX), scale) == p) {
			col = texture(screen_tex, c).rgb;
		} else {
			for (int j = 0; j < 2; j++) {
				for (int i = 0; i < 2; i++) {
					vec2 q = (origin + p * (vec2(float(i), float(j)) * 0.5 + 0.25)) / VIEWPORT_SIZE;
					if (block_size(linear_depth(q, INV_PROJECTION_MATRIX), scale) == p) {
						col = texture(screen_tex, q).rgb;
					}
				}
			}
		}
	}
	ALBEDO = posterise(col);
}

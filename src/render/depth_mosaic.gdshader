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
// It writes ALPHA so Godot puts it in the transparent pass, after the opaque frame and the sky:
// the screen texture only exists there. Without that a real GPU drew it in the opaque pass over
// an empty frame (build 340: a black screen with the sky showing through).
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
// Past this the frame is left alone (the backdrop and the sky are painted squares already, and
// the paintings' skies are smooth: posterised they band into rings).
uniform float far = 200.0;
// The quantise-once trial's knobs (docs/screenshots/quantise_once/), all off at the defaults:
// block size as block_k / depth^depth_power (1: the painting's blocks shrink with distance;
// 0.5: nearly one size near and far, as the saloon painting measures); `soft` render pixels of
// blend across each block's edges (the painting's blocks are soft-edged); the block's colour
// snapped to sat_steps of saturation and hue_steps of hue as well as `steps` of light (a
// limited palette, as the painting's regions have). 0 = off.
uniform float depth_power = 1.0;
uniform float soft = 0.0;
// 1: a block's colour is the average of its pixels (in its own depth band): the quantise-once
// rule, where the frame underneath is smooth (a point sample of a fine texture is speckle). 0:
// the sample at its centre (right for a frame that is already in blocks).
uniform float average = 0.0;
// With `average`: darker pixels weigh more in the mean (weight (1 - gamma luminance)^dark_weight),
// so a block on a shadow's edge keeps the shadow: a plain mean lifted the saloon's darks (deep
// shadow share 0.24 to the painting's 0.41). 0 = the plain mean.
uniform float dark_weight = 0.0;
uniform float sat_steps = 0.0;
uniform float hue_steps = 0.0;

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
	return floor(clamp(block_k * scale / pow(max(d, 0.05), depth_power), min_block * scale, max_block * scale) + 0.5);
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 posterise(vec3 col) {
	if (steps > 0.0) {
		float lum = max(dot(col, vec3(0.299, 0.587, 0.114)), 1e-4);
		float g = pow(lum, 1.0 / 2.2);
		float q = pow(floor(g * steps + 0.5) / steps, 2.2);
		col *= q / lum;
	}
	if (sat_steps > 0.0 || hue_steps > 0.0) {
		// Hue and saturation snapped in gamma space, the light kept as it is.
		vec3 hsv = rgb_to_hsv(pow(max(col, vec3(0.0)), vec3(1.0 / 2.2)));
		if (hue_steps > 0.0) {
			hsv.x = fract(floor(hsv.x * hue_steps + 0.5) / hue_steps);
		}
		if (sat_steps > 0.0) {
			hsv.y = floor(hsv.y * sat_steps + 0.5) / sat_steps;
		}
		col = pow(hsv_to_rgb(hsv), vec3(2.2));
	}
	return col;
}

// The one colour of the block whose corner is `origin` (render pixels), `p` a side: its centre's,
// if the centre is in the same depth band; else the nearest corner sample that is (so a block on
// a silhouette stays one colour).
vec3 block_colour(vec2 origin, float p, float scale, mat4 inv_proj, vec2 size) {
	vec2 c = (origin + p * 0.5) / size;
	if (average > 0.5) {
		vec3 sum = vec3(0.0);
		float n = 0.0;
		for (int j = 0; j < 4; j++) {
			for (int i = 0; i < 4; i++) {
				vec2 q = (origin + p * (vec2(float(i), float(j)) + 0.5) * 0.25) / size;
				if (block_size(linear_depth(q, inv_proj), scale) == p) {
					vec3 s = texture(screen_tex, q).rgb;
					float w = 1.0;
					if (dark_weight > 0.0) {
						float g = pow(clamp(dot(s, vec3(0.299, 0.587, 0.114)), 0.0, 1.0), 1.0 / 2.2);
						w = pow(1.0 - min(g, 0.98), dark_weight);
					}
					sum += s * w;
					n += w;
				}
			}
		}
		if (n > 0.0) {
			return sum / n;
		}
	}
	if (block_size(linear_depth(c, inv_proj), scale) == p) {
		return texture(screen_tex, c).rgb;
	}
	vec3 col = texture(screen_tex, c).rgb;
	for (int j = 0; j < 2; j++) {
		for (int i = 0; i < 2; i++) {
			vec2 q = (origin + p * (vec2(float(i), float(j)) * 0.5 + 0.25)) / size;
			if (block_size(linear_depth(q, inv_proj), scale) == p) {
				col = texture(screen_tex, q).rgb;
			}
		}
	}
	return col;
}

void fragment() {
	float scale = VIEWPORT_SIZE.x / 1280.0;
	float d = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float p = block_size(d, scale);
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	if (p > 1.0) {
		vec2 origin = floor(FRAGCOORD.xy / p) * p;
		col = posterise(block_colour(origin, p, scale, INV_PROJECTION_MATRIX, VIEWPORT_SIZE));
		if (soft > 0.0) {
			// Soft edges: within `soft` pixels of a block's edge, blend toward the neighbour across
			// it (half way at the edge itself), each a flat colour of its own first.
			vec2 f = FRAGCOORD.xy - origin;
			vec2 e = min(f, p - f);
			vec2 side = vec2(f.x < p * 0.5 ? -1.0 : 1.0, f.y < p * 0.5 ? -1.0 : 1.0);
			if (e.x < soft) {
				vec3 n = posterise(block_colour(origin + vec2(side.x * p, 0.0), p, scale, INV_PROJECTION_MATRIX, VIEWPORT_SIZE));
				col = mix(col, n, 0.5 * (1.0 - e.x / soft));
			}
			if (e.y < soft) {
				vec3 n = posterise(block_colour(origin + vec2(0.0, side.y * p), p, scale, INV_PROJECTION_MATRIX, VIEWPORT_SIZE));
				col = mix(col, n, 0.5 * (1.0 - e.y / soft));
			}
		}
	} else if (d <= far) {
		col = posterise(col);
	}
	// Past `far` (the sky, the backdrop) the frame is left as it is: the paintings' skies are
	// smooth gradients, and steps of light or hue band them into rings.
	ALBEDO = col;
	ALPHA = 1.0;
}

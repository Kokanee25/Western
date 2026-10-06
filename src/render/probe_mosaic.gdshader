shader_type spatial;
// The probe mosaic (a trial, off by default: Settings.probe_mosaic, V): the painting's blocks
// fixed to the world instead of to the screen, so they stay put when you turn or walk.
//
// The idea is texel splatting's (Ebert 2026, "Texel Splatting: Perspective-Stable 3D Pixel Art",
// arXiv 2603.14587): index the scene by direction from a point fixed in the world, a cube of
// `texels` x `texels` texels a face round an origin snapped to a grid, so a texel never moves while
// the origin stays put. The paper renders cubemaps from that origin and draws every texel as a
// quad; this does it as one pass over the frame the camera has already rendered, with no extra
// renders: each pixel's point in the world (from depth) falls in one texel of the cube, and the
// whole block takes one colour, the frame's at the block's centre (the texel's middle at the
// pixel's distance from the origin, the paper's p = o + d / |r|inf r, projected back into this
// frame). Whatever surface that centre point shows owns the block, so at a silhouette the nearer
// thing's blocks step out over the farther one's and are cut back where they miss the centre:
// silhouettes go stepped at the block size, as the paintings' are. `samples` 3 takes the mean of
// 3x3 points across the block on that same surface instead: a third steadier in motion, softer,
// and further from the paintings by the judge (tools/probe_walk.py stability; judge v2). The
// cube's texels are spaced by equal angle across a face (the idea of Google's equi-angular
// cubemap): spaced evenly across a face's plane, a texel at its edge spans half the angle of one
// at its middle, so the blocks on a man went from 4 px to 6 as you walked up to him.
//
// When the origin moves to the next grid point the blocks are re-cut; `fade` crosses from the old
// cube to the new a block at a time (the paper cross-fades its probes with a dither, per pixel).
// Light can be banded in OKLab lightness (Ottosson 2020, "A perceptual color space for image
// processing"; the paper bands its texels the same way), off by default (`bands`). Past `far`
// (the sky, the painted backdrop) the frame is left alone. Written for this project from the
// paper's description; no code from its repository.
//
// It writes ALPHA so Godot draws it in the transparent pass, after the opaque frame and the sky,
// where the screen texture exists (as DepthMosaic must: see depth_mosaic.gdshader). Transparent
// things drawn after it (lamp glass and flames, sign lettering) stay as they are.
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
// With mipmaps (Godot blurs them down from the frame) for `prefilter`; every read at a computed
// point gives its level, since a block-constant point has no smooth derivatives to pick one by.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
// The cube: its origin (snapped to a grid by ProbeMosaic), texels a face side.
uniform vec3 probe_origin = vec3(0.0);
uniform float texels = 384.0;
// The cube before the origin last moved, and how far the blocks have crossed to the new one
// (1: all new).
uniform vec3 prev_origin = vec3(0.0);
uniform float fade = 1.0;
// 1: the crossing mixes each block's old colour into its new one (no block jumps; for a moment
// the two cubes' blocks show through each other); 0: each block switches whole at its own moment
// (a dither by the block, as the paper does).
uniform int fade_blend = 0;
// Samples a side across each block, averaged where they land on the block's own surface (1: the
// centre alone, crisp).
uniform int samples = 1;
// Darker samples weigh more in a block's mean, (1 - gamma luminance)^dark_weight as DepthMosaic's
// average does, so a block an eye, a brow or a moustache's edge falls in keeps it as a dark block
// (the plain mean washes them into the skin). 0 = the plain mean.
uniform float dark_weight = 0.0;
// Each sample read from the frame blurred to its share of the block (the mip whose pixels are the
// samples' spacing on screen) instead of the one pixel under it: 9 point samples on a block 4 px
// across alias, and what they pick up changes as you move. 0 = point samples.
uniform float prefilter = 0.0;
// Lightness bands in OKLab (0: smooth light, the default: banded, a block whose light sits near a
// band's edge flips between two bands as you move, and the darks go coarse; the bands are cut
// before the tone curve).
uniform float bands = 0.0;
// Metres past which the frame is left as it is.
uniform float far = 200.0;
// Metres within which blocks are cut by the screen instead: the gun in your hand goes everywhere
// with you (fixed to the world its blocks would crawl over it as you walked, and the cube's origin
// can be a hand's breadth from it, where texels shrink to nothing), and anything else this close
// is a wall you're leaning on.
uniform float near_screen = 0.7;
// 1: each block a random colour (to see the grid); 2: how far each pixel's own point lands from
// itself when projected back (0 = right; a check of the maths); 3: each pixel's distance; 4: each
// pixel's distance in millimetres as three bytes (red high), for tools/probe_walk.py's
// reprojection, which needs the tonemapper linear and no glow or grading (probe_walk.gd
// --depth-pass sets that up).
uniform int debug = 0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 world_at(vec2 uv, mat4 inv_proj, mat4 inv_view) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return (inv_view * vec4(v.xyz / v.w, 1.0)).xyz;
}

// The texel of the cube round `o` that point `w` falls in: face (0-5) in .x, column and row in .yz,
// and w's Chebyshev distance from o in .w (the largest of its offsets along the axes). Columns
// and rows are spaced by equal angle.
vec4 texel_of(vec3 w, vec3 o) {
	vec3 d = w - o;
	vec3 a = abs(d);
	float face;
	vec2 st;
	float m;
	if (a.x >= a.y && a.x >= a.z) {
		m = a.x;
		face = d.x > 0.0 ? 0.0 : 1.0;
		st = d.yz / m;
	} else if (a.y >= a.z) {
		m = a.y;
		face = d.y > 0.0 ? 2.0 : 3.0;
		st = d.xz / m;
	} else {
		m = a.z;
		face = d.z > 0.0 ? 4.0 : 5.0;
		st = d.xy / m;
	}
	st = atan(st) * (4.0 / PI);  // equal angle across the face
	vec2 ij = clamp(floor((st * 0.5 + 0.5) * texels), vec2(0.0), vec2(texels - 1.0));
	return vec4(face, ij, max(m, 1e-4));
}

// The point at fraction f (0-1 each way) across texel t, at its Chebyshev distance (t.w) from o.
vec3 point_in(vec4 t, vec3 o, vec2 f) {
	vec2 st = tan(((t.yz + f) / texels * 2.0 - 1.0) * (PI / 4.0));
	vec3 r;
	if (t.x < 0.5) {
		r = vec3(1.0, st);
	} else if (t.x < 1.5) {
		r = vec3(-1.0, st);
	} else if (t.x < 2.5) {
		r = vec3(st.x, 1.0, st.y);
	} else if (t.x < 3.5) {
		r = vec3(st.x, -1.0, st.y);
	} else if (t.x < 4.5) {
		r = vec3(st, 1.0);
	} else {
		r = vec3(st, -1.0);
	}
	return o + r * t.w;
}

float texel_hash(vec4 t) {
	return fract(sin(dot(t.xyz, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

// Where world point p falls on screen (off screen or behind: x < 0).
vec2 screen_of(vec3 p, mat4 view, mat4 proj) {
	vec4 clip = proj * (view * vec4(p, 1.0));
	if (clip.w <= 0.0) {
		return vec2(-1.0);
	}
	vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
	return all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0))) ? uv : vec2(-1.0);
}

// The one colour of the block that point w falls in, in the cube round o (`own`: w's pixel, for a
// block whose centre is off screen). `t` gets the block's texel.
vec3 block_colour(vec3 w, vec3 o, vec3 own, vec3 cam, mat4 view, mat4 proj, mat4 inv_proj, mat4 inv_view, vec2 vsize, out vec4 t) {
	t = texel_of(w, o);
	vec2 uv = screen_of(point_in(t, o, vec2(0.5)), view, proj);
	if (uv.x < 0.0) {
		return own;
	}
	float lod = 0.0;
	if (prefilter > 0.0) {
		// The block's width on screen, across its middle, over the samples a side.
		vec2 a = screen_of(point_in(t, o, vec2(0.0, 0.5)), view, proj);
		vec2 b = screen_of(point_in(t, o, vec2(1.0, 0.5)), view, proj);
		if (a.x >= 0.0 && b.x >= 0.0) {
			lod = prefilter * max(0.0, log2(length((b - a) * vsize) / float(max(samples, 1))));
		}
	}
	vec3 centre = textureLod(screen_tex, uv, lod).rgb;
	if (samples <= 1) {
		return centre;
	}
	// The surface the centre shows, and the samples across the block that land on it.
	float dc = distance(world_at(uv, inv_proj, inv_view), cam);
	float tol = 0.03 * dc + 2.0 * t.w / texels;
	vec3 sum = vec3(0.0);
	float n = 0.0;
	for (int j = 0; j < samples; j++) {
		for (int i = 0; i < samples; i++) {
			vec2 f = (vec2(float(i), float(j)) + 0.5) / float(samples);
			vec2 q = screen_of(point_in(t, o, f), view, proj);
			if (q.x >= 0.0 && abs(distance(world_at(q, inv_proj, inv_view), cam) - dc) <= tol) {
				vec3 s = textureLod(screen_tex, q, lod).rgb;
				float wt = 1.0;
				if (dark_weight > 0.0) {
					float g = pow(clamp(dot(s, vec3(0.299, 0.587, 0.114)), 0.0, 1.0), 1.0 / 2.2);
					wt = pow(1.0 - min(g, 0.98), dark_weight);
				}
				sum += s * wt;
				n += wt;
			}
		}
	}
	return n > 0.0 ? sum / n : centre;
}

// OKLab (Ottosson 2020) from and to linear sRGB, for banding the light by perceived lightness.
vec3 oklab(vec3 c) {
	vec3 lms = vec3(
		0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b,
		0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b,
		0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b);
	lms = sign(lms) * pow(abs(lms), vec3(1.0 / 3.0));
	return vec3(
		0.2104542553 * lms.x + 0.7936177850 * lms.y - 0.0040720468 * lms.z,
		1.9779984951 * lms.x - 2.4285922050 * lms.y + 0.4505937099 * lms.z,
		0.0259040371 * lms.x + 0.7827717662 * lms.y - 0.8086757660 * lms.z);
}

vec3 linear_srgb(vec3 lab) {
	vec3 lms = vec3(
		lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z,
		lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z,
		lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z);
	lms = lms * lms * lms;
	return vec3(
		4.0767416621 * lms.x - 3.3077115913 * lms.y + 0.2309699292 * lms.z,
		-1.2684380046 * lms.x + 2.6097574011 * lms.y - 0.3413193965 * lms.z,
		-0.0041960863 * lms.x - 0.7034186147 * lms.y + 1.7076147010 * lms.z);
}

vec3 band(vec3 c) {
	if (bands <= 0.0) {
		return c;
	}
	vec3 lab = oklab(max(c, vec3(0.0)));
	lab.x = floor(lab.x * bands + 0.5) / bands;
	return max(linear_srgb(lab), vec3(0.0));
}

void fragment() {
	vec3 own = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	vec3 w = world_at(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 col = own;
	float dist = distance(w, cam);
	if (debug == 3) {
		// Each pixel's distance from the camera, 0-50 m black to white.
		col = vec3(dist / 50.0);
	} else if (debug == 4) {
		// Bytes that come back out of an 8-bit sRGB frame as they went in.
		float mm = clamp(floor(dist * 1000.0 + 0.5), 0.0, 16777215.0);
		vec3 bytes = vec3(floor(mm / 65536.0), floor(mod(mm, 65536.0) / 256.0), mod(mm, 256.0)) / 255.0;
		col = mix(bytes / 12.92, pow((bytes + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), bytes));
	} else if (dist < near_screen) {
		// Screen blocks the size a texel is (they are all one angle), each its centre's colour.
		float p = max(1.0, floor(VIEWPORT_SIZE.y * PROJECTION_MATRIX[1][1] * PI / (4.0 * texels) + 0.5));
		vec2 c = (floor(FRAGCOORD.xy / p) * p + p * 0.5) / VIEWPORT_SIZE;
		col = band(textureLod(screen_tex, c, 0.0).rgb);
	} else if (dist <= far) {
		vec4 t;
		col = block_colour(w, probe_origin, own, cam, VIEW_MATRIX, PROJECTION_MATRIX, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX, VIEWPORT_SIZE, t);
		if (fade < 1.0 && (fade_blend > 0 || texel_hash(t) >= fade)) {
			// This block hasn't crossed to the new cube yet (or, blending, is on its way): the old
			// cube's block here.
			vec4 tp;
			vec3 old = block_colour(w, prev_origin, own, cam, VIEW_MATRIX, PROJECTION_MATRIX, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX, VIEWPORT_SIZE, tp);
			col = fade_blend > 0 ? mix(old, col, smoothstep(0.0, 1.0, fade)) : old;
		}
		col = band(col);
		if (debug == 1) {
			col = vec3(texel_hash(t), texel_hash(t + 1.0), texel_hash(t + 2.0)) * 0.6 + 0.1;
		} else if (debug == 2) {
			vec4 clip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(w, 1.0));
			vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
			col = vec3(length((uv - SCREEN_UV) * VIEWPORT_SIZE) * 0.25, 0.0, 0.0);
		}
	}
	ALBEDO = col;
	ALPHA = 1.0;
}

shader_type sky;
// The scene's fog isn't laid over the sky (it washed the whole sky to the fog's colour); the haze
// along the horizon is painted here instead.
render_mode disable_fog;
// Painted-looking sky driven by DayCycle: a gradient, a sun with halo, a moon and square stars
// (they read as pixels once the frame is scaled up). When the sun is low the warm horizon glows
// toward it and the rest of the sky stays blue, and blocky clouds catch its light underneath, as
// in docs/concept/street-golden-hour.png.

uniform vec3 top_color : source_color = vec3(0.26, 0.47, 0.82);
uniform vec3 horizon_color : source_color = vec3(0.74, 0.8, 0.86);
uniform vec3 ground_color : source_color = vec3(0.22, 0.17, 0.12);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.9);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 moon_dir = vec3(0.0, -1.0, 0.0);
// The moon's size (its radius, radians), brightness, and the glow it puts in the sky round it.
uniform float moon_radius = 0.019;
uniform float moon_bright = 0.9;
uniform float moon_glow = 2.2;
uniform vec3 moon_glow_color : source_color = vec3(0.08, 0.15, 0.32);
uniform float star_strength = 0.0;
uniform float sun_size = 0.045;
// Clouds: how much of the sky they cover (0..1), how big (repeats per unit of the cloud plane: the
// painting's are small broken heaps, not big sheets), how ragged their edges are (high-frequency
// noise eaten out of them), and how many painted tones each is drawn in (0: smooth, the
// painting's sky and far clouds are soft; docs/ART_REVIEW.md §3.3).
uniform float cloud_cover = 0.46;
uniform float cloud_scale = 2.6;
uniform float cloud_ragged = 0.32;
uniform float cloud_tones = 0.0;
// How much darker the sky away from the sun gets when the sun is low (the painting's deep blue).
uniform float low_sun_dim = 0.45;
// The sky in squares, as the painting's is: directions snapped to a grid this many cells a
// radian (~100: a square ~7 screen pixels at 1280x720 and the street shot's lens), each a shade
// off its neighbours. 0 = smooth.
uniform float sky_squares = 0.0;
uniform float sky_mosaic = 0.0;
// Over 0 only under the surface-blocks look (Settings.surface_blocks, M): there the blocks are the
// surfaces' own texels and the sky has none, so it's drawn smooth whatever sky_squares says (the
// blind critic, 2026-10-05_r8: "the sky's squares giant beside surfaces that read smooth").
global uniform float block_soft;
// How far the clouds have drifted (DayCycle sends it with the sky's other updates). Not TIME: a
// sky that reads TIME is re-lit every frame (REALTIME), and that flickered every sky-lit surface.
uniform float cloud_drift = 0.0;
// How far the clouds take the afterglow just after sunset (0 = lit as before sunset).
uniform float dusk_clouds = 1.0;
// The gold sky of the street painting at golden hour (Part A's restore of round 10, under the bold
// look: src/art/bold_look.json sets it 1): a deeper blue overhead, the horizon band left bright
// gold, a stronger glow round the sun, and the clouds lit cream-gold and orange rather than dimmed.
// 0 = the sky as it was.
uniform float gold = 1.0;
// Sun rays at golden hour (src/render/sun_rays.gdshaderinc): how strong the shafts are. 0 = none.
uniform float ray_strength = 0.65;

// The painted sky (Sean's target docs/concept/targets/7_sky_target.jpg, 2026-10-16): two panels the
// image model painted, 180 degrees of sky each, one toward the low sun and one away from it
// (tools/textures/paint_sky.py, cut by reduce_sky.py; Backdrop hands them here with their
// assets/textures/sky/sky.json). Laid round the sky so the painted sun lies on DayCycle's, and shown
// while the sun is low (golden hour, morning and evening), the coded sky above at other hours.
// Only what's seen: the sky's light on the town (its radiance) stays the coded sky's.
uniform sampler2D paint_sun_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D paint_away_tex : source_color, filter_linear_mipmap, repeat_disable;
// How much of the painted sky shows (0 = none; Backdrop sets 1 once it has the panels).
uniform float painted = 0.0;
// The degrees of sky a panel's height covers, and where its painted sun is (u across, degrees up).
uniform float paint_span = 77.3;
uniform vec2 paint_sun = vec2(0.37, 7.6);
// The colour the painted sky fades to overhead, above the panels' tops.
uniform vec3 paint_zenith : source_color = vec3(0.31, 0.37, 0.5);
// The panels' brightness in the frame (the tonemap takes some of it).
uniform float paint_gain = 0.95;

#include "res://src/render/sun_rays.gdshaderinc"

// The painted panels' colour toward d (the sun's direction sd), fading to the zenith colour above
// their tops.
vec3 painted_sky(vec3 d, vec3 sd) {
	float bearing = degrees(atan(d.x, -d.z));
	float sun_bearing = degrees(atan(sd.x, -sd.z));
	float rel = mod(bearing - sun_bearing + 180.0, 360.0) - 180.0;
	// Across: the sun panel's painted sun on the real one; past either edge, the away panel.
	float u = paint_sun.x + rel / 180.0;
	float ua = u < 0.5 ? u + 1.0 : u - 1.0;
	// Up: lifted so the painted sun stands at the real sun's height.
	float up = degrees(asin(clamp(d.y, -1.0, 1.0))) - (degrees(asin(clamp(sd.y, -1.0, 1.0))) - paint_sun.y);
	float v = 1.0 - up / paint_span;
	vec3 a = textureLod(paint_sun_tex, vec2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0)), 0.0).rgb;
	vec3 b = textureLod(paint_away_tex, vec2(clamp(ua, 0.0, 1.0), clamp(v, 0.0, 1.0)), 0.0).rgb;
	// The seams (reduce_sky.py eased the edges toward each other): crossfaded over a few degrees.
	float own = smoothstep(-0.03, 0.03, u) * (1.0 - smoothstep(0.97, 1.03, u));
	vec3 col = mix(b, a, own);
	col = mix(col, paint_zenith, smoothstep(paint_span - 12.0, paint_span + 4.0, up));
	// The painted sun and the light nearest it a little over white, so it glows as the target's.
	float l = dot(col, vec3(0.333));
	return col * paint_gain * (1.0 + 1.5 * smoothstep(0.75, 1.0, l));
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += vnoise(p) * a;
		p = p * 2.07 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// The clouds' shape at p on their plane: broad heaps stretched by `band`, warped, their edges
// eaten into by finer noise (cloud_ragged).
float cloud_shape(vec2 p, vec2 band) {
	vec2 b = p * band;
	vec2 warp = vec2(fbm(b * 0.9 + 4.1), fbm(b * 0.9 + 8.3)) - 0.5;
	vec2 q = b + warp * 0.9;
	return fbm(q * 2.3) - cloud_ragged * (fbm(q * 9.0 + 2.0) - 0.5);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 cell_id = vec3(0.0);
	float squares = block_soft > 0.0 ? 0.0 : sky_squares;
	if (squares > 0.0) {
		cell_id = floor(d * squares);
		d = normalize((cell_id + 0.5) / squares);
	}
	float h = d.y;
	vec3 sd = normalize(sun_dir);
	float sun_up = smoothstep(-0.25, 0.05, sd.y);
	// How low the sun is (1 at the horizon, 0 high up), and how far round the sky from it we look.
	float low = 1.0 - smoothstep(0.1, 0.5, sd.y);
	vec2 dh = normalize(d.xz + vec2(1e-5));
	vec2 sh = normalize(sd.xz + vec2(1e-5));
	float toward = clamp(dot(dh, sh) * 0.5 + 0.5, 0.0, 1.0);
	// Nearness to the sun itself (not just its side of the sky): the glow over it fades upward.
	float near_sun = pow(max(dot(d, sd), 0.0), 6.0);
	// The warm horizon belongs to the sun's side of the sky when it's low; elsewhere it's a pale
	// blue haze (mixing the warm horizon into the blue top went lavender, which the painting never
	// is).
	vec3 top = mix(top_color, top_color * vec3(0.61, 0.87, 1.12), gold * low * sun_up);
	vec3 far_haze = mix(top, vec3(0.6, 0.72, 0.74), 0.5);
	vec3 horizon = mix(horizon_color, mix(far_haze, horizon_color, pow(toward, mix(2.5, 1.2, gold))), low * sun_up);
	// With the sun low the horizon band is a deep gold, not a bright one (the painting's sky away
	// from the sun sits around L* 55, ours was blown).
	horizon *= 1.0 - 0.3 * (1.0 - gold) * low * sun_up * (1.0 - pow(toward, 4.0));
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon, top, pow(max(h, 0.0), mix(0.55, 0.28, low * sun_up)));
		col *= 1.0 - mix(low_sun_dim, 0.5, gold) * low * sun_up * (1.0 - near_sun);
	} else {
		col = mix(horizon, ground_color, clamp(-h * 5.0, 0.0, 1.0));
	}
	float sun_dot = max(dot(d, sd), 0.0);
	col += sun_color * pow(sun_dot, 12.0) * mix(0.22, 0.3, gold) * sun_up;
	col += sun_color * pow(sun_dot, 5.0) * mix(0.06, 0.08, gold) * sun_up * (1.0 - clamp(h * 3.0, 0.0, 1.0)) * (1.0 - 0.5 * low);

	// Clouds on a flat layer overhead, as the painting paints them: loose bands of small heaps
	// across the sky (the noise stretched along Z, across the street), ragged at the edges (warped
	// by one noise, eaten into by a finer one), lots of blue between; each heap in three painted
	// tones: a cream-gold top (its edge toward the zenith), a warm body, a grey-violet underside
	// (its edge toward the horizon), golder toward the sun. None at the horizon (the haze) or at
	// night. They're drawn in the sky's own squares (sky_squares).
	if (h > 0.0) {
		vec2 p = d.xz / (h + 0.12) * cloud_scale + vec2(cloud_drift, 0.0);
		vec2 band = vec2(1.5, 0.45);
		float n = cloud_shape(p, band);
		float edge = 1.0 - cloud_cover - 0.12 * gold;
		// Soft edges, as the painting's heaps have (the blocks on them are the texture's, later).
		float c = smoothstep(edge - 0.05, edge + 0.05, n) * smoothstep(0.03, 0.14, h);
		float top = clamp((n - cloud_shape(p * 0.93, band)) * 7.0, 0.0, 1.0);
		float under = clamp((n - cloud_shape(p * 1.07, band)) * 7.0, 0.0, 1.0);
		float sunward = pow(toward, 3.0);
		vec3 lit = sun_color * mix(vec3(1.0, 0.96, 0.9), mix(vec3(0.84, 0.64, 0.42), vec3(1.0, 0.82, 0.6), gold), low);
		vec3 body = mix(vec3(0.78, 0.78, 0.8), mix(mix(vec3(0.82, 0.62, 0.5), vec3(0.86, 0.52, 0.34), gold), vec3(0.98, 0.64, 0.4), sunward), low);
		// (the gold sky's bellies warm, 2026-10-13: lavender-grey ones read overcast, the blind critic)
		vec3 belly = mix(vec3(0.48, 0.5, 0.56), mix(vec3(0.58, 0.45, 0.48), vec3(0.6, 0.42, 0.38), gold), low);
		float lift = clamp(top * 1.2 + sunward * 0.25 * low, 0.0, 1.0);
		float sink = clamp(under * 1.1 - top * 0.5, 0.0, 1.0);
		float tones = mix(cloud_tones, 3.0, gold);
		if (tones > 0.5) {
			lift = floor(lift * tones + 0.5) / tones;
			sink = floor(sink * tones + 0.5) / tones;
		}
		vec3 cloud = mix(mix(body, lit, lift), belly, sink) * mix(1.0, 0.75, low * (1.0 - sunward)) * mix(1.0, 0.7, low * (1.0 - gold));
		float day = smoothstep(-0.12, 0.05, sd.y);
		// After dusk they're dark shapes against the stars, faintly moonlit at the top.
		vec3 night = vec3(0.035, 0.04, 0.07) * (1.0 + top * 1.5);
		cloud = mix(night, cloud, day);
		// Just after sunset (the fire painting's sky): the sun lights the clouds from under the
		// horizon, so each heap is dark purple-grey with a red-orange underside, reddest toward
		// where it set; no cream tops.
		float after = smoothstep(0.02, -0.03, sd.y) * (1.0 - smoothstep(-0.1, -0.18, sd.y));
		vec3 afterglow = mix(vec3(0.62, 0.16, 0.1), vec3(0.9, 0.3, 0.12), sunward) * (0.35 + 0.65 * (1.0 - h));
		vec3 dusk_cloud = mix(vec3(0.11, 0.06, 0.12), afterglow, clamp(under * 1.3 + sunward * 0.35 - top * 0.4, 0.0, 1.0));
		cloud = mix(cloud, dusk_cloud, after * dusk_clouds);
		col = mix(col, cloud, c * 0.95);
		// The painting's golden-hour sky is a deeper picture than a bright clear one (its band over
		// the street at L* ~60, ours was 80 with the clouds in).
		// 2026-10-13: 0.15 -> 0.4 with the gold sky on by default (its clouds and the sky between
		// them went near white: 22% of the street shot's top over L* 80, the painting's 2%).
		col *= 1.0 - 0.4 * gold * low * sun_up * (1.0 - near_sun);
	}

	// The painted sky while the sun is low (its light on the town stays the coded sky's).
	float paint_on = painted * (1.0 - smoothstep(0.2, 0.45, sd.y)) * smoothstep(-0.07, 0.02, sd.y)
			* (AT_CUBEMAP_PASS ? 0.0 : 1.0);
	if (paint_on > 0.0) {
		col = mix(col, painted_sky(d, sd), paint_on);
	}

	// Haze low over the land: the horizon's colour, warmest toward the sun.
	float haze = (1.0 - smoothstep(0.0, 0.16, abs(h))) * 0.55 * (1.0 - 0.6 * paint_on);
	col = mix(col, horizon * (1.0 + near_sun * 0.6), haze);

	// Shafts of the low sun's light through the dust, and the darker air between them.
	vec2 rays = sun_rays(normalize(EYEDIR), sd, ray_strength * (1.0 - 0.5 * paint_on));
	vec3 ray_light = sun_color * vec3(1.0, 0.8, 0.5);
	col = col * (1.0 - 0.35 * rays.y) + ray_light * 0.8 * rays.x;

	// The gold sky at golden hour (2026-10-13, the blind critic: "lavender-grey, the sun a white
	// blob"): the whole sky leaned warm, and a gold halo round the sun, wide and soft, as the
	// painting's sun sits in a glow over the mesas.
	float golden = gold * low * sun_up * (1.0 - paint_on);
	col = mix(col, col * vec3(1.12, 0.93, 0.74), 0.6 * golden);
	col += vec3(1.0, 0.62, 0.28) * (pow(sun_dot, 60.0) * 0.8 + pow(sun_dot, 10.0) * 0.18) * golden;
	// The painting's setting sun is big and soft-edged: well over twice as big near the horizon.
	float disk_size = sun_size * mix(1.0, 2.4, low * sun_up);
	float disk = smoothstep(cos(disk_size), cos(disk_size * 0.75), sun_dot);
	// Low, it's a gold disk (the painting's), not a white burn.
	// Under the gold sky a white-gold disk a step over its halo (at 1.3x white gold it sank into the
	// halo, the blind critic: "no sun disc"; at 2.4 it drew a white burn).
	vec3 disk_col = mix(sun_color * 8.0, mix(vec3(1.0, 0.8, 0.42) * 2.4, vec3(1.0, 0.88, 0.64) * 2.2, gold), low * sun_up);
	col = mix(col, disk_col, disk * step(-0.02, h) * (1.0 - paint_on));

	vec3 md = normalize(moon_dir);
	float moon_up = smoothstep(-0.01, 0.03, md.y) * (1.0 - smoothstep(-0.12, 0.05, sd.y));
	// The saloon painting's moon (docs/concept/saloon-blocks.png, in its doorway): ~2 degrees
	// across, pale blue-white, drawn in squares (~11 across it) with grey-blue seas, the sky round
	// it lit a clear mid blue and fading to the night's navy some 30 degrees out.
	float md_dot = dot(d, md);
	col += moon_glow_color * (pow(max(md_dot, 0.0), 40.0) * 0.5 + pow(max(md_dot, 0.0), 8.0) * 0.5) * moon_glow * moon_up;
	vec3 mt = normalize(cross(md, abs(md.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	vec3 mb = cross(mt, md);
	vec2 muv = vec2(dot(d, mt), dot(d, mb)) / sin(moon_radius);
	vec2 mcell = floor(muv * 5.5);
	vec2 mc = (mcell + 0.5) / 5.5;
	float moon_disk = step(length(mc), 1.0) * step(0.0, md_dot);
	// Its seas: a few soft blots, read off the squares' centres so each square is one shade.
	float seas = smoothstep(0.38, 0.56, fbm(vec2(mc.x * 1.7 + 3.1, mc.y * 1.7 - 1.3)))
			* 0.5 + (hash2(mcell + 11.0) - 0.5) * 0.1;
	vec3 moon_col = mix(vec3(0.8, 0.88, 1.0), vec3(0.42, 0.52, 0.74), seas) * moon_bright;
	col = mix(col, moon_col, moon_disk * moon_up);

	vec3 cell = floor(d * 260.0);
	float s = hash(cell);
	float star = step(0.9978, s) * (0.4 + 0.6 * hash(cell + 7.3));
	col += vec3(star) * star_strength * smoothstep(0.02, 0.25, h);

	col *= 1.0 + (hash(cell_id + 3.1) - 0.5) * 2.0 * sky_mosaic * step(0.5, squares);
	COLOR = col;
}

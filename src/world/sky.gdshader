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
uniform float star_strength = 0.0;
uniform float sun_size = 0.035;
// Clouds: how much of the sky they cover (0..1), how big (repeats per unit of the cloud plane),
// and how coarse their squares are (cells per repeat; the painting's clouds are blocky).
uniform float cloud_cover = 0.56;
uniform float cloud_scale = 1.6;
uniform float cloud_blocks = 22.0;
// How much darker the sky away from the sun gets when the sun is low (the painting's deep blue).
uniform float low_sun_dim = 0.5;
// The sky in squares, as the painting's is: directions snapped to a grid this many cells a
// radian (~100: a square ~7 screen pixels at 1280x720 and the street shot's lens), each a shade
// off its neighbours. 0 = smooth.
uniform float sky_squares = 100.0;
uniform float sky_mosaic = 0.035;

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

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 cell_id = vec3(0.0);
	if (sky_squares > 0.0) {
		cell_id = floor(d * sky_squares);
		d = normalize((cell_id + 0.5) / sky_squares);
	}
	float h = d.y;
	vec3 sd = normalize(sun_dir);
	float sun_up = smoothstep(-0.25, 0.05, sd.y);
	// How low the sun is (1 at the horizon, 0 high up), and how far round the sky from it we look.
	float low = 1.0 - smoothstep(0.1, 0.5, sd.y);
	vec2 dh = normalize(d.xz + vec2(1e-5));
	vec2 sh = normalize(sd.xz + vec2(1e-5));
	float toward = dot(dh, sh) * 0.5 + 0.5;
	// Nearness to the sun itself (not just its side of the sky): the glow over it fades upward.
	float near_sun = pow(max(dot(d, sd), 0.0), 6.0);
	// The warm horizon belongs to the sun's side of the sky when it's low; elsewhere it's a pale
	// blue haze (mixing the warm horizon into the blue top went lavender, which the painting never
	// is).
	vec3 far_haze = mix(top_color, vec3(0.6, 0.72, 0.74), 0.5);
	vec3 horizon = mix(horizon_color, mix(far_haze, horizon_color, pow(toward, 2.5)), low * sun_up);
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon, top_color, pow(h, mix(0.55, 0.28, low * sun_up)));
		col *= 1.0 - low_sun_dim * low * sun_up * (1.0 - near_sun);
	} else {
		col = mix(horizon, ground_color, clamp(-h * 5.0, 0.0, 1.0));
	}
	float sun_dot = max(dot(d, sd), 0.0);
	col += sun_color * pow(sun_dot, 12.0) * 0.3 * sun_up;
	col += sun_color * pow(sun_dot, 5.0) * 0.08 * sun_up * (1.0 - clamp(h * 3.0, 0.0, 1.0)) * (1.0 - 0.5 * low);

	// Clouds on a flat layer overhead, in squares; lit gold underneath on the sun's side, grey-violet
	// away from it, their middles darker; none right at the horizon (the haze) or at night.
	if (h > 0.0) {
		vec2 p = d.xz / (h + 0.12) * cloud_scale + vec2(TIME * 0.002, 0.0);
		vec2 q = floor(p * cloud_blocks) / cloud_blocks;
		float n = fbm(q * 2.3);
		float edge = 1.0 - cloud_cover;
		float c = smoothstep(edge, edge + 0.03, n) * smoothstep(0.02, 0.12, h);
		// Thicker = darker underneath; the edge nearest the sun catches the light.
		float thick = smoothstep(edge + 0.05, edge + 0.3, n);
		float rim = clamp((n - fbm((q + sh * 0.04) * 2.3)) * 6.0, 0.0, 1.0);
		vec3 lit = sun_color * mix(vec3(1.0), vec3(1.0, 0.74, 0.62), low) * mix(0.7, 1.15, pow(toward, 2.0)) * mix(1.0, 0.42, low);
		vec3 shade = mix(vec3(0.38, 0.4, 0.43), vec3(0.5, 0.33, 0.24), toward * low) * mix(1.0, 0.7, low);
		vec3 cloud = mix(lit, shade, thick * 0.75 - rim * 0.4);
		float day = smoothstep(-0.12, 0.05, sd.y);
		// After dusk they're dark shapes against the stars, faintly moonlit at the edges.
		vec3 night = vec3(0.035, 0.04, 0.07) * (1.0 + rim * 1.5);
		cloud = mix(night, cloud, day);
		col = mix(col, cloud, c * 0.92);
	}

	// Haze low over the land: the horizon's colour, warmest toward the sun.
	float haze = (1.0 - smoothstep(0.0, 0.16, abs(h))) * 0.55;
	col = mix(col, horizon * (1.0 + near_sun * 0.6), haze);

	float disk = smoothstep(cos(sun_size), cos(sun_size * 0.7), sun_dot);
	col = mix(col, sun_color * 8.0, disk * step(-0.02, h));

	vec3 md = normalize(moon_dir);
	float moon_disk = smoothstep(0.99955, 0.9997, dot(d, md));
	col += vec3(0.85, 0.9, 1.0) * moon_disk * 1.4 * step(0.0, md.y);

	vec3 cell = floor(d * 260.0);
	float s = hash(cell);
	float star = step(0.9978, s) * (0.4 + 0.6 * hash(cell + 7.3));
	col += vec3(star) * star_strength * smoothstep(0.02, 0.25, h);

	col *= 1.0 + (hash(cell_id + 3.1) - 0.5) * 2.0 * sky_mosaic * step(0.5, sky_squares);
	COLOR = col;
}

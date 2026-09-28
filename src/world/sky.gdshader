shader_type sky;
// Painted-looking sky driven by DayCycle: a gradient, a sun with halo, a moon and square stars
// (they read as pixels once the frame is scaled up).

uniform vec3 top_color : source_color = vec3(0.26, 0.47, 0.82);
uniform vec3 horizon_color : source_color = vec3(0.74, 0.8, 0.86);
uniform vec3 ground_color : source_color = vec3(0.22, 0.17, 0.12);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.9);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 moon_dir = vec3(0.0, -1.0, 0.0);
uniform float star_strength = 0.0;
uniform float sun_size = 0.035;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon_color, top_color, pow(h, 0.55));
	} else {
		col = mix(horizon_color, ground_color, clamp(-h * 5.0, 0.0, 1.0));
	}
	vec3 sd = normalize(sun_dir);
	float sun_dot = max(dot(d, sd), 0.0);
	float sun_up = smoothstep(-0.25, 0.05, sd.y);
	col += sun_color * pow(sun_dot, 12.0) * 0.45 * sun_up;
	col += sun_color * pow(sun_dot, 3.0) * 0.12 * sun_up * (1.0 - clamp(h * 3.0, 0.0, 1.0));
	float disk = smoothstep(cos(sun_size), cos(sun_size * 0.7), sun_dot);
	col = mix(col, sun_color * 8.0, disk * step(-0.02, h));

	vec3 md = normalize(moon_dir);
	float moon_disk = smoothstep(0.99955, 0.9997, dot(d, md));
	col += vec3(0.85, 0.9, 1.0) * moon_disk * 1.4 * step(0.0, md.y);

	vec3 cell = floor(d * 260.0);
	float s = hash(cell);
	float star = step(0.9978, s) * (0.4 + 0.6 * hash(cell + 7.3));
	col += vec3(star) * star_strength * smoothstep(0.02, 0.25, h);

	COLOR = col;
}

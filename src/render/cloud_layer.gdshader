shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// The real look's clouds (#918): one layer of cloud on a flat sheet `height` metres over the eye,
// drifting with the wind (RealSky moves `wind_offset` each frame: no TIME, so it stops with the
// game). Drawn on a dome round the camera pushed to the far plane (behind the far land: far_land.gdshader), so all the land, near and far,
// stands in front of it and it stands in front of the sky. Shape: two scales of a tiling noise and
// a `coverage` from clear (0) to closed overcast (1). Light (after Schneider 2015, "The Real-time
// Volumetric Cloudscapes of Horizon Zero Dawn", SIGGRAPH Advances, cut to a single sheet): the
// cloud's depth toward the light read by two taps along it, Beer's law with the "powder" darkening
// of thin edges facing the light, a forward-and-back phase for the silver lining, the sky's blue
// from above and the land's warm bounce from below. The light is the sun's colour at the cloud's own
// height (SkyModel), so a sheet three kilometres up is still lit red after the street's sunset.
// A weather system later moves `coverage` and the wind; a storm cell is its own work (#918's
// handover).

uniform sampler2D shape_noise : filter_linear_mipmap, repeat_enable;
uniform float coverage = 0.3;
uniform float height = 2600.0;
// Metres a repeat of the large and small noise.
uniform float scale = 9000.0;
uniform float detail_scale = 2300.0;
uniform vec2 wind_offset = vec2(0.0);
// How far the clouds go on toward the horizon (metres; then they fade into the sky's haze).
uniform float fade_distance = 26000.0;
// Optical thickness of a full cloud toward the light, and of its body as seen.
uniform float thickness = 4.0;
uniform float opacity = 0.95;
uniform vec3 light_dir = vec3(0.0, 1.0, 0.0);
// The light on the cloud (linear radiance, the sun's or moon's at the cloud's height, x the scene's
// sun energy), the sky's light from above and the ground's from below.
uniform vec3 light_color = vec3(1.0);
uniform vec3 sky_light = vec3(0.3, 0.4, 0.6);
uniform vec3 ground_light = vec3(0.15, 0.12, 0.09);

varying vec3 v_dir;

void vertex() {
	// The dome's points are directions; RealSky keeps the dome on the camera.
	v_dir = VERTEX;
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX * 50.0, 1.0));
	// At the far plane (Godot's depth is reversed: 0 is far), behind everything.
	POSITION.z = POSITION.w * 1e-10;
}

// The cloud's cover at p (0..1) and its thickness (the raw noise: under a closed sky the cover is
// full everywhere and the thickness still rolls). A third, broad noise bunches them: fields of
// cloud and open sky between, not an even scatter.
vec2 cloud(vec2 p) {
	float a = texture(shape_noise, p / scale).r;
	float b = texture(shape_noise, p / detail_scale + vec2(0.37, 0.71)).r;
	float field = texture(shape_noise, p / (scale * 3.7) + vec2(0.53, 0.19)).r;
	float n = a * 0.65 + b * 0.35;
	float cov = clamp(coverage * mix(0.55, 1.45, field), 0.0, 1.0);
	float edge = 1.0 - cov;
	float c = smoothstep(edge - 0.05, edge + 0.2, n + 0.2 * cov * cov);
	return vec2(c, clamp((n - edge + 0.25) * 1.6, 0.0, 1.0));
}

float hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / (4.0 * 3.14159265 * pow(1.0 + g2 - 2.0 * g * c, 1.5));
}

void fragment() {
	vec3 d = normalize(v_dir);
	if (d.y < 0.004) {
		discard;
	}
	vec3 cam = NODE_POSITION_WORLD;
	float t = max(height - cam.y, 50.0) / d.y;
	vec2 p = cam.xz + d.xz * t + wind_offset;
	vec2 cc = cloud(p);
	float c = cc.x;
	if (c < 0.002) {
		discard;
	}
	// Toward the light along the sheet (a low light crosses more of it).
	vec2 toward = normalize(light_dir.xz + vec2(1e-5)) * 900.0;
	vec2 c1 = cloud(p + toward);
	vec2 c2 = cloud(p + toward * 2.5);
	float slant = 1.0 / max(abs(light_dir.y), 0.12);
	float thick = cc.y;
	float depth = (thick * 0.6 + c1.y * c1.x + c2.y * c2.x * 0.6) * thickness * mix(0.5, 1.0, min(slant / 4.0, 1.0));
	float beer = exp(-depth);
	float powder = 1.0 - exp(-depth * 2.0);
	float mu = dot(d, light_dir);
	float phase = mix(hg(mu, 0.6), hg(mu, -0.25), 0.3) * 4.0 * 3.14159265;
	// A light under the sheet lights its underside from the side; one below the horizon, from under.
	float under = smoothstep(0.15, -0.05, light_dir.y);
	vec3 direct = light_color * beer * mix(1.0, powder, 0.6) * phase * mix(1.0, 1.6, under);
	// We see the bases: thick cloud's are dark grey, thin edges take the sky's blue, the land's
	// warm light comes up under them.
	float belly = clamp(thick * (0.7 + coverage * 0.6), 0.0, 1.0);
	vec3 ambient = sky_light * mix(1.15, 0.45, belly) + ground_light * belly;
	vec3 col = direct + ambient;
	float fade = exp(-t / fade_distance);
	ALBEDO = col;
	ALPHA = clamp(c * opacity * fade * smoothstep(0.004, 0.05, d.y), 0.0, 1.0);
}

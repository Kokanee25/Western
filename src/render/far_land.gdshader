shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, skip_vertex_transform, fog_disabled, shadows_disabled;

// The far land (#918, FarLand): the ground past the camera's far plane and the ranges round the
// valley to 45 km. Lit here, not by the engine (RealSky sends the light: the sun's or moon's colour
// and energy and the sky's light above and round the horizon), as the clouds are; too far for
// shadows. Drawn in the transparent pass at the
// very back of the depth range, so the depth test lets it only where the sky shows; it writes no
// depth, and its meshes are in the painter's order (FarLand sorts them).
// Its cover is worked out here from the world height, slope and distance (desert tan low, pinon and
// juniper on the benches and out across the plain, spruce high, grey rock where steep and over the
// tree line, snow over ~3,650 m with the valley at ~2,070 m), broken by noise so its bands don't
// read as stripes.
// Its haze is its own, by its true distance (fog_disabled: the scene's fog and volumetric fog read
// its depth, at the back of the range, and turned all of it the fog's colour): the air's extinction
// at the valley's height (SkyModel's Rayleigh and dust at ~2 km, x `haze`) toward the sky's
// radiance round the horizon (RealSky sends it).

uniform vec3 haze_color = vec3(0.6, 0.7, 0.8);
uniform vec3 light_dir = vec3(0.0, 1.0, 0.0);
// (linear, the energy in it, as a lit surface of albedo 1 facing it would show)
uniform vec3 light_color = vec3(1.6);
uniform vec3 sky_up = vec3(0.2, 0.3, 0.5);
uniform vec3 sky_side = vec3(0.5, 0.6, 0.7);
uniform float haze = 1.6;
// The snow line and the tree line, metres over the valley's ground.
uniform float snow_line = 1650.0;
uniform float tree_line = 1450.0;

varying vec3 v_world;
varying vec3 v_world_normal;

void vertex() {
	// The mesh is in world space; FarLand keeps its node on the camera (for a steady sort), so the
	// node's own transform is left out.
	v_world = VERTEX;
	v_world_normal = NORMAL;
	vec4 view = VIEW_MATRIX * vec4(VERTEX, 1.0);
	VERTEX = view.xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	POSITION = PROJECTION_MATRIX * view;
	// Godot's depth is reversed (0 far) and cleared to 0: only the sky's pixels pass.
	POSITION.z = 0.0;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.5 + vnoise(p * 2.1 + 3.7) * 0.3 + vnoise(p * 4.3 + 9.1) * 0.2;
}

vec3 srgb(vec3 c) {
	return pow(c, vec3(2.2));
}

void fragment() {
	vec2 xz = v_world.xz;
	// (the curve of the Earth took this much off the drawn height out there)
	float d_centre = length(xz);
	float y = v_world.y + d_centre * d_centre / (2.0 * 6371000.0 * 7.0 / 6.0);
	float up = normalize(v_world_normal).y;
	float n1 = fbm(xz / 1800.0);
	float n2 = fbm(xz / 600.0 + 17.0);
	float yn = y + (n1 - 0.5) * 420.0;
	vec3 tan = srgb(vec3(0.58, 0.49, 0.38));
	vec3 pinon = srgb(vec3(0.30, 0.31, 0.22));
	vec3 spruce = srgb(vec3(0.16, 0.21, 0.17));
	vec3 rock = srgb(vec3(0.47, 0.45, 0.43));
	vec3 snow = srgb(vec3(0.90, 0.92, 0.95));
	float cover = clamp(smoothstep(60.0, 380.0, yn) + smoothstep(3000.0, 12000.0, d_centre) * 0.6, 0.0, 1.0);
	vec3 c = mix(tan, pinon, cover * (0.45 + 0.55 * n2));
	c = mix(c, spruce, smoothstep(650.0, 1000.0, yn) * (1.0 - smoothstep(tree_line - 150.0, tree_line + 80.0, yn)));
	c = mix(c, rock, max((1.0 - smoothstep(0.68, 0.86, up)) * 0.85, smoothstep(tree_line - 100.0, tree_line + 120.0, yn)));
	float s = smoothstep(snow_line - 80.0, snow_line + 120.0, yn + (up - 0.75) * 400.0 + (n2 - 0.5) * 200.0);
	c = mix(c, snow, s);
	// Lit land seen through the air: its light times what the air lets through, plus what the air
	// scatters in (the sky's own colour low down).
	float dist = length(VERTEX);
	vec3 ext = (vec3(5.802e-6, 13.558e-6, 33.1e-6) * 0.77 + vec3(4.44e-6 * 0.18)) * haze;
	vec3 tr = exp(-ext * dist);
	vec3 nrm = normalize(v_world_normal);
	// The sky's light in the shade, half its blue taken out (the land round about bounces warm).
	vec3 sky = mix(sky_side, sky_up, 0.5 + 0.5 * nrm.y);
	sky = mix(vec3(dot(sky, vec3(0.2126, 0.7152, 0.0722))), sky, 0.5);
	vec3 lit = light_color * max(dot(nrm, light_dir), 0.0) + sky * 0.9;
	ALBEDO = c * lit * tr + haze_color * (1.0 - tr);
	ALPHA = 1.0;
}

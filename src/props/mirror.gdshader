shader_type spatial;
// A looking glass painted, not traced (the back bar's mirrors, prop:mirror; Sean's saloon picture,
// docs/concept/targets/10_saloon_interior.png): the room it gives back is a warm, smoky haze with the
// lamps glowing in it, posts, the gallery's rail and balusters and the ceiling's beams going back in
// it, as the picture paints its mirror. The room is a box in front of the glass: the view ray is
// reflected off the glass and meets its far wall (`room_depth` away) or its ceiling, so the lamps and
// beams slide across the glass as you move (a reflection, not a picture stuck on it). Painted in
// squares on those faces, the room's light in bands as the men's paint, the lamps' glow soft.
// Free: two plane intersections and a few smooth steps a pixel, no probe or second camera.
// (The idea of a room drawn behind a flat face from the view ray: "interior mapping", van Dongen 2008.)
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float room_depth = 6.0;     // metres from the glass to the far wall it gives back
uniform float eye = 1.6;            // the viewer's eye over the floor (the room's floor is under him)
uniform float ceiling = 4.3;        // the room's ceiling (the gallery's) over the floor
uniform float lamp_height = 2.05;   // the lamps (sconces) over the floor
uniform float lamp_pitch = 1.7;     // metres between lamps along the far wall
uniform float post_pitch = 3.3;     // between the room's posts
uniform float rail_height = 3.25;   // the gallery's rail
uniform float beam_pitch = 1.2;     // between the ceiling's beams
uniform float square = 0.06;        // metres a painted square in the room
uniform float bands = 6.0;          // the room's light in steps (gamma space), as the men's paint
uniform float seed = 0.0;
uniform vec3 room_dark : source_color = vec3(0.10, 0.065, 0.045);
uniform vec3 room_haze : source_color = vec3(0.46, 0.31, 0.18);
uniform vec3 smoke : source_color = vec3(0.30, 0.30, 0.31);  // the picture's grey-blue smoke in the glass
uniform vec3 lamp_col : source_color = vec3(1.0, 0.70, 0.36);
uniform float glow = 1.0;           // the lamps' brightness (lit)
uniform float exposure = 0.5;
// The glass itself: dark, a little sheen of the real room on top.
uniform float roughness = 0.3;
uniform float specular = 0.15;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

float hash1(float x) {
	return fract(sin(x * 127.1 + seed * 311.7) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 74.7) * 43758.5453);
}

// Soft value noise (the smoke and the haze's unevenness).
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

// The far wall at q (along it, over the floor; metres): the room's haze, posts, the gallery.
vec3 wall(vec2 q) {
	// Haze brightest round the lamps' height, darker to the floor and up under the gallery.
	float hz = smoothstep(-0.2, 1.4, q.y) * (1.0 - 0.45 * smoothstep(2.6, 4.0, q.y));
	hz *= 0.8 + 0.4 * noise(q * vec2(0.6, 0.9));
	vec3 c = mix(room_dark, room_haze, hz);
	// Posts: dark uprights, the lamp side of each a little lit.
	float pc = floor(q.x / post_pitch + seed);
	float px = (fract(q.x / post_pitch + seed) - 0.5) * post_pitch;
	float pw = 0.14 + 0.05 * hash1(pc);
	float post = 1.0 - smoothstep(pw, pw + 0.04, abs(px));
	c = mix(c, mix(room_dark, room_haze, px > 0.0 ? 0.55 : 0.15), post * 0.9);
	// The gallery: its rail, balusters under it, its floor's edge over it.
	float rail = 1.0 - smoothstep(0.04, 0.07, abs(q.y - rail_height));
	float under = step(rail_height - 0.85, q.y) * step(q.y, rail_height);
	float bal = (1.0 - smoothstep(0.02, 0.035, abs(fract(q.x / 0.16) - 0.5) * 0.16)) * under;
	float edge = step(rail_height + 0.25, q.y) * step(q.y, rail_height + 0.5);
	c = mix(c, room_dark, max(max(rail * 0.85, bal * 0.6), edge * 0.7));
	// The room's lower half: tables and men as dark shapes against the haze.
	float low = (1.0 - smoothstep(0.7, 1.3, q.y + 0.4 * noise(q * vec2(1.3, 0.5) + 9.0))) * step(0.0, q.y);
	c = mix(c, room_dark * 1.3, low * 0.6);
	return c;
}

// The ceiling at q (along the far wall, back from it toward the glass; metres): boards lit warm by
// the lamps below, dark beams across.
vec3 ceil_(vec2 q) {
	float beam = 1.0 - smoothstep(0.08, 0.12, abs(fract(q.x / beam_pitch + seed) - 0.5) * beam_pitch);
	float fall = exp(-max(q.y, 0.0) * 0.25);
	vec3 c = mix(room_dark, room_haze * 0.75, 0.35 + 0.4 * fall * (0.8 + 0.4 * noise(q * 0.7)));
	return mix(c, room_dark * 0.7, beam * 0.85);
}

// The lamps on the far wall: a bright chimney and a soft glow round it. Not every bay has one.
vec3 lamps(vec2 q) {
	vec3 light = vec3(0.0);
	float lc0 = floor(q.x / lamp_pitch);
	for (float i = -1.0; i <= 1.0; i += 1.0) {
		float lc = lc0 + i;
		if (hash1(lc + 7.0) < 0.15) {
			continue;
		}
		vec2 at = vec2((lc + 0.5 + (hash1(lc) - 0.5) * 0.4) * lamp_pitch, lamp_height + (hash1(lc + 3.0) - 0.5) * 0.3);
		vec2 d = q - at;
		float core = 1.0 - smoothstep(0.04, 0.07, length(d / vec2(1.0, 1.9)));
		float r2 = dot(d, d);
		float halo = exp(-r2 / (0.18 * 0.18)) * 0.7 + exp(-r2 / (0.7 * 0.7)) * 0.3;
		light += mix(lamp_col, vec3(1.0, 0.93, 0.75), core) * (core * 3.0 + halo);
	}
	return light * glow;
}

vec3 step_light(vec3 c, float n) {
	float l = max(max(c.r, c.g), max(c.b, 1e-4));
	float g = pow(min(l, 1.0), 1.0 / 2.2);
	float lb = pow(max(floor(g * n + 0.5), 0.5) / n, 2.2);
	return c * (lb / l) * max(l, 1.0);
}

void fragment() {
	vec3 cam = CAMERA_POSITION_WORLD;
	vec3 n = normalize(wnorm);
	vec3 v = normalize(wpos - cam);
	if (dot(v, n) > 0.0) {
		n = -n;
	}
	vec3 r = reflect(v, n);
	vec3 along = normalize(cross(vec3(0.0, 1.0, 0.0), n));
	float floor_y = cam.y - eye;
	vec3 h = wpos + r * (room_depth / max(dot(r, n), 0.08));
	vec3 c;
	vec3 lit = vec3(0.0);
	if (h.y - floor_y > ceiling && r.y > 0.0) {
		// Up into the ceiling before the far wall.
		vec3 k = wpos + r * ((floor_y + ceiling - wpos.y) / r.y);
		vec2 q = (floor(vec2(dot(k, along), dot(k - wpos, n)) / square) + 0.5) * square;
		c = ceil_(q);
	} else {
		vec2 q = (floor(vec2(dot(h, along), h.y - floor_y) / square) + 0.5) * square;
		c = wall(q);
		lit = lamps(q);
	}
	// The room's smoke over everything it gives back: big soft grey-blue drifts.
	vec2 sp = vec2(dot(h, along), h.y) * 0.3;
	c = mix(c, smoke, smoothstep(0.4, 0.85, noise(sp + vec2(seed, 3.0))) * 0.35);
	c = step_light(c * exposure, bands) + step_light(lit * exposure, 12.0);
	ALBEDO = vec3(0.02, 0.018, 0.016);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = specular;
	EMISSION = c;
}

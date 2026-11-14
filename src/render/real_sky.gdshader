shader_type sky;
// The scattering is worked out a quarter of the screen's size (it is smooth); the sun, moon and
// stars at full size over it. The scene's fog is not laid over the sky: the sky is its own haze.
render_mode use_quarter_res_pass, disable_fog;

// The real look's sky (#918, docs/LAYOUT.md "src/render" "The real sky"): physically based, our
// own. Single scattering by air (Rayleigh) and dust (Mie) with ozone absorption, marched along the
// view ray through a spherical atmosphere; the light reaching each sample read from a precomputed
// transmittance table (Bruneton & Neyret 2008); coefficients and profiles of Hillaire 2020 / Bruneton
// 2017; multiple scattering as an isotropic share of the single (after Hillaire 2020). Lit by the sun
// and, far fainter, the moon, so twilight, the Earth's shadow, the blue hour and a moonlit sky all
// come out of the same sums. SkyModel (src/render/sky_model.gd) is the CPU half: its numbers must
// match these. RealSky sends every uniform.

const float R_GROUND = 6360000.0;
const float R_TOP = 6460000.0;
const vec3 RAYLEIGH = vec3(5.802e-6, 13.558e-6, 33.1e-6);
const float RAYLEIGH_H = 8000.0;
const float MIE_SCATTER = 3.996e-6;
const float MIE_EXTINCT = 4.440e-6;
const float MIE_H = 1200.0;
const vec3 OZONE = vec3(0.650e-6, 1.881e-6, 0.085e-6);

uniform sampler2D transmittance_lut : filter_linear, repeat_disable;
// (Named apart from the painted sky's sun_dir / moon_dir / star_strength: DayCycle sends those to
// whatever sky is in place, and its full moon's path is not ours.)
uniform vec3 sky_sun = vec3(0.0, 1.0, 0.0);
uniform vec3 sky_moon = vec3(0.0, -1.0, 0.0);
// Where the moon is lit from, for its phase (SkyModel.moon_lit_from).
uniform vec3 moon_lit_dir = vec3(0.0, 0.0, 1.0);
// The lights' illuminance on the air (the sun 1; the moon a small share, by its phase).
uniform float sun_light = 1.0;
uniform float moon_light = 0.0;
uniform float turbidity = 1.0;
uniform float mie_g = 0.8;
uniform float altitude = 2070.0;
uniform float multi = 0.35;
uniform float gain = 24.0;
// The night sky's own faint glow (airglow and starlight between the stars), linear.
uniform vec3 night_glow : source_color = vec3(0.0, 0.0, 0.0);
// The ground under the horizon (seen only where no land is drawn, and in the sky's light below).
uniform vec3 ground_albedo : source_color = vec3(0.3, 0.25, 0.2);
// The sun's disk: its angular radius (radians; the real sun is 0.0047) and brightness, and the
// colour the air leaves it (sent by RealSky: its transmittance toward the eye).
uniform float sun_radius = 0.0075;
uniform float sun_bright = 60.0;
uniform vec3 sun_tint = vec3(1.0);
// The moon's disk (radius, radians; the real one is 0.0045), brightness, and the air's tint on it.
uniform float moon_radius = 0.0075;
uniform float moon_bright = 2.5;
uniform vec3 moon_tint = vec3(1.0);
// Stars and the Milky Way: strength (0 by day, RealSky fades them with the sky's brightness), the
// stars' frame (equatorial: y the celestial pole, turned by the clock; world -> stars), the size
// of a star on screen (radians, about a pixel) and how many there are.
uniform float star_light = 0.0;
uniform mat3 star_frame = mat3(1.0);
uniform float star_size = 0.0012;
uniform float star_density = 0.0025;
uniform float milky_way = 1.0;
// The clouds' coverage, 0 clear .. 1 overcast: held here so a look sets it (`sky.coverage`);
// RealSky reads it back, feeds the cloud layer and works `overcast` from it.
uniform float coverage = 0.3;
// Overcast (0 clear .. 1 a closed sky; from the coverage): the sky goes to this grey.
uniform float overcast = 0.0;
uniform vec3 overcast_color : source_color = vec3(0.5);
// The eye's height over the world's ground (RealSky, in steps of 25 m).
uniform float eye_height = 0.0;
// How many steps along a view ray (the radiance pass takes half).
uniform int steps = 16;

vec2 lut_uv(float r, float mu) {
	float h = clamp(r - R_GROUND, 0.0, R_TOP - R_GROUND);
	float u = 0.5 + 0.5 * sign(mu) * sqrt(abs(clamp(mu, -1.0, 1.0)));
	return vec2(u, sqrt(h / (R_TOP - R_GROUND)));
}

vec3 light_to(float r, float mu) {
	return texture(transmittance_lut, lut_uv(r, mu)).rgb;
}

vec3 densities(float h) {
	float oz = max(0.0, 1.0 - abs(h - 25000.0) / 15000.0);
	return vec3(exp(-h / RAYLEIGH_H), exp(-h / MIE_H), oz);
}

float phase_mie(float c, float g) {
	float g2 = g * g;
	return 3.0 / (8.0 * PI) * (1.0 - g2) * (1.0 + c * c) / ((2.0 + g2) * pow(1.0 + g2 - 2.0 * g * c, 1.5));
}

// The sky's radiance toward d from a camera `cam_h` metres over the world's ground.
vec3 scatter(vec3 d, float cam_h, int n) {
	float r0 = R_GROUND + altitude + max(cam_h, 0.0);
	float mu = d.y;
	float disc_g = r0 * r0 * (mu * mu - 1.0) + R_GROUND * R_GROUND;
	bool ground = mu < 0.0 && disc_g >= 0.0;
	float tmax = ground ? (-r0 * mu - sqrt(disc_g)) : (-r0 * mu + sqrt(max(r0 * r0 * (mu * mu - 1.0) + R_TOP * R_TOP, 0.0)));
	vec3 cam = vec3(0.0, r0, 0.0);
	float cs = dot(d, sky_sun);
	float cm = dot(d, sky_moon);
	float pr_s = 3.0 / (16.0 * PI) * (1.0 + cs * cs);
	float pr_m = 3.0 / (16.0 * PI) * (1.0 + cm * cm);
	float pm_s = phase_mie(cs, mie_g);
	float pm_m = phase_mie(cm, mie_g);
	vec3 od = vec3(0.0);
	vec3 sum = vec3(0.0);
	float t_prev = 0.0;
	vec3 tv = vec3(1.0);
	for (int k = 0; k < n; k++) {
		float s = (float(k) + 1.0) / float(n);
		float t = tmax * s * s;
		float dt = t - t_prev;
		float tm = t_prev + dt * 0.5;
		t_prev = t;
		vec3 p = cam + d * tm;
		float r = length(p);
		vec3 up = p / r;
		float h = r - R_GROUND;
		vec3 dens = densities(h);
		vec3 sr = RAYLEIGH * dens.x;
		float sm = MIE_SCATTER * turbidity * dens.y;
		od += (sr + vec3(MIE_EXTINCT * turbidity * dens.y) + OZONE * dens.z) * dt;
		tv = exp(-od);
		vec3 ms = (sr + vec3(sm)) * (multi / (4.0 * PI));
		vec3 ls = light_to(r, dot(up, sky_sun)) * sun_light;
		vec3 lm = light_to(r, dot(up, sky_moon)) * moon_light;
		sum += tv * dt * (ls * (sr * pr_s + vec3(sm * pm_s) + ms) + lm * (sr * pr_m + vec3(sm * pm_m) + ms));
	}
	if (ground) {
		// The ground at the ray's end, lit by what reaches it, seen through the air.
		vec3 pg = normalize(cam + d * tmax);
		vec3 lit = light_to(R_GROUND, dot(pg, sky_sun)) * sun_light * max(dot(pg, sky_sun), 0.0)
				+ light_to(R_GROUND, dot(pg, sky_moon)) * moon_light * max(dot(pg, sky_moon), 0.0);
		sum += tv * ground_albedo * lit / PI;
	}
	return sum * gain;
}

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), u.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), u.x), u.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), u.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), u.x), u.y);
	return mix(a, b, u.z);
}

float fbm3(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += vnoise3(p) * a;
		p = p * 2.03 + vec3(1.7, 9.2, 3.3);
		a *= 0.5;
	}
	return v;
}

// An equatorial direction (right ascension, declination in degrees) in the stars' frame.
vec3 equatorial(float ra, float dec) {
	float a = radians(ra);
	float b = radians(dec);
	return vec3(cos(b) * cos(a), sin(b), cos(b) * sin(a));
}

// The Milky Way toward s (the stars' frame): a band round the galactic equator (its pole at RA
// 192.86, Dec +27.13), brightest toward the centre in Sagittarius (RA 266.4, Dec -28.9), torn by
// dark dust lanes along it.
vec3 milky(vec3 s) {
	vec3 gn = equatorial(192.86, 27.13);
	vec3 gc = equatorial(266.4, -28.94);
	float b = dot(s, gn);
	float band = exp(-b * b / (2.0 * 0.11 * 0.11));
	float bulge = pow(max(dot(s, gc), 0.0), 3.0);
	float clouds = fbm3(s * 7.0);
	float dust = smoothstep(0.42, 0.62, fbm3(s * 13.0 + 5.0)) * exp(-b * b / (2.0 * 0.04 * 0.04));
	float v = band * (0.35 + 0.65 * clouds) * (0.6 + 2.2 * bulge) * (1.0 - 0.8 * dust);
	return vec3(0.75, 0.8, 1.0) * v;
}

// An integer hash of a cell (a PCG step; Jarzynski & Olano 2020, "Hash Functions for GPU
// Rendering", JCGT): the float hashes drew the stars in rows.
uint pcg(uint v) {
	uint state = v * 747796405u + 2891336453u;
	uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	return (word >> 22u) ^ word;
}

float cell_rand(ivec2 c, uint face, uint k) {
	uint h = pcg(uint(c.x) * 73856093u ^ pcg(uint(c.y) * 19349663u ^ (face * 83492791u + k * 2654435761u)));
	return float(h & 0xFFFFFFu) / 16777216.0;
}

// The stars toward d: a grid on the faces of a cube round the eye, one star at most a cell (at a
// random spot in it), each a soft point about a pixel across, magnitudes many faint to few bright,
// white to blue-white to orange.
vec3 stars(vec3 s) {
	vec3 a = abs(s);
	vec2 uv;
	uint face;
	if (a.x >= a.y && a.x >= a.z) {
		uv = s.yz / a.x;
		face = s.x > 0.0 ? 0u : 1u;
	} else if (a.y >= a.z) {
		uv = s.xz / a.y;
		face = s.y > 0.0 ? 2u : 3u;
	} else {
		uv = s.xy / a.z;
		face = s.z > 0.0 ? 4u : 5u;
	}
	float n = 760.0;  // cells across a face: ~0.0026 rad a cell at its middle
	vec2 g = uv * n * 0.5;
	ivec2 cell = ivec2(floor(g));
	vec3 col = vec3(0.0);
	float sigma = star_size * n * 0.5;  // a star's size in cells
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			ivec2 c = cell + ivec2(i, j);
			if (cell_rand(c, face, 0u) > star_density) {
				continue;
			}
			vec2 at = vec2(c) + vec2(cell_rand(c, face, 1u), cell_rand(c, face, 2u));
			float dist = length(g - at);
			// Magnitudes: brightness ~ u^8, so few bright ones.
			float m = pow(cell_rand(c, face, 3u), 8.0) * 3.0 + 0.04;
			float t = cell_rand(c, face, 4u);
			vec3 tint = t < 0.2 ? vec3(1.0, 0.82, 0.62) : (t < 0.55 ? vec3(0.78, 0.86, 1.0) : vec3(1.0));
			col += tint * m * exp(-dist * dist / (2.0 * sigma * sigma));
		}
	}
	return col;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float cam_h = eye_height;
	if (AT_CUBEMAP_PASS) {
		// The light the world takes from the sky: the scattering alone (no stars, moon or sun disk:
		// the lights carry those), fewer steps.
		vec3 col = scatter(d, cam_h, max(steps / 2, 4)) + night_glow;
		COLOR = mix(col, overcast_color, overcast);
	} else if (AT_QUARTER_RES_PASS) {
		// The night's own glow, brightest low (airglow is a layer ~90 km up: seen edge-on at the horizon).
		vec3 col = scatter(d, cam_h, steps) + night_glow * (0.6 + 1.8 * pow(1.0 - clamp(d.y, 0.0, 1.0), 4.0));
		if (star_light > 0.001 && milky_way > 0.0 && d.y > -0.05) {
			col += milky(star_frame * d) * milky_way * star_light * 0.06;
		}
		COLOR = mix(col, overcast_color, overcast);
	} else {
		vec3 col = QUARTER_RES_COLOR.rgb;
		float clear = 1.0 - overcast;
		// The sun's disk, darkened toward its limb (a solar limb-darkening law, u ~ 0.6).
		float cs = dot(d, sky_sun);
		float ang = acos(clamp(cs, -1.0, 1.0));
		if (ang < sun_radius * 1.2 && d.y > -0.01) {
			float x = clamp(ang / sun_radius, 0.0, 1.0);
			float limb = 1.0 - 0.6 * (1.0 - sqrt(max(1.0 - x * x, 0.0)));
			float edge = 1.0 - smoothstep(0.92, 1.05, ang / sun_radius);
			col += sun_tint * sun_bright * sun_light * limb * edge * clear;
		}
		// The glare round the sun (the eye's and the air's aureole, tighter than the sky's own Mie).
		float sc = max(cs, 0.0);
		col += sun_tint * sun_light * (pow(sc, 3000.0) * 2.5 + pow(sc, 300.0) * 0.35) * clear * smoothstep(-0.02, 0.02, d.y);
		// The moon: a sphere lit from moon_lit_dir (its phase), grey seas, the dark side faintly
		// earthlit, through the air's tint.
		float cm = dot(d, sky_moon);
		// Its halo in the night air.
		float mc = max(cm, 0.0);
		col += moon_tint * moon_bright * (pow(mc, 6000.0) * 0.05 + pow(mc, 400.0) * 0.008) * clear * smoothstep(-0.02, 0.02, d.y);
		if (cm > cos(moon_radius * 1.3)) {
			vec3 mt = normalize(cross(sky_moon, abs(sky_moon.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
			vec3 mb = cross(mt, sky_moon);
			vec2 muv = vec2(dot(d, mt), dot(d, mb)) / sin(moon_radius);
			float r2 = dot(muv, muv);
			if (r2 < 1.1) {
				vec3 nrm = normalize(muv.x * mt + muv.y * mb - sqrt(max(1.0 - r2, 0.0)) * sky_moon);
				float lit = max(dot(nrm, moon_lit_dir), 0.0);
				float seas = smoothstep(0.42, 0.62, fbm3(vec3(muv * 1.6, 3.0)));
				float albedo = mix(0.95, 0.55, seas) * (0.9 + 0.2 * vnoise3(vec3(muv * 9.0, 1.0)));
				float edge = 1.0 - smoothstep(0.94, 1.04, sqrt(r2));
				// Behind the air: the sky's own light is added in front of it (a day moon is pale).
				vec3 m = moon_tint * moon_bright * albedo * (lit + 0.012);
				col += m * edge * clear * smoothstep(-0.02, 0.01, d.y);
			}
		}
		if (star_light > 0.001 && d.y > -0.02) {
			// Fainter toward the horizon, where the air's path is long (the eye's extinction).
			float air = exp(-0.25 / max(d.y + 0.03, 0.03));
			col += stars(star_frame * d) * star_light * air * clear;
		}
		COLOR = col;
	}
}

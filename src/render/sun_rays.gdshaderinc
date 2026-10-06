// Sun rays at golden hour, as the street painting has them (docs/concept/street-golden-hour.png):
// shafts of the low sun's light through the dusty air, fanning out from the sun, longest
// downward over the hills it sits on, with darker gaps between where the ridge's notches shadow
// the air. Painted into the sky (sky.gdshader) and over the far land (backdrop.gdshader) by
// direction, as the haze is: no screen pass, and nothing reads TIME (a sky that does is re-lit
// every frame and flickers).
//
// sun_rays(d, sd) gives, for a view direction d and the sun's direction sd (both unit): x the
// shafts' light (0..1), y the gaps' shadow (0..1), both already faded by angle from the sun and
// by how low it is. The caller adds x in the sun's colour and darkens by y.

// How far the shafts reach from the sun (radians), and how many round it.
const float RAY_REACH = 0.62;
const float RAY_COUNT = 34.0;

float ray_hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// Smooth 1D noise round the circle: `n` cells, wrapping.
float ray_noise(float a, float n) {
	float x = a * n;
	float i = floor(x);
	float f = x - i;
	f = f * f * (3.0 - 2.0 * f);
	return mix(ray_hash(mod(i, n)), ray_hash(mod(i + 1.0, n)), f);
}

vec2 sun_rays(vec3 d, vec3 sd, float strength) {
	// Only with the sun low and up (not at noon, not after it's set).
	float up = smoothstep(-0.04, 0.03, sd.y);
	float low = 1.0 - smoothstep(0.3, 0.55, sd.y);
	float k = strength * up * low;
	if (k <= 0.0) {
		return vec2(0.0);
	}
	float c = clamp(dot(d, sd), -1.0, 1.0);
	float theta = acos(c);
	if (theta > RAY_REACH * 1.6) {
		return vec2(0.0);
	}
	// Round the sun: 0 straight down, increasing to its right.
	vec3 su = normalize(vec3(0.0, 1.0, 0.0) - sd * sd.y);
	vec3 sr = normalize(cross(sd, su));
	vec3 p = d - sd * c;
	float phi = atan(dot(p, sr), -dot(p, su));  // -PI..PI, 0 below the sun
	float a = phi / 6.2831853 + 0.5;
	// The shafts: a few broad and many narrow, sharpened so they read as beams.
	float n = ray_noise(a, RAY_COUNT) * 0.6 + ray_noise(a + 0.37, RAY_COUNT * 0.45) * 0.4;
	float beam = smoothstep(0.44, 0.72, n);
	float gap = 1.0 - smoothstep(0.26, 0.5, n);
	// Longest straight down, shorter to the sides, short upward (the sky above is lit everywhere).
	float down = cos(phi) * 0.5 + 0.5;
	float reach = RAY_REACH * mix(0.35, 1.0, pow(down, 1.5));
	float fall = exp(-theta / (reach * 0.55)) * smoothstep(0.03, 0.07, theta);
	return vec2(beam, gap) * fall * k;
}

// How a realistic test man's surfaces take light (Sean, 2026-11-01, #547 step 3: "the game drawing
// them better, people only"). Included by realistic_person.gdshader (skin and cloth) and
// realistic_hair*.gdshader (hair, beard and brow cards). Used only by the test men whose report
// lists shapes under "realistic"; every other man keeps the game's people shader.
//
// Ideas, written fresh here:
// - Specular: the usual microfacet model (GGX distribution, height-correlated Smith visibility,
//   Schlick's Fresnel), as written up in Google's Filament documentation ("Physically Based
//   Rendering in Filament", 2018), so a surface shines as Godot's own would.
// - Soft skin: diffuse light wrapped round each colour channel by its own amount, red furthest
//   (Simon Green, "Real-Time Approximations to Subsurface Scattering", GPU Gems 1, ch. 16, 2004),
//   so the edge of a shadow on skin goes warm instead of grey; and light through thin parts seen
//   against it (Barré-Brisebois and Bouchard, "Approximating Translucency for a Fast, Cheap and
//   Convincing Subsurface Scattering Look", GDC 2011): a distorted back-light, raised to a power.
// - Hair: Kajiya and Kay's strand light (SIGGRAPH 1989) with Scheuermann's two shifted
//   highlights, a white one and a second in the hair's own colour ("Hair Rendering and Shading",
//   ATI, GDC 2004), along the strand's direction from the card's UVs.

const float RL_PI = 3.14159265;

// The strand's direction in view space (hair cards), set in fragment().
varying vec3 rl_strand;
// A strand's own shift of its highlights (from its place on the card), set in fragment().
varying float rl_shift;

float rl_d_ggx(float nh, float a) {
	float a2 = a * a;
	float f = nh * nh * (a2 - 1.0) + 1.0;
	return a2 / (RL_PI * f * f);
}

float rl_v_smith(float nv, float nl, float a) {
	float a2 = a * a;
	float gv = nl * sqrt(nv * nv * (1.0 - a2) + a2);
	float gl = nv * sqrt(nl * nl * (1.0 - a2) + a2);
	return 0.5 / max(gv + gl, 1e-5);
}

// A dielectric's shine: f0 from Godot's SPECULAR (0.5 is 4% at normal incidence).
vec3 rl_specular(vec3 n, vec3 l, vec3 v, float roughness, float specular) {
	vec3 h = normalize(l + v);
	float nl = clamp(dot(n, l), 0.0, 1.0);
	float nv = clamp(abs(dot(n, v)), 1e-4, 1.0);
	float nh = clamp(dot(n, h), 0.0, 1.0);
	float lh = clamp(dot(l, h), 0.0, 1.0);
	float a = max(roughness * roughness, 0.002);
	float f0 = 0.16 * specular * specular;
	float f = f0 + (1.0 - f0) * pow(1.0 - lh, 5.0);
	return vec3(rl_d_ggx(nh, a) * rl_v_smith(nv, nl, a) * f * nl);
}

// Diffuse with each channel's light wrapped `wrap` past the terminator (0: Lambert); full light
// where it faces the light, as Green's.
vec3 rl_wrapped(float nl, vec3 wrap) {
	return clamp((vec3(nl) + wrap) / (vec3(1.0) + wrap), 0.0, 1.0);
}

// Light through a thin part seen against it, in the scatter colour.
vec3 rl_through(vec3 n, vec3 l, vec3 v, float distortion, float power, vec3 tint) {
	vec3 lt = normalize(l + n * distortion);
	return tint * pow(clamp(dot(v, -lt), 0.0, 1.0), power);
}

// Kajiya-Kay's highlight along a strand: strongest where the half-vector is across it.
float rl_strand_spec(vec3 t, vec3 h, float exponent) {
	float th = dot(t, h);
	float s = sqrt(max(1.0 - th * th, 0.0));
	return smoothstep(-1.0, 0.0, th) * pow(s, exponent);
}

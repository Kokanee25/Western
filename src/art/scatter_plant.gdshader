shader_type spatial;
// A scanned plant in the valley's scatter (#891; ValleyScatter): the scan's own albedo, normal and
// roughness (Poly Haven's ARM: G roughness), its colour drawn toward the species' own (desaturated
// and tinted: the scans' green shrub becomes silvery sagebrush, their green grass dry straw, varied a
// plant at a time), cut by its alpha, and dithered out toward the end of its range (or in, past a
// nearer one: the far grass). Lit through and from the sky like foliage (#962: backlit sage read near
// black): its normals bent toward up and out from the plant's middle, light through its leaves, and
// darker toward its foot where it meets the ground.

render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D arm_tex : filter_linear_mipmap;
uniform bool has_normal = false;
uniform bool has_arm = false;
uniform vec3 tint : source_color = vec3(1.0);
uniform float saturation = 1.0;
uniform float brightness = 1.0;
// Drawn toward this colour by the scan's lightness (a dark scan made pale, as sagebrush is), by recolour_mix.
uniform vec3 recolour : source_color = vec3(0.5);
uniform float recolour_mix = 0.0;
// How much one plant differs from the next (its lightness and hue, by its place).
uniform float vary = 0.15;
uniform float alpha_cut = 0.4;
uniform float fade_from = 0.0;
uniform float fade_to = 0.0;
// Dithered in between these distances (m): a far layer taking over from a near one.
uniform float appear_from = 0.0;
uniform float appear_to = 0.0;
// How far the normals are bent toward up and out from the plant's middle (0 the scan's own .. 1 a dome).
uniform float bend = 0.0;
// The plant's height (m, its own: the mesh's), and how dark its foot is (0 none .. 1 black).
uniform float height_m = 1.0;
uniform float foot_dark = 0.0;
// The light through thin leaves and blades.
uniform float translucency = 0.25;

varying float die;
varying float up_t;

void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	die = fract(sin(dot(o.xz, vec2(12.9898, 78.233))) * 43758.5453);
	up_t = clamp(VERTEX.y / max(height_m, 0.01), 0.0, 1.0);
	// Out from a point below the plant's middle: a dome over it (the mesh's own space, as NORMAL is here).
	vec3 out_dir = normalize(VERTEX - vec3(0.0, -0.3 * height_m, 0.0));
	NORMAL = normalize(mix(NORMAL, out_dir, bend));
}

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	// Cut-outs thin away in the mipmaps; their alpha raised by the mip level keeps them full far off
	// (Ben Golus, "Anti-aliased Alpha Test: The Esoteric Alpha To Coverage", 2017).
	vec2 px = UV * vec2(textureSize(albedo_tex, 0));
	float lod = max(0.0, 0.5 * log2(max(dot(dFdx(px), dFdx(px)), dot(dFdy(px), dFdy(px)))));
	a.a *= 1.0 + lod * 0.25;
	if (a.a < alpha_cut) {
		discard;
	}
	if (fade_to > 0.0 || appear_to > 0.0) {
		float d = length(VERTEX);
		float keep = fade_to > 0.0 ? 1.0 - smoothstep(fade_from, fade_to, d) : 1.0;
		keep *= appear_to > 0.0 ? smoothstep(appear_from, appear_to, d) : 1.0;
		float dither = fract(dot(FRAGCOORD.xy, vec2(0.5, 0.25)) + fract(sin(dot(FRAGCOORD.xy, vec2(12.99, 78.23))) * 43758.5) * 0.5);
		if (keep < dither) {
			discard;
		}
	}
	vec3 c = a.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation) * tint * brightness;
	c = mix(c, recolour * (0.55 + l * 2.2), recolour_mix);
	c *= 1.0 + (die - 0.5) * vary * 2.0;
	c.r *= 1.0 + (die - 0.5) * vary;
	// Its foot in its own shade and the ground's.
	c *= mix(1.0 - foot_dark, 1.0, smoothstep(0.0, 0.45, up_t));
	ALBEDO = clamp(c, 0.0, 1.0);
	ROUGHNESS = has_arm ? texture(arm_tex, UV).g : 0.85;
	SPECULAR = 0.25;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = 1.0 - bend * 0.7;
	}
	BACKLIGHT = c * translucency;
}

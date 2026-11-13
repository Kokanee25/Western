shader_type spatial;
// A scanned plant in the valley's scatter (#891; ValleyScatter): the scan's own albedo, normal and
// roughness (Poly Haven's ARM: G roughness), its colour drawn toward the species' own (desaturated
// and tinted: the scans' green shrub becomes silvery sagebrush, their green grass dry straw, varied a
// plant at a time), cut by its alpha, and dithered out toward the end of its range.

render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D arm_tex : filter_linear_mipmap;
uniform bool has_normal = false;
uniform bool has_arm = false;
uniform vec3 tint : source_color = vec3(1.0);
uniform float saturation = 1.0;
uniform float brightness = 1.0;
// How much one plant differs from the next (its lightness and hue, by its place).
uniform float vary = 0.15;
uniform float alpha_cut = 0.4;
uniform float fade_from = 0.0;
uniform float fade_to = 0.0;
// The light through thin leaves and blades.
uniform float translucency = 0.25;

varying float die;

void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	die = fract(sin(dot(o.xz, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	if (a.a < alpha_cut) {
		discard;
	}
	if (fade_to > 0.0) {
		float d = length(VERTEX);
		float keep = 1.0 - smoothstep(fade_from, fade_to, d);
		float dither = fract(dot(FRAGCOORD.xy, vec2(0.5, 0.25)) + fract(sin(dot(FRAGCOORD.xy, vec2(12.99, 78.23))) * 43758.5) * 0.5);
		if (keep < dither) {
			discard;
		}
	}
	vec3 c = a.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation) * tint * brightness;
	c *= 1.0 + (die - 0.5) * vary * 2.0;
	c.r *= 1.0 + (die - 0.5) * vary;
	ALBEDO = clamp(c, 0.0, 1.0);
	ROUGHNESS = has_arm ? texture(arm_tex, UV).g : 0.85;
	SPECULAR = 0.25;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	BACKLIGHT = c * translucency;
}

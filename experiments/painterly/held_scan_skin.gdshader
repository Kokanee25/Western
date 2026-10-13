// Your hand on the modelled revolver from the scan of a real hand (assets/held/hand.glb, made by
// tools/blender/held_scan_hand.py from the Smithsonian's scan of Volk's cast of Lincoln's right
// hand, CC0): the cast gives the shape and its maps give the skin's own folds and creases (its
// normals, and its occlusion and the darkening in its creases); this gives it colour: sun-browned
// on the back of the hand, paler in the palm, a fine mottle, flushed over the knuckles, the nails.
// What it reads: UV the scan's own texture coordinates; UV2.x 1 where the hand was closed after
// the cut (no scan texture there); COLOR.r the nails, .g how open, .b the flush, .a the back of
// the hand (1) or the palm (0).
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D cavity_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D mottle_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 60.0;
uniform vec4 back_skin : source_color = vec4(0.44, 0.35, 0.30, 1.0);
uniform vec4 palm_skin : source_color = vec4(0.58, 0.45, 0.40, 1.0);
uniform vec4 flush : source_color = vec4(0.56, 0.30, 0.25, 1.0);
uniform vec4 nail : source_color = vec4(0.62, 0.50, 0.44, 1.0);
uniform float flush_amount = 0.6;
uniform float normal_depth = 1.2;
uniform float crease = 0.6;         // how dark the cast's creases draw
uniform float occlusion = 0.8;
uniform float ao_strength = 0.6;
uniform float sss = 0.3;

varying vec3 p;
varying vec3 n;

void vertex() {
	p = VERTEX;
	n = NORMAL;
}

void fragment() {
	float scan = 1.0 - clamp(UV2.x, 0.0, 1.0);
	vec3 w = pow(abs(n), vec3(3.0));
	w /= dot(w, vec3(1.0));
	vec4 t = texture(mottle_tex, p.zy * tex_scale) * w.x + texture(mottle_tex, p.xz * tex_scale) * w.y
		+ texture(mottle_tex, p.xy * tex_scale) * w.z;
	float back = smoothstep(0.3, 0.7, COLOR.a);
	vec3 c = mix(palm_skin.rgb, back_skin.rgb, back);
	c = mix(c, flush.rgb, clamp(COLOR.b * flush_amount, 0.0, 1.0)) * t.rgb;
	vec4 cav = texture(cavity_tex, UV);
	c *= mix(1.0, mix(1.0 - crease, 1.0, cav.g), scan);
	float nl = smoothstep(0.35, 0.75, COLOR.r);
	c = mix(c, nail.rgb * t.rgb, nl);
	ALBEDO = c;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), texture(normal_tex, UV).rgb, scan);
	NORMAL_MAP_DEPTH = normal_depth;
	ROUGHNESS = mix(0.6 + (1.0 - t.a) * 0.15 + (1.0 - cav.g) * 0.15 * scan, 0.35, nl);
	SPECULAR = 0.35;
	AO = mix(1.0, COLOR.g, ao_strength) * mix(1.0, cav.r, occlusion * scan);
	AO_LIGHT_AFFECT = 0.4;
	SSS_STRENGTH = sss * (1.0 - nl);
}

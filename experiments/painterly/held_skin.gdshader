// Your hand on the modelled revolver (assets/held/hand.glb, the painterly look): sun-browned skin
// on the back of the hand, paler and pinker in the palm, a fine mottle, flushed at the knuckles
// and fingertips, creases across the palm side of every finger joint and fine wrinkles over the
// knuckles, nails with a pale free edge and a little grime under it, a little light through it;
// darkened where it's against the gun. What the shader reads (tools/blender/held_hand.py):
// COLOR.r the nails, .g how open, .b the flush, .a the back of the hand (1) or the palm (0);
// UV.x how far along its finger a point is from the nearest knuckle (m, either way), 1 - UV.y how far from
// the fingertip (m; glTF turns v over).
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D mottle_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 60.0;
uniform vec4 back_skin : source_color = vec4(0.47, 0.335, 0.255, 1.0);
uniform vec4 palm_skin : source_color = vec4(0.60, 0.44, 0.37, 1.0);
uniform vec4 flush : source_color = vec4(0.55, 0.30, 0.25, 1.0);
uniform vec4 nail : source_color = vec4(0.58, 0.45, 0.39, 1.0);
uniform vec4 nail_edge : source_color = vec4(0.66, 0.58, 0.49, 1.0);
uniform vec4 grime : source_color = vec4(0.18, 0.12, 0.08, 1.0);
uniform float flush_amount = 0.6;
uniform float crease_width = 0.0009;     // m: the line across a joint's palm side
uniform float crease_dark = 0.45;
uniform float wrinkle_pitch = 0.0016;    // m between the wrinkles over a knuckle
uniform float wrinkle_reach = 0.0045;    // m either side of the knuckle they show
uniform float wrinkle_dark = 0.22;
uniform float sss = 0.3;
uniform float ao_strength = 0.9;

varying vec3 p;
varying vec3 n;

void vertex() {
	p = VERTEX;
	n = NORMAL;
}

void fragment() {
	vec3 w = pow(abs(n), vec3(3.0));
	w /= dot(w, vec3(1.0));
	vec4 t = texture(mottle_tex, p.zy * tex_scale) * w.x + texture(mottle_tex, p.xz * tex_scale) * w.y
		+ texture(mottle_tex, p.xy * tex_scale) * w.z;
	float back = smoothstep(0.3, 0.7, COLOR.a);
	vec3 c = mix(palm_skin.rgb, back_skin.rgb, back);
	c = mix(c, flush.rgb, clamp(COLOR.b * flush_amount, 0.0, 1.0)) * t.rgb;

	float u = UV.x;
	float crease = exp(-pow(u / crease_width, 2.0)) * (1.0 - back);
	float wrinkles = (0.5 + 0.5 * cos(u * 6.2832 / wrinkle_pitch)) * exp(-pow(u / wrinkle_reach, 2.0)) * back;
	float dark = crease * crease_dark + wrinkles * wrinkle_dark;
	c *= 1.0 - dark;

	float tip = 1.0 - UV.y;
	float nl = smoothstep(0.35, 0.75, COLOR.r);
	vec3 nails = mix(nail.rgb, nail_edge.rgb, smoothstep(0.0032, 0.0022, tip));
	// A thin dark line where the nail meets the skin, and grime under the free edge.
	float rim = smoothstep(0.2, 0.45, COLOR.r) * (1.0 - smoothstep(0.45, 0.7, COLOR.r));
	c = mix(c, grime.rgb, rim * 0.35);
	c = mix(c, nails, nl);
	c = mix(c, grime.rgb, nl * smoothstep(0.0024, 0.0019, tip) * (1.0 - smoothstep(0.0019, 0.0013, tip)) * 0.7);

	ALBEDO = c;
	ROUGHNESS = mix(0.62 + (1.0 - t.a) * 0.18 + dark * 0.2, 0.3, nl);
	SPECULAR = 0.3;
	AO = mix(1.0, COLOR.g, ao_strength) * (1.0 - dark * 0.5);
	AO_LIGHT_AFFECT = 0.4;
	SSS_STRENGTH = sss * (1.0 - nl);
}

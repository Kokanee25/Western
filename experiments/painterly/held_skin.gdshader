// Your hand on the modelled revolver (assets/held/hand.glb, the painterly look): a warm skin with
// a fine mottle, flushed at the knuckles and fingertips, pale nails, a little light through it;
// darkened where it's against the gun. The vertex colour (tools/blender/held_hand.py): red the
// nails, green how open, blue the flush.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D mottle_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 60.0;
uniform vec4 skin : source_color = vec4(0.56, 0.41, 0.32, 1.0);
uniform vec4 flush : source_color = vec4(0.58, 0.33, 0.28, 1.0);
uniform vec4 nail : source_color = vec4(0.72, 0.60, 0.53, 1.0);
uniform float flush_amount = 0.75;
uniform float sss = 0.35;
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
	vec3 c = mix(skin.rgb, flush.rgb, clamp(COLOR.b * flush_amount, 0.0, 1.0)) * t.rgb;
	float nl = smoothstep(0.35, 0.75, COLOR.r);
	ALBEDO = mix(c, nail.rgb, nl);
	ROUGHNESS = mix(0.58 + (1.0 - t.a) * 0.2, 0.28, nl);
	SPECULAR = 0.35;
	AO = mix(1.0, COLOR.g, ao_strength);
	AO_LIGHT_AFFECT = 0.4;
	SSS_STRENGTH = sss * (1.0 - nl);
}

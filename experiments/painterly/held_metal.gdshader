// The modelled guns and their wood (assets/held/*.glb, painterly look only): a tileable texture
// laid on triplanar in the part's own space (it moves with a hammer or cylinder), worn to bare
// metal where the model's vertex colour says an edge is sharp and outward (red), darkened in its
// creases (green: how open each vertex is). The texture's alpha is a noise that breaks up the wear
// and the roughness. tools/blender/held_revolver.py writes the colours.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tex_scale = 25.0;          // repeats a metre
uniform float uv_rot = 0.0;              // radians: turns the grain on every face
uniform vec4 tint : source_color = vec4(1.0);
uniform float metallic = 0.7;
uniform float roughness = 0.35;
uniform float rough_var = 0.2;
uniform vec4 worn : source_color = vec4(0.62, 0.62, 0.62, 1.0);
uniform float worn_metallic = 0.9;
uniform float worn_roughness = 0.28;
uniform float wear_from = 0.45;
uniform float wear_to = 0.8;
uniform float wear_noise = 0.4;
uniform float ao_strength = 0.85;

varying vec3 p;
varying vec3 n;

void vertex() {
	p = VERTEX;
	n = NORMAL;
}

vec4 tri(vec3 q, vec3 m) {
	vec3 w = pow(abs(m), vec3(3.0));
	w /= dot(w, vec3(1.0));
	mat2 r = mat2(vec2(cos(uv_rot), sin(uv_rot)), vec2(-sin(uv_rot), cos(uv_rot)));
	return texture(albedo_tex, r * q.zy * tex_scale) * w.x
		+ texture(albedo_tex, r * q.xz * tex_scale) * w.y
		+ texture(albedo_tex, r * q.xy * tex_scale) * w.z;
}

void fragment() {
	vec4 t = tri(p, n);
	float wear = smoothstep(wear_from, wear_to, COLOR.r + (t.a - 0.5) * wear_noise);
	ALBEDO = mix(t.rgb * tint.rgb, worn.rgb, wear);
	METALLIC = mix(metallic, worn_metallic, wear);
	ROUGHNESS = clamp(mix(roughness + (t.a - 0.5) * rough_var, worn_roughness, wear), 0.05, 1.0);
	AO = mix(1.0, COLOR.g, ao_strength);
	AO_LIGHT_AFFECT = 0.35;
}

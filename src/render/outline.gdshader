shader_type spatial;
// The concept painting's line work: a dark line round every form, on the near side of each
// silhouette (where the depth behind a pixel jumps away) and along sharp creases (where the
// surface turns hard). Drawn by a full-screen quad in front of the camera (Outline), after the
// opaque pass, from the depth and normal buffers. Lines are `thickness` screen pixels wide and
// darken what's under them towards `line_colour` rather than painting it flat black.
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform vec3 line_colour : source_color = vec3(0.09, 0.05, 0.03);
// How much of the colour under a line is kept (0 = the line colour only).
uniform float keep = 0.15;
uniform float thickness = 3.0;
// A silhouette: the neighbour is this much further away, as a share of this pixel's distance.
uniform float depth_jump = 0.06;
// A crease: the surface turns by more than this (cosine between the normals).
uniform float crease = 0.55;
// Past this distance lines fade out (far things stay soft, as in the painting's background).
uniform float fade_from = 6.0;
uniform float fade_to = 14.0;
uniform bool use_normals = true;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float d = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 n = texture(normal_tex, SCREEN_UV).xyz * 2.0 - 1.0;
	float edge = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 dir = vec2(i == 0 ? 1.0 : (i == 1 ? -1.0 : 0.0), i == 2 ? 1.0 : (i == 3 ? -1.0 : 0.0));
		vec2 uv = SCREEN_UV + dir * px * thickness;
		float dn = linear_depth(uv, INV_PROJECTION_MATRIX);
		// Only the nearer side of a silhouette gets the line (the line sits on the form's edge).
		if (dn - d > depth_jump * d) {
			edge = 1.0;
		}
		if (use_normals) {
			vec3 nn = texture(normal_tex, uv).xyz * 2.0 - 1.0;
			if (dot(n, nn) < crease && abs(dn - d) < depth_jump * d * 2.0) {
				edge = max(edge, 0.7);
			}
		}
	}
	float far = 1.0 - smoothstep(fade_from, fade_to, d);
	edge *= far;
	if (edge <= 0.0) {
		discard;
	}
	vec3 under = texture(screen_tex, SCREEN_UV).rgb;
	ALBEDO = mix(under, line_colour + under * keep, edge);
}

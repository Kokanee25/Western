// A StandardMaterial3D stand-in on the mosaic tiles (tiles.gdshaderinc): an albedo texture by UV,
// or triplanar in the mesh's own space like uv1_triplanar (the strongest plane wins: a tile needs
// one grid), tinted, with roughness and metallic. Made by Tiles.material().

#include "res://src/render/tiles.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform bool triplanar = false;
uniform float roughness = 0.9;
uniform float metallic = 0.0;
uniform float specular = 0.5;

varying vec3 obj_pos;
varying vec3 obj_normal;

void vertex() {
	obj_pos = VERTEX;
	obj_normal = NORMAL;
}

void fragment() {
	vec2 uv;
	if (triplanar) {
		vec3 an = abs(obj_normal);
		vec3 p = obj_pos * uv1_scale + uv1_offset;
		uv = an.x > an.y && an.x > an.z ? p.zy : (an.y > an.z ? p.xz : p.xy);
	} else {
		uv = UV * uv1_scale.xy + uv1_offset.xy;
	}
	vec2 tsize = vec2(textureSize(albedo_tex, 0));
	vec2 t = uv * tsize;
	vec2 centre = tile_centre(t);
	vec2 s = tile_screen_offset(t, centre);
	ALBEDO = albedo_color.rgb * textureGrad(albedo_tex, centre / tsize, dFdx(uv), dFdy(uv)).rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	LIGHT_VERTEX = VERTEX + dFdx(VERTEX) * s.x + dFdy(VERTEX) * s.y;
	NORMAL = normalize(NORMAL + dFdx(NORMAL) * s.x + dFdy(NORMAL) * s.y);
}

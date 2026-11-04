// The real look (docs/briefs/red-dead.md R0; RealLook, Settings.real_look): what a world shader
// does differently when the look is realistic. RealLook recompiles the world's shaders with
// REAL_LOOK defined (it puts the line after `shader_type`), so the painted look's code is
// untouched and costs nothing extra while it's in force.

#ifdef REAL_LOOK
// Textures drawn smooth: filtered, mipmapped, anisotropic (the painted look's are nearest).
#define GRID_FILTER filter_linear_mipmap_anisotropic
#else
#define GRID_FILTER filter_nearest_mipmap
#endif

// Metres of relief a texture's full light-to-dark range stands for (the albedo as height until
// scanned maps come, R2); 0 = flat. Set by RealLook (look address `real.relief`).
global uniform float real_relief;
// The gap between boards, metres wide (members' long edges and ends).
global uniform float real_groove;
// The least specular a world surface has under the real look (dry wood still has a sheen).
global uniform float real_specular;

// The normal tilted by a height field given only at this fragment, from its screen derivatives:
// Mikkelsen, "Bump Mapping Unparametrized Surfaces on the GPU" (2010), the surface gradient from
// dFdx/dFdy of position and height. `p` and `n` in view space (VERTEX, NORMAL); `h` in metres.
vec3 real_bump(vec3 p, vec3 n, float h) {
	vec3 dpdx = dFdx(p);
	vec3 dpdy = dFdy(p);
	float dhdx = dFdx(h);
	float dhdy = dFdy(h);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	if (abs(det) < 1e-12) {
		return n;
	}
	vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
	return normalize(abs(det) * n - grad);
}

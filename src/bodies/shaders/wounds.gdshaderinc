// Wound openings shared by the skin/clothing shader and the flesh-inside shader: up to 8 spheres
// (centre in the mesh's own space, radius) where the body has been torn open. Inside one it's gone
// (discarded); round the edge a ragged pixel rim of torn flesh and soaked cloth; further out, blood.
// Reduced gore keeps it all closed and paints a dark soaked wound instead.

uniform int wound_count = 0;
uniform vec4 wounds[8];
uniform bool reduced_gore = false;
// Pixel grid for the ragged edge (texels per metre).
uniform float edge_texels = 160.0;

float wound_hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

// How far into the nearest opening this point is: < 1 inside, 1..1.4 on the rim, more outside.
float wound_reach(vec3 local_pos) {
	vec3 q = floor(local_pos * edge_texels) / edge_texels;
	float nearest = 99.0;
	for (int i = 0; i < 8; i++) {
		if (i >= wound_count) {
			break;
		}
		float r = max(wounds[i].w, 0.0001);
		// A ragged edge: each pixel of the rim a little nearer or further.
		float jag = 1.0 + (wound_hash(q + float(i)) - 0.5) * 0.35;
		nearest = min(nearest, distance(q, wounds[i].xyz) / r * jag);
	}
	return nearest;
}

// Wear by use, dents and marks with a story (#901; docs/briefs/lived-in.md), for scan_wood.gdshader.
// Pure helpers here; the pass itself is in scan_wood's fragment (it reads the board's varyings).
//
// Every mark is the board's own, from its flat seed (the weave's lesson: a per-board hash must come
// from a flat varying), so no two boards match and nothing floats over the wood.
//  - Knocks: an arris crushed in a few places along its length (a bigger, uneven round: the eased
//    edge's radius grown there, the fibres bruised dark or torn pale).
//  - Dents and gouges in a face, one cell in a grid at most (cheap: a fragment looks at one cell):
//    heel and dropped-glass dents (a shallow bowl, darker where dirt packs in), spur and knife cuts,
//    dragged-chair gouges (a V groove, pale when fresh, dirty when old).
//  - The use roles (CUSTOM2.w, mod 10): 3 a door's leaf (its latch at +Y: hands' grease at the push,
//    boots at the foot), 4 a stair's tread (dished in the middle), 5 one of a walk's middle boards (worn
//    along it), 6 a kick board (boot scuffs: a bar's foot), 7 a bar's top (the front's rubbed
//    band, cigarette burns along the edge, rings, initials cut in it), 8 a chair's seat (polished where
//    you sit, its front edge rubbed), 9 a grip (a jamb or a chair's crest: polished, grimy at the hand).
// Period sources for where wear goes: Nicholson's Mechanic's Companion (arrises and treads), the USDA
// Wood Handbook ch. 16 (abrasion, finishes wearing through), photographs of saloon bars and stairs of the
// 1880s (Library of Congress HABS surveys: dished treads, bar fronts kicked dark).

float wu_hash(float s, float k) {
	return fract(sin(s * 127.1 + k * 311.7) * 43758.5453);
}

float wu_hash2(float s, vec2 c, float k) {
	return fract(sin(s * 157.3 + c.x * 12.9898 + c.y * 78.233 + k * 37.719) * 43758.5453);
}

// A segment's distance and where along it (0..1) p falls.
vec2 wu_seg(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-8), 0.0, 1.0);
	return vec2(length(p - a - ab * t), t);
}

// A letter cut in the wood, on a box 1 wide and 1.4 tall: the strokes' nearest distance (box units).
// Segments: 0 top, 1 middle, 2 bottom, 3 upper left, 4 upper right, 5 lower left, 6 lower right,
// 7 the rising diagonal, 8 the falling one, 9 the middle upright. Thirteen letters a knife cuts easily.
int wu_letter(float h) {
	int masks[13] = int[](
		1 + 2 + 8 + 16 + 32 + 64,  // A
		1 + 4 + 8 + 32,            // C
		1 + 2 + 4 + 8 + 32,        // E
		1 + 2 + 8 + 32,            // F
		2 + 8 + 16 + 32 + 64,      // H
		4 + 16 + 64,               // J
		4 + 8 + 32,                // L
		8 + 16 + 32 + 64 + 256,    // N
		1 + 2 + 8 + 16 + 32,       // P
		1 + 512,                   // T
		4 + 8 + 16 + 32 + 64,      // U
		128 + 256,                 // X
		1 + 4 + 128);              // Z
	return masks[int(floor(h * 12.999))];
}

float wu_letter_dist(vec2 p, int mask) {
	vec2 a[10] = vec2[](vec2(0.0, 1.4), vec2(0.0, 0.7), vec2(0.0, 0.0), vec2(0.0, 0.7), vec2(1.0, 0.7),
			vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(0.0, 0.0), vec2(0.0, 1.4), vec2(0.5, 0.0));
	vec2 b[10] = vec2[](vec2(1.0, 1.4), vec2(1.0, 0.7), vec2(1.0, 0.0), vec2(0.0, 1.4), vec2(1.0, 1.4),
			vec2(0.0, 0.7), vec2(1.0, 0.7), vec2(1.0, 1.4), vec2(1.0, 0.0), vec2(0.5, 1.4));
	float d = 10.0;
	for (int i = 0; i < 10; i++) {
		if ((mask & (1 << i)) != 0) {
			d = min(d, wu_seg(p, a[i], b[i]).x);
		}
	}
	return d;
}

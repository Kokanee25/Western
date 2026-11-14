shader_type canvas_item;
// Dirt and grit thrown on your eyes by a blast up close (#596 step 2; player_wounds.gd): specks of
// earth and pale grit in clumps, ragged and drawn out from the middle as if thrown, a few faint
// smears, more toward the edges and the side the blast came from, and a brown wash of dust over
// the view, heavier at its edges. No physics, no particles: one rect, drawn only while there's
// grit (player_wounds hides it otherwise).
//
// `amount` is how much is left (1 just after, 0 cleared): each speck has its own threshold, so they
// go one by one, not all fading together; the pattern is the blast's own (`seed`).

uniform float amount = 0.0;     // what's left, 0-1
uniform float strength = 0.0;   // how much it threw on you at first, 0-1 (fewer specks further off)
uniform float dust = 0.0;       // the brown wash, 0-1
uniform vec2 from_dir = vec2(0.0);  // the blast's side on the screen (x right, y down), its length how far off-centre
uniform float seed = 0.0;
uniform float aspect = 1.7778;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21) + seed * 0.618);
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Smooth value noise (0-1): the clumps.
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// How thick the dirt lies here: in clumps, more to the edges, more on the blast's side.
float density(vec2 uv) {
	vec2 d = uv - 0.5;
	d.x *= aspect;
	float edge = smoothstep(0.2, 0.9, length(d));
	float side = length(from_dir) > 0.01 ? max(dot(normalize(d + 1e-4), normalize(from_dir)), 0.0) * length(from_dir) : 0.0;
	float clump = smoothstep(0.3, 0.8, vnoise(uv * vec2(aspect, 1.0) * 3.5 + 7.0) * 0.7 + vnoise(uv * vec2(aspect, 1.0) * 9.0) * 0.3);
	return (0.2 + 0.6 * edge + 0.7 * side) * (0.15 + 1.2 * clump);
}

// One layer of specks, `cells` across (each cell at most one, kept inside it): ragged, drawn out
// along the way from the middle, sizes mostly small. Returns colour and cover.
vec4 specks(vec2 uv, float cells, float size, float alpha, float share) {
	vec2 sp = vec2(uv.x * aspect, uv.y);
	vec2 g = sp * cells;
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;
	float h1 = hash(cell);
	float h2 = hash(cell + 17.0);
	float h3 = hash(cell + 31.0);
	float h4 = hash(cell + 53.0);
	float h5 = hash(cell + 71.0);
	vec2 cuv = (cell + 0.5) / cells;
	cuv.x /= aspect;
	// There at all (by how much it threw and how thick it lies here), and still there now.
	float present = step(h1, strength * density(cuv) * share);
	float left = step(h4, amount);
	float r = min(mix(0.08, 0.36, pow(h2, 1.8)) * size, 0.44);
	vec2 at = (vec2(h3, h5) - 0.5) * (0.9 - 2.0 * r);
	vec2 q = f - at;
	// Drawn out along the line from the middle of the view (thrown at you), by up to 2x.
	vec2 out_dir = normalize(cuv - 0.5 + 1e-4);
	out_dir.x *= aspect;
	out_dir = normalize(out_dir);
	float along = dot(q, out_dir);
	float across = dot(q, vec2(-out_dir.y, out_dir.x));
	float stretch = mix(1.0, 2.2, h5 * h5);
	vec2 e = vec2(along / stretch, across);
	// Ragged: the edge in and out with the angle.
	float a = atan(e.y, e.x);
	float rr = r * (1.0 + 0.14 * sin(2.0 * a + h2 * 6.28) + 0.08 * sin(5.0 * a + h3 * 6.28));
	float l = length(e) / max(rr, 1e-4);
	float k = 1.0 - smoothstep(0.35, 1.0, l);
	vec3 earth = mix(vec3(0.14, 0.1, 0.06), vec3(0.3, 0.22, 0.14), h3);
	earth = mix(earth, vec3(0.62, 0.55, 0.43), step(0.82, h4 * h2 + 0.3 * h5));  // pale grit
	earth *= mix(0.7, 1.0, smoothstep(0.0, 0.7, l));  // a darker core
	return vec4(earth, k * present * left * alpha * mix(0.6, 1.0, h1));
}

void fragment() {
	vec2 d = UV - 0.5;
	d.x *= aspect;
	float edge = smoothstep(0.25, 1.0, length(d));
	vec4 c = vec4(0.47, 0.38, 0.26, dust * (0.5 + 0.5 * edge));
	// Smears: a few, big, soft, faint, and the grit over them.
	vec4 s = specks(UV, 6.0, 1.5, 0.35, 0.45);
	c = mix(c, vec4(mix(s.rgb, vec3(0.4, 0.32, 0.22), 0.6), 1.0), s.a * (1.0 - smoothstep(0.0, 1.0, 1.0 - amount)));
	vec4 b = specks(UV + 0.37, 24.0, 1.0, 0.9, 0.75);
	c = mix(c, vec4(b.rgb, 1.0), b.a);
	vec4 a = specks(UV, 60.0, 1.0, 0.95, 1.0);
	c = mix(c, vec4(a.rgb, 1.0), a.a);
	COLOR = vec4(c.rgb, clamp(c.a, 0.0, 1.0));
}

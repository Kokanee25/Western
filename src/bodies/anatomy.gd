class_name Anatomy
extends RefCounted
## The hidden anatomy under every person (config/anatomy.json): segments (the parts that move as
## one and come apart at the joints) and the structures inside them (bones, arteries, organs,
## fingers). `trace()` follows a bullet through one segment: flesh slows it, bones stop it or break,
## arteries are cut, organs torn, fingers taken off. All in the body's rest pose, metres.

const PATH := "res://config/anatomy.json"
## Joules a bullet loses per centimetre of flesh when this isn't set in the data.
const DEFAULT_FLESH_RESISTANCE := 13.0
## A path through that never goes deeper than this under the skin is a graze: a furrow, not a hole.
const GRAZE_DEPTH := 0.018

static var _shared: Anatomy

var height := 1.78
var flesh_resistance := DEFAULT_FLESH_RESISTANCE
## segment id -> {a, b, radius (its main capsule), capsules: [[a, b, radius]...], parent}
var segments := {}
## Every structure: {id, kind, segment, a, b, radius, and its kind's properties (strength, shell,
## cage, spine, bleed, limb, organ, group, cord, disables): see tools/anatomy/build_anatomy.py.
## A sphere has a == b.
var structures: Array[Dictionary] = []
## segment id -> Array of structures inside it.
var by_segment := {}


static func shared() -> Anatomy:
	if _shared == null:
		_shared = Anatomy.new()
		_shared.load_file(PATH)
	return _shared


func load_file(path: String) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_error("Anatomy: can't read %s" % path)
		return
	height = float(data.get("height", 1.78))
	flesh_resistance = float(data.get("flesh_resistance", DEFAULT_FLESH_RESISTANCE))
	for sid: String in data.segments:
		var s: Dictionary = data.segments[sid]
		var caps: Array = []
		for c: Array in s.capsules:
			caps.append([_v(c[0]), _v(c[1]), float(c[2])])
		segments[StringName(sid)] = {"a": caps[0][0], "b": caps[0][1], "radius": caps[0][2],
				"capsules": caps, "parent": StringName(s.get("parent", ""))}
		by_segment[StringName(sid)] = []
	for raw: Dictionary in data.structures:
		var st := {}
		for k: String in raw:
			st[StringName(k)] = raw[k]
		st.id = StringName(raw.id)
		st.kind = StringName(raw.kind)
		st.segment = StringName(raw.segment)
		if raw.has("capsule"):
			st.a = _v(raw.capsule[0])
			st.b = _v(raw.capsule[1])
			st.radius = float(raw.capsule[2])
		else:
			st.a = _v(raw.sphere[0])
			st.b = st.a
			st.radius = float(raw.sphere[1])
		st.erase(&"capsule")
		st.erase(&"sphere")
		structures.append(st)
		if by_segment.has(st.segment):
			by_segment[st.segment].append(st)


func structure(id: StringName) -> Dictionary:
	for st in structures:
		if st.id == id:
			return st
	return {}


## Centre of a segment in the rest pose (where its node sits).
func segment_center(segment: StringName) -> Vector3:
	var s: Dictionary = segments[segment]
	return (s.a + s.b) * 0.5


## Segments with every parent before its children (pelvis first).
func segment_order() -> Array[StringName]:
	var out: Array[StringName] = []
	while out.size() < segments.size():
		for sid: StringName in segments:
			var parent: StringName = segments[sid].parent
			if not out.has(sid) and (parent == &"" or out.has(parent)):
				out.append(sid)
	return out


## Every segment below this one (hand below forearm below upper arm...), including itself.
func segments_below(segment: StringName) -> Array[StringName]:
	var out: Array[StringName] = [segment]
	var grew := true
	while grew:
		grew = false
		for sid: StringName in segments:
			if not out.has(sid) and out.has(segments[sid].parent):
				out.append(sid)
				grew = true
	return out


## Follow a bullet through one segment. `origin` and `dir` are in the body's rest-pose space;
## `origin` should be on or just outside the segment's skin. `energy` in joules.
## Returns {segment, entry, exit (Vector3 or null), stop (where it ended inside, or null),
## energy_in, energy_out, track_cm, depth (deepest under the skin, m), graze (only skimmed it),
## hits: [{id, kind, effect, position}]}.
## effect: "cut" (artery, vein, nerve), "torn" (organ, muscle), "broken" / "stopped" (bone),
## "severed" (finger).
## Soft lead on bone (the gore lab, docs/briefs/gore-lab.md, after DiMaio's Gunshot Wounds and the
## Medical and Surgical History of the War of the Rebellion): a ball that breaks a bone flattens and
## goes on wider (BONE_FLATTEN of its radius), tearing more and a bigger hole out; one that breaks a
## strong bone (SPLIT_STRENGTH joules and up) with SPLIT_ENERGY left can split in two (SPLIT_CHANCE),
## each half on its own track; one that meets a bone nearly side-on (SKIP_COS of the bone's normal,
## about 17 degrees off its surface) skips off it (SKIP_CHANCE) and goes on bent, chipping it.
const BONE_FLATTEN := 1.5
const SPLIT_STRENGTH := 150.0
const SPLIT_ENERGY := 120.0
const SPLIT_CHANCE := 0.35
const SPLIT_SPREAD := 0.2  ## radians each half turns off the line
const SKIP_COS := 0.3
const SKIP_CHANCE := 0.6
const SKIP_KEEP := 0.8  ## of its energy a skipping ball keeps


## The result also has `flattened`, `split`, `skipped` (what happened to the ball), `out_dir` (the
## way it leaves, when that isn't `dir`) and `exits` (every hole out, a split ball's two).
func trace(segment: StringName, origin: Vector3, dir: Vector3, energy: float, bullet_radius: float,
		rng: RandomNumberGenerator, _depth := 0, _met: Array = []) -> Dictionary:
	dir = dir.normalized()
	var skin := skin_span(segment, origin, dir)
	var t_in := 0.0
	var t_out := 0.02
	if skin.x < INF:
		t_in = maxf(skin.x, 0.0)
		t_out = skin.y
	var result := {"segment": segment, "entry": origin + dir * t_in, "exit": null, "stop": null,
			"energy_in": energy, "energy_out": 0.0, "track_cm": 0.0, "hits": [], "radius": bullet_radius,
			"exits": [], "flattened": false, "split": false, "skipped": false}
	# Everything the path crosses, in order.
	var events: Array[Dictionary] = []
	for st: Dictionary in by_segment.get(segment, []):
		if st.kind == &"bone" and _met.has(st.id):
			continue  # the bone it's coming off (a sub-trace from it)
		var shell: float = st.get(&"shell", 0.0)
		var cage: float = st.get(&"cage", 0.0)
		var reach: float = st.radius + (bullet_radius if shell == 0.0 else 0.0)
		var span := ray_capsule(origin, dir, st.a, st.b, reach)
		if span.x == INF or span.y < t_in or span.x > t_out:
			continue
		if shell > 0.0:
			# A hollow bone (skull, ribcage): crossed going in and again coming out.
			if span.x >= t_in:
				events.append({"t": span.x, "t_end": span.x + shell, "st": st, "roll": cage})
			if span.y <= t_out:
				events.append({"t": span.y - shell, "t_end": span.y, "st": st, "roll": cage})
		else:
			events.append({"t": maxf(span.x, t_in), "t_end": minf(span.y, t_out), "st": st, "roll": 0.0})
	events.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p.t < q.t)
	var t := t_in
	var e := energy
	var per_m := flesh_resistance * 100.0
	var done := false
	for ev in events:
		if ev.t_end <= t:
			continue
		var start: float = maxf(ev.t, t)
		var cost := (start - t) * per_m
		if e <= cost:
			t += e / per_m
			e = 0.0
			done = true
			break
		e -= cost
		t = start
		var st: Dictionary = ev.st
		var at := origin + dir * t
		match st.kind:
			&"bone":
				if ev.roll > 0.0 and rng.randf() >= ev.roll:
					continue  # slipped between the ribs
				var strength: float = st.get(&"strength", 100.0)
				if _depth < 2 and ev.roll == 0.0:
					# Side-on to the bone: it skips off.
					var n := _off_axis(at, st.a, st.b)
					if n != Vector3.ZERO and absf(dir.dot(n)) < SKIP_COS and _roll(at, 1) < SKIP_CHANCE:
						_add_hit(result, st, &"chipped", at)
						var bent := (dir - 2.0 * dir.dot(n) * n).normalized().lerp(dir, 0.5).normalized()
						result.skipped = true
						_go_on(result, segment, at + bent * 0.003, bent, e * SKIP_KEEP, bullet_radius, rng, _depth, t - t_in, _met + [st.id])
						return result
				if e > strength:
					# Broken through; what's inside the bone (the spinal cord) is next.
					e -= strength
					_add_hit(result, st, &"broken", at)
					if _depth < 2 and ev.roll == 0.0:
						# Soft lead flattens on it, and a strong bone can split it.
						# On from where it broke in (what's inside the bone, the spinal cord, is next),
						# the bone itself left behind.
						var past: Vector3 = at + dir * 0.001
						result.flattened = true
						if strength >= SPLIT_STRENGTH and e > SPLIT_ENERGY and _roll(at, 2) < SPLIT_CHANCE:
							result.split = true
							var side := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
							var turn := _roll(at, 3) * TAU
							var off := side.rotated(dir, turn)
							var d1 := dir.rotated(off, SPLIT_SPREAD)
							var d2 := dir.rotated(off, -SPLIT_SPREAD)
							_go_on(result, segment, past, d1, e * 0.5, bullet_radius * 0.8, rng, _depth, t - t_in, _met + [st.id])
							var second := trace(segment, past, d2, e * 0.5, bullet_radius * 0.8, rng, _depth + 1, _met + [st.id])
							for h: Dictionary in second.hits:
								_add_hit(result, structure(h.id), h.effect, h.position)
							result.exits.append_array(second.exits)
							result.second = second
						else:
							_go_on(result, segment, past, dir, e, bullet_radius * BONE_FLATTEN, rng, _depth, t - t_in, _met + [st.id])
						return result
				else:
					e = 0.0
					_add_hit(result, st, &"stopped", at)
					done = true
					break
			&"finger", &"appendage":
				e = maxf(e - float(st.get(&"strength", 8.0)), 0.0)
				_add_hit(result, st, &"severed", at)
				if e <= 0.0:
					done = true
					break
			&"artery", &"vein", &"nerve":
				_add_hit(result, st, &"cut", at)
			_:
				_add_hit(result, st, &"torn", at)
	if not done:
		var cost := (t_out - t) * per_m
		if e > cost:
			e -= cost
			t = t_out
			result.exit = origin + dir * t_out
		else:
			t += e / per_m
			e = 0.0
	if result.exit == null:
		result.stop = origin + dir * t
	else:
		result.exits.append(result.exit)
	result.energy_out = e
	result.track_cm = (t - t_in) * 100.0
	result.depth = deepest(segment, origin + dir * t_in, origin + dir * t)
	result.graze = result.exit != null and result.depth < GRAZE_DEPTH
	return result


## The rest of a ball's way from a bone on (after it flattened, skipped or split), folded into
## `result`: its hits, where it ends, what it keeps. `so_far` is the track before (m).
func _go_on(result: Dictionary, segment: StringName, from: Vector3, dir: Vector3, e: float, radius: float,
		rng: RandomNumberGenerator, depth: int, so_far: float, met: Array) -> void:
	var rest := trace(segment, from, dir, e, radius, rng, depth + 1, met)
	for h: Dictionary in rest.hits:
		_add_hit(result, structure(h.id), h.effect, h.position)
	result.exit = rest.exit
	result.stop = rest.stop
	result.exits.append_array(rest.exits)
	result.energy_out = rest.energy_out
	result.track_cm = so_far * 100.0 + rest.track_cm
	result.radius = maxf(float(result.radius), radius)
	result.depth = maxf(deepest(segment, result.entry, from), rest.depth)
	result.graze = false
	for k in ["flattened", "split", "skipped"]:
		if rest.get(k, false):
			result[k] = true
	result.out_dir = rest.get("out_dir", dir)


## A roll (0..1) from where on the bone it happens: the same shot, the same outcome, and not drawn
## from the man's dice (what a ball does to a bone mustn't shift the rest of a fight's rolls).
static func _roll(p: Vector3, salt: int) -> float:
	return float(posmod(hash([p.snapped(Vector3.ONE * 0.0002), salt]), 10007)) / 10007.0


## The way out from a capsule's axis to a point (zero on the axis).
static func _off_axis(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	var off := p - (a + ab * t)
	return off.normalized() if off.length() > 1e-5 else Vector3.ZERO


## Follow a bullet through the whole body (for a body that's one collider, like the player's):
## segment after segment in the order the path enters them, until it stops or comes out.
## Returns {traces: [trace results], exit (Vector3 or null), energy_out}.
func trace_through(origin: Vector3, dir: Vector3, energy: float, bullet_radius: float,
		rng: RandomNumberGenerator) -> Dictionary:
	dir = dir.normalized()
	var entries: Array[Array] = []
	for sid: StringName in segments:
		var span := skin_span(sid, origin, dir)
		if span.x < INF and span.y > 0.0:
			entries.append([span.x, sid])
	entries.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var out := {"traces": [], "exit": null, "energy_out": energy}
	var e := energy
	var reached := -INF
	for entry in entries:
		var sid: StringName = entry[1]
		var span := skin_span(sid, origin, dir)
		if span.y <= reached:
			continue  # already passed through (overlapping segments)
		var start: float = maxf(span.x, reached)
		var tr := trace(sid, origin + dir * (start - 0.001), dir, e, bullet_radius, rng)
		out.traces.append(tr)
		e = tr.energy_out
		if tr.exit == null:
			out.exit = null
			break
		out.exit = tr.exit
		reached = (tr.exit - origin).dot(dir)
	out.energy_out = e
	return out


func _add_hit(result: Dictionary, st: Dictionary, effect: StringName, at: Vector3) -> void:
	for h: Dictionary in result.hits:
		if h.id == st.id:
			if effect == &"broken" or effect == &"stopped":
				h.effect = effect
			return
	result.hits.append({"id": st.id, "kind": st.kind, "effect": effect, "position": at})


## How far under the skin a straight path between two points gets at its deepest (m).
func deepest(segment: StringName, a: Vector3, b: Vector3) -> float:
	var best := 0.0
	for i in 9:
		var p := a.lerp(b, i / 8.0)
		var d := 0.0
		for c: Array in segments[segment].capsules:
			var ca: Vector3 = c[0]
			var ab: Vector3 = (c[1] as Vector3) - ca
			var t := clampf((p - ca).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			d = maxf(d, float(c[2]) - p.distance_to(ca + ab * t))
		best = maxf(best, d)
	return best


## Where a ray is inside a segment's skin (all its capsules together): Vector2(t_in, t_out).
func skin_span(segment: StringName, o: Vector3, dir: Vector3) -> Vector2:
	var lo := INF
	var hi := -INF
	for c: Array in segments[segment].capsules:
		var span := ray_capsule(o, dir, c[0], c[1], c[2])
		if span.x < INF:
			lo = minf(lo, span.x)
			hi = maxf(hi, span.y)
	return Vector2(lo, hi) if lo < INF else Vector2(INF, INF)


static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


## Where a ray enters and leaves a sphere: Vector2(t_in, t_out), or (INF, INF) if it misses.
## `dir` must be normalised.
static func ray_sphere(o: Vector3, dir: Vector3, c: Vector3, r: float) -> Vector2:
	var oc := o - c
	var b := oc.dot(dir)
	var h := b * b - (oc.length_squared() - r * r)
	if h < 0.0:
		return Vector2(INF, INF)
	h = sqrt(h)
	return Vector2(-b - h, -b + h)


## Where a ray enters and leaves a capsule (segment a–b, radius r): Vector2(t_in, t_out),
## or (INF, INF). The capsule is convex, so the ray is inside it for one interval: the union of its
## end spheres and the cylinder between them.
static func ray_capsule(o: Vector3, dir: Vector3, a: Vector3, b: Vector3, r: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for c in [a, b]:
		var s := ray_sphere(o, dir, c, r)
		if s.x < INF:
			lo = minf(lo, s.x)
			hi = maxf(hi, s.y)
	var ba := b - a
	var baba := ba.dot(ba)
	if baba > 1e-10:
		var oc := o - a
		var bard := ba.dot(dir)
		var baoc := ba.dot(oc)
		var k2 := baba - bard * bard
		if k2 > 1e-10:
			var k1 := baba * oc.dot(dir) - baoc * bard
			var k0 := baba * oc.dot(oc) - baoc * baoc - r * r * baba
			var h := k1 * k1 - k2 * k0
			if h >= 0.0:
				h = sqrt(h)
				var c0 := (-k1 - h) / k2
				var c1 := (-k1 + h) / k2
				# Keep the part of the cylinder between the end caps' planes.
				var s0 := -INF
				var s1 := INF
				if absf(bard) > 1e-10:
					var p := -baoc / bard
					var q := (baba - baoc) / bard
					s0 = minf(p, q)
					s1 = maxf(p, q)
				elif baoc < 0.0 or baoc > baba:
					s0 = INF
				var i0 := maxf(c0, s0)
				var i1 := minf(c1, s1)
				if i0 <= i1:
					lo = minf(lo, i0)
					hi = maxf(hi, i1)
	if lo == INF:
		return Vector2(INF, INF)
	return Vector2(lo, hi)

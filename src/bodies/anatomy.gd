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
func trace(segment: StringName, origin: Vector3, dir: Vector3, energy: float, bullet_radius: float,
		rng: RandomNumberGenerator) -> Dictionary:
	dir = dir.normalized()
	var skin := skin_span(segment, origin, dir)
	var t_in := 0.0
	var t_out := 0.02
	if skin.x < INF:
		t_in = maxf(skin.x, 0.0)
		t_out = skin.y
	var result := {"segment": segment, "entry": origin + dir * t_in, "exit": null, "stop": null,
			"energy_in": energy, "energy_out": 0.0, "track_cm": 0.0, "hits": []}
	# Everything the path crosses, in order.
	var events: Array[Dictionary] = []
	for st: Dictionary in by_segment.get(segment, []):
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
				if e > strength:
					# Broken through; what's inside the bone (the spinal cord) is next.
					e -= strength
					_add_hit(result, st, &"broken", at)
				else:
					e = 0.0
					_add_hit(result, st, &"stopped", at)
					done = true
					break
			&"finger":
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
	result.energy_out = e
	result.track_cm = (t - t_in) * 100.0
	result.depth = deepest(segment, origin + dir * t_in, origin + dir * t)
	result.graze = result.exit != null and result.depth < GRAZE_DEPTH
	return result


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

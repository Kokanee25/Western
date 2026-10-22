extends RefCounted
## The lived-in pass (docs/briefs/lived-in.md): marks on members from the building spec's `use`
## (who does what where, how often, for how many years) and `past` (what happened, to what). Every
## mark is on the member it's on (its meta `marks`: [{kind, s (0-1), cause, ...}]), so it burns,
## breaks and flies with it; every mark has a cause. Nothing is drawn yet: the woods' shader draws
## the marks after Gate A (the material lab's wear-down plan); the wear map render shows where they
## fall.

## The marks the shader will draw (the brief's vocabulary).
const KINDS := [&"foot", &"heel", &"scuff", &"hand", &"boot", &"grime", &"elbow", &"rings", &"spill", &"burn", &"cut",
		&"soot", &"splash", &"bleach", &"streak", &"new", &"pale", &"holes", &"bullet", &"filled", &"scrubbed", &"carved"]


## Marks every member the spec's use and past reach; returns what it did: marks by cause and kind.
static func place(b: Structure, spec: Dictionary) -> Dictionary:
	var out := {"by_cause": {}, "by_kind": {}, "unresolved": []}
	var use: Dictionary = spec.get("use", {})
	var years := float(use.get("years", 1))
	var lv: Dictionary = spec.levels
	var own: Array[StructureMember] = b.get_members()
	var kit: Array[StructureMember] = []
	for k in b.find_children("*", "KitProp", true, false):
		kit.append_array((k as KitProp).get_members())
	var boards := {}  # level -> its floor boards
	for lvl in ["ground", "upper"]:
		var y: float = float(lv[lvl].top)
		boards[lvl] = own.filter(func(m: StructureMember) -> bool:
			return m.kind == &"floor_board" and absf(m.structure_aabb().end.y - y) < 0.04)
	# Paths: the boards a path crosses wear along the stretch it crosses them, most on its centre line.
	for p: Dictionary in use.get("paths", []):
		var w := float(p.width)
		var s_max := _grow(float(p.daily), years)
		var pts: Array = p.points
		var touched := {}
		for i in pts.size() - 1:
			var a := Vector2(pts[i][0], pts[i][1])
			var e := Vector2(pts[i + 1][0], pts[i + 1][1])
			var n := maxi(1, ceili(a.distance_to(e) / 0.15))
			for k in n + 1:
				var q := a.lerp(e, float(k) / n)
				for m: StructureMember in boards[p.level]:
					var d := _xz_distance(m.structure_aabb(), q)
					if d > w * 0.5:
						continue
					var s := s_max * exp(-2.0 * pow(d / (w * 0.5), 2.0))
					var t := (Vector3(q.x, 0, q.y) - m.transform.origin).dot(m.axis())
					var hit: Dictionary = touched.get(m, {"t0": t, "t1": t, "s": 0.0})
					hit.t0 = minf(hit.t0, t)
					hit.t1 = maxf(hit.t1, t)
					hit.s = maxf(hit.s, s)
					touched[m] = hit
		for m: StructureMember in touched:
			var h: Dictionary = touched[m]
			_mark(out, m, {"kind": &"foot", "s": snappedf(h.s, 0.01), "cause": p.id, "along": [snappedf(h.t0, 0.01), snappedf(h.t1, 0.01)]})
	# Stairs: treads worn in the middle (the first and last most: where people turn onto them), the
	# nosings rounded, the hand rail and newel polished.
	for id: String in use.get("stairs", {}):
		var s := _grow(float(use.stairs[id]), years)
		var prefix := "%s/stair/%s/" % [b.structure_id, id]
		var treads := own.filter(func(m: StructureMember) -> bool: return String(m.member_id).begins_with(prefix + "tread/"))
		for i in treads.size():
			var turn := 1.3 if i == 0 or i == treads.size() - 1 else 1.0
			_mark(out, treads[i], {"kind": &"foot", "s": snappedf(minf(1.0, s * turn), 0.01), "cause": "stair_" + id, "where": "centre"})
		for m: StructureMember in own:
			var mid := String(m.member_id)
			if mid.begins_with(prefix + "rail/rail/") or mid == prefix + "newel":
				_mark(out, m, {"kind": &"hand", "s": snappedf(s, 0.01), "cause": "stair_" + id})
	# Where people stand: the rail they lean on polished there, heel marks on the boards under them.
	for sp: Dictionary in use.get("spots", []):
		var s := _grow(float(sp.daily), years)
		var at := Vector2(sp.at[0], sp.at[1])
		var y := float(lv[sp.level].top)
		for m: StructureMember in own:
			if m.kind == &"trim" and String(m.member_id).contains("rail") and absf(m.structure_aabb().get_center().y - (y + 0.97)) < 0.15 \
					and _xz_distance(m.structure_aabb(), at) < 0.4:
				var t := (Vector3(at.x, 0, at.y) - m.transform.origin).dot(m.axis())
				_mark(out, m, {"kind": &"hand", "s": snappedf(s, 0.01), "cause": sp.id, "along": [snappedf(t - 0.4, 0.01), snappedf(t + 0.4, 0.01)]})
		for m: StructureMember in boards[sp.level]:
			if _xz_distance(m.structure_aabb(), Vector2(sp.feet[0], sp.feet[1])) < 0.35:
				_mark(out, m, {"kind": &"heel", "s": snappedf(s, 0.01), "cause": sp.id, "at": _local(m, Vector3(sp.feet[0], y, sp.feet[1])), "r": 0.35})
	# Doors: grime round where they're pushed, the boards under the swing scuffed.
	if use.has("doors"):
		var s := _grow(float(use.doors.daily), years)
		for m: StructureMember in own:
			if m.kind != &"door":
				continue
			_mark(out, m, {"kind": &"grime", "s": snappedf(s, 0.01), "cause": "doors"})
			var box := m.structure_aabb()
			for lvl in boards:
				for f: StructureMember in boards[lvl]:
					var fb := f.structure_aabb()
					if absf(fb.end.y - box.position.y) < 0.03 and fb.grow(0.02).intersects(AABB(box.position - Vector3(0, 0.05, 0), box.size + Vector3(0, 0.1, 0))):
						var c := box.get_center()
						_mark(out, f, {"kind": &"scuff", "s": snappedf(s * 0.6, 0.01), "cause": "doors", "at": _local(f, Vector3(c.x, fb.end.y, c.z)),
								"r": maxf(box.size.x, box.size.z) * 0.5})
	# Lamps: soot on what's over them.
	if use.has("lamps") and "lamps" in b:
		var s := float(use.lamps.soot)
		for lamp: Node3D in b.lamps:
			var at := b.to_local(lamp.global_position)
			var box := AABB(at + Vector3(-0.2, 0.3, -0.2), Vector3(0.4, 0.9, 0.4))
			for m: StructureMember in own:
				if m.kind in [&"board", &"trim", &"beam", &"joist", &"floor_board", &"plate", &"ledger"] and m.structure_aabb().intersects(box):
					_mark(out, m, {"kind": &"soot", "s": s, "cause": "lamps"})
	# Spills.
	for sp: Dictionary in use.get("spills", []):
		var r: Array = sp.rect
		var area := AABB(Vector3(r[0], -1, r[1]), Vector3(float(r[2]) - float(r[0]), 20, float(r[3]) - float(r[1])))
		for m: StructureMember in boards[sp.level]:
			var mb := m.structure_aabb()
			if mb.intersects(area):
				var ov := mb.intersection(area)
				var t0 := (ov.position - m.transform.origin).dot(m.axis())
				var t1 := (ov.end - m.transform.origin).dot(m.axis())
				_mark(out, m, {"kind": &"spill", "s": float(sp.s), "cause": sp.id, "along": [snappedf(minf(t0, t1), 0.01), snappedf(maxf(t0, t1), 0.01)]})
	# The kit's furniture: the tables' tops, the floor round the chairs, the bar's foot rail.
	var furn: Dictionary = use.get("furniture", {})
	var drinkers: Array = spec.use_points.filter(func(u: Dictionary) -> bool: return u.get("use", "") == furn.get("foot_rail", "-"))
	for k in b.find_children("*", "KitProp", true, false):
		var kp := k as KitProp
		var at := b.to_local(kp.global_position)
		if kp.kit_id == &"card_table" and furn.get("tables", false):
			for m in kp.get_members():
				if String(m.member_id).contains("/top_"):
					for kind in [&"rings", &"elbow", &"cut"]:
						_mark(out, m, {"kind": kind, "s": snappedf(_grow(150.0, years), 0.01), "cause": "cards"})
		elif kp.kit_id == &"chair" and furn.get("chairs", false):
			for f: StructureMember in boards.ground:
				if _xz_distance(f.structure_aabb(), Vector2(at.x, at.z)) < 0.45:
					_mark(out, f, {"kind": &"scuff", "s": 0.5, "cause": "chairs", "at": _local(f, Vector3(at.x, f.structure_aabb().end.y, at.z)), "r": 0.45})
		elif kp.kit_id == &"bar":
			for m in kp.get_members():
				if not String(m.member_id).ends_with("/foot_rail"):
					continue
				for u: Dictionary in drinkers:
					var p := b.to_global(Vector3(u.at[0], u.at[1], u.at[2]))
					var mb := m.world_aabb()
					if mb.grow(0.8).has_point(Vector3(p.x, mb.get_center().y, p.z)):
						var t := (kp.to_local(p) - m.transform.origin).dot(m.axis())
						_mark(out, m, {"kind": &"boot", "s": snappedf(_grow(400.0 / maxf(drinkers.size(), 1), years), 0.01), "cause": u.id, "along": [snappedf(t - 0.25, 0.01), snappedf(t + 0.25, 0.01)]})
	# Weather: mud splashed up the street walls' foot, the sun on the south face and the roof,
	# water off the sills.
	var weather: Dictionary = use.get("weather", {})
	if weather.has("splash"):
		var h := float(weather.splash.height)
		for wid: String in weather.splash.walls:
			for m: StructureMember in own:
				if String(m.member_id).begins_with("%s/%s/siding/" % [b.structure_id, wid]) and m.structure_aabb().position.y < h:
					_mark(out, m, {"kind": &"splash", "s": snappedf(1.0 - m.structure_aabb().position.y / h, 0.01), "cause": "weather", "below": h})
	if weather.has("bleach"):
		for m: StructureMember in own:
			var mid := String(m.member_id)
			var on_wall := false
			for wid: String in weather.bleach.walls:
				if mid.begins_with("%s/%s/siding/" % [b.structure_id, wid]):
					on_wall = true
			if on_wall or (weather.bleach.get("roof", false) and m.kind == &"roof_board"):
				_mark(out, m, {"kind": &"bleach", "s": 0.6, "cause": "weather"})
	if weather.get("streaks", "") == "under_sills":
		for w: Dictionary in spec.walls:
			if w.get("partition", false):
				continue
			var a := Vector3(w.line[0][0], 0, w.line[0][1])
			var e := Vector3(w.line[1][0], 0, w.line[1][1])
			var along := (e - a).normalized()
			for o: Dictionary in w.openings:
				if o.type != "window":
					continue
				var sill := float(lv[o.level].top) + float(o.sill)
				var c := a + along * float(o.at)
				for m: StructureMember in own:
					var mb := m.structure_aabb()
					if not String(m.member_id).begins_with("%s/%s/siding/" % [b.structure_id, w.id]):
						continue
					var w0 := float(o.at) - float(o.width) * 0.5
					var w1 := float(o.at) + float(o.width) * 0.5
					# Under the window (a lap board runs the wall's width: just the stretch below it).
					if mb.end.y <= sill + 0.02 and mb.end.y > sill - 1.3 and (mb.position - a).dot(along) < w1 and (mb.end - a).dot(along) > w0:
						var t0 := (a + along * w0 - m.transform.origin).dot(m.axis())
						var t1 := (a + along * w1 - m.transform.origin).dot(m.axis())
						_mark(out, m, {"kind": &"streak", "s": 0.6, "cause": "weather", "from": snappedf(sill, 0.01),
								"along": [snappedf(minf(t0, t1), 0.01), snappedf(maxf(t0, t1), 0.01)]})
	# The past: each mark on the nearest members of its kinds within its reach.
	var every: Array[StructureMember] = own.duplicate()
	every.append_array(kit)
	for ev: Dictionary in spec.get("past", []):
		for pm: Dictionary in ev.marks:
			var at := b.to_global(Vector3(pm.at[0], pm.at[1], pm.at[2]))
			var r := float(pm.r)
			var kinds: Array = pm.get("kinds", [])
			var hits := 0
			var best: StructureMember = null
			var best_d := INF
			for m in every:
				if not kinds.is_empty() and not kinds.has(String(m.kind)):
					continue
				var d := _distance(m.world_aabb(), at)
				if d <= r:
					var mark := {"kind": StringName(pm.kind), "s": 1.0, "cause": ev.id, "at": _arr(m.to_local(at)), "r": r}
					for f in ["pried", "filled"]:
						if pm.get(f, false):
							mark[f] = true
					_mark(out, m, mark)
					hits += 1
				elif d < best_d:
					best_d = d
					best = m
			if hits == 0:
				(out.unresolved as Array).append("%s: %s at %s (nearest %s %.2f m off)" % [ev.id, pm.kind, pm.at,
						String(best.member_id) if best else "none", best_d])
	return out


## How deep a use's wear has gone: it grows with uses and years, toward 1.
static func _grow(daily: float, years: float) -> float:
	return 1.0 - exp(-daily * years / 800.0)


static func _mark(out: Dictionary, m: StructureMember, mark: Dictionary) -> void:
	var marks: Array = m.get_meta(&"marks", [])
	marks.append(mark)
	m.set_meta(&"marks", marks)
	var c := String(mark.cause)
	out.by_cause[c] = int(out.by_cause.get(c, 0)) + 1
	var k := String(mark.kind)
	out.by_kind[k] = int(out.by_kind.get(k, 0)) + 1


static func _xz_distance(box: AABB, q: Vector2) -> float:
	var dx := maxf(maxf(box.position.x - q.x, 0.0), q.x - box.end.x)
	var dz := maxf(maxf(box.position.z - q.y, 0.0), q.y - box.end.z)
	return sqrt(dx * dx + dz * dz)


static func _distance(box: AABB, p: Vector3) -> float:
	var d := Vector3(maxf(maxf(box.position.x - p.x, 0.0), p.x - box.end.x), maxf(maxf(box.position.y - p.y, 0.0), p.y - box.end.y),
			maxf(maxf(box.position.z - p.z, 0.0), p.z - box.end.z))
	return d.length()


## A point in the structure's space in the member's own, as the marks keep it.
static func _local(m: StructureMember, p: Vector3) -> Array:
	return _arr(m.transform.affine_inverse() * p)


static func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

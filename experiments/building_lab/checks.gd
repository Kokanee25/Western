extends RefCounted
## The building pipeline's checks (docs/briefs/building-pipeline.md "Checks") on a building the
## lab built from its spec: each returns a Dictionary of what it found ("ok", "failures", and its
## numbers), so the test (tests/test_building_lab.gd) and the lab's runner (run.gd) say the same.

## Everything that may collide or draw in a building and isn't a member, a kit prop's member, or a
## fitting's own (an OilLamp's): each with its owner. The destructibility walk allows these and
## nothing else.
const EXCEPTIONS := {
	&"batch": "a structure's batched draw of its untouched members (Structure.batch_meshes; a member leaves it the moment anything happens to it) - gameplay, src/structures/structure.gd",
	&"stair_ramp": "a stair's walking ramp, Layers.WALK only (falling men meet the treads); the builder frees it when the stringers go - gameplay, the Stair part (experiments/building_lab/stair.gd, to be promoted)",
	&"lamp_hitbox": "an OilLamp's hitbox (a ball smashes the lamp) - gameplay, src/world/oil_lamp.gd",
	&"ground": "the ground (here boxes round the cellar's pit) - gameplay, the town's ground",
	&"static_batch": "the dressing's glass props' fixed parts drawn together (StaticBatch; a prop shot or falling is handed back) - #844, src/world/static_batch.gd",
}
## Not things (they neither collide nor draw a surface): allowed, counted.
const NOT_THINGS := "the lamps' lights (OilLamp), the room's light probe and haze (FalseFrontBuilding._add_interior_ambient), use points (Marker3D)"


## The walk: every node under `root` that collides or draws, sorted. "bad" lists any that's
## neither a member's, a kit prop's, a fitting's nor an allowed exception.
static func destructible(root: Node, building: Structure) -> Dictionary:
	var out := {"bad": [], "members": 0, "kit_members": 0, "kit_props": 0, "lamps": 0, "allowed": {}, "not_things": 0,
			"stone": 0, "iron": 0, "glass": 0, "rigs": []}
	_walk(root, building, out)
	out.ok = (out.bad as Array).is_empty() and (out.rigs as Array).is_empty()
	return out


static func _walk(n: Node, building: Structure, out: Dictionary) -> void:
	for c in n.get_children(true):
		if c is GlassProp or c is ClothProp:
			# A kit prop that shatters (a hung lamp, #824) or a cloth (the doctor's towel, #844): its
			# own body and pieces are the prop's, its OilLamp the light it carries.
			out.kit_props += 1
			out.lamps += c.find_children("*", "OilLamp", true, false).size()
			continue
		_sort(c, building, out)
		_walk(c, building, out)


static func _sort(n: Node, building: Structure, out: Dictionary) -> void:
	var allowed: Dictionary = out.allowed
	if n is Structure:
		if not (n as Structure).collapses:
			(out.rigs as Array).append(str(n.get_path()))  # a fixture that holds still whatever happens
		if n is KitProp:
			out.kit_props += 1
		return
	if n is OilLamp:
		out.lamps += 1
		return
	if n is CollisionObject3D:
		if n is StructureMember:
			var m := n as StructureMember
			if m.get_parent() is KitProp:
				out.kit_members += 1
			elif m.get_parent() == building:
				out.members += 1
			else:
				(out.bad as Array).append("%s: a member of a structure that isn't the building or a kit prop" % n.get_path())
			if m.wood in [&"stone", &"iron", &"glass"]:
				out[String(m.wood)] += 1
		elif n.has_meta(&"oil_lamp"):
			allowed[&"lamp_hitbox"] = int(allowed.get(&"lamp_hitbox", 0)) + 1
		elif n.is_in_group(&"ground"):
			allowed[&"ground"] = int(allowed.get(&"ground", 0)) + 1
		elif n.has_meta(&"stair") and (n as CollisionObject3D).collision_layer == Layers.WALK:
			allowed[&"stair_ramp"] = int(allowed.get(&"stair_ramp", 0)) + 1
		else:
			(out.bad as Array).append("%s: a %s that collides and isn't a member" % [n.get_path(), n.get_class()])
		return
	if n is GeometryInstance3D:
		# A member's own mesh (and what's drawn on it: a painted sign, a voxel member's inside), a
		# lamp's own, or a structure's batch.
		var p := n.get_parent()
		while p != null and p != building.get_parent():
			if p is StructureMember or p is OilLamp:
				return
			p = p.get_parent()
		if n.get_parent() is StaticBatch:
			allowed[&"static_batch"] = int(allowed.get(&"static_batch", 0)) + 1
			return
		if n.get_parent() is Structure and _internal(n):
			allowed[&"batch"] = int(allowed.get(&"batch", 0)) + 1
			return
		(out.bad as Array).append("%s: a %s drawn that isn't a member's, a fitting's or a batch" % [n.get_path(), n.get_class()])
		return
	if n is VisualInstance3D or n is Marker3D:
		out.not_things += 1


static func _internal(n: Node) -> bool:
	var parent := n.get_parent()
	for c in parent.get_children(false):
		if c == n:
			return false
	return true


## It stands: a load path for every member and none over its limit, under its own weight and then
## with the floors loaded as the period's codes and handbooks load them (a crowd), with what fails.
static func stands(b: Structure, crowd := 1915.0, balcony := 2873.0) -> Dictionary:
	var out := {}
	var falling := b.members_without_load_path()
	var a := StructuralAnalysis.new().analyse(b)
	out.dead = {"falling": falling.size(), "over": a.overloaded().size(), "worst": _worst(a, 8),
		"falling_first": falling.slice(0, 12).map(func(m: Variant) -> String: return String(m.member_id if m is StructureMember else m).get_slice("/", 1) + "/" + String(m.member_id if m is StructureMember else m).get_slice("/", 2))}
	# A crowd on every floor board (40 lb/ft2), 60 on the balcony and galleries (people pressing
	# to the rail).
	var before := {}
	for m in b.get_members():
		if m.kind == &"floor_board" or (m.kind == &"furniture_top" and String(m.member_id).contains("/stair/")):
			before[m] = m.extra_load
			var q := crowd
			var id := String(m.member_id)
			if id.contains("/floor/street") or id.contains("/floor/front_gallery") or id.contains("/floor/east_gallery"):
				q = balcony
			var plan := m.size.x * m.size.z
			m.extra_load += q * plan
	var u := StructuralAnalysis.new().analyse(b)
	out.crowd = {"over": u.overloaded().size(), "worst": _worst(u, 12)}
	for m: StructureMember in before:
		m.extra_load = before[m]
	out.ok = falling.is_empty() and a.overloaded().is_empty()
	out.ok_crowd = u.overloaded().is_empty()
	return out


static func _worst(a: StructuralAnalysis, n: int) -> Array:
	var ids: Array = a.utilisation.keys()
	ids.sort_custom(func(x: StringName, y: StringName) -> bool: return a.utilisation[x] > a.utilisation[y])
	var out := []
	for id: StringName in ids.slice(0, n):
		out.append([String(id).get_slice("/", 1) + "/" + String(id).trim_prefix(String(id).get_slice("/", 0) + "/" + String(id).get_slice("/", 1) + "/"),
				snappedf(a.utilisation[id], 0.01), String(a.mode[id])])
	return out


## It falls right (by the rules, no physics): knock out each post in turn and see what loses its
## load path and what's over its limit with it gone. "floats" lists any that would still stand
## with nothing under it (there can't be any: a member without a load path is what falls).
static func knockouts(b: Structure, ids: Array) -> Array:
	var out := []
	for id: StringName in ids:
		var gone := {id: true}
		var falling := b.members_without_load_path(gone)
		var a := StructuralAnalysis.new().analyse(b, gone)
		var over := a.overloaded()
		out.append({"post": String(id), "falls": falling.size(), "over": over.size(), "over_first": over.slice(0, 4).map(func(x: StringName) -> String: return String(x).trim_prefix("saloon_spec/"))})
	return out


## People fit: each door's clear opening and head room, each stair's head room along its walking
## line, and each use point on a floor (not a step, not in a doorway) with room to stand.
static func people_fit(b: Structure, spec: Dictionary) -> Dictionary:
	var failures := []
	var space := World.space(b)
	var lv: Dictionary = spec.levels
	var doors := []
	for w: Dictionary in spec.walls:
		var line: Array = w.line
		var a := Vector3(line[0][0], 0, line[0][1])
		var e := Vector3(line[1][0], 0, line[1][1])
		var along := (e - a).normalized()
		for o: Dictionary in w.get("openings", []):
			if not (o.type in ["door", "batwings"]):
				continue
			var lvl: String = o.get("level", w.get("level", "ground"))
			var y0 := float(lv[lvl].top)
			if float(o.width) < 0.76 or float(o.height) < 1.98:
				failures.append("%s door at %.2f: %.2f x %.2f m, less than 0.76 x 1.98" % [w.id, o.at, o.width, o.height])
			var c := a + along * float(o.at)
			var mid := Vector3(c.x, y0 + float(o.height) * 0.5 + 0.02, c.z)
			if not w.get("partition", false):
				mid -= _axis(String(w.out)) * 0.05
			doors.append({"at": mid, "wall": w.id, "lvl": lvl})
			# A man through it: a box 0.6 wide, 1.9 tall, across the wall's thickness.
			var box := BoxShape3D.new()
			box.size = along.abs() * 0.6 + Vector3.UP * 1.9 + Vector3(along.z, 0, along.x).abs() * 0.16
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = box
			q.transform = Transform3D(Basis(), b.to_global(Vector3(mid.x, y0 + 0.97, mid.z)))
			q.collision_mask = Layers.WORLD
			for hit in space.intersect_shape(q, 8):
				var m := hit.collider as StructureMember
				if m and m.kind != &"door":
					failures.append("%s door at %.2f: %s in the way" % [w.id, o.at, String(m.member_id).trim_prefix("saloon_spec/")])
			# And its way in either side (#844: the kitchen chimney stood in the kitchen side of the hall's
			# door): 0.45 m beyond each face, 0.6 wide, from a tread over the floor; nothing but a leaf.
			var across := Vector3(along.z, 0, along.x).abs()
			var normal := Vector3(-along.z, 0, along.x)
			for side: float in [-1.0, 1.0]:
				var way := BoxShape3D.new()
				way.size = along.abs() * 0.6 + Vector3.UP * 1.8 + across * 0.45
				var wq := PhysicsShapeQueryParameters3D.new()
				wq.shape = way
				wq.transform = Transform3D(Basis(), b.to_global(Vector3(mid.x, y0 + 1.0, mid.z) + normal * side * 0.325))
				wq.collision_mask = Layers.WORLD
				for hit in space.intersect_shape(wq, 8):
					var m := hit.collider as StructureMember
					# (a ladder up to a door is its way in: the doctor's loft door; a gate opens like a door:
					# the jail's cell-corridor grille inside its back door)
					if m and m.kind != &"door" and not String(m.member_id).contains("/ladder/") \
							and not String(m.member_id).contains("/gate/"):
						failures.append("%s door at %.2f: %s in its way in" % [w.id, o.at, String(m.member_id).trim_prefix("saloon_spec/")])
	# Stairs: two metres over the nosings all the way up.
	var stairs := 0
	for ramp in b.find_children("Ramp_*", "StaticBody3D", false, false):
		stairs += 1
		var r := ramp as StaticBody3D
		var shape := (r.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var tr := r.transform
		for k in 9:
			var t := (k + 0.5) / 9.0 - 0.5
			var p := tr * Vector3(shape.size.x * t, 0.03, 0.0)
			var q := PhysicsRayQueryParameters3D.create(b.to_global(p + Vector3.UP * 0.25), b.to_global(p + Vector3.UP * 2.0), Layers.WORLD)
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				var m := hit.collider as StructureMember
				var who := String(m.member_id).trim_prefix("saloon_spec/") if m else str(hit.collider)
				if not who.begins_with("stair/%s" % String(r.get_meta(&"stair")).trim_prefix("stair/")):
					failures.append("%s: head room %.2f m at %.0f%% up (%s)" % [r.get_meta(&"stair"), (hit.position as Vector3).y - b.to_global(p).y, (t + 0.5) * 100.0, who])
	# Use points: a floor under each, room for a man, not on a step or in a doorway.
	var points := 0
	for u in b.find_children("*", "Marker3D", true, false):
		points += 1
		var at := (u as Marker3D).position
		# What's under his feet (a little box, not a ray: boards have 4 mm gaps).
		var foot := BoxShape3D.new()
		foot.size = Vector3(0.24, 0.04, 0.24)
		var fq := PhysicsShapeQueryParameters3D.new()
		fq.shape = foot
		fq.transform = Transform3D(Basis(), b.to_global(at + Vector3.DOWN * 0.03))
		fq.collision_mask = Layers.WORLD
		var under := space.intersect_shape(fq, 4)
		if under.is_empty():
			failures.append("%s: nothing under it" % u.name)
			continue
		var on := []
		var floored := false
		for h in under:
			var fm := h.collider as StructureMember
			on.append(String(fm.member_id).trim_prefix("saloon_spec/") if fm else str(h.collider))
			if fm and fm.kind in [&"floor_board", &"sill"]:
				floored = true
		if not floored:
			failures.append("%s: stands on %s" % [u.name, on])
		for d: Dictionary in doors:
			if (d.at as Vector3).distance_to(Vector3(at.x, (d.at as Vector3).y, at.z)) < 0.6 and absf(at.y - float(lv[d.lvl].top)) < 0.2:
				failures.append("%s: in the %s doorway" % [u.name, d.wall])
		var cap := CapsuleShape3D.new()
		cap.radius = 0.22
		cap.height = 1.7
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis(), b.to_global(at + Vector3.UP * 0.92))
		q.collision_mask = Layers.WORLD
		# A point on furniture (a bed, the table, his chair: `prop`, #844) leaves that prop out; it
		# must be there.
		var on_prop := StringName(u.get_meta(&"prop", &""))
		if on_prop != &"" and not b.find_children("*", "KitProp", true, false).any(func(k: Node) -> bool: return (k as KitProp).structure_id == on_prop):
			failures.append("%s: its %s isn't there" % [u.name, on_prop])
		for h in space.intersect_shape(q, 8):
			var m := h.collider as StructureMember
			if m and on_prop != &"" and m.get_parent() is KitProp and (m.get_parent() as KitProp).structure_id == on_prop:
				continue
			failures.append("%s: no room (%s)" % [u.name, String(m.member_id).trim_prefix("saloon_spec/") if m else str(h.collider)])
	return {"ok": failures.is_empty(), "failures": failures, "doors": doors.size(), "stairs": stairs, "use_points": points}


## It's used: each room has use points for the people who'd be there, and the barman's are behind
## the bar.
static func used(b: Structure, spec: Dictionary) -> Dictionary:
	var failures := []
	var markers := b.find_children("*", "Marker3D", true, false)
	var seats := 0
	for k in b.find_children("*", "KitProp", true, false):
		if (k as KitProp).definition.has("seat"):
			seats += 1
	for r: Dictionary in spec.rooms:
		var rr: Array = r.rect
		var lvl: String = r.level
		var y := float(spec.levels[lvl].top) if spec.levels[lvl].has("top") else float(spec.levels[lvl].floor)
		var n := 0
		for m in markers:
			var p := (m as Marker3D).position
			if p.x >= float(rr[0]) and p.x <= float(rr[2]) and p.z >= float(rr[1]) and p.z <= float(rr[3]) and absf(p.y - y) < 0.2:
				n += 1
		if n == 0 and not (r.id == "hall" and seats > 0):
			failures.append("%s (%s): no use point" % [r.id, r.use])
	# Between the bar and the back bar (across them: their sections face the same way).
	var bar_at := Vector2.ZERO
	var back_at := Vector2.ZERO
	for f: Dictionary in spec.fixtures:
		if f.kit == "bar":
			bar_at = Vector2(f.at[0], f.at[1])
		elif f.kit == "back_bar":
			back_at = Vector2(f.at[0], f.at[1])
	var lo := minf(bar_at.x, back_at.x)
	var hi := maxf(bar_at.x, back_at.x)
	for m in markers:
		if m.get_meta(&"who") == "barman" and m.get_meta(&"use") == "serve":
			var p := (m as Marker3D).position
			if p.x < lo or p.x > hi:
				failures.append("%s: not between the bar and the back bar" % m.name)
	return {"ok": failures.is_empty(), "failures": failures, "seats": seats, "use_points": markers.size()}


## What it costs to draw: its batches and the meshes drawn on their own.
static func draw_calls(root: Node) -> Dictionary:
	var batches := 0
	var own := 0
	var lamps := 0
	var lights := 0
	for n in _all(root):
		if n is GeometryInstance3D and (n as GeometryInstance3D).is_visible_in_tree():
			var g := n as GeometryInstance3D
			if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
				continue
			if g.get_parent() is Structure:
				batches += 1
			elif _under(g, "OilLamp"):
				lamps += 1
			else:
				own += 1
		elif n is OmniLight3D:
			lights += 1
	return {"batches": batches, "own_meshes": own, "lamp_meshes": lamps, "lights": lights, "total": batches + own + lamps}


static func _all(n: Node, out: Array = []) -> Array:
	for c in n.get_children(true):
		out.append(c)
		_all(c, out)
	return out


static func _under(n: Node, cls: String) -> bool:
	var p := n.get_parent()
	while p:
		if p.is_class(cls) or (p.get_script() and p is OilLamp and cls == "OilLamp"):
			return true
		p = p.get_parent()
	return false


static func _axis(n: String) -> Vector3:
	var v := {"x": Vector3.RIGHT, "y": Vector3.UP, "z": Vector3.BACK}[n.trim_prefix("-").trim_prefix("+")] as Vector3
	return -v if n.begins_with("-") else v


## Built right (#695, Sean 2026-11-07: "windows aren't being blocked by studs or boards"): through
## every opening in every wall, from the siding's face outside to the finish's face inside, nothing
## but its glass and its door's leaf; every opening in an outer wall framed (a king stud each side,
## a header over it, a rough sill under a window) and glazed if it's a window, so what's a window
## outside is a window inside. A member's box is tested by its long edges and its middle line (a
## rafter is tilted: its box is not its bounds).
static func built_right(b: Node, spec: Dictionary) -> Dictionary:
	var failures := []
	var sid := String(b.structure_id) + "/"
	var lv: Dictionary = b._lv
	var by_id := {}
	for m: StructureMember in b.get_members():
		by_id[String(m.member_id).trim_prefix(sid)] = m
	var openings := 0
	var framed := 0
	for w: Dictionary in spec.walls:
		var wl: Dictionary = b.walls.get(w.id, {})
		if wl.is_empty():
			failures.append("%s: not built" % w.id)
			continue
		var wall: Dictionary = wl.dict
		var partition: bool = w.get("partition", false)
		var origin: Vector3 = wall.origin
		var along: Vector3 = wall.along
		var out: Vector3 = wall.out
		# Through the wall: an outer wall from the siding's face to its inside finish's; a partition both faces.
		var d0 := -0.1 - 0.025 if not partition else -0.075
		var d1 := 0.025 + 0.01 if not partition else 0.075
		var stone: bool = w.get("stone", false)
		if stone:
			# A stone wall (#780): from its outer face (its line) through its thickness at a man's height.
			var t := 0.56
			for p: Array in w.get("profile", []):
				if float(p[0]) <= float(lv.ground) + 1.0:
					t = -float(p[1])
			d0 = -t + 0.012
			d1 = -0.012
		var j := 0
		for o: Dictionary in w.get("openings", []):
			if o.type == "void":
				j += 1
				continue  # a cut corner: open by design, its column and beams its frame (saloon B)
			openings += 1
			var lvl: String = o.get("level", w.get("level", "ground"))
			var y0 := float(lv[lvl]) + float(o.get("sill", 0.0))
			var s0 := float(o.at) - float(o.width) * 0.5
			var s1 := float(o.at) + float(o.width) * 0.5
			var pts := [origin + along * (s0 + 0.012) + out * d0 + Vector3.UP * (y0 + 0.012),
				origin + along * (s1 - 0.012) + out * d1 + Vector3.UP * (y0 + float(o.height) - 0.012)]
			var lo: Vector3 = (pts[0] as Vector3).min(pts[1])
			var hi: Vector3 = (pts[0] as Vector3).max(pts[1])
			var clear := AABB(lo, hi - lo)
			for id: String in by_id:
				var m: StructureMember = by_id[id]
				if m.kind in [&"glass", &"door"] or id.contains("/transom_bar_") or id.contains("/window_") or id.contains("/bars_"):
					continue  # its glass, its leaf, a door's transom bar, its sash window and lining, its bars
				if not m.structure_aabb().intersects(clear):
					continue
				if _crosses(m, clear):
					failures.append("%s %s at %.2f: %s across it" % [w.id, o.type, float(o.at), id])
			if not partition:
				var pre := "%s/opening%d/" % [w.id, j]
				var ok := by_id.has(pre + "king0") and by_id.has(pre + "king1") and by_id.has(pre + "header")
				if stone:
					ok = by_id.has(pre + "lintel")  # a stone wall's opening: its lintel (and a window's sill)
				if o.type == "window" and y0 > float(lv[lvl]) + 0.4:
					ok = ok and by_id.has(pre + "sill")
				if ok:
					framed += 1
				else:
					failures.append("%s %s at %.2f: not framed (%s%s)" % [w.id, o.type, float(o.at), "lintel" if stone else "kings, header", ", sill" if o.type == "window" else ""])
				if o.type == "window" and o.get("glass", true):
					var glazed := false
					for id: String in by_id:
						var gm: StructureMember = by_id[id]
						if gm.kind == &"glass" and clear.grow(0.02).has_point(gm.transform.origin):
							glazed = true
					if not glazed:
						failures.append("%s window at %.2f: no glass" % [w.id, float(o.at)])
					# A sash window (#826): its lights built, a pane each, and its reveal lined.
					if o.has("lights"):
						var panes := 0
						var linings := 0
						for id: String in by_id:
							if not id.begins_with(w.id + "/window_"):
								continue
							var wm: StructureMember = by_id[id]
							if not clear.grow(0.03).has_point(wm.transform.origin):
								continue
							if wm.kind == &"glass":
								panes += 1
							elif id.contains("/lining_"):
								linings += 1
						if panes != int(o.lights):
							failures.append("%s window at %.2f: %d panes for %d lights" % [w.id, float(o.at), panes, int(o.lights)])
						if linings < 4:
							failures.append("%s window at %.2f: its reveal open (%d linings of 4)" % [w.id, float(o.at), linings])
			j += 1
	return {"ok": failures.is_empty(), "failures": failures, "openings": openings, "framed": framed}


## Whether a member (an oriented box) passes through `clear`: its middle line and its four long edges.
static func _crosses(m: StructureMember, clear: AABB) -> bool:
	var t := m.transform
	var h := m.size * 0.5
	var ax := 0
	if h.y > h[ax]:
		ax = 1
	if h.z > h[ax]:
		ax = 2
	var u := Vector3.ZERO
	u[ax] = h[ax]
	var others := [0, 1, 2]
	others.erase(ax)
	var a: int = others[0]
	var c: int = others[1]
	var offs := [Vector3.ZERO]
	for sa in [-1.0, 1.0]:
		for sc in [-1.0, 1.0]:
			var v := Vector3.ZERO
			v[a] = h[a] * sa * 0.98
			v[c] = h[c] * sc * 0.98
			offs.append(v)
	for off: Vector3 in offs:
		var p0 := t * (off - u)
		var p1 := t * (off + u)
		if clear.has_point(p0) or clear.has_point(p1) or clear.intersects_segment(p0, p1):
			return true
	return false


## Every member as data (the X-ray sheet's: tools/buildings/xray.py): id, kind, wood, its box's
## centre, axes (columns of its basis) and size, in the structure's space.
static func export_members(b: Structure, path: String) -> int:
	var out := []
	var sid := String(b.structure_id) + "/"
	for m: StructureMember in b.get_members():
		var t := m.transform
		out.append({"id": String(m.member_id).trim_prefix(sid), "kind": String(m.kind), "wood": String(m.wood),
			"c": [t.origin.x, t.origin.y, t.origin.z], "x": [t.basis.x.x, t.basis.x.y, t.basis.x.z],
			"y": [t.basis.y.x, t.basis.y.y, t.basis.y.z], "z": [t.basis.z.x, t.basis.z.y, t.basis.z.z],
			"s": [m.size.x, m.size.y, m.size.z]})
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"structure": String(b.structure_id), "members": out}))
	f.close()
	return out.size()

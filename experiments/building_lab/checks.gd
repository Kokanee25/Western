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
	out.dead = {"falling": falling.size(), "over": a.overloaded().size(), "worst": _worst(a, 8)}
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
	var space := b.get_world_3d().direct_space_state
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
		for h in space.intersect_shape(q, 4):
			var m := h.collider as StructureMember
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

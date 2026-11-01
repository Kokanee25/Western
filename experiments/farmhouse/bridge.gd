extends BridgeLab
## The farmhouse (issue #520): its walls for the breach check, and the hole a blast leaves.
##
##   farm_wall front        -> where to stand outside the front wall to plant chest high, and look
##   farm_hole front        -> the clear height through that wall now (a man walks through at 1.7)

const HELP := {
	"farm_wall": "farm_wall WALL -> where to stand 0.9 m outside that wall (front, west, east, back, lean_back, lean_west, lean_east) and the chest-high point to look at",
	"farm_hole": "farm_hole WALL -> the clear height through that wall at its breach spot (0 if none): a 0.4 x 0.5 m box from the floor up, slid 0.5 m either way",
	"farm_view": "farm_view NAME -> where to stand and look for a contact sheet view (closer, corner, back, front_room, front_room_back, bedroom, kitchen, loft)",
	"farm_start": "farm_start [here] -> start the farmhouse mission (the men at their posts, the rancher tied), you at the edge of town (here: where you are)",
	"farm_state": "farm_state -> the mission: its state, the alarm, threat, rescue and end times, each man",
	"farm_free": "farm_free -> cut the rancher loose (as E held by him does)",
	"farm_fail": "farm_fail -> lose it now (to try the way back in: Enter starts it again)",
	"farm_hide": "farm_hide [wall=lean_back] [x=-6,15] [z=5,22] [step=0.5] [doorway=1] [spots=X,Z;X,Z] -> where to hide from a stick planted chest high on that wall: a map of the yard (seen from an opening, hidden, hidden and clear of the blast) and each spot's detail",
	"farm_blast": "farm_blast WALL [along=M] [wait=S] [none=1] -> the mission started (you left where you are), a stick planted chest high on that wall's breach spot (slid along it M) as you'd plant it, set off; after S s (8): the rancher (hits, awake), the loft's broken members, each man",
	"farm_run": "farm_run front|breach|back seed=N [max=S] [aim=DEG] [out=FILE] -> one scripted run: the mission started and the scripted player in that way, till it's won or lost",
}

## Each wall's breach spot in the house's own space (FORMAT.md): a point on its outer face in a
## stretch with no opening, and the way out. "west" and "east" are as built: turned round to face
## the road, the house's west is the world's east.
const WALLS := {
	"front": [Vector3(7.3, 0.0, 0.0), Vector3(0, 0, -1)],
	"west": [Vector3(0.0, 0.0, 1.2), Vector3(-1, 0, 0)],
	"east": [Vector3(9.0, 0.0, 4.0), Vector3(1, 0, 0)],
	"back": [Vector3(7.3, 0.0, 5.2), Vector3(0, 0, 1)],
	"lean_back": [Vector3(2.9, 0.0, 7.6), Vector3(0, 0, 1)],
	"lean_west": [Vector3(0.0, 0.0, 6.4), Vector3(-1, 0, 0)],
	"lean_east": [Vector3(5.6, 0.0, 6.4), Vector3(1, 0, 0)],
}
const TALLS := [0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]


func _cmd_farm_wall(a: Array) -> Dictionary:
	var w: Array = WALLS.get(String(a[0]) if a.size() > 0 else "", [])
	if w.is_empty():
		return {"ok": false, "error": "no wall %s (%s)" % [a, WALLS.keys()]}
	var on: Vector3 = w[0]
	var out: Vector3 = w[1]
	var stand := Farmhouse.on_ground(on.x + out.x * 0.9, on.z + out.z * 0.9)
	# Chest high on the wall from where he stands (the planting check's chest-high aim: 1.2 m up).
	var look := Farmhouse.at(Vector3(on.x, 0.0, on.z))
	look.y = stand.y + 1.2
	return {"stand": arr(stand), "look": arr(look)}


func _cmd_farm_hole(a: Array) -> Dictionary:
	var w: Array = WALLS.get(String(a[0]) if a.size() > 0 else "", [])
	if w.is_empty():
		return {"ok": false, "error": "no wall %s" % [a]}
	await physics_frames(1)
	var house := Farmhouse.of(get_tree())
	var space := World.space(house)
	var on: Vector3 = w[0]
	var out: Vector3 = w[1]
	var along := Vector3(absf(out.z), 0.0, absf(out.x))
	var clear := 0.0
	var base := Farmhouse.FLOOR + 0.07
	for tall: float in TALLS:
		var q := PhysicsShapeQueryParameters3D.new()
		var box := BoxShape3D.new()
		# Across the wall 0.4 m, along it 0.5 m.
		box.size = Vector3(0.4, tall, 0.5) if out.x == 0.0 else Vector3(0.4, tall, 0.5)
		q.shape = box
		q.collision_mask = Layers.WORLD
		var through := false
		for k in range(-10, 11):
			var c := on + along * (k * 0.05) + Vector3.UP * (base + tall * 0.5)
			var basis := Basis.IDENTITY if out.x != 0.0 else Basis(Vector3.UP, PI * 0.5)
			q.transform = house.global_transform * Transform3D(basis, c)
			var standing := space.intersect_shape(q, 8).filter(func(h: Dictionary) -> bool: return not h.collider is RigidBody3D)
			if standing.is_empty():
				through = true
				break
		if through:
			clear = tall
	return {"wall": a[0], "clear": clear, "walk": clear >= 1.7, "stoop": clear >= 1.3}


## Where to hide from a stick on a wall (issue #537): a crouched man (eyes 1.15 m up, his body 0.9)
## at each spot of the yard, looked for from every window and door of the house (a man 0.3 and
## 0.9 m inside it, at its sides and middle, crouched and standing; `doorway=1`, a man standing in
## each doorway too: he's as good as out in the yard and sees along the wall), the gang's
## own sight line (Sight.clear). And the stick's harm there: the head's distance from it and
## whether a standing wall is between (Blast.shielding). The map's rows run from the far yard to
## the house, x along: '#' something solid, 'H' the house, '.' seen, 'o' hidden but in the blast's
## harm (an eardrum within 5 m in the open, within 3.2 m behind a wall), '+' hidden and clear.
func _cmd_farm_hide(a: Array) -> Dictionary:
	var opts := {}
	for w in a:
		var kv := String(w).split("=")
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var wall: Array = WALLS.get(String(opts.get("wall", "lean_back")), [])
	if wall.is_empty():
		return {"ok": false, "error": "no wall %s" % opts.get("wall")}
	await physics_frames(1)
	var house := Farmhouse.of(get_tree())
	var space := World.space(house)
	var on: Vector3 = wall[0]
	var out: Vector3 = wall[1]
	var stick := Farmhouse.on_ground(on.x + out.x * 0.9, on.z + out.z * 0.9)
	stick = Farmhouse.at(Vector3(on.x + out.x * 0.05, 0.0, on.z + out.z * 0.05)) * Vector3(1, 0, 1) + Vector3.UP * (stick.y + 1.2)
	var eyes := _opening_eyes(opts.get("doorway", "0") == "1")
	var xs := String(opts.get("x", "-6,15")).split(",")
	var zs := String(opts.get("z", "5,22")).split(",")
	var step := float(opts.get("step", "0.5"))
	var rows: Array[String] = []
	var clear_spots: Array = []
	var z := float(zs[1])
	while z >= float(zs[0]) - 0.001:
		var row := ""
		var x := float(xs[0])
		while x <= float(xs[1]) + 0.001:
			var r := _hide_at(space, eyes, stick, x, z)
			row += r.mark
			if r.mark == "+":
				clear_spots.append([x, z, r.dist])
			x += step
		rows.append("%5.1f %s" % [z, row])
		z -= step
	clear_spots.sort_custom(func(p: Array, q: Array) -> bool: return p[2] < q[2])
	var detail := {}
	for sp in String(opts.get("spots", "")).split(";", false):
		var xz := sp.split(",")
		detail[sp] = _hide_at(space, eyes, stick, float(xz[0]), float(xz[1]))
	return {"wall": opts.get("wall", "lean_back"), "stick": arr(Farmhouse.origin().affine_inverse() * stick), "x": xs, "step": step,
			"map": rows, "nearest_clear": clear_spots.slice(0, 12), "spots": detail}


## Every opening's eyes (the spec's walls with a way out): [{id, eyes: Array[Vector3]}] in the world.
func _opening_eyes(doorway := false) -> Array:
	var spec: Dictionary = load("res://experiments/building_lab/spec_building.gd").load_spec(Farmhouse.SPEC)
	var outs := {"-z": Vector3(0, 0, -1), "+z": Vector3(0, 0, 1), "-x": Vector3(-1, 0, 0), "+x": Vector3(1, 0, 0)}
	var levels := {"ground": Farmhouse.FLOOR, "upper": 3.11}
	var res: Array = []
	for w: Dictionary in spec.walls:
		if not outs.has(String(w.get("out", ""))):
			continue
		var p0 := Vector3(w.line[0][0], 0.0, w.line[0][1])
		var p1 := Vector3(w.line[1][0], 0.0, w.line[1][1])
		var along := (p1 - p0).normalized()
		var n: Vector3 = outs[w.out]
		for o: Dictionary in w.get("openings", []):
			var floor_y: float = levels.get(String(o.get("level", "ground")), Farmhouse.FLOOR)
			var c := p0 + along * float(o.at)
			var pts: Array[Vector3] = []
			var depths := [0.3, 0.9] + ([0.0] if o.type == "door" and doorway else [])
			for depth: float in depths:
				for side in [-0.35, 0.0, 0.35]:
					for h in [1.1, 1.6]:
						pts.append(Farmhouse.at(c + along * float(o.width) * side - n * depth + Vector3.UP * (floor_y + h)))
			res.append({"id": "%s_%s_%s" % [w.id, o.type, o.at], "eyes": pts})
	return res


func _hide_at(space: PhysicsDirectSpaceState3D, eyes: Array, stick: Vector3, x: float, z: float) -> Dictionary:
	if not FarmhouseMission.clear_of_house(Farmhouse.at(Vector3(x, 0.0, z)), 0.25):
		return {"mark": "H"}
	var g := Farmhouse.on_ground(x, z)
	var pq := PhysicsShapeQueryParameters3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.25
	pq.shape = sph
	pq.collision_mask = Layers.WORLD
	pq.transform = Transform3D(Basis(), g + Vector3.UP * 0.9)
	if not space.intersect_shape(pq, 1).is_empty():
		return {"mark": "#"}
	var seen_by: Array = []
	for o: Dictionary in eyes:
		for e: Vector3 in o.eyes:
			if Sight.clear(space, e, g + Vector3.UP * 1.15) or Sight.clear(space, e, g + Vector3.UP * 0.9):
				seen_by.append(o.id)
				break
	var head := g + Vector3.UP * 1.15
	var dist := head.distance_to(stick)
	var shield := Blast.shielding(Farmhouse.of(get_tree()).get_parent() as Node3D, stick, g + Vector3.UP * 1.0)
	var harmed := dist < (3.2 if shield < 1.0 else 5.0)
	var mark := "." if not seen_by.is_empty() else ("o" if harmed else "+")
	return {"mark": mark, "seen_by": seen_by, "dist": snappedf(dist, 0.01), "shielded": shield < 1.0}


## Which wall to blow (issue #537): what one stick on it does to the house and the men in it, before
## any alarm (the surprise). The stick as the player sets it (DynamiteViewmodel.plant_spot from 0.9 m
## out, chest high), its fuse 0.1 s.
func _cmd_farm_blast(a: Array) -> Dictionary:
	var opts := {}
	for w in a.slice(1):
		var kv := String(w).split("=")
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var wall: Array = WALLS.get(String(a[0]) if a.size() > 0 else "", [])
	var m := _mission()
	if wall.is_empty() or m == null:
		return {"ok": false, "error": "no wall %s or no mission" % [a]}
	if m.state != FarmhouseMission.State.ON:
		m.begin(false)
		await seconds(3.0)
	var on: Vector3 = wall[0]
	var out: Vector3 = wall[1]
	var along := Vector3(absf(out.z), 0.0, absf(out.x)) * float(opts.get("along", "0"))
	var stand := Farmhouse.on_ground(on.x + along.x + out.x * 0.9, on.z + along.z + out.z * 0.9)
	var to := Farmhouse.at(Vector3(on.x + along.x, 0.0, on.z + along.z))
	to.y = stand.y + 1.2
	var eye := stand + Vector3.UP * 1.6
	var house := Farmhouse.of(get_tree())
	var spot := DynamiteViewmodel.plant_spot(World.space(house), eye, (to - eye).normalized(), 2.2, [player.get_rid()])
	if spot.is_empty():
		return {"ok": false, "error": "no wall in reach"}
	var hits := []
	var on_hit := func(info: Dictionary) -> void: hits.append([snappedf(m.t, 0.01), String(info.get("kind", "")), String(info.get("part", ""))])
	m.hostage.hit.connect(on_hit)
	if opts.get("none", "0") != "1":  # none=1: the same wait without the stick (what happens anyway)
		var s := DynamiteStick.make(house.get_parent(), spot.at, Vector3.ZERO, 0.1)
		s.owner_node = player
		s.global_basis = spot.basis
		s.stick_to(spot.collider)
		s.light()
	var t0 := m.t
	await seconds(float(opts.get("wait", "8")))
	m.hostage.hit.disconnect(on_hit)
	var broken := 0
	var loft := 0
	var kinds := {}
	for mem in house.building.get_members():
		if mem.broken:
			broken += 1
			if String(mem.member_id).contains("loft"):
				loft += 1
			var parts := String(mem.member_id).split("/")
			var k := "/".join(parts.slice(1, 3)) if parts.size() > 2 else String(mem.member_id)
			k = k.rstrip("0123456789_")
			kinds[k] = kinds.get(k, 0) + 1
	var r := m.result()
	r.timeline = r.timeline.filter(func(e: Array) -> bool: return e[0] >= t0 - 0.01)
	var h := m.hostage
	return {"wall": a[0], "along": opts.get("along", "0"), "stick": arr(Farmhouse.origin().affine_inverse() * spot.at),
			"rancher": {"alive": h.physiology.alive, "awake": h.physiology.is_conscious(), "limp": h.limp, "hits": hits.size(),
				"how": h.physiology.describe(), "first_hits": hits.slice(0, 6)},
			"broken": broken, "loft_broken": loft, "broken_kinds": kinds, "alarm": r.alarm, "surprise": r.surprise, "men": r.men_state, "timeline": r.timeline}


## The contact sheet's views (the house's own space: where you stand, feet; what you look at).
const VIEWS := {
	"closer": [Vector3(2.0, 0.0, -9.0), Vector3(4.5, 2.4, 2.6)],
	"corner": [Vector3(13.0, 0.0, -6.0), Vector3(4.5, 2.0, 3.0)],
	"back": [Vector3(3.0, 0.0, 14.0), Vector3(4.0, 2.0, 5.0)],
	"front_room": [Vector3(4.6, Farmhouse.FLOOR, 0.6), Vector3(0.8, 1.2, 4.2)],
	"front_room_back": [Vector3(0.6, Farmhouse.FLOOR, 4.5), Vector3(4.0, 1.4, 0.4)],
	"bedroom": [Vector3(6.0, Farmhouse.FLOOR, 0.5), Vector3(8.5, 0.9, 4.4)],
	"kitchen": [Vector3(0.6, Farmhouse.FLOOR, 5.5), Vector3(4.6, 1.3, 7.4)],
	"loft": [Vector3(1.2, Farmhouse.LOFT, 4.5), Vector3(6.5, Farmhouse.LOFT + 0.9, 1.0)],
}


func _cmd_farm_view(a: Array) -> Dictionary:
	var v: Array = VIEWS.get(String(a[0]) if a.size() > 0 else "", [])
	if v.is_empty():
		return {"ok": false, "error": "no view %s (%s)" % [a, VIEWS.keys()]}
	var s: Vector3 = v[0]
	var stand := Farmhouse.on_ground(s.x, s.z) if s.y < 0.05 else Farmhouse.at(s)
	var lk: Vector3 = v[1]
	var look := Farmhouse.at(Vector3(lk.x, 0.0, lk.z))
	look.y = Farmhouse.origin().origin.y + lk.y if s.y >= 0.05 else stand.y + lk.y
	return {"stand": arr(stand), "look": arr(look)}


# --- The mission (steps 2-5) ---------------------------------------------------------------------

const FarmBot := preload("res://experiments/farmhouse/farm_bot.gd")


func _mission() -> FarmhouseMission:
	return FarmhouseMission.of(get_tree())


func _cmd_farm_start(a: Array) -> Dictionary:
	var m := _mission()
	if m == null:
		return {"ok": false, "error": "no FarmhouseMission in the street"}
	m.begin(not a.has("here"))
	await seconds(1.0)
	return m.result()


func _cmd_farm_state(_a: Array) -> Dictionary:
	var m := _mission()
	return m.result() if m else {"ok": false, "error": "no mission"}


func _cmd_farm_free(_a: Array) -> Dictionary:
	var m := _mission()
	if m == null or m.hostage_brain == null:
		return {"ok": false, "error": "not started"}
	m.hostage_brain.free_by(player)
	return m.result()


func _cmd_farm_fail(_a: Array) -> Dictionary:
	var m := _mission()
	if m == null or m.state != FarmhouseMission.State.ON:
		return {"ok": false, "error": "not on"}
	m._lose(&"test", m.tuning_line("lost_hostage"))
	return m.result()


## One scripted run: the mission started, the scripted player in by `way` till it's won or lost (or
## `max` s), the record to `out`.
func _cmd_farm_run(a: Array) -> Dictionary:
	var way: String = a[0] if a.size() > 0 else "front"
	var opts := {}
	for w in a.slice(1):
		var kv := String(w).split("=")
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var seed_value := int(opts.get("seed", "1"))
	var max_s := float(opts.get("max", "240"))
	var m := _mission()
	if m == null:
		return {"ok": false, "error": "no mission"}
	seed(seed_value)
	m.begin(true)
	await physics_frames(30)
	var bot = FarmBot.new()
	bot.setup(player, m, way, seed_value, float(opts.get("aim", "1.0")))
	var t := 0.0
	var tail := -1.0
	# The frames' wall clock (each physics tick's, here: F3's frame on this core, headless): through
	# the fight (from the alarm), and the blast's (the worst of the ticks just after it went off).
	var ms: Array[float] = []
	var blast_ms := -1.0
	var blast_at := -1
	var went := [false]
	var on_blast := func(_at: Vector3, _kg: float) -> void: went[0] = true
	Events.exploded.connect(on_blast)
	var last := Time.get_ticks_usec()
	while t < max_s:
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		var frame := (now - last) / 1000.0
		last = now
		if m.alarm_t >= 0.0 and m.state == FarmhouseMission.State.ON:
			ms.append(frame)
		if went[0] and blast_at < 0:
			blast_at = ms.size()
		if blast_at >= 0 and ms.size() - blast_at < 4:
			blast_ms = maxf(blast_ms, frame)
		var dt := get_physics_process_delta_time()
		t += dt
		bot.tick(dt, t)
		if m.state in [FarmhouseMission.State.WON, FarmhouseMission.State.LOST]:
			if tail < 0.0:
				tail = t
			if t - tail > 2.0:
				break
	bot.bot.release_all()
	var r := m.result()
	r.way = way
	r.seed = seed_value
	r.bot = bot.stats
	r.bot_phase = bot.phase
	var inv := Farmhouse.origin().affine_inverse()
	r.player_local = arr(inv * player.global_position)
	if m.hostage and is_instance_valid(m.hostage):
		r.hostage_local = arr(inv * m.hostage_at())
		r.hostage_body = {"conscious": m.hostage.physiology.is_conscious(), "limp": m.hostage.limp, "prone": m.hostage.prone,
				"pose": str(m.hostage.pose), "tied": m.hostage_brain.tied,
				"head": arr(inv * (m.hostage.parts[&"head"] as Node3D).global_position),
				"pelvis": arr(inv * (m.hostage.parts[&"pelvis"] as Node3D).global_position) if m.hostage.parts.has(&"pelvis") else [],
				"chair": arr(inv * m.hostage_brain.chair.global_position) if m.hostage_brain.chair and is_instance_valid(m.hostage_brain.chair) else []}
	if not bot.route.is_empty():
		r.route_next = arr(inv * bot.route[0])
		r.route_left = bot.route.size()
	var q := PhysicsShapeQueryParameters3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.6
	q.shape = sph
	q.collide_with_bodies = true
	var near: Array = []
	for hgt in [0.3, 1.0, 1.6]:
		q.transform = Transform3D(Basis(), player.global_position + Vector3(0, hgt, 0) + (bot.route[0] - player.global_position if not bot.route.is_empty() else Vector3.ZERO).normalized() * 0.4)
		for hit in player.get_world_3d().direct_space_state.intersect_shape(q, 12):
			var c: Object = hit.collider
			near.append("%s:%s" % [hgt, c.get_parent().name + "/" + c.name if c is Node and c.get_parent() else str(c)])
			if c is RigidBody3D:
				var kids := []
				for k in (c as Node).get_children():
					kids.append(k.name)
				near.append("RB %s at %s mass %s kids %s meta %s" % [c.get_class(), arr(inv * (c as Node3D).global_position), (c as RigidBody3D).mass, kids, (c as Node).get_meta_list()])
	r.blocking = near
	r.bot_target = str(bot.bot.target.name) if bot.bot.target != null and is_instance_valid(bot.bot.target) else ""
	Events.exploded.disconnect(on_blast)
	ms.sort()
	r.frames = {"fight_ticks": ms.size(), "mean_ms": snappedf(ms.reduce(func(x: float, y: float) -> float: return x + y, 0.0) / maxf(ms.size(), 1), 0.01),
			"p95_ms": snappedf(ms[int(ms.size() * 0.95)] if not ms.is_empty() else 0.0, 0.01), "max_ms": snappedf(ms.back() if not ms.is_empty() else 0.0, 0.01),
			"blast_ms": snappedf(blast_ms, 0.01)}
	if r.outcome == "":
		r.outcome = "timeout"
	if opts.has("out"):
		var f := FileAccess.open(String(opts.out), FileAccess.WRITE)
		f.store_string(JSON.stringify(r, " "))
	bot.teardown()
	return r

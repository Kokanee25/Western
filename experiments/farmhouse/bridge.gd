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

extends RefCounted
## The body lab's bench (README.md beside this file): aiming at a marked spot, firing the game's
## own guns and dynamite, what a wound crossed, what it leaves him able to do, and his blood run
## forward with and without treatment. Shared by lab_runner.gd (the command line) and bridge.gd
## (the dev bridge). Measurement only: it calls the production HumanBody, Physiology, Ballistics
## and Blast and changes none of them. The treatments are the lab's, written to do what the game's
## own tending does (OutlawBrain._tend, PlayerWounds._tend and _patch_up).

const DATA := "res://experiments/body_lab/scenarios.json"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return _data


## Every scenario the axes make: {name, group, kind, ...}.
static func scenarios() -> Array:
	var d := data()
	var out := []
	for w: String in d.weapons:
		for r in d.ranges:
			for spot: String in d.spots:
				out.append({"name": "%s_%02dm_%s" % [w, int(r), spot], "group": w, "kind": "shot",
						"weapon": w, "range": float(r), "spot": spot})
	for r in d.dynamite.distances:
		out.append({"name": "dynamite_%dm" % int(r), "group": "dynamite", "kind": "blast", "range": float(r)})
	out.append({"name": "check", "group": "check", "kind": "check"})
	out.append({"name": "same_tick", "group": "probe", "kind": "same_tick"})
	return out


static func v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func arr(v: Variant) -> Variant:
	if v is Vector3:
		return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]
	return v


# --- Aiming and firing ---------------------------------------------------------------------------

## A spot's point in the world, on the man as he stands now.
static func spot_world(man: HumanBody, spot: Dictionary) -> Vector3:
	var seg := StringName(spot.segment)
	var part := man.parts[seg] as Node3D
	return part.global_transform * (v3(spot.target) - man.anatomy.segment_center(seg))


## The load and sights of a gun, from its tuning resource.
static func gun(weapon: String) -> Dictionary:
	if weapon == "shotgun":
		var s: ShotgunTuning = load("res://config/shotgun.tres")
		return {"weapon": weapon, "speed": s.muzzle_velocity, "mass": s.pellet_mass, "diameter": s.pellet_diameter,
				"form": 0.0, "zero": s.zero_distance, "spread_aim": s.spread_aim_degrees, "pellets": s.pellets,
				"pattern": s.pattern_degrees, "blast": s.blast_joules, "blast_reach": s.blast_reach}
	var t: RevolverTuning = load("res://config/revolver.tres")
	return {"weapon": "revolver", "speed": t.muzzle_velocity, "mass": t.bullet_mass, "diameter": t.bullet_diameter,
			"form": t.form_factor, "zero": t.zero_distance, "spread_aim": t.spread_aim_degrees, "pellets": 1,
			"pattern": 0.0, "blast": 300.0, "blast_reach": 1.5}


## The way the ball leaves an eye sighted on `target`, the sights regulated for the gun's zero
## (WeaponViewmodel.zeroed with the muzzle at the eye).
static func sighted(ballistics: Ballistics, eye: Vector3, target: Vector3, g: Dictionary) -> Vector3:
	var sight := (target - eye).normalized()
	var raise := ballistics.holdover(float(g.zero), g.speed, g.mass, g.diameter, g.form)
	var axis := sight.cross(Vector3.UP)
	if axis.length() < 1e-4:
		return sight
	return sight.rotated(axis.normalized(), raise)


## Where the zeroed ball meets the target's distance (its rise and fall along the way): the ball's
## landing point for a perfect aim. Straight line from the eye (the arc's angle at arrival differs
## by well under a degree at these ranges).
static func landing(ballistics: Ballistics, eye: Vector3, target: Vector3, g: Dictionary) -> Vector3:
	var dir := sighted(ballistics, eye, target, g)
	var dist := eye.distance_to(target)
	var fl: Dictionary = ballistics.flight(dist, g.speed, g.mass, g.diameter, g.form)
	return eye + dir * dist - Vector3(0, float(fl.drop), 0)


## A ray `half_angle` (radians) at most off `dir`, as WeaponViewmodel._cone throws a shot.
static func cone(dir: Vector3, half_angle: float, rng: RandomNumberGenerator) -> Vector3:
	if half_angle <= 0.0:
		return dir
	var axis := dir.cross(Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT).normalized()
	var off := dir.rotated(axis, rng.randf() * half_angle)
	return off.rotated(dir, rng.randf() * TAU).normalized()


## Fire the gun from `eye` at `target` with a perfect aim (no wobble): one ball, or a shotgun's
## charge with its own pattern. Returns the projectiles.
static func fire(ballistics: Ballistics, eye: Vector3, target: Vector3, g: Dictionary, rng: RandomNumberGenerator) -> Array:
	var dir := sighted(ballistics, eye, target, g)
	if g.weapon == "shotgun":
		return ballistics.fire_charge(eye, dir, int(g.pellets), deg_to_rad(g.pattern), g.speed, g.mass, g.diameter,
				[] as Array[RID], rng, g.blast, g.blast_reach)
	var b := ballistics.fire(eye, dir, g.speed, g.mass, g.diameter)
	b.form = g.form
	return [b]


## Without touching him: `n` shots with the game's aimed wobble (and a shotgun's pattern, pellet by
## pellet), each a ray to see which part it meets and `Anatomy.trace` (a copy of the rng, so his own
## is left alone) to see what it would cross there. What the aim gets, as shares.
static func sample(man: HumanBody, ballistics: Ballistics, eye: Vector3, spot: Dictionary, g: Dictionary, n: int,
		rng: RandomNumberGenerator) -> Dictionary:
	var target := spot_world(man, spot)
	var land := landing(ballistics, eye, target, g)
	var base := (land - eye).normalized()
	var dist := eye.distance_to(target)
	var fl: Dictionary = ballistics.flight(dist, g.speed, g.mass, g.diameter, g.form)
	var energy := 0.5 * float(g.mass) * float(fl.speed) * float(fl.speed)
	var space := man.get_world_3d().direct_space_state
	var trng := RandomNumberGenerator.new()
	trng.seed = 7
	var want: Array = spot.aims_for
	var shots := 0
	var hit_man := 0
	var hit_seg := 0
	var crossed := 0
	var segs := {}
	var structs := {}
	for i in n:
		var aim := cone(base, deg_to_rad(g.spread_aim), rng)
		var any_man := false
		var any_seg := false
		var any_want := false
		for p in int(g.pellets):
			shots += 1
			var d := aim
			if g.pattern > 0.0:
				var side := aim.cross(Vector3.UP).normalized()
				var up := side.cross(aim).normalized()
				var off := Vector2(rng.randfn(0.0, 1.0), rng.randfn(0.0, 1.0))
				if off.length() > 2.5:
					off = off.normalized() * 2.5
				d = (aim + (side * off.x + up * off.y) * tan(deg_to_rad(g.pattern))).normalized()
			var q := PhysicsRayQueryParameters3D.create(eye, eye + d * (dist + 2.0), Layers.BODY_PARTS)
			var hit := space.intersect_ray(q)
			if hit.is_empty() or not (hit.collider as Object).has_meta(&"segment"):
				continue
			var seg: StringName = (hit.collider as Object).get_meta(&"segment")
			any_man = true
			segs[seg] = int(segs.get(seg, 0)) + 1
			if seg == StringName(spot.segment):
				any_seg = true
			var xf := (hit.collider as Node3D).global_transform
			var center := man.anatomy.segment_center(seg)
			var ld := (xf.affine_inverse().basis * d).normalized()
			var o := xf.affine_inverse() * (hit.position as Vector3) + center - ld * 0.01
			var e := energy
			for gm in man.garments:
				if gm.covers.has(seg):
					e -= float(gm.resistance)
			var tr := man.anatomy.trace(seg, o, ld, maxf(e, 0.0), float(g.diameter) * 0.5, trng)
			for h: Dictionary in tr.hits:
				structs[String(h.id)] = int(structs.get(String(h.id), 0)) + 1
				if want.has(String(h.id)):
					any_want = true
		hit_man += 1 if any_man else 0
		hit_seg += 1 if any_seg else 0
		crossed += 1 if any_want else 0
	var top := structs.keys()
	top.sort_custom(func(a: String, b: String) -> bool: return structs[a] > structs[b])
	return {"shots": n, "pellets_each": int(g.pellets), "man": float(hit_man) / n, "segment": float(hit_seg) / n,
			"aims_for": float(crossed) / n, "segments": segs, "crossed_most": top.slice(0, 8).map(
				func(k: String) -> Array: return [k, snappedf(float(structs[k]) / shots, 0.001)]),
			"point_of_impact_cm": snappedf((land - target).y * 100.0, 0.1),
			"energy_at_range_j": snappedf(energy, 0.1), "speed_at_range": snappedf(float(fl.speed), 0.1)}


# --- What he has and can do ----------------------------------------------------------------------

## One wound as plain data (what it crossed).
static func wound_row(w: Dictionary) -> Dictionary:
	return {"segment": String(w.segment), "kind": String(w.get("kind", "")), "part": String(w.get("part", "")),
			"hits": (w.get("hits", []) as Array).map(func(h: Dictionary) -> String: return "%s:%s" % [h.id, h.effect]),
			"lodged": w.get("lodged", false), "entry": arr(w.get("entry")), "exit": arr(w.get("exit")),
			"garments": (w.get("garments", []) as Array).map(func(g: StringName) -> String: return String(g)),
			"harm": w.get("harm", []), "kpa": snappedf(float(w.get("kpa", 0.0)), 0.1)}


## What his wounds let him do now (Physiology's own answers).
static func abilities(p: Physiology) -> Dictionary:
	return {"conscious": p.is_conscious(), "can_stand": p.can_stand(), "can_run": p.can_run(),
			"can_hold_r": p.can_hold("r"), "can_hold_l": p.can_hold("l"), "leg_strength": snappedf(p.leg_strength(), 0.01),
			"arm_steadiness_r": snappedf(p.arm_steadiness("r"), 0.01), "legs_paralysed": p.legs_paralysed(),
			"arms_paralysed": p.arms_paralysed(), "can_speak": p.can_speak(), "breath": snappedf(p.breath_capacity(), 0.01),
			"leg_ok_r": p.leg_ok("r"), "leg_ok_l": p.leg_ok("l")}


static func injuries(p: Physiology) -> Dictionary:
	return {"broken": p.broken.keys().map(func(k: StringName) -> String: return String(k)),
			"cut": p.cut.keys().map(func(k: StringName) -> String: return String(k)),
			"torn": p.torn.keys().map(func(k: StringName) -> String: return String(k)),
			"fingers": p.lost_fingers.keys().map(func(k: StringName) -> String: return String(k)),
			"severed": p.severed_segments.keys().map(func(k: StringName) -> String: return String(k)),
			"eardrums": p.eardrums_burst.size(), "lungs": p.lung_damage.keys().map(func(k: StringName) -> String: return String(k)),
			"gut": p.gut_seconds >= 0.0, "neck_cord": p.neck_seconds >= 0.0, "concussion_s": snappedf(p.concussion, 0.1),
			"burns": snappedf(p.burns, 0.01), "blood_ml": snappedf(p.blood_ml, 1.0),
			"bleeds": p.bleeds.map(func(b: Dictionary) -> Dictionary: return {"source": String(b.source),
					"segment": String(b.segment), "kind": String(b.kind), "ml_s": snappedf(float(b.rate), 0.01), "clots": b.clots}),
			"bleed_ml_s": snappedf(p.total_bleed_rate(), 0.01), "alive": p.alive, "cause": String(p.cause_of_death)}


# --- Treatment and the blood run forward ---------------------------------------------------------

const LIMB_WORDS := ["arm", "hand", "thigh", "shin", "foot"]


static func _limb(seg: StringName) -> bool:
	for w: String in LIMB_WORDS:
		if String(seg).contains(w):
			return true
	return false


## A belt goes high on the limb: the thigh or the upper arm (PlayerWounds._limb_top).
static func limb_top(seg: StringName) -> StringName:
	var s := String(seg)
	var side := s.right(1)
	return StringName(("upper_arm_" if s.contains("arm") or s.contains("hand") else "thigh_") + side)


## Apply one treatment to `p` now. Returns whether there was anything it could do.
static func treat(p: Physiology, what: String) -> bool:
	var did := false
	match what:
		"tourniquet":
			for b: Dictionary in p.bleeds:
				if _limb(b.segment) and b.kind != &"internal" and float(b.rate) > p.tuning.clot_max_rate and not b.tourniquet:
					p.apply_tourniquet(limb_top(b.segment))
					did = true
		"packing":
			for b: Dictionary in p.bleeds:
				if b.kind != &"internal" and not b.tourniquet:
					b.pressure = true
					b.bandaged = true
					did = true
		"doctor":
			if not p.alive:
				return false
			for b: Dictionary in p.bleeds:
				b.clot = 0.0
				b.tourniquet = false
				b.pressure = true
				b.bandaged = true
			did = not p.bleeds.is_empty() or not p.lung_damage.is_empty() or p.gut_seconds >= 0.0
			p.lung_damage.clear()
			p.airway_blood = false
			p.gut_seconds = -1.0
	return did


## Run a copy of his physiology (`state`, Physiology.to_dict(), taken `from_t` seconds after the
## hit) forward under one treatment, to `horizon` seconds. Times are seconds after the hit.
static func outcome(state: Dictionary, from_t: float, treatment: Dictionary, horizon: float, dt: float, seed := 1) -> Dictionary:
	var p := Physiology.new()
	p.from_dict(state)
	p.roll_rng.seed = hash(["physiology", seed])
	var t := from_t
	var steps := []  # [time, treatment] still to do
	match String(treatment.name):
		"tourniquet", "packing":
			steps.append([float(treatment.at), String(treatment.name)])
		"doctor":
			steps.append([float(treatment.packing_at), "packing"])
			steps.append([float(treatment.at), "doctor"])
	var res := {"treatment": treatment.name, "applicable": treatment.name == "none", "reached": treatment.name == "none",
			"dead_s": null, "cause": "",
			"unconscious_s": null if p.is_conscious() else from_t, "shock_s": null, "lost_ml": 0.0}
	if not p.alive:
		res.dead_s = from_t
		res.cause = String(p.cause_of_death)
	var start_ml := p.tuning.blood_ml
	while t < horizon and p.alive:
		while not steps.is_empty() and t >= float(steps[0][0]):
			if steps[0][1] == String(treatment.name):
				res.reached = true
			if treat(p, steps[0][1]) and steps[0][1] == String(treatment.name):
				res.applicable = true
			steps.pop_front()
		p.step(dt)
		t += dt
		if res.unconscious_s == null and not p.is_conscious():
			res.unconscious_s = snappedf(t, 0.1)
		if res.shock_s == null and p.blood_loss() >= p.tuning.shock_at_loss:
			res.shock_s = snappedf(t, 0.1)
		if not p.alive:
			res.dead_s = snappedf(t, 0.1)
			res.cause = String(p.cause_of_death)
	res.lost_ml = snappedf(start_ml - p.blood_ml, 1.0)
	return res


## Every treatment in the data, run forward from the same state.
static func outcomes(state: Dictionary, from_t: float) -> Dictionary:
	var d := data()
	var out := {}
	for tr: Dictionary in d.treatments:
		out[tr.name] = outcome(state, from_t, tr, float(d.horizon_seconds), float(d.sim_dt), int(d.seed))
	return out


## One vessel or organ cut on its own (no wound track, so no flesh bleed), each treatment.
static func vessel(id: StringName) -> Dictionary:
	var a := Anatomy.shared()
	var st := a.structure(id)
	var p := Physiology.new()
	var effect := &"cut" if st.kind in [&"artery", &"vein"] else &"torn"
	p.apply_trace({"segment": st.segment, "track_cm": 0.0, "hits": [{"id": id, "kind": st.kind, "effect": effect}]})
	var row := {"id": String(id), "kind": String(st.kind) + (" (inside)" if st.get(&"inside", false) else ""), "segment": String(st.segment), "ml_s": float(st.get(&"bleed", 0.0)),
			"limb": bool(st.get(&"limb", false)), "clots": p.bleeds[0].clots if not p.bleeds.is_empty() else false}
	row.outcomes = outcomes(p.to_dict(), 0.0)
	# Packing holds or not by a roll (PhysiologyTuning.packing_holds): the share of 40 seeds he lives.
	var d := data()
	var packing: Dictionary = d.treatments.filter(func(t: Dictionary) -> bool: return t.name == "packing")[0]
	# Only a bleed too fast to clot that packing reaches rolls; for the rest one run says it all.
	if p.bleeds.is_empty() or p.bleeds[0].clots or p.bleeds[0].kind == &"internal":
		row.packed_lives_share = 1.0 if row.outcomes.packing.dead_s == null else 0.0
		return row
	var lives := 0
	for k in 40:
		# Packed or not, a bleed that hasn't killed him in an hour won't (it's held or clotted).
		if outcome(p.to_dict(), 0.0, packing, 3600.0, 0.5, k + 1).dead_s == null:
			lives += 1
	row.packed_lives_share = lives / 40.0
	return row

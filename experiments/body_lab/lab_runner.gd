extends "res://experiments/physics_lab/lab_runner.gd"
## The body lab's runner (README.md beside this file). One scenario on one man: the production
## HumanBody (the model chosen by the lab's --model, not the game's default) standing on level
## ground, shot through the game's Ballistics with the game's own loads, or caught by a stick of
## dynamite through Blast.detonate; a few seconds live (he falls, bleeds, loses what he loses), then
## his physiology copied and run forward untreated and treated (wound_bench.gd). The `check`
## scenario looks at what a new man's body does with wounds, severing, stumps and his hat; `perf`
## is ten wounded men against the people budget. Extends the ragdoll lab's runner for its ground,
## light and stats; measurement only. Started by lab.gd.

const Bench := preload("res://experiments/body_lab/wound_bench.gd")

var seed_value := 1
var ballistics: Ballistics
var man: HumanBody
var _rng := RandomNumberGenerator.new()
var _infos: Array = []
var _fired_tick := -1
var _stand_ticks := 30
var _live_ticks := 180
var _phase := ""
var _found := {}
var _perf := {"standing": [], "after": [], "people_standing": [], "people_after": [], "body": [], "skeleton": [], "blood": [], "brains": []}
## --brains: each perf man has an OutlawBrain (senses, fear, tending his wounds), as the gang does.
var brains := false
## --no-grab: no hand goes to a wound (HumanBody.hand_to_wound), for an A/B.
var grab_on := true
var _perf_last := 0
var _toward: Array = []  ## the blast's gravel and splinters that left toward him
var _spot_cam := {}  ## where the close-up looks (a shot's spot), fixed at the hit


func _ready() -> void:
	process_physics_priority = -100
	process_priority = 1000
	HumanBody.hand_to_wound = grab_on
	DirAccess.make_dir_recursive_absolute(out_dir)
	_rng.seed = seed_value
	var d := Bench.data()
	_stand_ticks = int(round(float(d.stand_seconds) * 60.0))
	_live_ticks = int(round(float(d.live_seconds) * 60.0))
	_world = Node3D.new()
	_world.name = "LabWorld"
	add_child(_world)
	_box(Vector3(0, -0.5, 0), Vector3(200, 1, 200), Color(0.45, 0.42, 0.38))
	_light()
	ballistics = Ballistics.new()
	ballistics.name = "Ballistics"
	_world.add_child(ballistics)
	match String(scenario.kind):
		"perf":
			Prof.on = true
			var p: Dictionary = d.perf
			for i in int(p.men):
				var m := _spawn(Vector3((i - (int(p.men) - 1) * 0.5) * float(p.spacing), 0, 0), i)
				if brains:
					var b := OutlawBrain.new()
					b.name = "Brain"
					m.add_child(b)
				_men.append(m)
		"same_tick":
			for i in 3:
				_men.append(_spawn(Vector3(i * 3.0, 0, 0), i))
		"check":
			# Four men far enough apart that the blast (at the last) reaches only its own.
			for i in 4:
				_men.append(_spawn(Vector3([0.0, 3.0, 6.0, 60.0][i], 0, 0), i))
		_:
			man = _spawn(Vector3.ZERO, 0)
			_men.append(man)
			man.hit.connect(func(info: Dictionary) -> void: _infos.append(_info_row(info)))
	_last_us = Time.get_ticks_usec()
	_perf_last = _last_us


func _spawn(at: Vector3, i: int) -> HumanBody:
	var m := HumanBody.new()
	m.name = "Man%d" % i
	m.has_gun = false
	m.body_model = model
	if has_meta(&"mixed"):
		var mixed: Array = get_meta(&"mixed")
		m.body_model = StringName(mixed[i % mixed.size()])
	m.rng_seed = seed_value + i
	m.person_id = StringName("lab_%d" % i)
	_world.add_child(m)
	m.global_transform = Transform3D(Basis.IDENTITY, at)
	return m


func _info_row(info: Dictionary) -> Dictionary:
	return {"segment": String(info.get("segment", "")), "kind": String(info.get("kind", "")),
			"hits": (info.get("hits", []) as Array).map(func(h: Dictionary) -> String: return "%s:%s" % [h.id, h.effect]),
			"deposited_j": snappedf(float(info.get("deposited", 0.0)), 0.1), "severe": info.get("severe", false),
			"knocked_down": info.get("knocked_down", false), "lodged": info.get("lodged", false),
			"harm": info.get("harm", []), "kpa": snappedf(float(info.get("kpa", 0.0)), 0.1),
			"tick": _tick - _fired_tick}


# --- The run -------------------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if done:
		return
	_tick += 1
	match String(scenario.kind):
		"shot":
			_run_shot()
		"blast":
			_run_blast()
		"check":
			_run_check()
		"perf":
			_run_perf()
		"same_tick":
			_run_same_tick()


func _process(_delta: float) -> void:
	if String(scenario.get("kind", "")) != "perf" or done:
		return
	# One frame's whole cost (physics tick and process) and the people's own timers in it.
	var now := Time.get_ticks_usec()
	var ms := (now - _perf_last) / 1000.0
	_perf_last = now
	Prof.roll()
	var body: float = Prof.per_frame.get(&"people_body", 0.0)
	var skel: float = Prof.per_frame.get(&"people_skeleton", 0.0)
	var blood: float = Prof.per_frame.get(&"blood", 0.0)
	# The people row's other timers (CLAUDE.md, frame budget): brains and senses.
	var minds: float = Prof.per_frame.get(&"outlaw_brain", 0.0) + Prof.per_frame.get(&"senses", 0.0)
	var key := "standing" if _fired_tick < 0 else "after"
	if _tick < 10:
		return  # warm-up
	(_perf[key] as Array).append(ms)
	(_perf["people_" + key] as Array).append(body + skel + blood + minds)
	if key == "after":
		(_perf.body as Array).append(body)
		(_perf.skeleton as Array).append(skel)
		(_perf.blood as Array).append(blood)
		(_perf.brains as Array).append(minds)


func _eye(range_m: float, at := Vector3.ZERO) -> Vector3:
	return at + Vector3(0, float(Bench.data().eye_height), -range_m)


func _run_shot() -> void:
	var d := Bench.data()
	if _tick == _stand_ticks:
		var spot: Dictionary = d.spots[scenario.spot]
		var g := Bench.gun(scenario.weapon)
		var eye := _eye(scenario.range)
		var target := Bench.spot_world(man, spot)
		summary["aim"] = Bench.sample(man, ballistics, eye, spot, g, int(d.aim_samples), _rng)
		summary["target_world"] = Bench.arr(target)
		_spot_cam = {"at": target, "from": target + Vector3(0.15, 0.1, -0.9)}
		Bench.fire(ballistics, eye, target, g, _rng)
		_fired_tick = _tick
		return
	_live(_tick - _fired_tick if _fired_tick >= 0 else -1)


func _run_blast() -> void:
	if _tick == _stand_ticks:
		var d := Bench.data()
		var at := Vector3(0, float(d.dynamite.height), -float(scenario.range))
		var kg := Blast.t().tnt_per_stick
		summary["charge"] = {"at": Bench.arr(at), "kg": kg,
				"chest_kpa_side_on": snappedf(Blast.overpressure_kpa(kg, at.distance_to((man.parts[&"chest"] as Node3D).global_position)), 0.1)}
		_spot_cam = {"at": Vector3(0, 0.9, 0), "from": Vector3(1.2, 1.2, -1.6)}
		_fired_tick = _tick
		var report := Blast.detonate(_world, at, kg)
		summary.charge["projectiles"] = ballistics.bullets.size()
		summary.charge["splinters_and_gravel"] = report.splinters
		# How many of the gravel and splinters left toward him (within his width), and how high.
		var toward := []
		for bl: Ballistics.Bullet in ballistics.bullets:
			var dir := bl.velocity.normalized()
			if absf(atan2(dir.x, dir.z)) < atan(0.25 / float(scenario.range)):
				toward.append(snappedf(rad_to_deg(asin(dir.y)), 0.1))
				_toward.append(bl)
		summary.charge["projectiles_toward_him_elevation_deg"] = toward
		return
	_live(_tick - _fired_tick if _fired_tick >= 0 else -1)


## After the hit: a close-up as it lands, the whole man at the end, then the numbers.
func _live(since: int) -> void:
	if since < 0:
		return
	if scenario.get("grab", false):
		_watch_grab(since)
	if render and since == 9 and not scenario.get("grab", false):
		_snap("spot", _spot_cam.from, _spot_cam.at, 45.0)
	if since == _live_ticks:
		_finish_wound()
		if render:
			var c := _com(man)
			await _snap("full", c + Vector3(1.6, 1.4, -2.2), c, 50.0)
		_write()


var _grab_log := []  ## [t, side, weight, palm to the hole (cm)] each tick
## He's made to let go (hands up) this many ticks after the hit, to see the bleeding come back.
const GRAB_LET_GO_AT := 90
var _grab_wound := {}
var _grab_bleed := []  ## [t, what the wound bleeds with no hand on it, what comes out now] (ml/s)


func _out_now(w: Dictionary) -> float:
	var r := 0.0
	for i: int in w.get("bleeds", []):
		if i < man.physiology.bleeds.size():
			r += man.physiology.bleed_rate(man.physiology.bleeds[i])
	return r


## The hand to the wound: which hand, how far along, and how far the middle of his palm is from the
## hole (less the hand's own thickness off the skin). Footage every 3 ticks with --render.
func _watch_grab(since: int) -> void:
	if since == GRAB_LET_GO_AT:
		man.set_pose(&"hands_up")  # he has to let go: does it spurt again?
	var g: Dictionary = man._grab
	if not g.is_empty():
		_grab_wound = g.wound
	_grab_bleed.append([snappedf(since / 60.0, 0.01), snappedf(man._wound_bleed(_grab_wound) if not _grab_wound.is_empty() else 0.0, 0.01),
			snappedf(_out_now(_grab_wound), 0.01)])
	var row := [snappedf(since / 60.0, 0.01), "", 0.0, null, man.limp]
	if not g.is_empty():
		var part := man.parts[g.seg] as Node3D
		var hole: Vector3 = part.global_transform * (g.at as Vector3)
		var palm := (man.parts[StringName("hand_" + g.side)] as Node3D).global_position
		row = [snappedf(since / 60.0, 0.01), g.side, snappedf(g.w, 0.01),
				snappedf(maxf(palm.distance_to(hole) - HumanBody.GRAB_OFF_SKIN, 0.0) * 100.0, 0.1), man.limp]
		if since == 1:
			_spot_cam = {"at": hole, "from": hole + man.global_basis * Vector3(0.5, 0.2, -1.3)}
	_grab_log.append(row)
	if render and since % 3 == 0 and since <= 180 and not _spot_cam.is_empty():
		_snap("grab_%03d" % since, _spot_cam.from, _spot_cam.at, 50.0)


func _grab_summary() -> Dictionary:
	var reached := -1.0
	for r: Array in _grab_log:
		if r[3] != null and float(r[3]) <= 5.0 and float(r[2]) >= 0.99:
			reached = r[0]
			break
	var last: Array = _grab_log[-1] if not _grab_log.is_empty() else []
	var at_1s: Array = _grab_log[mini(59, _grab_log.size() - 1)] if not _grab_log.is_empty() else []
	return {"hand": last[1] if not last.is_empty() else "", "reached_s": reached if reached >= 0.0 else null,
			"palm_to_hole_cm_at_1s": at_1s[3] if not at_1s.is_empty() else null,
			"palm_to_hole_cm_end": last[3] if not last.is_empty() else null, "weight_end": last[2] if not last.is_empty() else 0.0,
			"down": man.limp or man.prone, "log": _grab_log.filter(func(r: Array) -> bool: return int(round(r[0] * 60.0)) % 6 == 0),
			"bleeding": _grab_bleed.filter(func(r: Array) -> bool: return int(round(r[0] * 60.0)) % 15 == 0)}


func _finish_wound() -> void:
	var p := man.physiology
	if scenario.get("grab", false):
		summary["grab"] = _grab_summary()
	if not _toward.is_empty():
		summary.charge["toward_him_paths"] = _toward.map(func(b: Ballistics.Bullet) -> Array:
			return [b.alive, b.hits.size(), Array(b.path).slice(0, 4).map(func(q: Vector3) -> Variant: return Bench.arr(q))])
	var d := Bench.data()
	summary["scenario"] = scenario
	summary["model"] = String(model)
	summary["seed"] = seed_value
	summary["hits"] = _infos
	summary["wounds"] = man.wounds.map(func(w: Dictionary) -> Dictionary: return Bench.wound_row(w))
	var crossed := {}
	for w: Dictionary in man.wounds:
		for h: Dictionary in w.get("hits", []):
			crossed[String(h.id)] = String(h.effect)
	summary["crossed"] = crossed
	if scenario.kind == "shot":
		var want: Array = d.spots[scenario.spot].aims_for
		summary["on_target"] = want.filter(func(id: String) -> bool: return crossed.has(id))
		summary["segments_hit"] = _infos.map(func(i: Dictionary) -> String: return i.segment)
	summary["injuries"] = Bench.injuries(p)
	summary["abilities"] = Bench.abilities(p)
	summary["body"] = {"limp": man.limp, "prone": man.prone, "hat_off": man.hat_off, "openings": man.openings.size(),
			"knocked_down": _infos.any(func(i: Dictionary) -> bool: return i.knocked_down),
			"severed_parts": get_tree().get_nodes_in_group(&"severed_parts").size()}
	summary["severed_where"] = man.wounds.filter(func(w: Dictionary) -> bool: return w.kind == &"severed").map(
			func(w: Dictionary) -> Dictionary: return {"part": String(w.part), "at_joint_of": String(w.segment),
				"stump_cm_from_joint": snappedf(((w.entry as Vector3) - (man._pivot_rest(w.part) - man.anatomy.segment_center(w.segment))).length() * 100.0, 0.1)})
	var from_t := float(_live_ticks) / 60.0
	summary["outcomes"] = Bench.outcomes(p.to_dict(), from_t)


func _write() -> void:
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.close()
	done = true


# --- Each man's own check ------------------------------------------------------------------------

func _run_check() -> void:
	if _tick == _stand_ticks:
		_check_start()
	elif _tick == _stand_ticks + 9 and render:
		_snap("wound", (_men[0].parts[&"chest"] as Node3D).global_position + Vector3(0.2, 0.1, -0.8),
				(_men[0].parts[&"chest"] as Node3D).global_position, 40.0)
	elif _tick == _stand_ticks + 60:
		_check_sever(_men[2], &"shin_l")
	elif _tick == _stand_ticks + 150:
		_check_end()
		if render:
			var c := _com(_men[2])
			_snap("stumps", c + Vector3(1.0, 0.9, -1.2), c, 50.0)
			var h: Node3D = null
			for n in get_tree().get_nodes_in_group(&"hats"):
				if n.get_meta(&"hat_of", null) == _men[1]:
					h = n
			var hc: Vector3 = h.global_position if h else (_men[1].parts[&"head"] as Node3D).global_position
			_snap("hat", hc + Vector3(0.9, 0.8, -1.2), hc, 50.0)
			var c3 := _com(_men[3])
			_snap("blast", c3 + Vector3(1.5, 1.3, -2.0), c3, 50.0)
	elif _tick == _stand_ticks + 160:
		_write()


func _check_start() -> void:
	var a: HumanBody = _men[0]
	var b: HumanBody = _men[1]
	var c: HumanBody = _men[2]
	var dman: HumanBody = _men[3]
	_found["model"] = {"id": String(model), "loaded": PeopleBodies.has_model(model), "whole": PeopleBodies.report(model).get("whole", false),
			"skeleton": a.skeleton != null, "pieces_per_segment": _counts(a.segment_pieces),
			"shapes": _shape_names(a), "hat_pieces": a._hat_pieces().size(), "hat_body": a.hat_body != null,
			"hat_box_cm": Bench.arr(a._hat_box().size * 100.0)}
	# A wound: a revolver ball into the chest from 5 m.
	var spot: Dictionary = Bench.data().spots.chest
	Bench.fire(ballistics, _eye(5.0, a.global_position), Bench.spot_world(a, spot), Bench.gun("revolver"), _rng)
	# The hat: a ball through its crown from 5 m, a hand above his head.
	if b.hat_body:
		# How much room the crown leaves over his head: its top against his skull's.
		var box := b._hat_box()
		var top := b.hat_body.global_position.y + box.size.y * 0.5
		var head := b.anatomy.segments[&"head"] as Dictionary
		var skull := -INF
		for cap: Array in head.capsules:
			for end in [cap[0], cap[1]]:
				skull = maxf(skull, ((b.parts[&"head"] as Node3D).global_transform * ((end as Vector3) - b.anatomy.segment_center(&"head"))).y + float(cap[2]))
		_found["hat_crown_clearance_cm"] = snappedf((top - skull) * 100.0, 0.1)
		var crown := b.hat_body.global_position + Vector3(0, box.size.y * 0.5 - 0.015, 0)
		var eye := crown + Vector3(0, 0.0, -5.0)
		var shot := ballistics.fire(eye, (crown - eye).normalized(), 274.0, 0.0165, 0.0114)
		shot.form = 1.27
	# Severing: his right forearm off at the elbow now, his left shin at the knee a second later.
	_check_sever(c, &"forearm_r")
	# The hat on a man thrown down by a blast 1 m off.
	var at := dman.global_position + Vector3(0, 0.05, -1.0)
	Blast.detonate(_world, at, Blast.t().tnt_per_stick)


var _stumps := []  ## [man, segment, the joint in the parent part's space]


func _check_sever(m: HumanBody, seg: StringName) -> void:
	var joint := m.get_node_or_null(NodePath("Joint_%s" % seg)) as Node3D
	var parent: StringName = m.anatomy.segments[seg].parent
	var at: Vector3 = joint.global_position if joint else (m.parts[seg] as Node3D).global_position
	_stumps.append([m, seg, (m.parts[parent] as Node3D).global_transform.affine_inverse() * at])
	m.sever_limb(seg, Vector3(1.5, 1.0, 0.0))


func _check_end() -> void:
	var a: HumanBody = _men[0]
	var b: HumanBody = _men[1]
	var dman: HumanBody = _men[3]
	# The wound: is it open, is the inside built, does every piece of the chest show it?
	var pieces: Array = a.segment_pieces.get(&"chest", [])
	var showing := 0
	for mi: MeshInstance3D in pieces:
		var m := mi.material_override as ShaderMaterial
		if m and int(m.get_shader_parameter(&"wound_count")) > 0:
			showing += 1
	_found["wound"] = {"wounds": a.wounds.size(), "hits": a.wounds.map(func(w: Dictionary) -> Array: return Bench.wound_row(w).hits),
			"open": a.is_open(&"chest"), "inside_built": (a.visuals[&"chest"] as Node3D).get_node_or_null(^"Inside") != null,
			"chest_pieces": pieces.size(), "pieces_showing_it": showing,
			"pieces_not_showing": pieces.filter(func(mi: MeshInstance3D) -> bool:
				var m := mi.material_override as ShaderMaterial
				return m == null or int(m.get_shader_parameter(&"wound_count")) == 0).map(func(mi: MeshInstance3D) -> String: return String(mi.name))}
	# The hat.
	var flying: Array = get_tree().get_nodes_in_group(&"hats").filter(func(n: Node) -> bool: return n.get_meta(&"hat_of", null) == b)
	_found["hat"] = {"had_hat": b.hat_body != null or b.hat_off, "shot_off": b.hat_off, "flying_hat": flying.size(),
			"its_meshes": (flying[0] as Node).find_children("*", "MeshInstance3D", false, false).size() if not flying.is_empty() else 0,
			"head_wounds": b.wounds.filter(func(w: Dictionary) -> bool: return w.segment == &"head").size(),
			"worn_pieces_left_visible": b._hat_pieces().filter(func(mi: MeshInstance3D) -> bool: return mi.visible).size(),
			"hat_on_landing": (flying[0] as Node3D).global_position.y if not flying.is_empty() else null}
	_found["hat_in_blast"] = {"thrown_down": dman.limp, "hat_off": dman.hat_off, "had_hat": dman.hat_body != null or dman.hat_off,
			"severed": dman.physiology.severed_segments.keys().map(func(k: StringName) -> String: return String(k))}
	# Stumps.
	var stumps := []
	for s: Array in _stumps:
		var m: HumanBody = s[0]
		var seg: StringName = s[1]
		var parent: StringName = m.anatomy.segments[seg].parent
		var bone := m.skeleton.find_bone(String(seg))
		# Where his skin's bone puts the segment's centre, against where its part is.
		var bone_at := m.skeleton.global_transform * m.skeleton.get_bone_global_pose(bone) \
				* m.skeleton.get_bone_rest(bone).affine_inverse() * m.anatomy.segment_center(seg)
		var joint_world := (m.parts[parent] as Node3D).global_transform * (s[2] as Vector3)
		var pivot := m._pivot_rest(seg)
		stumps.append({"segment": String(seg), "joint_freed": m.get_node_or_null(NodePath("Joint_%s" % seg)) == null,
				"severed_in_physiology": m.physiology.severed_segments.has(seg),
				"limb_flew_m": snappedf((m.parts[seg] as Node3D).global_position.distance_to(joint_world), 0.01),
				"bone_follows_part_cm": snappedf(bone_at.distance_to((m.parts[seg] as Node3D).global_position) * 100.0, 0.1),
				"stump_open_edges": _open_edges(m, parent, pivot), "limb_end_open_edges": _open_edges(m, seg, pivot),
				"stump_opened": m.is_open(parent), "stump_bleed_ml_s": snappedf(m.physiology.total_bleed_rate(), 0.1)})
	_found["stumps"] = stumps
	summary["check"] = _found
	summary["scenario"] = scenario
	summary["model"] = String(model)


func _counts(d: Dictionary) -> Dictionary:
	var out := {}
	for k: StringName in d:
		out[String(k)] = (d[k] as Array).size()
	return out


func _shape_names(m: HumanBody) -> Array:
	var out := {}
	for key: String in m.skin_meshes:
		out[key.get_slice("/", 0)] = true
	return out.keys()


## The open edges (used by one triangle) of a segment's skin and clothes pieces near a joint (in
## the rest pose, within 8 cm of it): the rim of a cut no cap closes. Per shape, in cm of edge.
func _open_edges(m: HumanBody, seg: StringName, pivot: Vector3) -> Dictionary:
	var out := {}
	for mi: MeshInstance3D in m.segment_pieces.get(seg, []):
		var mesh := mi.mesh as ArrayMesh
		if mesh == null:
			continue
		var shape := ""
		for key: String in m.skin_meshes:
			if m.skin_meshes[key] == mi:
				shape = key.get_slice("/", 0)
		var edges := {}
		var pos := {}
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			var keys := PackedInt64Array()
			keys.resize(v.size())
			for i in v.size():
				var k := Vector3i((v[i] * 2000.0).round())
				var h := hash(k)
				keys[i] = h
				pos[h] = v[i]
			for t in range(0, idx.size() - 2, 3):
				for e in 3:
					var p0 := keys[idx[t + e]]
					var p1 := keys[idx[t + (e + 1) % 3]]
					if p0 == p1:
						continue
					var ek := "%d:%d" % [mini(p0, p1), maxi(p0, p1)]
					edges[ek] = int(edges.get(ek, 0)) + 1
		var near := 0.0
		for ek: String in edges:
			if edges[ek] != 1:
				continue
			var ab := ek.split(":")
			var pa: Vector3 = pos[int(ab[0])]
			var pb: Vector3 = pos[int(ab[1])]
			if (pa + pb).distance_to(pivot * 2.0) < 0.16:
				near += pa.distance_to(pb)
		if near > 0.0:
			out[shape] = snappedf(float(out.get(shape, 0.0)) + near * 100.0, 0.1)
	return out


# --- A ball on the tick he goes limp -------------------------------------------------------------

## Three men, a revolver ball into each one's right thigh from 3 m: standing; fired on the tick he
## goes limp; fired the tick after. Does it find him?
func _run_same_tick() -> void:
	var g := Bench.gun("revolver")
	var spot: Dictionary = Bench.data().spots.thigh
	if _tick == _stand_ticks:
		_fired_tick = _tick
		for i in 2:
			var m: HumanBody = _men[i]
			var target := Bench.spot_world(m, spot)
			if i == 1:
				m.go_limp()
			Bench.fire(ballistics, _eye(3.0, m.global_position), target, g, _rng)
		_found["target_2"] = Bench.spot_world(_men[2], spot)
		_men[2].go_limp()
	elif _tick == _stand_ticks + 1:
		Bench.fire(ballistics, _eye(3.0, _men[2].global_position), _found.target_2, g, _rng)
	elif _tick == _stand_ticks + 30:
		var names := ["standing", "fired the tick he goes limp", "fired the tick after"]
		summary["scenario"] = scenario
		summary["model"] = String(model)
		summary["same_tick"] = range(3).map(func(i: int) -> Dictionary: return {"case": names[i],
				"wounds": (_men[i] as HumanBody).wounds.size()})
		_write()


# --- Ten wounded men -----------------------------------------------------------------------------

func _run_perf() -> void:
	var p: Dictionary = Bench.data().perf
	var standing := int(float(p.standing_seconds) * 60.0)
	if _tick == standing:
		var spots: Array = Bench.data().spots.keys()
		var g := Bench.gun(p.weapon)
		for i in _men.size():
			var m: HumanBody = _men[i]
			var spot: Dictionary = Bench.data().spots[spots[i % spots.size()]]
			Bench.fire(ballistics, _eye(float(p.range), m.global_position), Bench.spot_world(m, spot), g, _rng)
		_fired_tick = _tick
	elif _tick == standing + int(float(p.after_seconds) * 60.0):
		var scale := 0.65
		var out := {"men": _men.size(), "model": String(model), "budget_ms": p.budget_ms, "clock_scale": scale,
				"frame_ms_standing": _stats(_typed(_perf.standing)), "frame_ms_after": _stats(_typed(_perf.after)),
				"people_ms_standing": _stats(_typed(_perf.people_standing)), "people_ms_after": _stats(_typed(_perf.people_after)),
				"people_body_ms_after": _stats(_typed(_perf.body)), "people_skeleton_ms_after": _stats(_typed(_perf.skeleton)),
				"blood_ms_after": _stats(_typed(_perf.blood)), "brains": brains,
				"brains_and_senses_ms_after": _stats(_typed(_perf.brains)),
				"down": _men.filter(func(m: HumanBody) -> bool: return m.limp or m.prone).size(),
				"dead": _men.filter(func(m: HumanBody) -> bool: return not m.physiology.alive).size(),
				"wounds": _men.map(func(m: HumanBody) -> int: return m.wounds.size())}
		out["people_ms_after_at_seans"] = snappedf(float(out.people_ms_after.get("mean", 0.0)) * scale, 0.01)
		out["frame_ms_after_at_seans"] = snappedf(float(out.frame_ms_after.get("mean", 0.0)) * scale, 0.01)
		summary = out
		Prof.on = false
		_write()


static func _typed(a: Array) -> Array[float]:
	var out: Array[float] = []
	for x in a:
		out.append(float(x))
	return out


# --- Pictures ------------------------------------------------------------------------------------

## One picture from `from` looking at `at`, into frames/<name>.png (a viewport of its own, freed after).
func _snap(name: String, from: Vector3, at: Vector3, fov: float) -> void:
	var sv := SubViewport.new()
	sv.size = view_size
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var cam := Camera3D.new()
	cam.fov = fov
	sv.add_child(cam)
	cam.look_at_from_position(from, at, Vector3.UP)
	cam.current = true
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("frames"))
	for i in 3:
		await RenderingServer.frame_post_draw
	sv.get_texture().get_image().save_png(out_dir.path_join("frames").path_join(name + ".png"))
	sv.queue_free()

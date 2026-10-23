extends BridgeLab
## The gunfight lab's bridge commands (README.md beside this file; docs/briefs/labs.md "Gunfight
## lab"). run.py starts one game per fight with `gf_fight ...` as its --bridge-script, so the fight
## starts on the same frame every time (a seed gives the same fight).

const Fight := preload("res://experiments/gunfight_lab/fight.gd")
const SpecSaloon := preload("res://experiments/gunfight_lab/spec_saloon.gd")

const HELP := {
	"gf_fight": "gf_fight SCENARIO [hour=golden|night|H] [weapon=revolver|shotgun] [style=hold|cover|push] [variant=A|B|C|D] [fixes=all|none|a+b|-a] [opening=draw|shoot] [bodies=studio|outlaw|game] [seed=N] [aim=DEGREES] [max=S] [out=FILE.json] [shots=DIR every=S] -> one fight to its end, its numbers",
	"gf_lineup": "gf_lineup PATH [holstered] [studio|outlaw|MODEL...] -> the men side by side, guns up (or holstered), facing a camera: a picture (drawn runs)",
	"gf_cover": "gf_cover X Y Z [FROM_X FROM_Y FROM_Z] -> is there cover within 1.5 m of X Y Z from that eye (default: the street's trough), as the gang judges it",
	"gf_bodies": "gf_bodies [studio|outlaw|MODEL...] -> each man stood up alone: his hat's hitbox, his gun, and how much of what you see of him no hitbox covers",
	"gf_coverwhy": "gf_coverwhy X Y Z EYE_X EYE_Y EYE_Z [TRAVEL] -> the gang's cover search from X Y Z against that eye: how many spots, and why each was turned down",
	"gf_ways": "gf_ways [PREFIX] -> the spec saloon built and its places added; a man walked along every link between places named PREFIX* (spec_ by default): which he gets along and which he doesn't",
	"gf_what": "gf_what X Y Z [R] -> what a walker would touch in a sphere of R m (0.3) at X Y Z in the spec saloon's own space",
	"gf_play": "gf_play SETUP [seed=N] [variant=A|B|C|D] -> the three gunmen in the new saloon, set up as the Y key does (spec_hall, spec_stair, spec_gallery, spec_back, spec_front), your gun away: it starts when you shoot or after 6 s; returns once they're in (play it with the usual commands)",
	"gf_result": "gf_result -> the played fight so far: started, over, seconds, how it ended, each man's state",
	"gf_map": "gf_map [X Z R] -> what stands near the arena (cover props, troughs, lamps, places) within R m of X Z",
}


func _cmd_gf_fight(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": HELP.gf_fight}
	var opts := {"scenario": a[0], "hour": "golden", "weapon": "revolver", "style": "hold", "variant": "C", "bodies": "studio", "seed": 1,
		"aim": 1.0, "max": 180.0, "out": "", "shots": "", "every": 4.0}
	for w: String in a.slice(1):
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var fight := Fight.new(self, opts)
	add_child(fight)
	var err: String = await fight.setup()
	if err != "":
		fight.queue_free()
		return {"ok": false, "error": err}
	while not fight.done:
		await get_tree().physics_frame
	await get_tree().physics_frame
	while fight.capturing > 0:
		await get_tree().process_frame
	var rec: Dictionary = fight.record
	if opts.out != "":
		DirAccess.make_dir_recursive_absolute(String(opts.out).get_base_dir())
		var f := FileAccess.open(opts.out, FileAccess.WRITE)
		f.store_string(JSON.stringify(rec, " "))
		f.close()
	fight.queue_free()
	# The answer is the headline; the file has the timeline and the track.
	var head := rec.duplicate()
	head.erase("timeline")
	head.erase("track")
	head.erase("men")
	return head


func _cmd_gf_cover(a: Array) -> Dictionary:
	if a.size() < 3:
		return {"ok": false, "error": HELP.gf_cover}
	var eye := vec(a, 3) if a.size() >= 6 else Vector3(3.6, 1.64, -5.2)
	var fight := Fight.new(self, {})
	fight.player = player
	var space := player.get_world_3d().direct_space_state
	var c: Dictionary = fight._cover_near(space, vec(a, 0), eye, null)
	fight.free()
	if c.is_empty():
		# Why not, at the spot itself.
		var ex: Array[RID] = [player.get_rid()]
		var g: Variant = Cover._ground(space, vec(a, 0), ex)
		var why := "no ground" if g == null else "in plain view" if not Cover._blocked(space, g, eye, Cover.LIE_CHEST, ex) \
				else "no room" if not Cover._room(space, g, ex) \
				else "too low to hide him" if not (Cover.hidden_at(space, g, eye, Cover.HIDE_HEAD, ex) and Cover.hidden_at(space, g, eye, Cover.CHEST, ex)) \
				else "no peek"
		var parts := {}
		if g != null:
			for h in [Cover.LIE_CHEST, Cover.CHEST, Cover.HIDE_HEAD, Cover.CROUCH_HEAD, Cover.STAND_HEAD]:
				var q := PhysicsRayQueryParameters3D.create(eye, (g as Vector3) + Vector3.UP * h, Layers.WORLD)
				q.exclude = ex
				var hit := space.intersect_ray(q)
				parts[str(h)] = "clear" if hit.is_empty() else "%s at %.2f m from him" % [String((hit.collider as Node).name), (hit.position as Vector3).distance_to((g as Vector3) + Vector3.UP * h)]
		return {"cover": false, "why": why, "rays": parts}
	return {"cover": true, "at": arr(c.at), "peek": arr(c.peek) if c.peek != Vector3.INF else null, "low": c.low, "lie": c.lie, "crouch_ok": c.crouch_ok}


func _models(words: Array) -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Fight.SCENARIOS))
	var models: Array = []
	for w: String in (words if not words.is_empty() else ["studio", "outlaw"]):
		for m: String in ((data.gang_models[w] as Dictionary).values() if (data.gang_models as Dictionary).has(w) else [w]):
			if not m in models:
				models.append(m)
	return models


func _cmd_gf_lineup(a: Array) -> Dictionary:
	if a.is_empty() or DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "gf_lineup PATH [bodies...] (a drawn run)"}
	var holstered := "holstered" in a
	var models := _models(a.slice(1).filter(func(w: String) -> bool: return w != "holstered"))
	var men: Array[HumanBody] = []
	var cam_at := Vector3(36.0 + (models.size() - 1) * 0.6, 1.35, -12.6)
	for i in models.size():
		var man := HumanBody.new()
		man.person_id = StringName("lineup_%d" % i)
		man.body_model = StringName(models[i])
		var at := Vector3(36.0 + i * 1.2, 0.0, -8.4)
		man.enter(street, at, HumanBody.yaw_toward(at, cam_at))
		men.append(man)
	await physics_frames(3)
	if not holstered:
		for man in men:
			man.draw_gun()
		await seconds(1.2)
		for man in men:
			man.set_pose(&"aim")
			man.face(cam_at + Vector3(0.6, 0.0, 0.0))
	await seconds(0.8)
	var cam := Camera3D.new()
	street.add_child(cam)
	cam.global_position = cam_at
	cam.look_at(Vector3(cam_at.x, 1.0, -8.4))
	cam.fov = 50.0
	cam.attributes = player.camera.attributes
	cam.make_current()
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(a[0])
	player.camera.make_current()
	cam.queue_free()
	for man in men:
		man.queue_free()
	return {"path": a[0], "models": models}


func _cmd_gf_bodies(a: Array) -> Dictionary:
	var models := _models(a)
	var out := {}
	for model: String in models:
		if out.has(model):
			continue
		var man := HumanBody.new()
		man.person_id = StringName("probe_" + model)
		man.body_model = StringName(model)
		man.enter(street, Vector3(60.0, 0.0, 25.0), 0.0)
		await physics_frames(3)
		out[model] = _surface_outside(man)
		man.queue_free()
		await physics_frames(2)
	return {"bodies": out}


## How much of a man's surface (his skinned meshes' vertices, at rest; his hat aside) lies outside
## every hitbox capsule (the anatomy's, the same for every man): what you can see of him and shoot
## through without touching him.
func _surface_outside(man: HumanBody) -> Dictionary:
	var caps: Array = []
	for sid: StringName in man.anatomy.segments:
		for c: Array in man.anatomy.segments[sid].capsules:
			caps.append(c)
	var n := 0
	var out3 := 0
	var out8 := 0
	var worst := 0.0
	var by_shape := {}
	var top := 0.0
	for key: String in man.skin_meshes:
		var mi := man.skin_meshes[key] as MeshInstance3D
		var shape := key.get_slice("/", 0)
		if shape in HumanBody.HAT_SHAPES:
			continue  # a hat has its own hitbox (hat_hitbox)
		for si in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
			for vi in range(0, verts.size(), 7):
				var v := verts[vi]
				top = maxf(top, v.y)
				var best := INF
				for c: Array in caps:
					var a: Vector3 = c[0]
					var b: Vector3 = c[1]
					var ab := b - a
					var u := clampf((v - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
					best = minf(best, v.distance_to(a + ab * u) - float(c[2]))
				n += 1
				if best > 0.03:
					out3 += 1
					var e: Array = by_shape.get_or_add(shape, [0, 0])
					e[0] += 1
				if best > 0.08:
					out8 += 1
					(by_shape[shape] as Array)[1] += 1
				worst = maxf(worst, best)
	var shapes := {}
	for k: String in by_shape:
		shapes[k] = {"over_3cm": by_shape[k][0], "over_8cm": by_shape[k][1]}
	return {"loaded": PeopleBodies.has_model(man.body_model), "whole": PeopleBodies._is_whole(man.body_model),
		"hat_hitbox": man.hat_body != null, "gun": man.held_gun != null, "holstered": man.gun_holstered,
		"mesh_top_m": snappedf(top, 0.01), "anatomy_height_m": snappedf(man.anatomy.height, 0.01), "vertices": n,
		"outside_hitboxes_over_3cm_pct": snappedf(100.0 * out3 / maxf(n, 1), 0.1),
		"outside_hitboxes_over_8cm_pct": snappedf(100.0 * out8 / maxf(n, 1), 0.1), "furthest_outside_m": snappedf(worst, 0.01),
		"by_shape": shapes}


func _cmd_gf_coverwhy(a: Array) -> Dictionary:
	if a.size() < 6:
		return {"ok": false, "error": HELP.gf_coverwhy}
	var from := vec(a, 0)
	var eye := vec(a, 3)
	var travel := float(a[6]) if a.size() > 6 else 11.0
	var levels := "levels" in a  # candidates dropped to whatever ground is under them, any height
	var space := player.get_world_3d().direct_space_state
	var ex: Array[RID] = [player.get_rid()]
	var rng := RandomNumberGenerator.new()
	var cands: Array[Vector3] = []
	for r: float in Cover.RADII:
		if r > travel:
			break
		for i in Cover.DIRECTIONS:
			var ang := TAU * i / Cover.DIRECTIONS
			cands.append(from + Vector3(cos(ang), 0.0, sin(ang)) * r)
	var shadows := Cover._shadows(space, from, eye, ex, travel)
	cands.append_array(shadows)
	cands = Cover._dedupe(cands)
	var why := {}
	var good: Array = []
	var flat := Vector3(eye.x, from.y, eye.z)
	for p0 in cands:
		var p := p0
		if levels:
			var q := PhysicsRayQueryParameters3D.create(p0 + Vector3.UP * 2.0, p0 + Vector3.DOWN * 2.0, Layers.WORLD)
			q.exclude = ex
			var hit := space.intersect_ray(q)
			if not hit.is_empty() and (hit.normal as Vector3).y > 0.7:
				p = (hit.position as Vector3) + Vector3.UP * 0.05
		var reason := ""
		var g: Variant = Cover._ground(space, p, ex)
		if g == null:
			reason = "no ground"
		elif absf((g as Vector3).y - p.y) > 0.5:
			reason = "step up or down"
		elif not Cover._blocked(space, g, eye, Cover.LIE_CHEST, ex):
			reason = "in plain view (nothing near him in the way)"
		elif not Cover._room(space, g, ex):
			reason = "no room"
		else:
			var spot := Cover.evaluate(space, p, eye, ex)
			if spot.is_empty():
				var hid := Cover.hidden_at(space, g, eye, Cover.HIDE_HEAD, ex) and Cover.hidden_at(space, g, eye, Cover.CHEST, ex)
				var lay := Cover.hidden_at(space, g, eye, Cover.LIE_HEAD, ex) and Cover.hidden_at(space, g, eye, Cover.LIE_CHEST, ex)
				reason = "no peek to shoot from" if hid or lay else "too low to hide him"
			elif not levels and Cover.route(space, from, spot.at, ex).is_empty():
				reason = "no way there"
			elif (spot.at as Vector3).distance_to(flat) < 5.0 or ((spot.at as Vector3) - from).dot((flat - from).normalized()) > 3.0:
				reason = "toward you, or within 5 m of you"
			else:
				good.append(arr(spot.at))
		if reason != "":
			why[reason] = int(why.get(reason, 0)) + 1
	# And what the gang's own search picks (with the town's ways, as their brains call it).
	var places := (street.get_node_or_null(^"TownLife") as TownLife).places
	rng.seed = 7
	var t0 := Time.get_ticks_usec()
	Cover.find(street, from, eye, ex, rng, Vector3.INF, travel)
	var t_plain := Time.get_ticks_usec() - t0
	rng.seed = 7
	t0 = Time.get_ticks_usec()
	var pick := Cover.find(street, from, eye, ex, rng, Vector3.INF, travel, places)
	var t_town := Time.get_ticks_usec() - t0
	var picked: Variant = null
	if not pick.is_empty():
		picked = {"at": arr(pick.at), "low": pick.low, "lie": pick.lie, "way": (pick.route as Array).map(func(w: Vector3) -> Array: return arr(w))}
	return {"candidates": cands.size(), "shadow_points": shadows.size(), "good": good.size(), "good_spots": good.slice(0, 8), "turned_down": why,
		"picked": picked, "ms_plain": t_plain / 1000.0, "ms_town": t_town / 1000.0}


func _cmd_gf_map(a: Array) -> Dictionary:
	var c := Vector3(float(a[0]), 0.0, float(a[1])) if a.size() >= 2 else Vector3(8.0, 0.0, -4.0)
	var r := float(a[2]) if a.size() >= 3 else 20.0
	var out := {"props": [], "structures": [], "lamps": [], "places": {}}
	for n in street.find_children("*", "Node3D", true, false):
		var n3 := n as Node3D
		var p := n3.global_position
		if Vector2(p.x - c.x, p.z - c.z).length() > r:
			continue
		var nm := String(n3.name)
		if n3 is OilLamp:
			out.lamps.append({"name": nm, "at": arr(p), "lit": (n3 as OilLamp).lit, "path": String(street.get_path_to(n3))})
		elif n3 is Structure:
			out.structures.append({"name": nm, "at": arr(p), "script": (n3.get_script() as Script).resource_path.get_file() if n3.get_script() else ""})
		elif nm.begins_with("Crate") or nm.begins_with("Barrel") or nm.begins_with("Hay") or nm.begins_with("Horse") \
				or nm.to_lower().contains("rail") or nm.to_lower().contains("table") or nm.to_lower().contains("chair"):
			out.props.append({"name": nm, "at": arr(p), "parent": String(n3.get_parent().name)})
	var places := (street.get_node_or_null(^"TownLife") as TownLife).places
	for k: StringName in places.points:
		var p: Vector3 = places.points[k]
		if Vector2(p.x - c.x, p.z - c.z).length() <= r:
			out.places[String(k)] = arr(p)
	return out


## Every link between the spec saloon's places walked by a man (built and joined in first): along
## each link from one end, at a run, until he's there, stuck (0.8 s without moving 5 cm) or 12 s.
func _cmd_gf_ways(a: Array) -> Dictionary:
	var prefix := String(a[0]) if a.size() > 0 else "spec_"
	var places := (street.get_node_or_null(^"TownLife") as TownLife).places
	SpecSaloon.ensure(street, places)
	await physics_frames(10)
	var done := {}
	var ok := []
	var bad := []
	var man := HumanBody.new()
	man.name = "Walker"
	man.person_id = &"walker"
	for n: StringName in places.points:
		if not String(n).begins_with(prefix):
			continue
		for nb: StringName in places.links.get(n, []):
			var key := [String(n), String(nb)]
			key.sort()
			if done.has(str(key)):
				continue
			done[str(key)] = true
			var from: Vector3 = places.points[n]
			var to: Vector3 = places.points[nb]
			if not man.is_inside_tree():
				man.enter(street, from + Vector3.UP * 0.05, HumanBody.yaw_toward(from, to))
				await physics_frames(20)
			else:
				man.global_position = from + Vector3.UP * 0.05
				await physics_frames(3)
			var t := 0.0
			var still := 0.0
			var last := man.global_position
			var arrived := false
			while t < 12.0:
				await get_tree().physics_frame
				var dt := 1.0 / Engine.physics_ticks_per_second
				t += dt
				if man.walk_to(to, 3.8, dt):
					arrived = true
					break
				if man.global_position.distance_to(last) < 0.05:
					still += dt
					if still > 0.8:
						break
				else:
					still = 0.0
					last = man.global_position
			var end := man.global_position
			var line := {"from": String(n), "to": String(nb), "s": snappedf(t, 0.1), "at": arr(end - SpecSaloon.Play.ORIGIN),
				"dy": snappedf(end.y - to.y, 0.01), "left_m": snappedf(Vector2(end.x - to.x, end.z - to.z).length(), 0.01)}
			if arrived and absf(end.y - to.y) < 0.3:
				ok.append(line)
			else:
				bad.append(line)
	man.queue_free()
	return {"walked": ok.size(), "blocked": bad.size(), "bad": bad, "ok": ok.map(func(l: Dictionary) -> String: return "%s -> %s %.1f s" % [l.from, l.to, l.s])}


func _cmd_gf_what(a: Array) -> Dictionary:
	SpecSaloon.ensure(street, (street.get_node_or_null(^"TownLife") as TownLife).places)
	await physics_frames(3)
	var shape := SphereShape3D.new()
	shape.radius = float(a[3]) if a.size() > 3 else 0.3
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = Layers.STAND | Layers.PEOPLE
	q.transform = Transform3D(Basis.IDENTITY, SpecSaloon.at(vec(a, 0)))
	var out := []
	for h: Dictionary in player.get_world_3d().direct_space_state.intersect_shape(q, 16):
		var c := h.collider as Node
		out.append(String(c.get("member_id")) if c is StructureMember else String(c.get_path()))
	return {"touches": out}


var _played: Node


func _cmd_gf_play(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": HELP.gf_play}
	if _played != null:
		# Your wounds, blood and rounds are this game's: a fresh fight needs a fresh game (as the Y key
		# reloads the scene, which the bridge can't follow).
		return {"ok": false, "error": "one fight a game: your wounds and rounds carry over. Restart the game (bridge.py stop, then start) for the next"}
	var opts := {"scenario": a[0], "hour": "golden", "weapon": "revolver", "style": "human", "bodies": "game", "seed": 1,
		"variant": String(OutlawBrain.Variant.keys()[OutlawBrain.default_variant]), "max": 300.0, "count": 6.0, "draw_turns": "false"}
	for w: String in a.slice(1):
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	_played = Fight.new(self, opts)
	add_child(_played)
	var err: String = await _played.setup()
	if err != "":
		_played.queue_free()
		return {"ok": false, "error": err}
	return {"setup": a[0], "count_s": float(opts.count), "say": "your gun's away; they go for theirs when you shoot or in %d s" % int(float(opts.count))}


func _cmd_gf_result(_a: Array) -> Dictionary:
	if not is_instance_valid(_played):
		return {"ok": false, "error": "no played fight (gf_play)"}
	var men := {}
	for id: String in _played.gang_ids:
		var m: Dictionary = _played._men[id]
		men[id] = m.outcome
	return {"started": _played.started, "over": _played.done, "t": snappedf(_played.t, 0.1), "ending": _played.record.get("ending", ""),
		"men": men}

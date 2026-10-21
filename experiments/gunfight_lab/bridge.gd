extends BridgeLab
## The gunfight lab's bridge commands (README.md beside this file; docs/briefs/labs.md "Gunfight
## lab"). run.py starts one game per fight with `gf_fight ...` as its --bridge-script, so the fight
## starts on the same frame every time (a seed gives the same fight).

const Fight := preload("res://experiments/gunfight_lab/fight.gd")

const HELP := {
	"gf_fight": "gf_fight SCENARIO [hour=golden|night|H] [weapon=revolver|shotgun] [style=hold|cover|push] [bodies=studio|outlaw|game] [seed=N] [aim=DEGREES] [max=S] [out=FILE.json] [shots=DIR every=S] -> one fight to its end, its numbers",
	"gf_lineup": "gf_lineup PATH [holstered] [studio|outlaw|MODEL...] -> the men side by side, guns up (or holstered), facing a camera: a picture (drawn runs)",
	"gf_cover": "gf_cover X Y Z [FROM_X FROM_Y FROM_Z] -> is there cover within 1.5 m of X Y Z from that eye (default: the street's trough), as the gang judges it",
	"gf_bodies": "gf_bodies [studio|outlaw|MODEL...] -> each man stood up alone: his hat's hitbox, his gun, and how much of what you see of him no hitbox covers",
	"gf_map": "gf_map [X Z R] -> what stands near the arena (cover props, troughs, lamps, places) within R m of X Z",
}


func _cmd_gf_fight(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": HELP.gf_fight}
	var opts := {"scenario": a[0], "hour": "golden", "weapon": "revolver", "style": "hold", "bodies": "studio", "seed": 1,
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
	var c: Dictionary = fight._cover_near(player.get_world_3d().direct_space_state, vec(a, 0), eye, null)
	fight.free()
	if c.is_empty():
		return {"cover": false}
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

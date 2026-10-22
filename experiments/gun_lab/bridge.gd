extends BridgeLab
## The gun lab's dev bridge commands (README.md beside this file). Each job clears the town first,
## so run.py starts a fresh game for each.

const Bench := preload("res://experiments/gun_lab/bench.gd")

const HELP := {
	"gun_fp": "gun_fp revolver|shotgun [out=DIR] [hour=H] -> the gun in first person, a frame a state (rest, aim, walk, run, cocking, the shot, every reload step, put away): DIR/fp_<gun>/*.png and DIR/fp_<gun>.json (needs drawing: xvfb)",
	"gun_men": "gun_men BODY [out=DIR] [hour=H] -> one man's gun holstered, drawing, aiming, firing, reloading, dropped, from 1, 5 and 10 m, with the grip's gap to his hand: DIR/men_<body>/*.png, DIR/men_<body>.json (needs drawing)",
	"gun_grip": "gun_grip BODY -> the grip's and holster's gaps for one man, no frames (headless is fine)",
	"gun_framing": "gun_framing revolver|shotgun [aim] -> the share of each hand on screen, and where each hand part lands in the view (pixels), the gun held at rest (or aimed)",
	"gun_handling": "gun_handling [out=DIR] -> draw to first shot, cocking, rhythm, reloads, sight recovery, accuracy (steady, rushed, hip, walking, wounded) for both guns, and the outlaw's figures: DIR/handling.json",
}


func _bench(a: Array) -> Node:
	var b: Node = Bench.new()
	b.name = "GunBench"
	b.lab = self
	b.out_dir = "build/gun_lab/bridge"
	for w: String in a:
		var kv := w.split("=", true, 1)
		match kv[0]:
			"out": b.out_dir = kv[1]
			"hour": b.hour = float(kv[1])
	if not b.out_dir.is_absolute_path():
		b.out_dir = ProjectSettings.globalize_path("res://").path_join(b.out_dir)
	DirAccess.make_dir_recursive_absolute(b.out_dir)
	# Its PNGs aren't the project's to import.
	var root := ProjectSettings.globalize_path("res://").path_join("build")
	if b.out_dir.begins_with(root) and not FileAccess.file_exists(root.path_join(".gdignore")):
		FileAccess.open(root.path_join(".gdignore"), FileAccess.WRITE).close()
	add_child(b)
	return b


func _cmd_gun_fp(a: Array) -> Dictionary:
	if a.is_empty() or not a[0] in ["revolver", "shotgun"]:
		return {"ok": false, "error": "gun_fp revolver|shotgun [out=DIR]"}
	if DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "headless: nothing is drawn"}
	var b := _bench(a.slice(1))
	var out: Dictionary = await b.fp(String(a[0]))
	b.queue_free()
	return {"frames": (out.frames as Array).size(), "out": b.out_dir}


func _cmd_gun_men(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "gun_men BODY [out=DIR]"}
	if DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "headless: nothing is drawn"}
	var b := _bench(a.slice(1))
	var out: Dictionary = await b.men(StringName(a[0]))
	b.queue_free()
	return {"states": (out.states as Array).map(func(s: Dictionary) -> Dictionary: return {"state": s.state, "gap": s.gap}),
			"dropped": out.dropped}


func _cmd_gun_grip(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "gun_grip BODY"}
	var b := _bench([])
	await b.quiet_town()
	var man := HumanBody.new()
	man.has_gun = true
	man.start_holstered = true
	man.body_model = StringName(a[0])
	man.person_id = &"gunlab_grip"
	street.add_child(man)
	man.global_position = Bench.SPOT
	await seconds(1.0)
	var holstered: Dictionary = b.grip_gap(man)
	man.draw_gun()
	man.set_pose(&"aim")
	await seconds(1.0)
	var aimed: Dictionary = b.grip_gap(man)
	man.queue_free()
	b.queue_free()
	return {"holstered": holstered, "aiming": aimed}


func _cmd_gun_framing(a: Array) -> Dictionary:
	if a.is_empty() or not a[0] in ["revolver", "shotgun"]:
		return {"ok": false, "error": "gun_framing revolver|shotgun [aim]"}
	var b := _bench([])
	await b.quiet_town()
	await b._place_player()
	var w: WeaponViewmodel = await b._gun(String(a[0]))
	if a.has("aim"):
		bridge._act(true, &"aim")
	await seconds(1.0)
	var out: Dictionary = b.framing(w)
	var cam: Camera3D = player.camera
	var parts := {}
	for mi in w.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var path := String(w.get_path_to(m))
		if path.contains("Hand") or path.contains("Forearm"):
			parts[path] = [cam.unproject_position(m.global_position).round(), cam.is_position_behind(m.global_position)]
	out["parts"] = parts
	out["view"] = cam.get_viewport().get_visible_rect().size
	out["fov"] = cam.fov
	bridge._act(false, &"aim")
	b.queue_free()
	return out


func _cmd_gun_handling(a: Array) -> Dictionary:
	var b := _bench(a)
	var out: Dictionary = await b.handling()
	b.queue_free()
	return out

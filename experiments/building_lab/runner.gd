extends Node
## The building lab's runner (runner.gd; started by run.gd): every check in docs/briefs/building-pipeline.md that runs headless,
## on the saloon built from its spec, each on a fresh build, written to results/<date>/.
##   godot --headless --fixed-fps 60 -s res://experiments/building_lab/run.gd -- --out=experiments/building_lab/results/2026-10-22
## (A Node, so it compiles once the autoloads exist; run.gd only starts it.)

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")

var out_dir := "res://experiments/building_lab/results/latest"
var results := {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = "res://" + arg.substr(6).trim_prefix("res://")
		elif arg.begins_with("--only="):
			only = arg.substr(7)
	if only == "shots":
		# Rerun the shots alone, into the results there.
		var f := FileAccess.open(out_dir + "/results.json", FileAccess.READ)
		if f:
			results = JSON.parse_string(f.get_as_text())
		results.shots = await _shoot()
		_save()
		get_tree().quit()
		return
	var root := get_tree().root
	var settings := root.get_node_or_null(^"Settings")
	if settings:
		settings.autosave = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var lab := await _fresh()
	var b: Structure = lab.building
	var t0 := Time.get_ticks_msec()
	b.rebuild()
	lab.fittings.collect()  # (what it collected before were the old build's things)
	results.build = {"ms": Time.get_ticks_msec() - t0, "members": b.member_count(), "kit_props": b.kit_props.size(),
			"kit_members": b.kit_props.reduce(func(n: int, k: KitProp) -> int: return n + k.member_count(), 0), "lamps": b.lamps.size()}
	await get_tree().physics_frame
	results.destructible = Checks.destructible(b, b)
	results.stands = Checks.stands(b)
	var posts: Array = []
	for m in b.members_of_kind(&"post"):
		if String(m.member_id).begins_with("saloon_spec/post/") or String(m.member_id).contains("street/post") or String(m.member_id).contains("cellar/post"):
			posts.append(m.member_id)
	results.knockouts = Checks.knockouts(b, posts)
	results.people_fit = Checks.people_fit(b, lab.spec)
	results.used = Checks.used(b, lab.spec)
	results.draws = Checks.draw_calls(b)
	results.kinds = _kinds(b)
	results.frame = await _frame_time(lab)
	_save()
	lab.queue_free()
	await get_tree().physics_frame

	results.falls = await _knock_post(&"saloon_spec/post/12")
	_save()
	results.burns = await _burn()
	_save()
	results.shots = await _shoot()
	_save()
	results.blast = await _blast()
	_save()
	print("building lab: done -> %s" % out_dir)
	get_tree().quit()


func _fresh() -> Node3D:
	var lab := Lab.new()
	get_tree().root.add_child(lab)
	for i in 6:
		await get_tree().physics_frame
	return lab


func _kinds(b: Structure) -> Dictionary:
	var out := {}
	for m in b.get_members():
		out[String(m.kind)] = int(out.get(String(m.kind), 0)) + 1
	return out


## Wall time a frame over two seconds standing, every lamp lit, after the first second's
## one-off looks (Fittings, the kit's feet). Headless: physics and scripts, not rendering (the
## render run's). (Performance's TIME_ monitors read stale headless: measured by the clock.)
func _frame_time(lab: Node3D) -> Dictionary:
	for l: OilLamp in lab.building.lamps:
		l.set_lit(true)
	for i in 60:
		await get_tree().physics_frame
	var n := 120
	var t0 := Time.get_ticks_usec()
	for i in n:
		await get_tree().physics_frame
	return {"frame_ms": snappedf((Time.get_ticks_usec() - t0) / float(n) / 1000.0, 0.01), "note": "headless wall time a frame on this workspace's core; x0.65 for Sean's (CLAUDE.md)"}


## A gallery post knocked out, for real: what comes down, and whether anything is left standing
## with nothing under it once it's settled.
func _knock_post(id: StringName) -> Dictionary:
	var lab := await _fresh()
	var b: Structure = lab.building
	var post := b.get_member(id)
	var at := post.global_position
	var before := b.member_count()
	b.break_member(post)
	b.settle()
	for i in 240:
		await get_tree().physics_frame
	var broken := 0
	for m in b.get_members():
		if m.broken:
			broken += 1
	var floats: Array = []
	var held := {}
	for m in b.get_members():
		if m.broken:
			held[m.member_id] = true
	for f in b.members_without_load_path(held):
		floats.append(String(f).trim_prefix("saloon_spec/"))
	var out := {"post": String(id), "at": [snappedf(at.x, 0.01), snappedf(at.z, 0.01)], "members": before, "broken_or_fallen": broken,
			"rubble_bodies": b.rubble.size(), "floats": floats.slice(0, 20), "floats_count": floats.size(), "ok": floats.is_empty() and broken > 1}
	lab.queue_free()
	await get_tree().physics_frame
	return out


## A wall board by the bar and a floor board under a table set alight; the fire's rules run for
## twelve minutes in half-second steps.
func _burn() -> Dictionary:
	var lab := await _fresh()
	var b: Structure = lab.building
	var fire: FireSystem = lab.fire
	var lit := []
	for prefix in ["saloon_spec/hall_back/m/board/060", "saloon_spec/floor/ground/board/040_"]:
		for m in b.get_members():
			if String(m.member_id).begins_with(prefix):
				fire.ignite(m)
				lit.append(String(m.member_id))
				break
	var marks := {}
	var t := 0.0
	var ms := Time.get_ticks_msec()
	while t < 720.0:
		fire.step(0.5)
		t += 0.5
		if int(t) % 120 == 0 and absf(t - roundf(t)) < 0.01:
			var burning := 0
			var consumed := 0
			var kit_burning := 0
			for m in b.get_members():
				if m.burning:
					burning += 1
				if m.consumed:
					consumed += 1
			for k: KitProp in b.kit_props:
				for m in k.get_members():
					if m.burning:
						kit_burning += 1
			marks["%d s" % int(t)] = {"burning": burning, "consumed": consumed, "kit_burning": kit_burning}
	var out := {"lit": lit, "marks": marks, "ms": Time.get_ticks_msec() - ms}
	out.ok = int((marks.values().back() as Dictionary).burning) + int((marks.values().back() as Dictionary).consumed) > 50
	lab.queue_free()
	await get_tree().physics_frame
	return out


## Revolver balls from the door into the bar's front, a post, a wall board and the gallery's
## rail: each carves what it meets.
func _shoot() -> Dictionary:
	var lab := await _fresh()
	var b: Structure = lab.building
	var tune: RevolverTuning = load("res://config/revolver.tres")
	var from := Vector3(7.62, 0.78 + 1.5, 0.8)
	var targets := {"bar_front": Vector3(2.04, 0.78 + 0.6, 6.9), "post": Vector3(5.49, 2.2, 4.78), "east_wall": Vector3(15.12, 2.6, 4.0),
			"gallery_rail": Vector3(10.24, 4.44 + 0.9, 1.9), "chair": Vector3(11.64 + 0.85 * sin(deg_to_rad(15.0)), 0.6, 4.2 + 0.85 * cos(deg_to_rad(15.0)))}
	var out := {}
	for k: String in targets:
		var dir := ((targets[k] as Vector3) - from).normalized()
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 30.0, Layers.WORLD)
		var hit := b.get_world_3d().direct_space_state.intersect_ray(q)
		var m := hit.get("collider") as StructureMember
		var holes_before := m.holes.size() if m else 0
		var bullet: Ballistics.Bullet = lab.ballistics.fire(from, dir, tune.muzzle_velocity, tune.bullet_mass, tune.bullet_diameter)
		for i in 120:
			await get_tree().physics_frame
			if not bullet.alive:
				break
		out[k] = {"first_hit": String(m.member_id) if m else str(hit.get("collider")), "holed": m != null and (m.holes.size() > holes_before or m.voxels != null), "voxels": m != null and m.voxels != null}
	out.ok = (out.values().filter(func(v: Variant) -> bool: return v is Dictionary and v.holed) as Array).size() >= 4
	lab.queue_free()
	await get_tree().physics_frame
	return out


## A stick of dynamite on the hall's floor by a card table.
func _blast() -> Dictionary:
	var lab := await _fresh()
	var b: Structure = lab.building
	var at := b.to_global(Vector3(5.2, 0.85, 6.0))
	var before := b.rubble.size()
	var r := Blast.detonate(lab, at, 0.2)
	for i in 180:
		await get_tree().physics_frame
	var broken := 0
	for m in b.get_members():
		if m.broken:
			broken += 1
	var loose := 0
	for k: KitProp in b.kit_props:
		if is_instance_valid(k) and k.loose:
			loose += 1
	var out := {"at": [5.2, 6.0], "broken": broken, "rubble": b.rubble.size() - before, "kit_props_thrown_or_broken": loose, "detonate": r.keys()}
	out.ok = broken > 0
	lab.queue_free()
	await get_tree().physics_frame
	return out


func _save() -> void:
	var f := FileAccess.open(out_dir + "/results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "\t"))
	f.close()

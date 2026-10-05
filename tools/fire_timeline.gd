extends SceneTree
## How a fire grows, in game seconds: two boards of the general store's back wall lit, a second
## store 4 m off its side (the gap between lots), and the fire's rules run in half-second steps
## with no drawing. Prints when 5, 20 and 50 members are burning, the first framing member alight,
## half the roof down, and the neighbour catching; and a line every 30 s. For tuning how long you
## have to put a fire out (config/fire.tres).
##   godot --headless -s res://tools/fire_timeline.gd [-- --seconds=1200 --set=growth_seconds:30,...]

func _init() -> void:
	await process_frame
	var seconds := 1200.0
	var sets := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.get_slice("=", 1))
		elif a.begins_with("--set="):
			sets = a.get_slice("=", 1)
	var world := Node3D.new()
	root.add_child(world)
	var fire: Node = load("res://src/fire/fire_system.gd").new()
	world.add_child(fire)
	# --set=name:value,... tries other numbers without touching config/fire.tres.
	for kv in sets.split(",", false):
		fire.tuning.set(kv.get_slice(":", 0), float(kv.get_slice(":", 1)))
	var ff: Script = load("res://src/structures/false_front_building.gd")
	var store: Node3D = ff.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	var next: Node3D = ff.new()
	next.structure_id = &"next"
	next.build_seed = 8
	world.add_child(next)
	await physics_frame
	var box: AABB = _bounds(store)
	next.position = Vector3(box.end.x + 4.0 - _bounds(next).position.x, 0, 0)
	await physics_frame
	var rafters: Array = store.get_members().filter(func(m) -> bool:
		return String(m.member_id).begins_with("store/roof/") and m.kind == &"rafter")
	fire.ignite(store.get_member(&"store/back/siding/c10_0"))
	fire.ignite(store.get_member(&"store/back/siding/c11_0"))
	var marks := {}
	var t := 0.0
	var last_line := -30.0
	while t <= seconds:
		fire.step(0.5)
		t += 0.5
		var burning := 0
		var framing := false
		var next_burning := 0
		for m in store.get_members():
			if m.burning:
				burning += 1
				if m.kind in [&"stud", &"post", &"rafter", &"joist", &"plate", &"beam"]:
					framing = true
		for m in next.get_members():
			if m.burning:
				next_burning += 1
		var down := rafters.filter(func(m) -> bool: return m.broken).size()
		for n in [5, 20, 50]:
			if burning >= n and not marks.has("burning_%d" % n):
				marks["burning_%d" % n] = t
		if framing and not marks.has("framing"):
			marks["framing"] = t
		if down >= rafters.size() / 2 and not marks.has("roof_in"):
			marks["roof_in"] = t
		if next_burning > 0 and not marks.has("next_catches"):
			marks["next_catches"] = t
		if t - last_line >= 30.0:
			last_line = t
			print("  %4.0f s  burning %3d  roof down %d/%d  next %d" % [t, burning, down, rafters.size(), next_burning])
		if marks.has("roof_in") and marks.has("next_catches") and t > marks.roof_in + 60.0:
			break
	for k in ["burning_5", "burning_20", "burning_50", "framing", "roof_in", "next_catches"]:
		print("%-14s %s" % [k, ("%.0f s" % marks[k]) if marks.has(k) else "-"])
	quit()


func _bounds(s: Node) -> AABB:
	var b := AABB()
	var first := true
	for m in s.get_members():
		var a: AABB = m.world_aabb()
		b = a if first else b.merge(a)
		first = false
	return b

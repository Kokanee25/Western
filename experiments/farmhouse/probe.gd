extends SceneTree
## The farmhouse built on its own (no street): how long, how many members, whether it stands, fits
## people and is destructible through and through (the building lab's checks).
##   godot --headless -s res://experiments/farmhouse/probe.gd



func _initialize() -> void:
	# Loaded here, not named or preloaded: a -s script is compiled before the autoloads are there.
	var Checks: GDScript = load("res://experiments/building_lab/checks.gd")
	var root3 := Node3D.new()
	root.add_child(root3)
	var t0 := Time.get_ticks_msec()
	var f: Node3D = load("res://src/missions/farmhouse.gd").new()
	root3.add_child(f)
	print("built in %d ms" % (Time.get_ticks_msec() - t0))
	await physics_frame
	await physics_frame
	var b = f.building
	var r: Dictionary = Checks.destructible(f, b)
	print("members %d, kit props %d (%d members), lamps %d, bad %s, rigs %s, allowed %s" % [r.members, r.kit_props, r.kit_members, r.lamps, (r.bad as Array).slice(0, 10), r.rigs, r.allowed])
	var st: Dictionary = Checks.stands(b)
	print("stands: dead %s" % [st.dead])
	print("crowd %s" % [st.crowd])
	var pf: Dictionary = Checks.people_fit(b, f.building.spec)
	print("people fit: %s" % [pf])
	print("porch members %d" % f.porch.members_of_kind(&"floor_board").size())
	print("marks: %s" % [(f.building.marks as Dictionary).keys()])
	for id in b.members_without_load_path():
		print("no load path: %s supported_by %s" % [id, b.get_member(id).supported_by])
	for id in ["farmhouse/floor/loft/board/026_0", "farmhouse/floor/loft/board/012_0", "farmhouse/lean_to/rafter/01"]:
		var m = b.get_member(StringName(id))
		if m:
			print("%s size %s at %s supported_by %s" % [id, m.size, m.position, m.supported_by])
	quit()

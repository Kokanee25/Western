extends TestCase
## Our own cloth (#973, docs/briefs/garment-cloth.md step 1): `ClothCore` in the native plugin
## (addons/saltcreek_native/src/cloth.rs; its own `cargo test` too) and its face `SolverCloth`.
## A sheet pinned at two corners hangs within its strain limit, bends less with more bending
## stiffness, comes out bit for bit the same from the same seed, and never goes through the floor;
## the face's pins ride a node, let go it falls, lies and comes to rest. Needs the library in
## addons/saltcreek_native/bin (CI builds it).

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _native() -> bool:
	if ClassDB.class_exists(&"ClothCore"):
		return true
	check(false, "ClothCore is registered by addons/saltcreek_native (build it: cargo build --release there)")
	return false


## A sheet `cols`×`rows`, `w`×`d` m, flat at height `y`: [points, triangles].
func _sheet(cols: int, rows: int, w: float, d: float, y: float) -> Array:
	var pts := PackedVector3Array()
	for r in rows:
		for c in cols:
			pts.append(Vector3(w * (float(c) / (cols - 1) - 0.5), y, d * (float(r) / (rows - 1) - 0.5)))
	var tris := PackedInt32Array()
	for r in rows - 1:
		for c in cols - 1:
			var i := r * cols + c
			if (r + c) % 2 == 0:
				tris.append_array([i, i + 1, i + cols, i + 1, i + cols + 1, i + cols])
			else:
				tris.append_array([i, i + cols + 1, i + cols, i, i + 1, i + cols + 1])
	return [pts, tris]


func _core(cols: int, rows: int, w: float, d: float, y: float, tune := {}) -> RefCounted:
	var core: RefCounted = ClassDB.instantiate(&"ClothCore")
	for k: String in tune:
		check(core.tune(k, float(tune[k])), "a number: %s" % k)
	var s := _sheet(cols, rows, w, d, y)
	check(core.build(s[0], s[1], 0.2), "built")
	return core


func _run(core: RefCounted, ticks: int) -> void:
	for t in ticks:
		core.step(1.0 / 60.0)


func test_a_sheet_pinned_at_two_corners_hangs_within_its_strain_limit() -> void:
	if not _native():
		return
	var core := _core(16, 16, 0.5, 0.5, 1.0, {"floor_on": 0, "max_strain": 1.08})
	check_eq(core.point_count(), 256, "points")
	core.pin(PackedInt32Array([0, 15]), true)
	_run(core, 300)
	var pts: PackedVector3Array = core.points()
	check(pts[0].is_equal_approx(Vector3(-0.25, 1.0, -0.25)), "the pinned corner stays: %s" % pts[0])
	check(core.lowest_y() < 0.6, "it hangs: lowest %.3f" % core.lowest_y())
	check(core.max_strain() <= 1.08 * 1.01, "edges within the strain limit: %.4f" % core.max_strain())
	check(core.mean_speed() < 0.05, "it settles: %.3f m/s" % core.mean_speed())
	check(not core.tune("no_such_number", 1.0), "an unknown number is refused")


func test_more_bending_stiffness_bends_less() -> void:
	if not _native():
		return
	# Clamped along one edge by two rows (one row is a hinge a flat sheet turns about freely).
	var droop := []
	for k in [1e-5, 1e-3, 1e-2]:
		var core := _core(12, 8, 0.3, 0.19, 1.0, {"floor_on": 0, "damping": 3.0, "bend_stiffness": k})
		var clamped := PackedInt32Array()
		for i in 24:
			clamped.append(i)
		core.pin(clamped, true)
		_run(core, 600)
		droop.append(1.0 - core.lowest_y())
	check(droop[0] > droop[1] and droop[1] > droop[2], "droop %s" % [droop])
	check(droop[2] < 0.5 * droop[0], "the stiff one droops under half the soft one's: %s" % [droop])


func test_the_same_seed_gives_the_same_bits() -> void:
	if not _native():
		return
	var runs := []
	for seed_value in [5, 5, 6]:
		var core := _core(12, 12, 0.4, 0.4, 0.5)
		core.jitter(seed_value, 0.001)
		_run(core, 90)
		runs.append(core.points())
	check(runs[0] == runs[1], "seed 5 twice: the same points to the bit")
	check(runs[0] != runs[2], "seed 6: not the same")


func test_nothing_goes_through_the_floor() -> void:
	if not _native():
		return
	var core := _core(16, 16, 0.5, 0.5, 0.3, {"floor_y": 0.1, "thickness": 0.003})
	core.jitter(3, 0.002)
	core.add_velocity(Vector3(0.5, -4.0, 0.0))   # thrown down hard
	var least := INF
	for t in 180:
		core.step(1.0 / 60.0)
		least = minf(least, core.lowest_y())
	check(least >= 0.103 - 1e-5, "never under the floor and its thickness: %.5f" % least)
	check(core.mean_speed() < 0.05, "it lies there: %.3f m/s" % core.mean_speed())


func test_the_face_holds_lets_go_and_rests() -> void:
	if not _native():
		return
	var s := _sheet(10, 10, 0.3, 0.3, 1.0)
	var cloth := SolverCloth.make(s[0], s[1], PackedVector2Array(), null, 0.2, {"floor_y": 0.0})
	check(cloth != null, "made")
	world.add_child(cloth)
	var hand := Node3D.new()
	world.add_child(hand)
	var corners: Array[int] = [0, 9]
	cloth.pin_to(corners, hand)
	check(cloth.held == SolverCloth.Held.HAND, "held")
	for t in 30:
		hand.position.x += 0.01
		await physics_frames(1)
	var pts := cloth.points_now()
	check_near(pts[0].x, -0.15 + 0.3, 0.02, "the pinned corner rode the hand")
	check(cloth.stretch() < 1.08, "stretch %.3f" % cloth.stretch())
	cloth.let_go(Vector3(0, 0, 1))
	check(cloth.held == SolverCloth.Held.FREE, "free")
	var t := 0
	while not cloth.resting and t < 600:
		await physics_frames(1)
		t += 1
	check(cloth.resting, "it comes to rest on the floor (%d ticks)" % t)
	var low := INF
	for p in cloth.points_now():
		low = minf(low, p.y)
	check(low >= 0.0, "on the floor, not through it: %.4f" % low)
	check(cloth.mesh_instance.mesh.get_surface_count() == 1, "drawn")


func test_without_the_plugin_the_face_gives_way_to_jolt() -> void:
	# Where the plugin isn't (the web build), SolverCloth.make gives null and the caller keeps
	# GarmentCloth (the Jolt soft body).
	if SolverCloth.available():
		check(ClassDB.class_exists(&"ClothCore"), "available means ClothCore")
		return
	var s := _sheet(4, 4, 0.1, 0.1, 0.0)
	check(SolverCloth.make(s[0], s[1], PackedVector2Array(), null) == null, "null without the plugin")

extends TestCase
## The masonry lab's step 2 (docs/briefs/masonry-lab.md; docs/destruction/destruction-spec.md
## sections 2, 5 and 6): the loader reads materials.json, the expander lays the same wall from the
## same seed (and the committed panel is what it lays), a charge breaks joints, not stones, and a
## stick at the foot of the rubble-stone panel blows a hole through it and drops the stone above.

const PANEL := "res://config/destruction/structures/wall_panel.json"

var world: Node3D


func before_each() -> void:
	world = null


func after_each() -> void:
	if world != null:
		world.queue_free()
		world = null
		await physics_frames(2)


func _panel() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PANEL))


func test_the_loader_reads_the_materials() -> void:
	check(MasonryMaterials.is_masonry(&"rubble_stone"), "rubble stone is masonry")
	check(MasonryMaterials.is_masonry(&"adobe"), "adobe is masonry")
	check(MasonryMaterials.is_masonry(&"stone"), "the game's older stone is masonry")
	check(not MasonryMaterials.is_masonry(&"timber_in_masonry"), "timber in masonry is timber")
	check(not MasonryMaterials.is_masonry(&"framing"), "framing isn't")
	check_eq(MasonryMaterials.density(&"rubble_stone"), 2350.0, "rubble's density from the file")
	check_eq(MasonryMaterials.dial("min_bearing_share"), 0.25, "the solver's dials from the file")
	check_eq(float(MasonryMaterials.mortar_of(&"rubble_stone").tension), 80000.0, "its mortar's tension")
	var t := load("res://config/voxel_damage.tres") as VoxelDamageTuning
	check_eq(t.spall_cost(&"rubble_stone"), 150.0, "a ball carves it at its small_hit j_per_cm3")


func test_the_expander_lays_the_same_wall_from_the_same_seed() -> void:
	var spec := _panel()
	var mats := MasonryMaterials.data()
	var a := MasonryExpander.to_text(MasonryExpander.new().expand(spec, mats))
	var b := MasonryExpander.to_text(MasonryExpander.new().expand(spec, mats))
	check(a == b, "the same seed, the same wall")
	check(a == FileAccess.get_file_as_string(PANEL), "the committed panel is its walls expanded (run tools/masonry_expand.gd)")
	var other := spec.duplicate(true)
	other.seed = 2
	check(MasonryExpander.to_text(MasonryExpander.new().expand(other, mats)) != a, "another seed, another wall")


func test_the_panel_is_laid_soundly() -> void:
	var spec := _panel()
	var w := MasonryWall.from_spec(spec)
	check(w.count() > 250 and w.count() < 350, "about 300 stones (%d)" % w.count())
	var mass := 0.0
	for i in w.count():
		mass += w.mass[i]
		check(not w.rests_on[i].is_empty(), "%s rests on something" % w.ids[i])
		for s in w.rests_on[i]:
			if s >= 0:
				check(w.course[s] == w.course[i] - 1, "%s rests on the course under it" % w.ids[i])
		# No two boxes share any volume.
		for k in range(i + 1, w.count()):
			var o := (w.hi[i].min(w.hi[k]) - w.lo[i].max(w.lo[k]))
			if o.x > 0.002 and o.y > 0.002 and o.z > 0.002:
				check(false, "%s and %s overlap" % [w.ids[i], w.ids[k]])
	# 4 x 3 x 0.55 m of stone at 2,350 kg/m³, and the footing.
	check(mass > 4.0 * 3.0 * 0.55 * 2350.0 and mass < 4.0 * 3.3 * 0.75 * 2350.0, "its weight (%.0f kg)" % mass)
	check(w.ja.size() > 3 * w.count(), "joints between them (%d)" % w.ja.size())


## A stick at the panel's foot by its middle (spec section 5): its joints break over a stretch of
## wall, it frees stones, and the stones it cracks are few and right by it.
func test_a_charge_breaks_joints_not_stones() -> void:
	var w := MasonryWall.from_spec(_panel())
	var standing := {}
	for i in w.count():
		standing[i] = true
	var at := Vector3(2.0, 0.15, -0.15)
	var kg := Blast.t().tnt_per_stick * Blast.ground_share(Blast.t().tnt_per_stick, 0.15)
	var res := MasonryBlast.strike(w, at, kg, standing)
	var freed: Dictionary = res.freed
	check(res.broke.size() > 20, "joints broken (%d)" % res.broke.size())
	check(freed.size() >= 6, "stones freed (%d)" % freed.size())
	check(res.cracked.size() * 2 <= freed.size(), "stones mostly not cracked (%d of %d freed)" % [res.cracked.size(), freed.size()])
	for i: int in res.cracked:
		var d := (w.at[i] - at).length()
		check(d < 0.9, "a cracked stone is right by the charge (%.2f m)" % d)
	for i: int in freed:
		check((freed[i] as Vector3).z > 0.0, "%s flies away from the charge" % w.ids[i])
	# Far from it nothing gives.
	for j in res.broke:
		var mid := (w.at[w.ja[j]] + w.at[w.jb[j]]) * 0.5
		check((mid - at).length() < 2.5, "a broken joint is near the charge")
	# Behind the wall the same stick pushes the other way.
	var behind := MasonryBlast.strike(w, Vector3(2.0, 0.15, 0.7), kg, standing)
	for i: int in behind.freed:
		check((behind.freed[i] as Vector3).z < 0.0, "from behind, it flies out the front")
		break


## An intact panel stands: no element over 1, nothing falling, its weight all to the ground, and
## masonry never through the timber checks.
func test_the_panel_stands_whole() -> void:
	var s := await _build()
	var a := StructuralAnalysis.new().analyse(s)
	check(a.falling.is_empty(), "nothing falls")
	check(a.overloaded().is_empty(), "nothing over (%s)" % [a.overloaded().slice(0, 3)])
	var weight := 0.0
	for m in s.get_members():
		weight += m.weight(s.tuning)
	check_near(a.ground_load, weight, weight * 1e-4, "its weight reaches the ground")
	for id: StringName in a.mode:
		check(a.mode[id] in [&"bearing", &"bond"], "masonry checked only as masonry (%s)" % a.mode[id])
		if not a.mode[id] in [&"bearing", &"bond"]:
			break


## The breach (the step's "done when"): a stick at the foot blows a ragged hole through the wall and
## the stone over the hole falls; the ends of the wall stand.
func test_a_stick_at_the_foot_blows_a_hole_and_the_stone_above_falls() -> void:
	var s := await _build()
	var w := s.wall
	var at := s.to_global(Vector3(2.0, 0.12, -0.12))
	var report := Blast.detonate(world, at, Blast.t().tnt_per_stick)
	var freed: Dictionary = s.last_blast.freed
	await physics_frames(90)
	var fallen_above := 0
	var hole_through := 0
	var ends_standing := true
	for i in w.count():
		var m := s.element(i)
		var x := w.at[i].x
		if m.broken and not freed.has(i) and w.course[i] >= 2:
			fallen_above += 1
		if m.broken and w.course[i] <= 3 and absf(x - 2.0) < 0.6:
			hole_through += 1
		if (x < 0.4 or x > 3.6) and w.course[i] >= 1 and m.broken:
			ends_standing = false
	check(report.broken.size() > 0, "the blast broke the wall (%d)" % report.broken.size())
	check(freed.size() >= 6, "it blew stones out (%d)" % freed.size())
	check(hole_through >= 6, "a hole at the foot (%d stones gone)" % hole_through)
	check(fallen_above >= 1, "the stone over the hole fell (%d)" % fallen_above)
	check(ends_standing, "the wall's ends stand")
	# Both leaves gone somewhere at the foot: a way through.
	var leaves := {}
	for i: int in freed:
		leaves[w.wythe[i]] = true
		if w.kinds[i] == &"through":
			leaves[0] = true
			leaves[1] = true
	check(leaves.size() == 2, "both leaves blown: a hole through")


func _build() -> MasonryStructure:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	var s := MasonryStructure.from_file(PANEL)
	world.add_child(s)
	await physics_frames(2)
	return s

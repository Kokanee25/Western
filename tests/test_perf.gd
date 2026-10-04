extends TestCase
## The street mustn't creep back to costing what it did (tools/perf_bench.gd measures it properly;
## this guards it). Counts are exact and budgeted close; times are on whatever machine runs the
## tests, so their budgets leave room for a slow CI runner: about 3x what this workspace's 2.1 GHz
## core takes now. Today, here: calm 4.9 ms a frame, 1,291 visible meshes, ~43 a person, 25.5k
## nodes (an armed man 89); burning, 8.8 ms a frame, worst 72 ms.

const CALM_FRAME_MS := 16.0
const FIRE_FRAME_MS := 30.0
const FIRE_WORST_MS := 250.0
const VISIBLE_MESHES := 1800  # was 3,686 before the performance pass
## Body ~11, fingers 30, and an armed man's revolver 45 parts (was ~140 with the body in pieces).
const MESHES_A_PERSON := 95
const NODES := 30000

var street: Node3D


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await process_frames(3)
	(street.get_node(^"Player") as Player).input_enabled = false
	(street.get_node(^"TownLife") as TownLife).bring_gang()
	await process_frames(90)


func after_each() -> void:
	street.queue_free()
	await process_frames(2)


## Frame times (ms) over `n` frames, wall clock.
func _frames(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var last := Time.get_ticks_usec()
	for i in n:
		await process_frames(1)
		var now := Time.get_ticks_usec()
		out.append((now - last) / 1000.0)
		last = now
	return out


func _avg(t: PackedFloat32Array) -> float:
	var s := 0.0
	for x in t:
		s += x
	return s / maxf(t.size(), 1)


func test_the_calm_street_stays_cheap() -> void:
	var visible := 0
	for mi: MeshInstance3D in street.find_children("*", "MeshInstance3D", true, false):
		if mi.is_visible_in_tree():
			visible += 1
	check(visible <= VISIBLE_MESHES, "visible meshes %d (budget %d)" % [visible, VISIBLE_MESHES])
	var worst := 0
	for p: Node in get_tree().get_nodes_in_group(&"people"):
		var n := 0
		for mi: MeshInstance3D in p.find_children("*", "MeshInstance3D", true, false):
			if mi.is_visible_in_tree():
				n += 1
		worst = maxi(worst, n)
	check(worst <= MESHES_A_PERSON, "the most meshes on one person %d (budget %d)" % [worst, MESHES_A_PERSON])
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	check(nodes <= NODES, "nodes %d (budget %d)" % [nodes, NODES])
	var t: PackedFloat32Array = await _frames(180)
	check(_avg(t) <= CALM_FRAME_MS, "calm: %.1f ms a frame (budget %.0f)" % [_avg(t), CALM_FRAME_MS])


func test_a_burning_street_stays_playable() -> void:
	var fire := street.find_child("FireSystem", true, false) as FireSystem
	var lit := 0
	for b: FalseFrontBuilding in street.find_children("*", "FalseFrontBuilding", true, false):
		var members := b.find_children("*", "StructureMember", true, false)
		if members.is_empty():
			continue
		for k in 4:
			fire.ignite(members[(members.size() * (k + 1)) / 7])
		lit += 1
		if lit >= 3:
			break
	check_eq(lit, 3, "three buildings alight")
	await process_frames(60 * 8)  # well caught
	var t: PackedFloat32Array = await _frames(60 * 6)
	var worst := 0.0
	for x in t:
		worst = maxf(worst, x)
	check(fire.burning_members().size() > 50, "burning hard (%d members)" % fire.burning_members().size())
	check(_avg(t) <= FIRE_FRAME_MS, "burning: %.1f ms a frame (budget %.0f)" % [_avg(t), FIRE_FRAME_MS])
	check(worst <= FIRE_WORST_MS, "burning: worst frame %.0f ms (budget %.0f)" % [worst, FIRE_WORST_MS])

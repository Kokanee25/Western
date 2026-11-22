extends TestCase
## Harlan's homestead (#1126): the log cabin and the board barn built from their specs
## (config/buildings/harlan_cabin.json, harlan_barn.json) are destructible through and through, stand,
## are built right, fit a man at every door and use point; the cabin's log walls are logs (notched
## corners, chinking, bucked openings: LogWall); the five repair jobs are real broken or missing pieces;
## and the whole site (Homestead, config/buildings/harlan_homestead.json) stands on its pad.

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const CABIN := "res://config/buildings/harlan_cabin.json"
const BARN := "res://config/buildings/harlan_barn.json"

var lab: Node3D


func _open(path: String) -> void:
	Lab.spec_path = path
	lab = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)


func after_each() -> void:
	if lab:
		lab.queue_free()
		lab = null
	await physics_frames(2)


func _whole(b: Structure, name: String) -> void:
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %s: %d members; not things: %d" % [name, r.members, r.not_things])
	check((r.bad as Array).is_empty(), "%s: nothing but members and fittings: %s" % [name, (r.bad as Array).slice(0, 8)])
	var st := Checks.stands(b)
	print("  dead load: %s; with a crowd: %s" % [st.dead, st.crowd])
	check(int(st.dead.falling) == 0, "%s: every member has a load path (%d don't): %s" % [name, st.dead.falling, st.dead.get("falling_first", [])])
	check(int(st.dead.over) == 0, "%s: none over its limit under its own weight: %s" % [name, st.dead.worst])
	# (a repair job's piece, the sprung porch board, gives under a crowd: that's the job; nothing else may)
	var over := 0
	for w: Array in st.crowd.worst:
		var m := b.get_member(StringName("%s/%s" % [b.structure_id, String(w[0]).split("/", true, 1)[1] if String(w[0]).begins_with(String(b.structure_id)) else w[0]]))
		if float(w[1]) > 1.0 and not (m != null and m.has_meta(&"repair")):
			over += 1
	check(over == 0 and int(st.crowd.over) <= 1, "%s: nor with a crowd on its floors (but a repair's piece): %s" % [name, st.crowd.worst])
	var br := Checks.built_right(b, lab.spec)
	for f: String in (br.failures as Array).slice(0, 20):
		print("    ", f)
	check(br.ok, "%s: nothing across an opening, every opening framed and glazed (%d failures)" % [name, (br.failures as Array).size()])
	var fit := Checks.people_fit(b, lab.spec)
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "%s: doors, stairs and use points clear a man (%d failures)" % [name, (fit.failures as Array).size()])
	var used := Checks.used(b, lab.spec)
	check(used.ok, "%s: every room has its people's places: %s" % [name, used.failures])
	var settled: Variant = b.call(&"settle")
	check(settled == null or (settled is Array and (settled as Array).is_empty()) or (settled is Dictionary and (settled as Dictionary).is_empty()),
			"%s: the game's own settle finds nothing to fall: %s" % [name, settled])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	Checks.export_members(b, ProjectSettings.globalize_path("res://build/%s_members.json" % name))


func test_the_cabin_is_built_stands_and_fits() -> void:
	await _open(CABIN)
	_whole(lab.building, "harlan_cabin")


func test_the_cabins_walls_are_hewn_logs() -> void:
	await _open(CABIN)
	var b: Structure = lab.building
	var logs := 0
	var chink := 0
	var news := 0
	for m in b.get_members():
		var id := String(m.member_id)
		if id.contains("/log/"):
			logs += 1
			check(m.kind == &"sill", "a log lies on what's under it (%s)" % id)
			if id.ends_with("_new"):
				news += 1
		elif id.contains("/chink/"):
			chink += 1
	print("  %d logs, %d chinking, %d new" % [logs, chink, news])
	check(logs >= 36, "four walls of nine courses (%d logs)" % logs)
	check(chink > logs * 0.8, "chinking between the courses (%d)" % chink)
	check(news >= 1, "Harlan's new log at the east wall's foot")
	# The corners notched: course by course the logs' ends alternate past each corner.
	var past := {0: 0, 1: 0}
	for c in 2:
		var m := b.get_member(StringName("%s/west/log/%02d_0" % [b.structure_id, c]))
		check(m != null, "the west wall's course %d" % c)
		if m:
			var box := m.transform * AABB(-m.size * 0.5, m.size)
			past[c] = 1 if box.position.z < -0.05 else 0
	check(past[0] != past[1], "the west wall's logs run past the corner on alternate courses")
	# Every opening bucked: two jambs and a head of plank through the wall.
	var bucks := 0
	for m in b.get_members():
		if String(m.member_id).ends_with("/buck/jamb0"):
			bucks += 1
	check(bucks == 4, "the door and three windows bucked (%d)" % bucks)


func test_the_cabins_repair_jobs_are_real_pieces() -> void:
	await _open(CABIN)
	var b: Structure = lab.building
	var jobs: Dictionary = b.get(&"repair_jobs")
	print("  jobs: %s" % [jobs.keys()])
	for k: String in ["roof_patch", "porch_board", "rotten_step"]:
		check(jobs.has(k), "the job %s is listed" % k)
	check(not (jobs.porch_board.members as Array).is_empty(), "the sprung porch board is a member")
	var pb := b.get_member(StringName((jobs.porch_board.members as Array)[0]))
	check(pb != null and absf(pb.transform.basis.x.y) + absf(pb.transform.basis.z.y) > 0.01, "the porch board is tilted up")
	check((jobs.rotten_step.members as Array).size() == 2, "the rotten step is broken in two")
	# The missing patch of shakes: none over it, the boards under it still there.
	var spec: Dictionary = lab.spec
	var patch: Dictionary = spec.shakes.missing[0]
	var over := 0
	for m in b.get_members():
		if String(m.member_id).contains("/roof/shake_0/"):
			over += 1
	check(over > 50, "the west slope is shaked (%d)" % over)
	check(b.get_member(StringName("%s/roof/board_0/04_0" % b.structure_id)) != null, "its boards are there under the hole")
	check(patch.has("repair"), "the patch names its job")


func test_the_barn_is_built_stands_and_fits() -> void:
	await _open(BARN)
	_whole(lab.building, "harlan_barn")
	var jobs: Dictionary = lab.building.get(&"repair_jobs")
	check(jobs.has("barn_door") and (jobs.barn_door.members as Array).size() == 1, "the barn door off its hinge is listed")


func test_the_homestead_stands_on_its_pad() -> void:
	var h := Homestead.new()
	add_child(h)
	await physics_frames(3)
	check(h.buildings.has("cabin") and h.buildings.has("barn"), "the cabin and barn are built")
	check(h.corral != null and h.trough != null and h.yard != null, "the corral, the trough and the yard")
	for k: String in ["roof_patch", "porch_board", "rotten_step", "barn_door", "corral_rail"]:
		check(h.repair_jobs.has(k), "the five repair jobs: %s" % k)
	var st := Checks.stands(h.yard)
	check(int(st.dead.falling) == 0, "the yard's things all rest on something: %s" % [st.dead.get("falling_first", [])])
	var cs := Checks.stands(h.corral)
	check(int(cs.dead.falling) == 0, "the corral stands, its broken rail hanging off its post: %s" % [cs.dead.get("falling_first", [])])
	var pipe := 0
	for m in h.yard.get_members():
		if String(m.member_id).contains("/pipe/"):
			pipe += 1
	check(pipe > 10, "the pipe runs down from the spring (%d lengths)" % pipe)
	var bed: Node = h.buildings.cabin.find_child("bed", true, false)
	check(bed != null, "his bed's use point is there for the save")
	h.queue_free()
	await physics_frames(2)

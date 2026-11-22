extends TestCase
## Sleeping in a bed (#1148, PlayerSleep; docs/briefs/saving.md step 2): E at a bed ends the day,
## wakes you at dawn and saves; the save loaded onto a valley built fresh (as Continue does) is the
## world you slept in; a sleep's refused in a fight or bleeding; Continue's offered only with a save.

const SLOT := "test_sleep"

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	_wipe()
	ValleyFolk.murder_auto = false


func after_each() -> void:
	_wipe()
	StoryState.wipe()
	SaveGame.pending = {}
	ValleyFolk.murder_auto = true
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _wipe() -> void:
	for ext: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveGame.path_of(SLOT) + ext):
			DirAccess.remove_absolute(SaveGame.path_of(SLOT) + ext)


func _valley() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## You by the valley's first bed, facing it.
func _by_a_bed(p: Player) -> Node3D:
	var beds := get_tree().get_nodes_in_group(&"beds")
	if beds.is_empty():
		return null
	var bed := beds[0] as Node3D
	var off := bed.global_basis.z
	off.y = 0.0
	var at := p.clear_spot_near(bed.global_position + off.normalized() * 1.0 - Vector3.UP * 0.5, 1.5)
	p.global_position = at
	p.velocity = Vector3.ZERO
	var to := bed.global_position - at
	p.rotation.y = atan2(-to.x, -to.z)
	return bed


func _ball(man: HumanBody, seg: StringName, dir := Vector3.FORWARD) -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var at := (man.parts[seg] as Node3D).global_position
	man.take_bullet(man.parts[seg], at - dir * 0.15, dir, 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity,
			t.bullet_diameter * 0.5, t.bullet_mass, 5.0)


func _same(a: Variant, b: Variant, what: String, tol_m := 1e-3, skip: Array = [], tol := 1e-4) -> bool:
	var diff := SaveGame.differences(a, b, tol, tol_m, skip)
	return check(diff.is_empty(), "%s comes back the same (%d differ: %s)" % [what, diff.size(), ", ".join(diff.slice(0, 6))])


func test_hours_to_dawn() -> void:
	check_near(PlayerSleep.hours_to_dawn(22.0), 8.0, 1e-4, "from ten at night: eight hours")
	check_near(PlayerSleep.hours_to_dawn(2.5), 3.5, 1e-4, "from half two: three and a half")
	check_near(PlayerSleep.hours_to_dawn(12.0), 18.0, 1e-4, "from noon: to the next dawn")
	check_near(PlayerSleep.hours_to_dawn(5.5), 24.5, 1e-4, "half an hour before dawn: through to the one after")


func test_sleep_saves_wakes_at_dawn_and_loads_the_same() -> void:
	await _valley()
	var p := _player()
	p.sleep.slot = SLOT
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 1
	clock.set_time(21.0)
	valley.folk._look = 0.0
	await physics_frames(20)
	# Something to keep: a townsman shot dead, some of you gone.
	var out: Array = valley.folk.people.keys().filter(func(id: StringName) -> bool: return valley.folk.folk_man(id) != null)
	var dead: HumanBody = valley.folk.folk_man(out[0]) if not out.is_empty() else null
	if dead:
		_ball(dead, &"head")
		_ball(dead, &"chest")
		await wait_until(func() -> bool: return not dead.physiology.alive, 900)
	p.revolver().state.belt -= 4
	StoryState.set_fact("nolaw.murder", "seen", 1, 22.0)
	var bed := _by_a_bed(p)
	check(bed != null, "the valley has a bed (%d in the group)" % get_tree().get_nodes_in_group(&"beds").size())
	if bed == null:
		return
	await physics_frames(3)
	check(p.sleep.bed_here() == bed, "you're at it (%s)" % p.sleep.report())
	check(p.sleep.claims_use(p), "E at the bed is the sleep's, not a shove")
	var slept: bool = await p.sleep.sleep()
	check(slept, "you sleep (%s)" % p.sleep.refused)
	check(FileAccess.file_exists(SaveGame.path_of(SLOT)), "the save's written")
	check_eq(clock.day, 2, "it's the next day")
	check_near(clock.time_of_day, PlayerSleep.WAKE_HOUR, 0.05, "at dawn")
	check(p.input_enabled and not p.sleep.sleeping, "you're up and can move")
	var head := SaveGame.head(SLOT)
	check_eq(int(head.get("day", 0)), 2, "the file says day 2")
	var a := p.sleep.last_capture
	check(not a.is_empty(), "what was saved is kept")
	print("    sleep: %.1f h, capture %.1f ms, write %.1f ms, %d bytes" % [p.sleep.last.slept, p.sleep.last.capture_ms, p.sleep.last.write_ms, p.sleep.last.bytes])
	# Quit and Continue: the world freed, a fresh one built with the save on it (as load_slot's reload).
	holder.queue_free()
	holder = null
	await physics_frames(3)
	GameReset.clear_statics()
	var d := SaveGame.read(SLOT)
	check(not d.is_empty(), "it reads (%s)" % SaveGame.last_error)
	GameReset.clear_for_load(d)
	SaveGame.last_load = {}
	await _valley()
	await wait_until(func() -> bool: return not SaveGame.last_load.is_empty(), 120)
	check(not SaveGame.last_load.is_empty(), "the valley put the save on as it came up")
	check((SaveGame.last_load.get("missed", ["?"]) as Array).is_empty(), "everything in it found its place (%s)" % [SaveGame.last_load.get("missed")])
	var b := SaveGame.capture(get_tree())
	_same(a.story, b.story, "the story")
	_same(a.clock, b.clock, "the clock", 1e-3, [], 0.01)
	_same(a.player, b.player, "you", 0.05, [], 0.01)
	_same(a.folk, b.folk, "the town's day and its news", 1e-3, ["frame", "last_frame", "body"])
	_same(a.blood, b.blood, "the blood")
	check_eq(b.people.keys().size(), a.people.keys().size(), "the same people are in the world")
	for id: StringName in a.people:
		if not b.people.has(id):
			check(false, "%s is in the world" % id)
			continue
		var pa: Dictionary = a.people[id]
		# (A man the town brings again while his last body's still being freed gets another node name:
		# `made.name` is only what a dead man nobody makes is called.)
		_same(pa, b.people[id], "%s" % id, 0.12 if not pa.physiology.alive else 0.5, ["mind", "pose", "name"] if pa.physiology.alive else ["mind", "name"], 0.2)
	await physics_frames(50)
	check(_player().input_enabled, "you can move once it's on")
	check(get_tree().root.find_child("LoadCover", true, false) == null, "the black's lifted")


func test_no_sleep_in_a_fight_or_bleeding() -> void:
	await _valley()
	var p := _player()
	p.sleep.slot = SLOT
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.set_time(23.0)
	var day := clock.day
	var bed := _by_a_bed(p)
	if not check(bed != null, "the valley has a bed"):
		return
	await physics_frames(3)
	# A shot close by.
	Events.shot_fired.emit(p.global_position + Vector3(12, 1, 0), Vector3.LEFT, null)
	var slept: bool = await p.sleep.sleep()
	check(not slept, "no sleep with shooting close by")
	check_eq(p.sleep.refused, "Not with shooting this close.", "and it says why")
	check(not FileAccess.file_exists(SaveGame.path_of(SLOT)), "nothing's saved")
	check(clock.day == day and absf(clock.time_of_day - 23.0) < 0.1, "the night hasn't passed")
	# Half a minute on, bleeding.
	p.sleep._shot_at = -INF
	p.wounds.physiology._add_bleed(&"test", &"forearm_l", 2.0)
	check(p.wounds.physiology.total_bleed_rate() > 0.01, "you're bleeding")
	slept = await p.sleep.sleep()
	check(not slept, "no sleep bleeding")
	check_eq(p.sleep.refused, "You're bleeding: bind it before you lie down.", "and it says why")
	p.wounds.physiology.bleeds.clear()
	check_eq(p.sleep.why_not(), "", "nothing stops it now")


func test_continue_offered_only_with_a_save() -> void:
	var was := ContinueCard.done
	ContinueCard.done = false
	var args := PackedStringArray()
	check(not ContinueCard.offered(args, SLOT, false), "no save: no Continue")
	check_eq(SaveGame.write({"version": SaveGame.VERSION, "world": "valley", "clock": {"day": 3, "hour": 6.0}}, SLOT), OK, "a save written")
	check(ContinueCard.offered(args, SLOT, false), "a save: Continue")
	check(not ContinueCard.offered(PackedStringArray(["--mission=sheriff"]), SLOT, false), "not on a story start")
	check(not ContinueCard.offered(PackedStringArray(["--dev-bridge"]), SLOT, false), "not under the bridge")
	check(ContinueCard.offered(PackedStringArray(["--dev-bridge", "--continue-card"]), SLOT, false), "the bridge asks for it")
	check(not ContinueCard.offered(args, SLOT, true), "not headless")
	ContinueCard.done = true
	check(not ContinueCard.offered(args, SLOT, false), "not twice a run")
	ContinueCard.done = was

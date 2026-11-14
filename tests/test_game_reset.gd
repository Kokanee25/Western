extends TestCase
## Backspace starts the game again (GameReset, issue #318): the street built again after a reset is
## the street a fresh start builds: the same structures and props with the same ids, the same
## people, the player at the spawn, the clock at its start, held.


func _street() -> Node3D:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	street.get_node(^"TownLife").set(&"gang_arrives", 99999.0)
	add_child(street)
	await physics_frames(3)
	return street


## What a start leaves: every structure's id, every person's name, the player's place, the clock.
func _signature(street: Node3D) -> Dictionary:
	var ids: Array[String] = []
	for s in street.find_children("*", "Structure", true, false):
		ids.append(String((s as Structure).structure_id))
	ids.sort()
	var people: Array[String] = []
	for p in get_tree().get_nodes_in_group(&"people"):
		if street.is_ancestor_of(p):
			people.append(String(p.name))
	people.sort()
	var clock := street.get_node(^"DayCycle") as DayCycle
	var player := street.get_node(^"Player") as Node3D
	return {"structures": ids, "people": people, "clock": clock.get_clock_text(), "held": clock.held,
			"player": player.global_position.snapped(Vector3.ONE * 0.01)}


func test_a_reset_builds_the_same_street_as_a_fresh_start() -> void:
	GameReset.clear_statics()  # as at the game's start (other tests have made props before this)
	var first := await _street()
	var fresh := _signature(first)
	first.free()
	await process_frames(1)
	# Without the reset's clearing the props come back as other variants with other ids.
	var again := await _street()
	var unreset := _signature(again)
	again.free()
	await process_frames(1)
	GameReset.clear_statics()
	var second := await _street()
	var after := _signature(second)
	check_eq(after.structures, fresh.structures, "the same structures and props, the same ids")
	check_eq(after.people, fresh.people, "the same people")
	check_eq(after.player, fresh.player, "the player at the spawn")
	check_eq(after.clock, "12:00", "the clock back at noon")
	check(after.held, "and held")
	check(unreset.structures != fresh.structures, "(the check would catch it: built again without the reset, the ids differ)")
	second.free()
	await process_frames(1)


func test_backspace_is_bound() -> void:
	check(InputMap.has_action(&"reset_game"), "the reset has a key")
	var keys := InputMap.action_get_events(&"reset_game").filter(func(e: InputEvent) -> bool:
		return e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_BACKSPACE)
	check_eq(keys.size(), 1, "Backspace")


## Every reload of the running scene goes through GameReset.reload_scene (issue #671): the gunfight lab's
## Y/X/Z and the look's I and M reloaded on their own, leaving the props' counters (another town)
## and the freeze watchdog counting the load as a stall.
func test_every_reload_comes_through_game_reset() -> void:
	var found := 0
	for path in _scripts("res://src") + _scripts("res://experiments"):
		if path == "res://src/main/game_reset.gd":
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var code := lines[i].get_slice("#", 0)
			if "reload_current_scene" in code:
				found += 1
				check(false, "%s:%d reloads the scene itself (use GameReset.reload_scene)" % [path, i + 1])
	check_eq(found, 0, "no reload but GameReset's")
	check("reload_current_scene" in FileAccess.get_file_as_string("res://src/main/game_reset.gd"), "(the check reads the source)")


func _scripts(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		if sub != "results":
			out.append_array(_scripts(dir.path_join(sub)))
	return out


## A fresh start wipes the story (#864, review A5): after Backspace No Law's murder plays again.
func test_a_fresh_start_wipes_the_story() -> void:
	StoryState.set_fact("nolaw.murder", "done")
	StoryState.set_fact("sheriff.care", "good")
	StoryState.mark_checkpoint()
	GameReset.clear_statics()  # what Backspace, a look's reload and the bridge's world do first
	check(StoryState.facts.is_empty(), "no facts (%s)" % StoryState.facts)
	check(StoryState.when.is_empty(), "no times")
	check(StoryState.checkpoint.is_empty(), "no mission's checkpoint either")


## A mission's retry starts from the story as it stood when the mission began: what earlier missions
## set holds, what the lost try set is gone; and again on a second retry.
func test_a_retry_puts_back_the_story_as_the_mission_began() -> void:
	GameReset.clear_statics()
	StoryState.set_fact("sheriff.care", "good", 1, 7.5)
	StoryState.mark_checkpoint()  # the mission begins (CoachCut.start_coach, FarmhouseMission.begin, ...)
	StoryState.set_fact("coach.outcome", "lost")
	StoryState.set_fact("sheriff.care", "poor")  # (nothing a try does to an earlier fact sticks)
	GameReset.clear_for_retry()
	check_eq(StoryState.get_fact("sheriff.care"), "good", "the earlier mission's fact as it was")
	check_eq(StoryState.when.get("sheriff.care"), [1, 7.5], "and when it was set")
	check(not StoryState.has_fact("coach.outcome"), "the lost try's fact gone")
	StoryState.set_fact("coach.outcome", "lost")
	GameReset.clear_for_retry()
	check(not StoryState.has_fact("coach.outcome"), "gone again on the second retry")
	check_eq(StoryState.get_fact("sheriff.care"), "good", "the checkpoint kept")
	GameReset.clear_statics()


## Every mission's retry reloads through GameReset.retry (the story to its checkpoint), not the
## fresh start; and each mission marks its checkpoint as it begins.
func test_every_mission_retry_keeps_the_story_to_its_start() -> void:
	for path: String in ["res://src/missions/coach_fight.gd", "res://src/missions/farmhouse_mission.gd"]:
		var src := FileAccess.get_file_as_string(path)
		check("GameReset.retry(" in src, "%s retries through GameReset.retry" % path.get_file())
		check(not "GameReset.reset(" in src, "%s doesn't start the game afresh" % path.get_file())
	for path: String in ["res://src/missions/coach_cut.gd", "res://src/missions/farmhouse_mission.gd",
			"res://src/missions/sheriff_on_road.gd", "res://src/missions/sheriff_dies.gd"]:
		check("StoryState.mark_checkpoint()" in FileAccess.get_file_as_string(path), "%s marks its checkpoint" % path.get_file())

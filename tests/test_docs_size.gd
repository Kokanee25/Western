extends TestCase
## The working notes stay small (Sean, 2026-11-14): every session pays for CLAUDE.md on every turn,
## and the lane files on each read. CLAUDE.md grew to 117 KB once; these limits keep it from happening again.

## Hard ceilings, above the targets (30 KB, 10 KB) sessions keep to, so one session's lines on a file already
## near its target can't turn main red for everyone (it did, build 4602).
const CLAUDE_MAX := 32 * 1024
const LANE_MAX := 12 * 1024


func _size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return -1
	var n := f.get_length()
	f.close()
	return n


func test_claude_md_under_its_ceiling() -> void:
	var n := _size("res://CLAUDE.md")
	check(n > 0, "CLAUDE.md is readable")
	check(n <= CLAUDE_MAX, "CLAUDE.md is %d bytes, over %d: trim your own stale lines" % [n, CLAUDE_MAX])


func test_each_lane_file_under_its_ceiling() -> void:
	var dir := DirAccess.open("res://docs/lanes")
	check(dir != null, "docs/lanes exists")
	if dir == null:
		return
	for name in dir.get_files():
		if not name.ends_with(".md"):
			continue
		var n := _size("res://docs/lanes/" + name)
		check(n <= LANE_MAX, "docs/lanes/%s is %d bytes, over %d: trim your own stale lines" % [name, n, LANE_MAX])

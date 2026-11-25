extends SceneTree
## What a building's members cost in memory, part by part (#1259). Builds one spec on its own
## (SpecBuilding, as docs/reviews/2026-11-building-bodies.md did), measuring Godot's static memory as
## each phase of `Structure.rebuild` adds its part (members and their nodes, the support graph, the
## batches), then takes the finished building apart a part at a time, so the drops add up to the whole:
## KB a member by part.
##
##   godot --headless -s res://tools/member_memory.gd -- [--spec=res://config/buildings/hotel.json]
##       [--json=build/member_memory.json] [--budget]
##
## `--budget` checks the result against config/frame_budget.tres's `kb_per_member` (exit 1 over).
## Headless: the rendering server is the dummy one, which keeps each mesh's arrays in RAM as a real
## driver keeps them in video memory, so "the batches' meshes" is video memory on a GPU.

const LIB := "res://tools/member_memory_lib.gd"

var spec := "res://config/buildings/hotel.json"
var json_out := ""
var check_budget := false
var warm := true


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spec="):
			spec = a.trim_prefix("--spec=")
		elif a.begins_with("--json="):
			json_out = a.trim_prefix("--json=")
		elif a == "--cold":
			warm = false
		elif a == "--budget":
			check_budget = true
	_run.call_deferred()


func _settle() -> void:
	for i in 3:
		await process_frame


func _run() -> void:
	await _settle()
	var lib: GDScript = load(LIB)
	if warm:  # what the first building loads once (scripts, materials, textures): not a member's
		await lib.measure(root, "res://config/buildings/saloon.json")
		await _settle()
	var r: Dictionary = await lib.measure(root, spec)
	lib.print_report(r)
	if json_out != "":
		var f := FileAccess.open(json_out, FileAccess.WRITE)
		f.store_string(JSON.stringify(r, "  "))
	var code := 0
	if check_budget:
		var fb = load("res://config/frame_budget.tres")
		var kb: float = float(r.kb_per_member)
		var limit: float = float(fb.kb_per_member)
		print("budget: %.1f KB a member (limit %.1f)%s" % [kb, limit, " OVER" if kb > limit else ""])
		if kb > limit:
			code = 1
	quit(code)



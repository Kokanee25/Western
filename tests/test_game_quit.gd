extends TestCase
## The quit (GameQuit, issue #435): every pool task this repo posts is high priority (two low ones
## overlapping at quit hang Godot's worker pool, #392), the drain sees what's still running, and
## the native plugin carries the last layer (QuitWatchdog).


## Every WorkerThreadPool.add_task / add_group_task under src/ and experiments/ asks for high
## priority (add_task's second argument, add_group_task's fourth).
func test_every_pool_task_is_high_priority() -> void:
	var calls := 0
	for path in _scripts("res://src") + _scripts("res://experiments"):
		var text := FileAccess.get_file_as_string(path)
		for kind: String in ["add_task(", "add_group_task("]:
			var at := text.find("WorkerThreadPool." + kind)
			while at >= 0:
				var args := _args(text, at + "WorkerThreadPool.".length() + kind.length())
				var want := 1 if kind == "add_task(" else 3
				calls += 1
				check(args.size() > want and args[want] == "true", "%s:%d posts %s with high priority (%s)" % [
						path, text.substr(0, at).count("\n") + 1, kind.trim_suffix("("), args])
				at = text.find("WorkerThreadPool." + kind, at + 1)
	check(calls >= 4, "the calls are found (%d)" % calls)


## A quiet tree has nothing in flight; a sound warm-up running is named.
func test_the_drain_names_what_runs() -> void:
	var tree := get_tree()
	SynthSounds.finish_warm()
	check_eq(GameQuit.in_flight(tree), PackedStringArray(), "nothing of ours running")
	check(not GameQuit.quitting, "and nobody's quitting")


func test_the_watchdog_is_in_the_plugin() -> void:
	if not ClassDB.class_exists(&"VoxelMember"):
		return  # no native plugin here (the web build)
	check(ClassDB.class_exists(&"QuitWatchdog"), "the plugin has the quit's watchdog")
	check(not ClassDB.class_call_static(&"QuitWatchdog", &"armed"), "unarmed until a quit")


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


## The top-level arguments of the call whose "(" ends just before `from`, as written.
func _args(text: String, from: int) -> PackedStringArray:
	var out := PackedStringArray()
	var depth := 0
	var start := from
	var quote := ""
	var i := from
	while i < text.length():
		var c := text[i]
		if quote != "":
			if c == "\\":
				i += 1
			elif c == quote:
				quote = ""
		elif c == "#":
			var eol := text.find("\n", i)
			i = text.length() if eol < 0 else eol
			continue
		elif c == "\"" or c == "'":
			quote = c
		elif c == "(" or c == "[" or c == "{":
			depth += 1
		elif c == ")" or c == "]" or c == "}":
			if depth == 0:
				out.append(text.substr(start, i - start).strip_edges())
				return out
			depth -= 1
		elif c == "," and depth == 0:
			out.append(text.substr(start, i - start).strip_edges())
			start = i + 1
		i += 1
	return out

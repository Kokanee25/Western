class_name GameQuit
## The one way the game quits (#435): new work stops, what's in flight on the worker threads is
## waited for, then the tree quits. Godot's worker pool can hang at quit: in `Main::cleanup`, after
## the scene tree is freed, `exit_languages_threads` waits for every pool thread to count itself
## idle, and two low-priority tasks overlapping at that switch leave the idle threads uncounted for
## good (issue #392; `core/object/worker_thread_pool.cpp`, `_handle_runlevel`). A slow frame makes
## that likelier (with the physics catch-up cap the game crawls and its work is still in flight at
## quit), so every way out comes through here: the window's close (main.gd), the smoke test, the
## soak, the bridge's `quit`.
##
## 1. `quitting` goes up: no shadow merge is posted after it (Structure looks).
## 2. If a pool task of ours is running (the structures' shadow merges and analyses, the fire's
##    check, the sound warm-up, the smoke grids' steps), the tree pauses (no people's prepare,
##    smoke step, fire check or batch rebuild posted) and they're waited for, a frame at a time and
##    at most WAIT_MS; past that it quits anyway and says what was still running. With none
##    running it quits in the frame it was asked in: every frame drawn on the way out can leave
##    the renderer's background pipeline compiles (the engine's own low-priority pool tasks) queued
##    at the switch, and an extra frame each quit made the hang below likelier (5 of 9 drawn runs
##    under load against main's 0 of 8, #435). Deferred calls left are flushed in Godot's cleanup,
##    and a structure freed waits for its own task.
## 3. The native plugin's watchdog is armed (`QuitWatchdog`, watchdog.rs): if the process is still
##    shutting down WATCHDOG_S after the scene tree went (its root leaving the tree, after the last
##    frame: a drawn frame under software Vulkan takes seconds), as in Godot's pool hang (the
##    engine's own low-priority tasks can make the pair, #392), it flushes stdout and ends the
##    process with the same exit code. Nothing of the player's is lost (the game saves only in
##    bed); at worst the shader cache is rebuilt next start. `-- --quit-watchdog=S` sets its
##    seconds for one run (0: not armed, to look at a hang).

const WAIT_MS := 2000
const WATCHDOG_S := 5.0

static var quitting := false


## Quit `tree` with `code`, the safe way (a coroutine: call it and return; a second call is ignored).
static func quit(tree: SceneTree, code := 0) -> void:
	if quitting:
		return
	quitting = true
	var t0 := Time.get_ticks_msec()
	var busy := in_flight(tree)
	if not busy.is_empty():
		var first := busy
		tree.paused = true
		while not busy.is_empty() and Time.get_ticks_msec() - t0 < WAIT_MS:
			await tree.process_frame
			busy = in_flight(tree)
		if busy.is_empty():
			print("[quit] waited %d ms for %s" % [Time.get_ticks_msec() - t0, ", ".join(first)])
		else:
			print("[quit] still running after %d ms, quitting anyway: %s" % [WAIT_MS, ", ".join(busy)])
	SynthSounds.finish_warm()
	var wait_s := WATCHDOG_S
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--quit-watchdog="):
			wait_s = float(a.substr(16))
	if ClassDB.class_exists(&"QuitWatchdog") and wait_s > 0.0:
		ClassDB.class_call_static(&"QuitWatchdog", &"arm", wait_s, code)
		tree.root.tree_exiting.connect(func() -> void: ClassDB.class_call_static(&"QuitWatchdog", &"begin_count"),
				CONNECT_ONE_SHOT)
	tree.quit(code)


## What of ours is still running on a worker, by name ([] when nothing). Doesn't block (a task
## found done is waited for by its owner: a structure as it's freed, the sound warm-up just after).
static func in_flight(tree: SceneTree) -> PackedStringArray:
	var out := PackedStringArray()
	if SynthSounds.warming():
		out.append("the sound warm-up")
	var shadows := 0
	var analyses := 0
	var batches := 0
	for s: Structure in tree.get_nodes_in_group(&"structures"):
		if s.shadow_running():
			shadows += 1
		if s.batches_running():
			batches += 1
		if s.last_analysis and s.last_analysis.running():
			analyses += 1
	if shadows > 0:
		out.append("%d shadow merges" % shadows)
	if analyses > 0:
		out.append("%d analyses" % analyses)
	if batches > 0:
		out.append("%d batch merges" % batches)
	for r: RubbleRest in tree.root.find_children("*", "RubbleRest", true, false):
		if r.running():
			out.append("a rubble cell")
	var fire := FireSystem.find(tree)
	if fire and fire.check_running():
		out.append("the fire's check")
	var smoke := 0
	for f: SmokeField in tree.root.find_children("*", "SmokeField", true, false):
		if f.grid and f.grid.call(&"is_busy"):
			smoke += 1
	if smoke > 0:
		out.append("%d smoke steps" % smoke)
	return out

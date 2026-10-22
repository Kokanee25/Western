extends Node
## The gunfight lab played by you (PLAYTEST.md beside this file): the three gunmen in the saloon,
## Brody at the bar, Lyle at the card table, the Kid at the back, and you just in at the door with
## your gun away. They go for theirs when you go for yours, or when the count's out. The same men,
## room, guns and starting spots every run; only the gang's variant (OutlawBrain.Variant: A as the
## game plays, B aims by his hand and finds the town's cover, C is B and shaken first) and the seed
## change.
##
##   Y  the next run of the playtest: nine runs, each variant once on each of three seeds, in an
##      order that puts each variant first, second and third once (a Latin square). Blind: the
##      variant shows only when the fight's over.
##   X  this run again (same variant, same seed: the men's dice the same; what you do isn't).
##   Z  free play: the next variant (A, B, C) on this seed, the variant shown.
##
## Each run starts from a fresh town (the scene reloads, as the I and M keys do). The lab's own
## fight (fight.gd, style "human") watches it and writes it down: user://gunfight_runs/, one JSON
## a run and a line in runs.csv. F3 shows each man's state and his last decision and why.
## main.gd adds this node when the lab's folder is there; it changes nothing until a key is pressed.
## The run state lives on Engine (STATE), so it outlives the reload.

const Fight := preload("res://experiments/gunfight_lab/fight.gd")
## [variant, seed] for the playtest's nine runs.
const SCHEDULE := [["A", 1], ["B", 1], ["C", 1], ["B", 2], ["C", 2], ["A", 2], ["C", 3], ["A", 3], ["B", 3]]
const VARIANTS := ["A", "B", "C"]
const OUT := "user://gunfight_runs"

## Across the reload (kept on Engine, which outlives the scene and this script): the run asked
## for ("pending"), the last one played ("last"), where the playtest has got to ("next").
const STATE := &"gunfight_play"

var street: Node
var player: Player
var _fight: Node
var _run := {}
var _hud: Label
var _over := ""


static func _state() -> Dictionary:
	if not Engine.has_meta(STATE):
		Engine.set_meta(STATE, {"pending": {}, "last": {}, "next": 0})
	return Engine.get_meta(STATE)


func _ready() -> void:
	var main := get_parent()
	street = main.find_child("TestStreet", true, false)
	player = main.find_child("Player", true, false) as Player
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	_hud.add_theme_font_size_override(&"font_size", 15)
	_hud.add_theme_color_override(&"font_color", Color(1.0, 0.93, 0.78))
	_hud.add_theme_color_override(&"font_outline_color", Color(0, 0, 0))
	_hud.add_theme_constant_override(&"outline_size", 5)
	_hud.visible = false
	layer.add_child(_hud)
	var st := _state()
	if not (st.pending as Dictionary).is_empty():
		_run = st.pending
		st.pending = {}
		_start.call_deferred()


func _process(_delta: float) -> void:
	if street == null or player == null:
		return
	var st := _state()
	var last: Dictionary = st.last
	if Input.is_action_just_pressed(&"gunfight_next"):
		var i := int(st.next) % SCHEDULE.size()
		_queue({"variant": SCHEDULE[i][0], "seed": SCHEDULE[i][1], "run": i + 1, "blind": true})
		st.next = i + 1
	elif Input.is_action_just_pressed(&"gunfight_again") and not last.is_empty():
		_queue(last)
	elif Input.is_action_just_pressed(&"gunfight_free"):
		var v: String = VARIANTS[(VARIANTS.find(String(last.get("variant", "C"))) + 1) % VARIANTS.size()] if not last.is_empty() else "A"
		_queue({"variant": v, "seed": int(last.get("seed", 1)), "run": 0, "blind": false})
	_update_hud()


## Start a run from a fresh town: the scene reloads and the new GunfightPlay picks it up.
func _queue(run: Dictionary) -> void:
	_state().pending = run.duplicate()
	_state().last = run.duplicate()
	get_tree().reload_current_scene.call_deferred()


func _start() -> void:
	await get_tree().physics_frame
	await seconds(0.5)  # the town settles (people placed, lamps made) before the men come in
	var opts := {"scenario": "saloon", "hour": "golden", "weapon": "revolver", "style": "human", "bodies": "game",
		"variant": _run.variant, "seed": int(_run.seed), "max": 300.0, "count": 3.0}
	_fight = Fight.new(self, opts)
	add_child(_fight)
	var err: String = await _fight.setup()
	if err != "":
		_over = "Couldn't set the fight up: %s" % err
		return
	_hud.visible = true
	while is_instance_valid(_fight) and not _fight.done:
		await get_tree().physics_frame
	_save(_fight.record)


func _update_hud() -> void:
	if not _hud.visible:
		return
	var label := "Run %d of %d" % [_run.run, SCHEDULE.size()] if int(_run.run) > 0 else "Free play"
	var v := "?" if _run.blind and _over == "" else String(_run.variant)
	var head := "THREE GUNMEN   %s   variant %s   seed %d" % [label, v, int(_run.seed)]
	var line := ""
	if _over != "":
		line = _over
	elif is_instance_valid(_fight) and _fight.started:
		if _fight._count >= 0.0:
			line = "Draw when you're ready (they go for theirs in %.0f s)" % ceilf(_fight._count)
		else:
			line = "%.0f s" % _fight.t
	_hud.text = head + "\n" + line + "\nY next run   X this run again   Z free play (next variant)   F3 what they're thinking"


## The run's record to user://gunfight_runs/, a line in runs.csv, and what happened on screen.
func _save(rec: Dictionary) -> void:
	rec["run"] = int(_run.run)
	rec["blind"] = bool(_run.blind)
	rec["saved_at"] = Time.get_datetime_string_from_system()
	DirAccess.make_dir_recursive_absolute(OUT)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s_run%d_%s_s%d.json" % [OUT, stamp, int(_run.run), _run.variant, int(_run.seed)]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(rec, " "))
		f.close()
	var csv := OUT + "/runs.csv"
	var fresh := not FileAccess.file_exists(csv)
	var c := FileAccess.open(csv, FileAccess.READ_WRITE if not fresh else FileAccess.WRITE)
	if c:
		c.seek_end()
		if fresh:
			c.store_line("saved_at,run,variant,seed,length_s,ending,your_shots,your_hits,hits_on_you,relocations,decisions,unfair,file")
		var you: Dictionary = rec.get("you", {})
		var decisions := 0
		for m: Dictionary in (rec.get("men", {}) as Dictionary).values():
			decisions += (m.get("decisions", []) as Array).size()
		c.store_line("%s,%d,%s,%d,%.1f,%s,%d,%d,%d,%d,%d,%d,%s" % [rec.saved_at, int(_run.run), _run.variant, int(_run.seed),
			float(rec.get("length_s", 0.0)), rec.get("ending", ""), int(you.get("shots", 0)), int(you.get("hits", 0)),
			int(you.get("hits_taken", 0)), int(you.get("relocations", 0)), decisions, (rec.get("unfair", []) as Array).size(), path.get_file()])
		c.close()
	var outcomes := []
	for k: String in (rec.get("outcomes", {}) as Dictionary):
		outcomes.append("%s %d" % [k.replace("_", " "), int(rec.outcomes[k])])
	_over = "Over in %.1f s: %s (%s). It was variant %s.%s\nScore it now (PLAYTEST.md). Saved to %s" % [float(rec.get("length_s", 0.0)),
		String(rec.get("ending", "")).replace("_", " "), ", ".join(outcomes), _run.variant,
		"" if int(_run.run) == 0 or int(_run.run) < SCHEDULE.size() else " That's all nine.",
		ProjectSettings.globalize_path(path)]


# What fight.gd needs from whoever runs it (as BridgeLab gives the bridge's fights).
func seconds(s: float) -> void:
	var until := Engine.get_physics_frames() + int(round(s * Engine.physics_ticks_per_second))
	while Engine.get_physics_frames() < until:
		await get_tree().physics_frame


func physics_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

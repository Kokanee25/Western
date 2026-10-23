extends Node
## The gunfight lab played by you (PLAYTEST.md beside this file): the three gunmen in the new
## saloon (the building lab's, out in the desert west of town: F5's eighth stop), in one of five
## setups: the hall round the bar and tables, the stair, the galleries, the back of the hall by the
## kitchen and back room, and out front under the street balcony. Your gun's away. Drawing doesn't
## start it (they warn you off, as men do in town); your first shot does, or they go for theirs
## when the count's out (6 s). The gang fights as the game's does (OutlawBrain.default_variant);
## Z tries the others (A as it was, B aims by his hand and finds cover, C is B and shaken first, D
## is C and fights that commit).
##
##   Y  the next setup (hall, stair, gallery, back, front, then again on the next seed).
##   X  this run again (same setup, variant and seed: the men's dice the same; what you do isn't).
##   Z  this setup and seed with the next variant (A, B, C, D), shown.
##
## Each run starts from a fresh town (the scene reloads, as the I and M keys do). The lab's own
## fight (fight.gd, style "human") watches it and writes it down: user://gunfight_runs/, one JSON
## a run and a line in runs.csv. F3 shows each man's state and his last decision and why.
## main.gd adds this node when the lab's folder is there; it changes nothing until a key is pressed.
## The run state lives on Engine (STATE), so it outlives the reload.

const Fight := preload("res://experiments/gunfight_lab/fight.gd")
## The setups (scenarios.json), in the order Y plays them, and what the HUD calls them.
const SETUPS := ["spec_hall", "spec_stair", "spec_gallery", "spec_back", "spec_front"]
const SETUP_NAMES := {"spec_hall": "the hall", "spec_stair": "the stair", "spec_gallery": "the galleries",
	"spec_back": "the back of the hall", "spec_front": "out front"}
const VARIANTS := ["A", "B", "C", "D"]
## Seconds before they go for their guns if you haven't shot.
const COUNT := 6.0
const OUT := "user://gunfight_runs"

## Across the reload (kept on Engine, which outlives the scene and this script): the run asked
## for ("pending"), the last one played ("last"), where the playtest has got to ("next").
const STATE := &"gunfight_play"

var street: Node
var player: Player
var _fight: Node
var _run := {}
var _hud: Label
var _panel: PanelContainer
var _over := ""
var _queued := false  # a reload's on its way


static func _state() -> Dictionary:
	if not Engine.has_meta(STATE):
		Engine.set_meta(STATE, {"pending": {}, "last": {}, "next": 0})
	return Engine.get_meta(STATE)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var main := get_parent()
	street = main.find_child("TestStreet", true, false)
	player = main.find_child("Player", true, false) as Player
	var layer := CanvasLayer.new()
	layer.layer = 120  # over F3's readout
	add_child(layer)
	# Bottom left on a dark panel, readable over the readout and the scene.
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.04, 0.03, 0.82)
	box.set_content_margin_all(8.0)
	_panel.add_theme_stylebox_override(&"panel", box)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = 12.0
	_panel.offset_bottom = -10.0
	_panel.visible = false
	layer.add_child(_panel)
	_hud = Label.new()
	_hud.add_theme_font_size_override(&"font_size", 15)
	_hud.add_theme_color_override(&"font_color", Color(1.0, 0.93, 0.78))
	_hud.add_theme_color_override(&"font_outline_color", Color(0, 0, 0))
	_hud.add_theme_constant_override(&"outline_size", 5)
	_panel.add_child(_hud)
	var st := _state()
	if not (st.pending as Dictionary).is_empty():
		_run = st.pending
		st.pending = {}
		_panel.visible = true
		_start.call_deferred()


func _process(_delta: float) -> void:
	_update_hud()


## The keys as events (a key pressed and let go inside one slow frame is still seen), whether or
## not the game's paused or you're out cold.
func _input(event: InputEvent) -> void:
	if street == null or player == null or _queued or event.is_echo() or not event.is_pressed():
		return
	var st := _state()
	var last: Dictionary = st.last
	var game := String(OutlawBrain.Variant.keys()[OutlawBrain.default_variant])
	if event.is_action_pressed(&"gunfight_next"):
		var i := int(st.next)
		_queue({"setup": SETUPS[i % SETUPS.size()], "variant": game, "seed": 1 + i / SETUPS.size(), "run": i + 1})
		st.next = i + 1
	elif event.is_action_pressed(&"gunfight_again") and not last.is_empty():
		_queue(last)
	elif event.is_action_pressed(&"gunfight_free"):
		var v: String = VARIANTS[(VARIANTS.find(String(last.get("variant", game))) + 1) % VARIANTS.size()] if not last.is_empty() else "A"
		_queue({"setup": String(last.get("setup", SETUPS[0])), "variant": v, "seed": int(last.get("seed", 1)), "run": int(last.get("run", 0))})


## Start a run from a fresh town: the scene reloads and the new GunfightPlay picks it up.
func _queue(run: Dictionary) -> void:
	_queued = true
	_state().pending = run.duplicate()
	_state().last = run.duplicate()
	get_tree().reload_current_scene.call_deferred()


func _start() -> void:
	await get_tree().physics_frame
	await seconds(0.5)  # the town settles (people placed, lamps made) before the men come in
	var opts := {"scenario": String(_run.get("setup", SETUPS[0])), "hour": "golden", "weapon": "revolver", "style": "human", "bodies": "game",
		"variant": _run.variant, "seed": int(_run.seed), "max": 300.0, "count": COUNT, "draw_turns": "false"}
	_fight = Fight.new(self, opts)
	add_child(_fight)
	var err: String = await _fight.setup()
	if err != "":
		_over = "Couldn't set the fight up: %s" % err
		return
	_panel.visible = true
	while is_instance_valid(_fight) and not _fight.done:
		await get_tree().physics_frame
	_save(_fight.record)


func _update_hud() -> void:
	if not _panel.visible:
		return
	var setup := String(_run.get("setup", SETUPS[0]))
	var head := "THREE GUNMEN   %s   run %d   variant %s   seed %d" % [SETUP_NAMES.get(setup, setup), int(_run.run), _run.variant, int(_run.seed)]
	var line := ""
	if _over != "":
		line = _over
	elif not is_instance_valid(_fight) or not _fight.started:
		line = "The men are coming in..."
	elif is_instance_valid(_fight) and _fight.started:
		if _fight._count >= 0.0:
			line = "Shoot first, or wait: they go for theirs in %.0f s" % ceilf(_fight._count)
		else:
			line = "%.0f s" % _fight.t
	_hud.text = head + "\n" + line + "\nY next setup   X this run again   Z this one with the next variant   F3 what they're thinking"


## The run's record to user://gunfight_runs/, a line in runs.csv, and what happened on screen.
func _save(rec: Dictionary) -> void:
	rec["run"] = int(_run.run)
	rec["saved_at"] = Time.get_datetime_string_from_system()
	DirAccess.make_dir_recursive_absolute(OUT)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s_run%d_%s_%s_s%d.json" % [OUT, stamp, int(_run.run), String(_run.get("setup", "")), _run.variant, int(_run.seed)]
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
			c.store_line("saved_at,run,setup,variant,seed,length_s,ending,your_shots,your_hits,hits_on_you,relocations,decisions,unfair,file")
		var you: Dictionary = rec.get("you", {})
		var decisions := 0
		for m: Dictionary in (rec.get("men", {}) as Dictionary).values():
			decisions += (m.get("decisions", []) as Array).size()
		c.store_line("%s,%d,%s,%s,%d,%.1f,%s,%d,%d,%d,%d,%d,%d,%s" % [rec.saved_at, int(_run.run), String(_run.get("setup", "")), _run.variant, int(_run.seed),
			float(rec.get("length_s", 0.0)), rec.get("ending", ""), int(you.get("shots", 0)), int(you.get("hits", 0)),
			int(you.get("hits_taken", 0)), int(you.get("relocations", 0)), decisions, (rec.get("unfair", []) as Array).size(), path.get_file()])
		c.close()
	var outcomes := []
	for k: String in (rec.get("outcomes", {}) as Dictionary):
		outcomes.append("%s %d" % [k.replace("_", " "), int(rec.outcomes[k])])
	_over = "Over in %.1f s: %s (%s).\nScore it now (PLAYTEST.md). Saved as gunfight_runs/%s in the game's user folder" % [float(rec.get("length_s", 0.0)),
		String(rec.get("ending", "")).replace("_", " "), ", ".join(outcomes), path.get_file()]


# What fight.gd needs from whoever runs it (as BridgeLab gives the bridge's fights).
func seconds(s: float) -> void:
	var until := Engine.get_physics_frames() + int(round(s * Engine.physics_ticks_per_second))
	while Engine.get_physics_frames() < until:
		await get_tree().physics_frame


func physics_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

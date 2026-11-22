class_name PlayerSleep
extends Node
## Sleeping in a bed (#1148, saving step 2; DESIGN.md §3: the game is saved only when you sleep in a
## bed; docs/briefs/saving.md). E at a bed (any node in the group `beds`: a spec building's use point
## with `use: sleep` is put there by SpecBuilding, so the doctor's cot, the jail's bunk and saloon B's
## lodgers' beds all are, and Harlan's once his cabin's spec has one) fades the screen out, ends the
## day, and in the dark: the clock on to the next dawn (`DayCycle.pass_hours`: blood and floor marks
## dry, each hour and midnight announced, so the town's news goes overnight and the folk are where
## their day puts them), the hours told to everything that heals or calms by them
## (`Events.hours_passed`, &"sleep": your wounds mend by them, PlayerWounds; a townsman's run on),
## then the save, taken AFTER the night (you wake at dawn: a load puts you there, getting up by the
## bed), then the fade back in.
##
## Refused, with a line on screen saying why (`why_not`): bleeding; a man by the collar or a seat;
## a hostile man about who could shoot you (an outlaw on his feet, Joe turned) or shooting close by
## in the last half minute (yours too); a scene in play (a Moment not done: nobody sleeps in the middle of one).
## In the group `claims_use`, so E at a bed isn't a shove.

signal slept(result: Dictionary)

var player: Player
## The save slot a sleep writes (the title card's Continue reads it).
var slot := "slot1"
## Asleep now (the fade and the night).
var sleeping := false
## The last sleep's {"slept": hours, "day", "hour", "error", "capture_ms", "write_ms", "bytes"}.
var last := {}
## What the last sleep saved (the dictionary written): the tests compare a load against it.
var last_capture := {}
## The last refusal's reason ("" if the last E at a bed slept).
var refused := ""

## You wake at this hour (the sun's up a little after 6 with the arc's lift: DayCycleConfig).
const WAKE_HOUR := 6.0
## Asleep less than this (h), you sleep through to the dawn after (you can't lie down at 05:40 to
## save and be up at 06:00: a sleep is a night).
const LEAST_HOURS := 1.0
## A bed within this of you (m, flat), and its height within BED_DY of your feet's.
const REACH_M := 1.9
const BED_DY := 1.3
## Facing it within this (degrees), unless you're right by it.
const VIEW_DEG := 75.0
## No sleep with a hostile man within this (m) on his feet, or a shot fired within it in SHOT_S.
const DANGER_M := 60.0
const SHOT_S := 30.0
## The fade out and in (s), and the dark between (frames: the town placed by its day, then saved).
const FADE_S := 0.7
const DARK_FRAMES := 12

var _t := 0.0
var _shot_at := -INF
var _near: Node3D
var _told_ago := INF
const TOLD_GAP := 8.0
const LOOK_EVERY := 0.25
var _look_t := 0.0
var _layer: CanvasLayer
var _black: ColorRect


func _ready() -> void:
	add_to_group(&"claims_use")
	Events.shot_fired.connect(_on_shot)


func _on_shot(origin: Vector3, _dir: Vector3, shooter: Node) -> void:
	# Yours too (the playtest, #1148: shot a man and slept seven seconds on): nobody lies down with the
	# gun still warm.
	if player == null or not player.is_inside_tree():
		return
	if origin.distance_to(player.global_position) < DANGER_M:
		_shot_at = _t


## The bed you're at (by it and facing it), or null.
func bed_here() -> Node3D:
	if player == null or not player.is_inside_tree() or player.is_crawling or player.ladder != null:
		return null
	var fwd := player.get_forward()
	fwd.y = 0.0
	fwd = fwd.normalized()
	var best: Node3D = null
	var best_d := INF
	for n: Node in player.get_tree().get_nodes_in_group(&"beds"):
		var bed := n as Node3D
		if bed == null or not bed.is_inside_tree():
			continue
		var to := bed.global_position - player.global_position
		if absf(to.y) > BED_DY:
			continue
		to.y = 0.0
		var d := to.length()
		if d > REACH_M or d >= best_d:
			continue
		if d > 0.6 and rad_to_deg(fwd.angle_to(to)) > VIEW_DEG:
			continue
		best = bed
		best_d = d
	if best == null:
		return null
	# A man down by you or by the collar has E first (PlayerCarry), then a free chair (the doctor's
	# bedside chair) or your own seat.
	if player.carry != null and (player.carry.carrying() or player.carry.near_man() != null):
		return null
	if player.seat != null and (player.seat.seated() or player.seat.chair_here() != null):
		return null
	return best


## Why you can't sleep now ("" if you can).
func why_not() -> String:
	if player == null or player.wounds == null:
		return "no one to sleep"
	var w := player.wounds
	if not w.physiology.alive or w.out_cold > 0.0:
		return "out cold"
	if player.seat != null and player.seat.seated():
		return "Get up out of the chair first."
	if player.carry != null and player.carry.carrying():
		return "Put him down first."
	if w.physiology.total_bleed_rate() > 0.01:
		return "You're bleeding: bind it before you lie down."
	if _t - _shot_at < SHOT_S:
		return "Not with shooting this close."
	var foe := _hostile_near()
	if foe != "":
		return "Not with %s about." % foe
	for m: Node in player.get_tree().get_nodes_in_group(&"moment"):
		if m is Moment and not (m as Moment).done and m.is_inside_tree():
			return "Not now: there's something going on."
	return ""


## Who'd shoot you, on his feet within DANGER_M ("" if nobody): an outlaw not down or given up, Joe turned.
func _hostile_near() -> String:
	for n: Node in player.get_tree().get_nodes_in_group(&"people"):
		var man := n as HumanBody
		if man == null or not man.is_inside_tree() or not man.physiology.alive or not man.physiology.is_conscious():
			continue
		if man.global_position.distance_to(player.global_position) > DANGER_M:
			continue
		var brain := man.get_node_or_null(^"Brain")
		if brain is OutlawBrain:
			var mood: int = (brain as OutlawBrain).mood
			if mood in [OutlawBrain.Mood.SURRENDERED, OutlawBrain.Mood.DOWN, OutlawBrain.Mood.DEAD]:
				continue
			if brain is CompanionBrain:
				if (brain as CompanionBrain).turned:
					return "Joe turned on you"
				continue
			var ob := brain as OutlawBrain
			if ob.target == player or (ob.relations != null and ob.relations.stance(player) >= Relations.Stance.THREAT):
				return "armed men after you"
	return ""


func claims_use(p: Player) -> bool:
	return p == player and (sleeping or bed_here() != null)


func _physics_process(delta: float) -> void:
	_t += delta
	if player == null or sleeping:
		return
	var pressed := player.input_enabled and Input.is_action_just_pressed(&"shove")
	# Looked for a few times a second (and on E), not every tick.
	_look_t -= delta
	_told_ago += delta
	if _look_t > 0.0 and not pressed:
		return
	_look_t = LOOK_EVERY
	var here := bed_here()
	if here != _near:
		_near = here
		if here != null and player.wounds and player.input_enabled and _told_ago > TOLD_GAP:
			_told_ago = 0.0
			player.wounds.say("E: sleep till morning (saves the game)", 2.0)
	if here != null and pressed:
		sleep(here)


## Hours from `hour` to the next wake (at least LEAST_HOURS).
static func hours_to_dawn(hour: float) -> float:
	var h := fposmod(WAKE_HOUR - hour, 24.0)
	if h < LEAST_HOURS:
		h += 24.0
	return h


## Lie down in `bed` (or the one you're at) and sleep till dawn, then save. False, with the reason on
## screen and in `refused`, if you can't. Awaitable: it returns once you're up again.
func sleep(bed: Node3D = null) -> bool:
	if sleeping:
		return false
	if bed == null:
		bed = bed_here()
	refused = "no bed here" if bed == null else why_not()
	if refused != "":
		if bed != null and player.wounds and refused != "out cold":
			player.wounds.say(refused, 2.5)
		return false
	sleeping = true
	var stood := player.global_transform
	var was_input := player.input_enabled
	player.input_enabled = false
	player.velocity = Vector3.ZERO
	if player.weapon:
		player.weapon.put_away()  # you wake standing, guns away (the brief)
	await _fade(1.0)
	var clock := player.get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	var hours := hours_to_dawn(clock.time_of_day) if clock else 8.0
	if clock:
		clock.pass_hours(hours)
		clock.apply_visuals()
	# Who died in the night (a hurt man bled out while you slept): said when you wake.
	var died: Array[String] = []
	var on_died := func(who: Node, _cause: StringName) -> void:
		var n := player.wounds._name_of(who) if player.wounds else ""
		if n != "" and not n in died:
			died.append(n)
	Events.person_died.connect(on_died)
	Events.hours_passed.emit(hours, &"sleep")
	# The town where its day has it at dawn (ValleyFolk looks at the clock twice a second; now).
	var folk := player.get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk
	if folk:
		folk._look = 0.0
	for i in DARK_FRAMES:
		player.global_transform = stood
		player.velocity = Vector3.ZERO
		await player.get_tree().physics_frame
	Events.person_died.disconnect(on_died)
	# Up by the bed where you lay down, and the save taken: you wake at dawn.
	player.global_transform = stood
	player.velocity = Vector3.ZERO
	var u := Time.get_ticks_usec()
	last_capture = SaveGame.capture(player.get_tree())
	var c := Time.get_ticks_usec()
	var err := SaveGame.write(last_capture, slot)
	var wt := Time.get_ticks_usec()
	last = {"slept": hours, "day": clock.day if clock else 0, "hour": clock.time_of_day if clock else 0.0,
			"error": err, "capture_ms": (c - u) / 1000.0, "write_ms": (wt - c) / 1000.0,
			"bytes": FileAccess.get_file_as_bytes(SaveGame.path_of(slot)).size() if err == OK else 0}
	var line := "You sleep till dawn. Day %d, %s." % [last.day, clock.get_clock_text() if clock else ""]
	line += " Saved." if err == OK else " (The save failed: %s.)" % SaveGame.last_error
	if not died.is_empty():
		line += "\n%s died in the night." % " and ".join(died)
	last["died"] = died
	await _fade(0.0)
	player.input_enabled = was_input
	sleeping = false
	if player.wounds:
		player.wounds.say(line, 4.0)
	slept.emit(last)
	return true


## The screen to black (1) or back (0) over FADE_S.
func _fade(to: float) -> void:
	if _layer == null:
		_layer = CanvasLayer.new()
		_layer.layer = 95
		add_child(_layer)
		_black = ColorRect.new()
		_black.color = Color(0, 0, 0, 0)
		_black.set_anchors_preset(Control.PRESET_FULL_RECT)
		_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer.add_child(_black)
	var from := _black.color.a
	var t := 0.0
	while t < FADE_S:
		await player.get_tree().process_frame
		t += player.get_process_delta_time()
		_black.color.a = lerpf(from, to, clampf(t / FADE_S, 0.0, 1.0))
	_black.color.a = to


func report() -> Dictionary:
	var bed := bed_here()
	return {"at_bed": String(bed.name) if bed else "", "why_not": why_not() if bed else "",
			"sleeping": sleeping, "refused": refused, "last": last.duplicate()}

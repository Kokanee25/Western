class_name RideThere
extends Node
## "Ride there" (#1120): a stand-in for riding (riding's after the slice, #478; the run speed stays,
## Sean 2026-11-20). E at a tied horse lists the places you know (config/ride_there.json, each one of
## valley.json's places); choosing one, the screen fades, the clock goes on by the ride's real time
## (the distance at a trot, plus a little) and you're stood by your horse at that place's hitching
## rail, him tied there. No riding and no way through walls: you and he are put down at the rail.
##
## Not while you've a man over your shoulder or by the collar, bleed hard, are in a fight (anyone
## hostile to you within `hostile_m` who knows where you are, or within `close_m`), or an act is running (Act.ride_refusal:
## a scene's own story says no) or anything in the group `ride_check` says no (`ride_refusal(player)
## -> String`, "" for yes: the farmhouse while its fight is on). One line says why.
##
## The world goes on while you ride: the clock jumps (DayCycle.pass_hours), Events.hours_passed says
## how long (your wounds and everyone's run on, frights fade), and whatever came due on the way is
## asked of the group `timed_beats` (`beats_due(day, from_h, hours) -> [{what, hour, ride, say}]`):
## `ride` "no" refuses the ride with `say` (the beat waits for you), "on" lets it go and the beat
## happens at its hour, by its own clock, after you arrive (ValleyFolk's are polled), its `say` (if
## any) told you on arrival. Nothing due on the way is passed over without its owner being asked.
##
## The horse: yours, made at the hitch nearest where you start; any tied horse (a mission's too)
## offers the list, and wherever you rode from, yours is the one stood at the rail you arrive at.
## The dev bridge's `ride PLACE` does the same from a horse (`ride` alone lists what's offered).

signal rode(from: StringName, to: StringName, seconds: float)

const CONFIG := "res://config/ride_there.json"

var layout: ValleyLayout
var town: ValleyTown
var player: Player
var data := {}
## id -> {id, name, known, at (the rail's middle), dir (the rail's way), horse (his place), facing
## (his nose's way, to the rail), stand (yours), look (the place's middle)}, in the data's order.
var spots := {}
var order: Array[StringName] = []
## Your horse (null where the model isn't built: then there's no riding).
var horse: Horse
## Where your horse stands now (a spot's id).
var horse_at := &""
## idle, menu, out (fading out), black (the card), in (fading in).
var state := &"idle"
## The last ride or refusal: {to, from, metres, seconds, from_clock, to_clock, beats, refused}.
var last := {}
var rides := 0

var _choices: Array[StringName] = []
var _pick := 0
var _t := 0.0
var _going := {}
var _menu_layer: CanvasLayer
var _menu_label: Label
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _card: Label
var _look_t := 0.0
var _been_t := 0.0
var _told_for: Node = null
var _from_horse: Horse = null
var _rails := {}
const LOOK_EVERY := 0.25
const BEEN_EVERY := 1.0


func _ready() -> void:
	add_to_group(&"ride_there")
	add_to_group(&"claims_use")  # E at a tied horse is this, not a shove
	data = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if layout == null:
		layout = ValleyLayout.main()
	for p: Dictionary in data.get("places", []):
		var s := _spot(p)
		if s.is_empty():
			push_warning("RideThere: no hitch for %s" % p.get("id", "?"))
			continue
		spots[s.id] = s
		order.append(s.id)
	_build_rails()
	_horse_soon.call_deferred()


# --- The places and their hitches ---------------------------------------------------------------

func _spot(p: Dictionary) -> Dictionary:
	var id := StringName(p.get("id", ""))
	if not layout.has_place(String(id)):
		return {}
	var place_xz := layout.place_at(String(id))
	var s := {"id": id, "name": String(p.get("name", id)), "known": p.get("known", ["always"]),
			"look": Vector3(place_xz.x, ground(place_xz.x, place_xz.y), place_xz.y)}
	var rail: Vector3
	var along: Vector3
	var facing: Vector3
	if p.has("lot"):
		var lot := layout.lot(String(p.lot))
		if lot.is_empty():
			return {}
		var north := layout.lots("north").any(func(x: Dictionary) -> bool: return String(x.id) == String(p.lot))
		rail = ValleyFolk.point_of_lot(layout, town, String(p.lot), float(p.get("along", 0.0)), float(p.get("out", -3.4)))
		along = Vector3(1.0, 0.0, 0.0)
		facing = Vector3(0.0, 0.0, -1.0 if north else 1.0)  # nose to the rail, the lot behind it
	elif p.has("road"):
		var line := layout.road_line(String(p.road))
		if line.size() < 2:
			return {}
		# Walked back from the road's end at the place.
		if line[0].distance_to(place_xz) < line[line.size() - 1].distance_to(place_xz):
			line.reverse()
		var back := float(p.get("back_m", 40.0))
		var at := line[line.size() - 1]
		var way := (line[line.size() - 1] - line[line.size() - 2]).normalized()
		var i := line.size() - 1
		while i > 0 and back > 0.0:
			var seg := line[i] - line[i - 1]
			var len := seg.length()
			way = seg / maxf(len, 0.001)
			if back <= len:
				at = line[i] - way * back
				back = 0.0
			else:
				back -= len
				at = line[i - 1]
			i -= 1
		along = Vector3(way.x, 0.0, way.y)
		var right := Vector3(-way.y, 0.0, way.x)
		var off := float(p.get("side_m", 3.2))
		rail = Vector3(at.x, 0.0, at.y) + right * off
		rail.y = ground(rail.x, rail.z)
		facing = right if off >= 0.0 else -right
	else:
		return {}
	var h := rail - facing * 1.6
	h.y = ground(h.x, h.z)
	var stand := h - facing * 0.3 + along * 1.5
	stand.y = ground(stand.x, stand.z)
	s.merge({"at": rail, "dir": along, "horse": h, "facing": facing, "stand": stand})
	return s


## What you'd stand on there: the town's walks and street, else the valley's ground.
func ground(x: float, z: float) -> float:
	return ValleyFolk.surface_of(town, x, z)


## A hitching rail at each spot (HitchingRail: a part, it breaks and burns as any).
func _build_rails() -> void:
	for id: StringName in order:
		var s: Dictionary = spots[id]
		var r := HitchingRail.new()
		r.name = "HitchingRail_%s" % id
		var dir: Vector3 = s.dir
		r.transform = Transform3D(Basis(Vector3.UP, atan2(-dir.z, dir.x)), (s.at as Vector3) - dir * r.length * 0.5)
		add_child(r)
		_rails[id] = r


## The places by name for the bridge's goto (`horse_<id>`: where you stand by the horse there).
func add_places(w: Waypoints) -> void:
	# Unjoined: the way there from the place isn't always a walk (the mine's, the hideout's: test_valley_town).
	for id: StringName in order:
		w.add(StringName("horse_%s" % id), (spots[id].stand as Vector3) + Vector3.UP * 0.05)


# --- Your horse ---------------------------------------------------------------------------------

func _horse_soon() -> void:
	# After the missions have put you where they start you (they wait five frames).
	for i in 8:
		await get_tree().physics_frame
	if not is_inside_tree() or not Horse.available() or order.is_empty():
		return
	var p := _player()
	var best := order[0]
	if p:
		var d := INF
		for id: StringName in order:
			var dd := _flat(p.global_position, spots[id].horse)
			if dd < d:
				d = dd
				best = id
	if _load_at != &"" and spots.has(_load_at):
		best = _load_at  # (a save put him there before he was made)
	horse = Horse.new()
	horse.name = "YourHorse"
	add_child(horse)
	stand_horse(best)


## Your horse tied at that spot's rail.
func stand_horse(id: StringName) -> void:
	if horse == null or not spots.has(id):
		return
	var s: Dictionary = spots[id]
	var f: Vector3 = s.facing
	horse.global_transform = Transform3D(Basis(Vector3.UP, atan2(f.z, -f.x)), s.horse)
	var nose: Vector3 = s.at
	horse.tie_to(nose + Vector3.UP * 1.09)
	horse.follow_bones()
	horse_at = id


func _player() -> Player:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(&"player") as Player if is_inside_tree() else null
	return player


## The tied horse by you (within reach, in front of you or right by you; `facing` false: any way you
## face, the bridge's), or null.
func horse_here(reach := -1.0, facing := true) -> Horse:
	var p := _player()
	if p == null or not p.is_inside_tree() or p.is_crawling or p.ladder != null:
		return null
	if p.seat != null and p.seat.seated():
		return null
	if reach < 0.0:
		reach = float(data.get("reach_m", 2.8))
	var fwd := p.get_forward()
	fwd.y = 0.0
	fwd = fwd.normalized()
	var best: Horse = null
	var best_d := INF
	for n: Node in get_tree().get_nodes_in_group(&"horses"):
		var h := n as Horse
		if h == null or not h.tied or not h.is_inside_tree():
			continue
		# His barrel's near side, not his middle: he's 2.4 m long.
		var to := h.global_position - p.global_position
		to.y = 0.0
		var d := maxf(to.length() - 0.9, 0.0)
		if d > reach or (facing and d > 0.6 and fwd.dot(to.normalized()) < 0.2):
			continue
		if d < best_d:
			best_d = d
			best = h
	return best


func claims_use(p: Player) -> bool:
	return p == _player() and (state != &"idle" or horse_here() != null)


# --- Where you can go ---------------------------------------------------------------------------

## Do you know the place (its `known`)?
func knows(id: StringName) -> bool:
	if not spots.has(id):
		return false
	for k: String in spots[id].known:
		if k == "always":
			return true
		if k == "been" and StoryState.get_fact("known.%s" % id, false) == true:
			return true
		if k.begins_with("fact:"):
			var kv := k.substr(5).split("=", true, 1)
			if kv.size() == 1 and StoryState.has_fact(kv[0]):
				return true
			if kv.size() == 2 and String(StoryState.get_fact(kv[0], "")) == kv[1]:
				return true
	return false


## The places you'd be offered from where you are: known, and not where you stand.
func offered() -> Array[StringName]:
	var out: Array[StringName] = []
	var p := _player()
	for id: StringName in order:
		if not knows(id):
			continue
		if p and _flat(p.global_position, spots[id].look) < float(data.get("near_m", 150.0)) \
				and _flat(p.global_position, spots[id].stand) < float(data.get("near_m", 150.0)):
			continue
		out.append(id)
	return out


## The ride's metres and game seconds from `from` to the place `id`.
func ride_of(from: Vector3, id: StringName) -> Dictionary:
	var m := _flat(from, spots[id].stand) * float(data.get("winding", 1.3))
	var mps := float(layout.speeds().get(String(data.get("speed", "horse_trot")), 3.9))
	return {"metres": m, "seconds": m / maxf(mps, 0.5) + float(data.get("extra_s", 45.0))}


# --- Why not ------------------------------------------------------------------------------------

## Why you can't ride now, in one line ("" : you can).
func refusal() -> String:
	var p := _player()
	if p == null:
		return "No one to ride."
	if p.carry != null and p.carry.carrying():
		return "Not with a man over your shoulder."
	for n: Node in get_tree().get_nodes_in_group(&"people"):
		var m := n as HumanBody
		if m != null and m.dragged_by == p:
			return "Not with a man by the collar."
	var ph: Physiology = p.wounds.physiology if p.wounds else null
	if ph != null and ph.total_bleed_rate() > float(data.get("bleed_ml_s", 2.0)):
		return "You're bleeding too hard to sit a horse. Bind it first."
	var foe := hostile_near()
	if foe != "":
		return "Not with %s after you." % foe
	for n: Node in get_tree().get_nodes_in_group(&"moment"):
		if n is Act and not (n as Act).done and n.is_inside_tree():
			var why := (n as Act).ride_refusal()
			if why != "":
				return why
	for n: Node in get_tree().get_nodes_in_group(&"ride_check"):
		if n.has_method(&"ride_refusal"):
			var why := String(n.call(&"ride_refusal", p))
			if why != "":
				return why
	return ""


## Who's hostile to you and knows where you are, within `hostile_m` ("" : nobody): "a man" or his
## name.
func hostile_near() -> String:
	var p := _player()
	var reach := float(data.get("hostile_m", 90.0))
	for n: Node in get_tree().get_nodes_in_group(&"people"):
		var m := n as HumanBody
		if m == null or not is_instance_valid(m) or m.physiology == null or not m.physiology.alive or not m.physiology.is_conscious():
			continue
		if m.global_position.distance_to(p.global_position) > reach:
			continue
		var b := Crew.brain_of(m)
		if b == null or b.mood in [OutlawBrain.Mood.SURRENDERED, OutlawBrain.Mood.DOWN, OutlawBrain.Mood.DEAD]:
			continue
		var against := b.target == p
		if b.relations != null and b.relations.stance(p) >= Relations.Stance.THREAT:
			against = true
		if b is CompanionBrain and (b as CompanionBrain).turned:
			against = true
		if not against:
			continue
		# He knows where you are, or is close enough that he would.
		if b.senses == null or b.senses.sees(p) or b.senses.knows(p) or m.global_position.distance_to(p.global_position) < float(data.get("close_m", 30.0)):
			return "a man" if m.person_id == &"" else String(m.person_id).capitalize()
	return ""


## What comes due on the way, from the group `timed_beats`.
func beats_on_way(hours: float) -> Array:
	var out: Array = []
	var c := _clock()
	if c == null:
		return out
	for n: Node in get_tree().get_nodes_in_group(&"timed_beats"):
		if n.has_method(&"beats_due"):
			out.append_array(n.call(&"beats_due", c.day, c.time_of_day, hours))
	return out


# --- Riding -------------------------------------------------------------------------------------

## E at a horse: the list (or why not).
func open_menu() -> bool:
	var p := _player()
	if state != &"idle" or p == null:
		return false
	var why := refusal()
	if why != "":
		_refused(why)
		return false
	_choices = offered()
	if _choices.is_empty():
		_refused("Nowhere you know to ride to from here.")
		return false
	_from_horse = horse_here()
	_pick = 0
	state = &"menu"
	p.input_enabled = false
	_show_menu()
	return true


func close_menu() -> void:
	if state != &"menu":
		return
	state = &"idle"
	if _menu_layer:
		_menu_layer.visible = false
	var p := _player()
	if p:
		p.input_enabled = true


## Ride to `id` now (the list's pick, or the bridge's): "" if you're off, else why not.
func ride(id: StringName) -> String:
	if state == &"menu":
		close_menu()
	if state != &"idle":
		return "already riding"
	var why := refusal()
	if why == "" and not spots.has(id):
		why = "No such place to ride to."
	if why == "" and not knows(id):
		why = "You don't know the way there."
	if why == "" and not id in offered():
		why = "You're there already."
	var p := _player()
	var r := ride_of(p.global_position, id) if why == "" else {}
	var beats: Array = beats_on_way(float(r.seconds) / 3600.0) if why == "" else []
	for b: Dictionary in beats:
		if String(b.get("ride", "on")) == "no":
			why = String(b.get("say", "Not now: you'd be late for it."))
			break
	if why != "":
		_refused(why, id)
		return why
	var c := _clock()
	_going = {"to": id, "from": horse_at if _from_horse == horse else &"", "metres": snappedf(r.metres, 1.0),
			"seconds": snappedf(r.seconds, 1.0), "from_clock": c.get_clock_text() if c else "",
			"beats": beats, "refused": ""}
	if _from_horse == null:
		_from_horse = horse_here()
	state = &"out"
	_t = 0.0
	p.input_enabled = false
	_show_fade(0.0)
	return ""


func _refused(why: String, id := &"") -> void:
	last = {"to": String(id), "refused": why}
	var p := _player()
	if p and p.wounds:
		p.wounds.say(why, 3.0)


## At the black: you, your horse and the clock moved on.
func _arrive() -> void:
	var id: StringName = _going.to
	var s: Dictionary = spots[id]
	var p := _player()
	var hours := float(_going.seconds) / 3600.0
	var c := _clock()
	if c:
		c.pass_hours(hours)
	stand_horse(id)
	var at: Vector3 = s.stand
	p.global_position = p.clear_spot_near(at + Vector3.UP * 0.05, 2.5)
	p.velocity = Vector3.ZERO
	var look: Vector3 = s.look
	p.rotation.y = atan2(-(look.x - at.x), -(look.z - at.z))
	# Your own wounds ran on (bleeding a little, you're down that much more).
	if p.wounds and p.wounds.physiology and p.wounds.physiology.alive:
		p.wounds.physiology.pass_time(float(_going.seconds))
	Events.hours_passed.emit(hours, &"rode")
	StoryState.set_fact("known.%s" % id, true, c.day if c else 1, c.time_of_day if c else -1.0)
	_going["to_clock"] = c.get_clock_text() if c else ""
	_card.text = "You ride to %s." % s.name


func _done() -> void:
	state = &"idle"
	_fade_layer.visible = false
	var p := _player()
	if p:
		p.input_enabled = true
	var id: StringName = _going.to
	var lines: PackedStringArray = ["%s, %d minutes on. It's %s." % [_cap(String(spots[id].name)), roundi(float(_going.seconds) / 60.0), _going.get("to_clock", "")]]
	for b: Dictionary in _going.get("beats", []):
		if String(b.get("say", "")) != "":
			lines.append(String(b.say))
	if p and p.wounds:
		p.wounds.say(" ".join(lines), 4.0)
	last = _going.duplicate()
	last.erase("refused")
	last["to"] = String(id)
	last["from"] = String(last.get("from", ""))
	last["beats"] = (_going.get("beats", []) as Array).map(func(b: Dictionary) -> String: return String(b.get("what", "")))
	rides += 1
	rode.emit(StringName(last.from), id, float(_going.seconds))


func _clock() -> DayCycle:
	return get_tree().get_first_node_in_group(&"day_cycle") as DayCycle if is_inside_tree() else null


## The fade and the card, on the physics clock (the arrival's spot is found by a physics query).
func _ride_step(delta: float) -> void:
	_t += delta
	var fade := float(data.get("fade_s", 0.5))
	match state:
		&"out":
			_fade.color.a = clampf(_t / fade, 0.0, 1.0)
			if _t >= fade:
				state = &"black"
				_t = 0.0
				_arrive()
		&"black":
			if _t >= float(data.get("card_s", 2.0)):
				state = &"in"
				_t = 0.0
				_card.text = ""
		&"in":
			_fade.color.a = 1.0 - clampf(_t / fade, 0.0, 1.0)
			if _t >= fade:
				_done()


func _physics_process(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	if not state in [&"idle", &"menu"]:
		_ride_step(delta)
		return
	_been_t -= delta
	if _been_t <= 0.0:
		_been_t = BEEN_EVERY
		_note_been(p)
	if state == &"menu":
		_menu_keys(p)
		return
	if state != &"idle":
		return
	var pressed := p.input_enabled and Input.is_action_just_pressed(&"shove")
	_look_t -= delta
	if _look_t > 0.0 and not pressed:
		return
	_look_t = LOOK_EVERY
	var h := horse_here()
	# A man over your shoulder or down by you: E is his (PlayerCarry), and you're told why not.
	var carry_has_e := p.carry != null and (p.carry.carrying() or p.carry.man_here() != null)
	if h != _told_for:
		_told_for = h
		if h != null and p.wounds:
			p.wounds.say("Not with a man over your shoulder." if p.carry != null and p.carry.carrying() else "E: ride somewhere", 1.5)
	if h != null and pressed and not carry_has_e:
		open_menu()


## The places you've come near enough to know.
func _note_been(p: Player) -> void:
	var c := _clock()
	for id: StringName in order:
		if StoryState.get_fact("known.%s" % id, false) == true:
			continue
		var s: Dictionary = spots[id]
		var near := float(data.get("been_m", 120.0))
		if _flat(p.global_position, s.look) < near or _flat(p.global_position, s.stand) < near:
			StoryState.set_fact("known.%s" % id, true, c.day if c else 1, c.time_of_day if c else -1.0)


func _menu_keys(p: Player) -> void:
	if Input.is_action_just_pressed(&"release_mouse"):
		close_menu()
		return
	for i in mini(_choices.size(), 9):
		if Input.is_key_pressed(KEY_1 + i):
			ride(_choices[i])
			return
	if Input.is_action_just_pressed(&"ui_down") or Input.is_action_just_pressed(&"move_back"):
		_pick = (_pick + 1) % _choices.size()
		_show_menu()
	elif Input.is_action_just_pressed(&"ui_up") or Input.is_action_just_pressed(&"move_forward"):
		_pick = (_pick + _choices.size() - 1) % _choices.size()
		_show_menu()
	elif Input.is_action_just_pressed(&"shove") or Input.is_action_just_pressed(&"ui_accept"):
		ride(_choices[_pick])


# --- On screen ----------------------------------------------------------------------------------

func _show_menu() -> void:
	if _menu_layer == null:
		_menu_layer = CanvasLayer.new()
		_menu_layer.layer = 85
		add_child(_menu_layer)
		var back := PanelContainer.new()
		back.set_anchors_preset(Control.PRESET_CENTER)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.05, 0.04, 0.03, 0.86)
		box.set_content_margin_all(18)
		back.add_theme_stylebox_override(&"panel", box)
		_menu_layer.add_child(back)
		_menu_label = Label.new()
		_menu_label.add_theme_color_override(&"font_color", Color(0.93, 0.88, 0.78))
		_menu_label.add_theme_font_size_override(&"font_size", 22)
		back.add_child(_menu_label)
	var p := _player()
	var lines: PackedStringArray = ["Ride to:"]
	for i in _choices.size():
		var id := _choices[i]
		var mins := roundi(float(ride_of(p.global_position, id).seconds) / 60.0)
		lines.append("%s %d  %s, about %d min" % [">" if i == _pick else " ", i + 1, _cap(String(spots[id].name)), mins])
	lines.append("")
	lines.append("1-%d or E: ride   Esc: stay" % mini(_choices.size(), 9))
	_menu_label.text = "\n".join(lines)
	_menu_layer.visible = true
	var c := _menu_layer.get_child(0) as Control
	c.reset_size()
	c.position = (c.get_viewport_rect().size - c.size) * 0.5


func _show_fade(a: float) -> void:
	if _fade_layer == null:
		_fade_layer = CanvasLayer.new()
		_fade_layer.layer = 90
		add_child(_fade_layer)
		_fade = ColorRect.new()
		_fade.color = Color(0.03, 0.025, 0.02, a)
		_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_layer.add_child(_fade)
		_card = Label.new()
		_card.set_anchors_preset(Control.PRESET_FULL_RECT)
		_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_card.add_theme_color_override(&"font_color", Color(0.93, 0.88, 0.78))
		_card.add_theme_font_size_override(&"font_size", 26)
		_fade.add_child(_card)
	if _menu_layer:
		_menu_layer.visible = false
	_fade.color.a = a
	_card.text = ""
	_fade_layer.visible = true


## What a save keeps (SaveGame, #1154): where your horse is tied. The places you know are story facts.
func save_dict() -> Dictionary:
	return {"horse_at": String(horse_at)}


## A save's horse put back: tied at the rail you left him at (now, or once he's made).
func load_dict(d: Dictionary) -> void:
	var at := StringName(String(d.get("horse_at", "")))
	if at == &"" or not spots.has(at):
		return
	_load_at = at
	if horse != null and is_instance_valid(horse):
		stand_horse(at)
	else:
		horse_at = at


var _load_at := &""


## For the bridge and the tests.
func report() -> Dictionary:
	var p := _player()
	var list: Array = []
	for id: StringName in offered():
		list.append({"id": String(id), "name": String(spots[id].name), "minutes": snappedf(float(ride_of(p.global_position, id).seconds) / 60.0, 0.1)})
	return {"state": String(state), "horse_at": String(horse_at), "at_horse": horse_here() != null,
			"why_not": refusal(), "offered": list, "rides": rides, "last": last}


static func _cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

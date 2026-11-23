class_name SaveGame
extends RefCounted
## The save (#1138; DESIGN.md §3: only when you sleep in a bed; docs/briefs/saving.md has the whole
## inventory): the difference from the authored valley, taken from the world as one dictionary
## (`capture`), written as one versioned file in user://saves (`write`: a temp file, then renamed over
## the last, which is kept as `.bak`), read back (`read`: old versions brought up by `MIGRATIONS`) and
## put onto a freshly built valley (`apply`). Each system keeps and restores its own state (a
## `to_dict`/`from_dict` or `save_dict`/`load_dict` on it); this only gathers them, in an order that
## works (the story and clock, then the world's damage, then the people on it, then you).
##
## Not kept, on purpose: anything in flight (a save is a sleep: rubble lies where it is, asleep),
## chips, shards, smoke, sparks, sound, what a man's senses hold this second, his mood (he wakes to
## his day; what he thinks of you is kept), an act half played (nobody sleeps in one).

const VERSION := 1
const DIR := "user://saves"
const MAGIC := "SALTCREEK-SAVE"
## The sections, in the order they're put back.
const SECTIONS: Array[String] = ["story", "clock", "structures", "ground", "floor", "blood", "dynamite", "folk", "people", "player", "horse"]

## Bringing an old save up: version -> a Callable(Dictionary) -> Dictionary giving the next
## version's shape. `read` runs them in turn until the save is this build's; a save from a newer
## build, or one with a step missing, isn't loaded.
static var MIGRATIONS := {}
## Why the last `read` or `write` failed ("" if it didn't).
static var last_error := ""
## True while `apply` runs: what's put back isn't happening now (no deeds, no news of it).
static var loading := false
## A save to put on the valley as it's next built (#1148: Continue, the bridge's `load`): set by
## `load_slot`, taken by ValleyWorld once its folk are in (`ValleyWorld._load_pending`).
static var pending := {}
## The last load's `apply` report ({missed, ms}) and the slot it came from, for the bridge and tests.
static var last_load := {}


## The game reloaded with `slot`'s save on it (Continue, the bridge's `load`): read now, the world's
## statics cleared and the story put back as the save had it (a load is a retry's shape: the story
## restored, never wiped), the scene reloaded, the rest applied once the fresh valley's in. False
## (and `last_error`) if there's no save to load.
static func load_slot(tree: SceneTree, slot := "slot1") -> bool:
	var d := read(slot)
	if d.is_empty():
		return false
	if String(d.get("world", "")) != "" and StringName(d.world) != Settings.world:
		Settings.set_world(StringName(d.world))
	GameReset.load_save(tree, d)
	return true


# --- Taking it from the world ------------------------------------------------------------------

static func capture(tree: SceneTree) -> Dictionary:
	var world := World.root(tree.root)
	var d := {"version": VERSION, "world": String(Settings.world), "warnings": []}
	d["story"] = {"facts": StoryState.facts.duplicate(true), "when": StoryState.when.duplicate(true),
			"checkpoint": StoryState.checkpoint.duplicate(true)}
	var clock := _clock(tree)
	if clock:
		d["clock"] = {"hour": clock.time_of_day, "day": clock.day, "scale": clock.time_scale, "held": clock.held}
	# The structures anything's happened to (most never are: nothing kept of those).
	var structures := {}
	for s: Structure in _structures(tree):
		if not s.maybe_changed():
			continue
		var sd := s.to_dict()
		if Structure.untouched(sd):
			continue
		if structures.has(sd.id):
			(d.warnings as Array).append("two structures called %s: only the first kept" % sd.id)
			continue
		structures[sd.id] = sd
	d["structures"] = structures
	var ground := {}
	for g: Node in tree.get_nodes_in_group(&"ground"):
		if g.has_method(&"to_dict") and g.has_method(&"from_dict"):
			ground[String(world.get_path_to(g)) if world else String(g.name)] = g.call(&"to_dict")
	d["ground"] = ground
	var floor := tree.get_first_node_in_group(&"floor_marks") as FloorMarks
	d["floor"] = floor.save_dict() if floor else {}
	d["blood"] = Blood.save_list()
	d["dynamite"] = HumanBody.plain(DynamiteStick.save_all(tree))
	var folk := _folk(tree)
	d["folk"] = folk.save_dict() if folk else {}
	var people := {}
	for n: Node in tree.get_nodes_in_group(&"people"):
		var man := n as HumanBody
		if man == null or not man.is_inside_tree() or man.is_queued_for_deletion():
			continue
		if people.has(man.person_id):
			(d.warnings as Array).append("two people called %s: only the first kept" % man.person_id)
			continue
		var pd := man.save_dict()
		pd["mind"] = _mind(man)
		pd["roster"] = folk != null and folk.people.get(man.person_id) == man
		people[man.person_id] = pd
	d["people"] = people
	var player := tree.get_first_node_in_group(&"player") as Player
	d["player"] = _player(player) if player else {}
	var ride := tree.get_first_node_in_group(&"ride_there") as RideThere
	d["horse"] = ride.save_dict() if ride else {}
	return d


static func _clock(tree: SceneTree) -> DayCycle:
	return tree.get_first_node_in_group(&"day_cycle") as DayCycle


static func _folk(tree: SceneTree) -> ValleyFolk:
	return tree.get_first_node_in_group(&"valley_folk") as ValleyFolk


static func _structures(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(&"structures").filter(func(n: Node) -> bool:
		return n is Structure and n.is_inside_tree() and not n.is_queued_for_deletion())


## What's kept of a man's mind: how afraid he is, whether he's still shaken, what he thinks of each
## person he's had cause to think about (Relations), whether he's turned on you (a companion).
static func _mind(man: HumanBody) -> Dictionary:
	var brain := man.get_node_or_null(^"Brain")
	if brain == null:
		return {}
	var out := {"kind": (brain.get_script() as Script).get_global_name(), "fear": float(brain.get(&"fear")) if brain.get(&"fear") != null else 0.0}
	var reaction: Variant = brain.get(&"reaction")
	if reaction is Reaction:
		out["shaken_since"] = (reaction as Reaction).shaken_since
	if brain.get(&"turned") != null:
		out["turned"] = bool(brain.get(&"turned"))
	var rel: Variant = brain.get(&"relations")
	if rel is Relations:
		out["relations"] = (rel as Relations).to_dict()
	return out


static func _player(p: Player) -> Dictionary:
	var out := {"at": p.global_transform, "pitch": p.get_pitch_degrees(), "movement": p.movement,
			"lacks": p.lacks.duplicate(), "weapon": _kind_of(p, p.weapon), "guns": {}}
	for kind: StringName in Player.KIND_NODES:
		var w := p.camera.get_node_or_null(Player.KIND_NODES[kind])
		if w == null:
			continue
		var st: Variant = w.get(&"state")
		if st is Object and (st as Object).has_method(&"to_dict"):
			out.guns[kind] = (st as Object).call(&"to_dict")
	if p.dynamite():
		out["sticks"] = p.dynamite().sticks
		out["bundles"] = p.dynamite().bundles
	if p.bucket():
		out["litres"] = p.bucket().litres
	if p.carry:
		out["blood_on_you"] = p.carry.blood_on_you
	if p.wounds:
		out["wounds"] = p.wounds.save_dict()
	return out


static func _kind_of(p: Player, w: Node) -> StringName:
	for kind: StringName in Player.KIND_NODES:
		if w != null and p.camera.get_node_or_null(Player.KIND_NODES[kind]) == w:
			return kind
	return &""


# --- Putting it back ---------------------------------------------------------------------------

## A save put onto the valley as built fresh (the same world: `d.world`). Returns what it couldn't
## place ({"missed": [what, ...], "ms": {section: ms}}): a structure or a living man the fresh
## world hasn't got (a mission's cast: its own resume brings them, step 2).
static func apply(tree: SceneTree, d: Dictionary) -> Dictionary:
	var missed: Array[String] = []
	var ms := {}
	loading = true
	var world := World.root(tree.root)
	for section in SECTIONS:
		if not d.has(section):
			continue
		var u := Time.get_ticks_usec()
		_apply_section(tree, world, section, d[section], missed)
		ms[section] = (Time.get_ticks_usec() - u) / 1000.0
	apply_laid(tree, d)
	loading = false
	return {"missed": missed, "ms": ms}


static func _apply_section(tree: SceneTree, world: Node3D, section: String, sd: Variant, missed: Array[String]) -> void:
	match section:
		"story":
			StoryState.restore(sd)
			StoryState.checkpoint = (sd.get("checkpoint", {}) as Dictionary).duplicate(true)
		"clock":
			var clock := _clock(tree)
			if clock and not (sd as Dictionary).is_empty():
				clock.day = int(sd.day)
				clock.set_time_scale(float(sd.scale))
				clock.set_held(bool(sd.held))
				clock.set_time(float(sd.hour))
		"structures":
			var by_id := {}
			for s: Structure in _structures(tree):
				if not by_id.has(String(s.structure_id)):
					by_id[String(s.structure_id)] = s
			for id: String in sd:
				var s: Structure = by_id.get(id)
				if s == null:
					missed.append("structure %s" % id)
					continue
				var n := s.from_dict(sd[id])
				if n > 0:
					missed.append("%d members of %s" % [n, id])
		"ground":
			for path: String in sd:
				var g := world.get_node_or_null(NodePath(path)) if world else null
				if g == null or not g.has_method(&"from_dict"):
					missed.append("ground %s" % path)
				else:
					g.call(&"from_dict", sd[path])
		"floor":
			var floor := tree.get_first_node_in_group(&"floor_marks") as FloorMarks
			if floor:
				floor.load_dict(sd)
		"blood":
			if world:
				Blood.load_list(world, sd)
		"dynamite":
			if world and not (sd as Array).is_empty():
				DynamiteStick.restore_all(world, sd)
		"folk":
			var folk := _folk(tree)
			if folk and not (sd as Dictionary).is_empty():
				folk.load_dict(sd)
		"people":
			_apply_people(tree, world, sd, missed)
		"player":
			var player := tree.get_first_node_in_group(&"player") as Player
			if player and not (sd as Dictionary).is_empty():
				_apply_player(player, sd)
		"horse":
			var ride := tree.get_first_node_in_group(&"ride_there") as RideThere
			if ride and not (sd as Dictionary).is_empty():
				ride.load_dict(sd)


static func _apply_people(tree: SceneTree, world: Node3D, sd: Dictionary, missed: Array[String]) -> void:
	var by_id := {}
	for n: Node in tree.get_nodes_in_group(&"people"):
		if n is HumanBody and n.is_inside_tree() and not n.is_queued_for_deletion() and not by_id.has((n as HumanBody).person_id):
			by_id[(n as HumanBody).person_id] = n
	for id: StringName in sd:
		var pd: Dictionary = sd[id]
		var man: HumanBody = by_id.get(id)
		if man == null and not bool(pd.physiology.alive) and world != null:
			# A dead man nobody makes again (a mission's outlaw): made of what the save kept of him.
			man = HumanBody.made_from(pd)
			world.add_child(man)
			by_id[id] = man
		if man == null:
			missed.append("person %s" % id)
			continue
		man.load_dict(pd)
		var folk := _folk(tree)
		if folk and not man.physiology.alive and folk.people.get(id) == man:
			folk.state[id] = &"dead"
	# Minds last: what each thinks of the others needs the others there.
	var player := tree.get_first_node_in_group(&"player")
	var find := func(key: String) -> Node:
		return player if key == "player" else by_id.get(StringName(key))
	for id: StringName in sd:
		var man: HumanBody = by_id.get(id)
		var mind: Dictionary = sd[id].get("mind", {})
		var brain := man.get_node_or_null(^"Brain") if man else null
		if brain == null or mind.is_empty():
			continue
		if brain.get(&"fear") != null:
			brain.set(&"fear", float(mind.get("fear", 0.0)))
		if brain.get(&"reaction") is Reaction and mind.has("shaken_since"):
			(brain.get(&"reaction") as Reaction).shaken_since = float(mind.shaken_since)
		if mind.has("turned") and brain.get(&"turned") != null:
			brain.set(&"turned", bool(mind.turned))
		if brain.get(&"relations") is Relations and mind.has("relations"):
			(brain.get(&"relations") as Relations).from_dict(mind.relations, find)


## The dead laid out under their sheets again: after the people (they lie as saved by then).
static func apply_laid(tree: SceneTree, d: Dictionary) -> void:
	var folk := _folk(tree)
	if folk and not (d.get("folk", {}) as Dictionary).is_empty():
		folk.load_laid(d.folk)


static func _apply_player(p: Player, sd: Dictionary) -> void:
	p.global_transform = sd.at
	p.velocity = Vector3.ZERO
	var was := p.input_enabled
	p.input_enabled = true
	p.add_look(Vector2(0.0, float(sd.pitch) - p.get_pitch_degrees()), false)
	p.input_enabled = was
	if p.movement != sd.movement:
		p.set_movement(sd.movement)
	for kind: StringName in Player.KIND_NODES:
		if sd.lacks.has(kind) and not p.lacks.has(kind):
			p.lack(kind)
		elif p.lacks.has(kind) and not sd.lacks.has(kind):
			p.give(kind)
	# (The rifle shares the Colt's belt: the Colt's is put back after it, so it's the one kept.)
	for kind: StringName in [&"shotgun", &"rifle", &"revolver"]:
		var w := p.camera.get_node_or_null(Player.KIND_NODES[kind])
		var st: Variant = w.get(&"state") if w else null
		if st is Object and sd.guns.has(kind):
			(st as Object).call(&"from_dict", sd.guns[kind])
	if p.dynamite() and sd.has("sticks"):
		p.dynamite().sticks = int(sd.sticks)
		p.dynamite().bundles = int(sd.bundles)
	if p.bucket() and sd.has("litres"):
		p.bucket().litres = float(sd.litres)
	if p.carry and sd.has("blood_on_you"):
		p.carry.blood_on_you = float(sd.blood_on_you)
	if p.wounds and sd.has("wounds"):
		p.wounds.load_dict(sd.wounds)


# --- The file ----------------------------------------------------------------------------------

static func path_of(slot: String) -> String:
	return "%s/%s.save" % [DIR, slot]


## One file: a line of JSON anyone can read (the version, the day and hour, when it was written,
## how big the rest is unpacked), then the save itself, Godot's own binary form of the dictionary,
## compressed. Written whole to a temp file first; the save it replaces is kept as `.bak` until the
## next, so at no moment is there no whole save on the disk.
static func write(d: Dictionary, slot := "slot1") -> Error:
	last_error = ""
	var err := DirAccess.make_dir_recursive_absolute(DIR)
	if err != OK:
		last_error = "couldn't make %s (%d)" % [DIR, err]
		return err
	var raw := var_to_bytes(d)
	var packed := raw.compress(FileAccess.COMPRESSION_ZSTD)
	var clock: Dictionary = d.get("clock", {})
	var head := {"magic": MAGIC, "version": int(d.get("version", VERSION)), "day": clock.get("day", 1),
			"hour": snappedf(float(clock.get("hour", 0.0)), 0.01), "world": d.get("world", ""),
			"written": Time.get_datetime_string_from_system(true), "size": raw.size(), "check": packed.size()}
	var path := path_of(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "couldn't open %s (%d)" % [tmp, FileAccess.get_open_error()]
		return FileAccess.get_open_error()
	f.store_line(JSON.stringify(head))
	f.store_buffer(packed)
	f.flush()
	err = f.get_error()
	f.close()
	if err != OK:
		last_error = "couldn't write %s (%d)" % [tmp, err]
		DirAccess.remove_absolute(tmp)
		return err
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		last_error = "couldn't put %s in place (%d)" % [path, err]
	return err


## The line at the top of a slot's file ({} if there's none or it isn't one): for a Continue button.
static func head(slot := "slot1") -> Dictionary:
	for path: String in [path_of(slot), path_of(slot) + ".bak"]:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var h := _head_of(f)
		if not h.is_empty():
			return h
	return {}


static func _head_of(f: FileAccess) -> Dictionary:
	var json := JSON.new()
	if json.parse(f.get_line()) != OK or not (json.data is Dictionary) or json.data.get("magic", "") != MAGIC:
		return {}
	return json.data


## A slot's save, brought up to this build's version ({}: none, broken or too new; `last_error`
## says which). A file cut short or spoilt falls back to the one before it (`.bak`).
static func read(slot := "slot1") -> Dictionary:
	last_error = "no save in %s" % slot
	for path: String in [path_of(slot), path_of(slot) + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var d := _read_file(path)
		if not d.is_empty():
			last_error = ""
			return d
	return {}


static func _read_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		last_error = "couldn't open %s" % path
		return {}
	var h := _head_of(f)
	if h.is_empty():
		last_error = "%s isn't a save" % path
		return {}
	var packed := f.get_buffer(f.get_length() - f.get_position())
	if packed.size() != int(h.get("check", -1)):
		last_error = "%s is cut short" % path
		return {}
	var raw := packed.decompress(int(h.size), FileAccess.COMPRESSION_ZSTD)
	var v: Variant = bytes_to_var(raw) if raw.size() == int(h.size) else null
	if not (v is Dictionary):
		last_error = "%s is spoilt" % path
		return {}
	return migrate(v)


## An older save brought up a version at a time ({} and `last_error` if it can't be).
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 0))
	if v > VERSION:
		last_error = "the save is from a newer build (version %d, this is %d)" % [v, VERSION]
		return {}
	while v < VERSION:
		if not MIGRATIONS.has(v):
			last_error = "no way up from a version %d save" % v
			return {}
		d = (MIGRATIONS[v] as Callable).call(d)
		v += 1
		d["version"] = v
	return d


## Capture and write, timed: {"error", "capture_ms", "write_ms", "bytes"}.
static func save(tree: SceneTree, slot := "slot1") -> Dictionary:
	var u := Time.get_ticks_usec()
	var d := capture(tree)
	var c := Time.get_ticks_usec()
	var err := write(d, slot)
	var w := Time.get_ticks_usec()
	var f := FileAccess.open(path_of(slot), FileAccess.READ)
	return {"error": err, "capture_ms": (c - u) / 1000.0, "write_ms": (w - c) / 1000.0, "bytes": f.get_length() if f else 0}


# --- Comparing two (the tests, the soak) -------------------------------------------------------

## Where two captures differ, as paths ("people/earl/physiology/blood_ml: 4000 != 3900"), numbers
## within `tol` and transforms within `tol_m` of each other the same. `skip`: keys left out.
static func differences(a: Variant, b: Variant, tol := 1e-4, tol_m := 1e-3, skip: Array = [], path := "", out: Array[String] = []) -> Array[String]:
	if out.size() > 60:
		return out
	if a is Dictionary and b is Dictionary:
		for k: Variant in a:
			if k in skip:
				continue
			if not (b as Dictionary).has(k):
				out.append("%s/%s: gone" % [path, k])
			else:
				differences(a[k], b[k], tol, tol_m, skip, "%s/%s" % [path, k], out)
		for k: Variant in b:
			if not (k in skip) and not (a as Dictionary).has(k):
				out.append("%s/%s: new" % [path, k])
	elif a is Array and b is Array:
		if (a as Array).size() != (b as Array).size():
			out.append("%s: %d things != %d" % [path, (a as Array).size(), (b as Array).size()])
		else:
			for i in (a as Array).size():
				differences(a[i], b[i], tol, tol_m, skip, "%s/%d" % [path, i], out)
	elif (a is float or a is int) and (b is float or b is int):
		if absf(float(a) - float(b)) > tol and not (is_nan(float(a)) and is_nan(float(b))):
			out.append("%s: %s != %s" % [path, a, b])
	elif a is Vector3 and b is Vector3:
		if (a as Vector3).distance_to(b) > tol_m:
			out.append("%s: %s != %s" % [path, a, b])
	elif a is Transform3D and b is Transform3D:
		var ta: Transform3D = a
		var tb: Transform3D = b
		if ta.origin.distance_to(tb.origin) > tol_m or ta.basis.get_rotation_quaternion().angle_to(tb.basis.get_rotation_quaternion()) > tol_m * 10.0:
			out.append("%s: at %s != %s" % [path, ta.origin, tb.origin])
	elif typeof(a) != typeof(b) and not ((a is String or a is StringName) and (b is String or b is StringName)):
		out.append("%s: %s != %s" % [path, a, b])
	elif not ((a is String or a is StringName) and String(a) == String(b)) and a != b:
		out.append("%s: %s != %s" % [path, a, b])
	return out

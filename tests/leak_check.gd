extends RefCounted
## What a test file left behind (#1326): the runner takes a picture of the world before each file
## (`take`) and compares it after (`leaks`), so a file that leaves something for the next one fails
## by name, not as a random red three files later. What it looks at:
##   - nodes: the root's children (a test's scene, a player, a valley not freed) and how many nodes
##     stand under each autoload;
##   - physics: the bodies and areas in the root's world (a raw RID, or a body outside the tree);
##   - signals: connections to the autoloads' signals left pointing at nothing live (a lambda left on
##     Events.noise by a freed test);
##   - statics: every class's public plain `static var`, the dials tests set (a bool, a number, a
##     string: ValleyFolk.murder_auto, FireSystem.in_play, Lab.spec_path ...);
##   - the engine: its time scale, physics rate and metas, the mouse mode;
##   - tweens still running.
## Settings are compared too (`settings_changed`); the runner puts them back before every file, so a
## setting left changed is named but not a leak. Timers made by SceneTree.create_timer can't be listed
## (the engine keeps them to itself): a Timer node is a node and is caught as one.
## `free_leaks` takes away what's in the tree and puts the statics and the engine back, so the next
## file starts as the last one did, whether or not this one failed.

## Statics that are the game's own state, not a test's dial: per-run caches, counters and clocks a
## fresh start leaves to fill (GameReset clears what must be). Checked by class.name.
const IGNORED_STATICS := {
	"Cover.asked": true, "Waypoints.asked": true, "Prof.frame_number": true,  # (counts of what was asked)
	"Ground.lifted": true, "Ground.rescued": true, "Structure.runaways": true,
	"ContinueCard.done": true,  # (once a run: every valley built headless sets it)
}

## Nodes a system makes on the root the first time it's needed when there's no current scene (in the
## game they go in the scene and go with it): taken away after every file so the next makes its own
## fresh, but not the file's fault. SpawnQueue kept its tick's room and its place in the physics
## order from one file to the next; DentWatch its listener on Events.bullet_hit.
const SYSTEM_NODES := ["GameAudio", "SpawnQueue", "DentWatch"]

## Statics that follow a setting (the runner puts the settings back before every file): not the file's
## fault, but put back after every file by their own function, so the next starts as the suite did.
## class.var -> the function that sets it.
## "" : the runner's own settings restore re-applies it (Settings._apply_quantise).
const FOLLOWERS := {
	"RealLook.shaders_real": "swap_shaders",  # (the world's shaders recompiled for the real look)
	"PixelArt.real": "", "PixelArt.blocks": "", "PixelArt.bold": "", "PixelArt.smooth": "",
	"PeopleBodies.smooth_paint": "",
}

## Every `static var` at a script's top level, by class (from the sources: Godot doesn't list them).
var statics := {}  # class name -> [script, [var names]]
var _before := {}
var _followers := {}  # class.var -> its value before the file


func _init() -> void:
	for k: String in FOLLOWERS:
		_followers[k] = null
	var re := RegEx.create_from_string("(?m)^static var ([A-Za-z_][A-Za-z0-9_]*)")
	for c: Dictionary in ProjectSettings.get_global_class_list():
		var path: String = c.path
		if not path.ends_with(".gd") or path.begins_with("res://tests/") or path.begins_with("res://addons/gut"):
			continue
		var text := FileAccess.get_file_as_string(path)
		if not text.contains("static var "):
			continue
		var names: Array[String] = []
		for m in re.search_all(text):
			var n := m.get_string(1)
			# (a public static is a dial a test may set; an `_x` one is a system's own cache or count)
			var k := "%s.%s" % [c.class, n]
			if not n.begins_with("_") and not IGNORED_STATICS.has(k) and not FOLLOWERS.has(k):
				names.append(n)
		if not names.is_empty():
			statics[String(c.class)] = [path, names]


## A value worth comparing: a dial (bool, number, string, vector, colour). Objects (a tuning loaded on
## first use, a material made once) and arrays and dictionaries (caches) aren't: GameReset clears
## what must be.
static func _plain(v: Variant) -> Variant:
	match typeof(v):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I, \
				TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_COLOR, TYPE_NODE_PATH:
			return v
	return null


func _statics() -> Dictionary:
	var out := {}
	for cls: String in statics:
		var path: String = statics[cls][0]
		if not ResourceLoader.has_cached(path):
			continue  # (not loaded yet: nothing has set it)
		var s := load(path) as GDScript
		if s == null:
			continue
		for n: String in statics[cls][1]:
			var v: Variant = s.get(n)
			var p: Variant = _plain(v)
			if p != null:
				out["%s.%s" % [cls, n]] = p
	return out


## Connections to the autoloads' signals that point at nothing live: a lambda whose test is gone, a
## node out of the tree (a system's own listener, a live object in the tree or a static's, is fine).
func _signals(root: Window) -> Dictionary:
	var out := {}
	for c in root.get_children():
		if not _is_autoload(c):
			continue
		for sig: Dictionary in c.get_signal_list():
			for con: Dictionary in c.get_signal_connection_list(sig.name):
				var call: Callable = con.callable
				var o: Object = call.get_object() if call.is_valid() else null
				var dead := not call.is_valid() or o == null or (o is Node and not (o as Node).is_inside_tree())
				if dead:
					var k := "%s.%s" % [c.name, sig.name]
					out[k] = int(out.get(k, 0)) + 1
	return out


static func _is_autoload(n: Node) -> bool:
	return ProjectSettings.has_setting("autoload/%s" % n.name)


static func _count(n: Node) -> int:
	var k := 1
	for c in n.get_children(true):
		k += _count(c)
	return k


static func physics_count(root: Window) -> int:
	var w := root.find_world_3d()
	if w == null:
		return 0
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * 200000.0
	q.shape = box
	q.collision_mask = 0xFFFFFFFF
	q.collide_with_areas = true
	q.collide_with_bodies = true
	return w.direct_space_state.intersect_shape(q, 65536).size()


func _engine(root: Window) -> Dictionary:
	var out := {
		"Engine.time_scale": Engine.time_scale,
		"Engine.physics_ticks_per_second": Engine.physics_ticks_per_second,
		"Engine.max_fps": Engine.max_fps,
		"Input.mouse_mode": Input.mouse_mode,
		"root.size": root.size,
	}
	for m: StringName in Engine.get_meta_list():
		out["Engine meta %s" % m] = _plain(Engine.get_meta(m))
	return out


## The picture before a file.
func take(root: Window) -> void:
	var kids := {}
	for c in root.get_children():
		kids[c.get_instance_id()] = _count(c) if _is_autoload(c) else 0
	for k: String in _followers:
		_followers[k] = _static_now(k)
	_before = {
		"kids": kids,
		"physics": physics_count(root),
		"signals": _signals(root),
		"statics": _statics(),
		"engine": _engine(root),
		"tweens": root.get_tree().get_processed_tweens().size(),
	}


## What's different now (`case` is the file's own node, on its way out): one line each, empty if
## nothing. Call it once the file's node is gone (the frame after its queue_free).
func leaks(root: Window, case: Node = null) -> PackedStringArray:
	var out: PackedStringArray = []
	var kids: Dictionary = _before.kids
	var extra := []
	for c in root.get_children():
		if case != null and is_instance_valid(case) and c == case:
			continue
		if not kids.has(c.get_instance_id()) and not SYSTEM_NODES.has(String(c.name)):
			extra.append("%s (%s, %d nodes)" % [c.name, _kind(c), _count(c)])
		elif _is_autoload(c):
			var grew := _count(c) - int(kids[c.get_instance_id()])
			if grew > 0:
				out.append("nodes: %d more under the %s autoload" % [grew, c.name])
	if not extra.is_empty():
		out.append("nodes left in the tree: %s" % ", ".join(extra))
	var bodies := physics_count(root) - int(_before.physics)
	if bodies > 0:
		out.append("physics: %d more bodies and areas in the world" % bodies)
	var sigs := _signals(root)
	var was: Dictionary = _before.signals
	for k: String in sigs:
		var more := int(sigs[k]) - int(was.get(k, 0))
		if more > 0:
			out.append("signals: %d more connected to %s" % [more, k])
	var st := _statics()
	var st0: Dictionary = _before.statics
	for k: String in st:
		if st0.has(k) and st0[k] != st[k]:
			out.append("static %s: %s -> %s" % [k, _show(st0.get(k)), _show(st[k])])
	var en := _engine(root)
	var en0: Dictionary = _before.engine
	for k: String in en:
		if en0.get(k) != en[k]:
			out.append("%s: %s -> %s" % [k, _show(en0.get(k)), _show(en[k])])
	for k: String in en0:
		if not en.has(k):
			out.append("%s: removed" % k)
	var tw := root.get_tree().get_processed_tweens().size() - int(_before.tweens)
	if tw > 0:
		out.append("tweens: %d still running" % tw)
	return out


static func _kind(n: Node) -> String:
	var s := n.get_script() as Script
	if s == null:
		return n.get_class()
	return String(s.get_global_name()) if s.get_global_name() != &"" else s.resource_path.get_file()


static func _show(v: Variant) -> String:
	return var_to_str(v)


## Put things back for the next file: nodes in the tree freed, statics and the engine as they were
## (signal connections are left: a lambda can't be told from the game's own).
func free_leaks(root: Window, case: Node = null) -> void:
	var kids: Dictionary = _before.kids
	for c in root.get_children():
		if kids.has(c.get_instance_id()) or (case != null and is_instance_valid(case) and c == case):
			continue
		root.remove_child(c)  # (out now: the next file starts on this frame)
		c.queue_free()
	var st := _statics()
	var st0: Dictionary = _before.statics
	for k: String in st:
		if st0.has(k) and st0[k] != st[k]:
			var parts := k.split(".")
			(load(statics[parts[0]][0]) as GDScript).set(parts[1], st0[k])
	var en0: Dictionary = _before.engine
	Engine.time_scale = en0["Engine.time_scale"]
	Engine.physics_ticks_per_second = en0["Engine.physics_ticks_per_second"]
	Engine.max_fps = en0["Engine.max_fps"]
	Input.mouse_mode = en0["Input.mouse_mode"]
	for m: StringName in Engine.get_meta_list():
		var k := "Engine meta %s" % m
		if not en0.has(k):
			Engine.remove_meta(m)
		elif en0[k] != null:
			Engine.set_meta(m, en0[k])


static func _class_script(cls: String) -> GDScript:
	for c: Dictionary in ProjectSettings.get_global_class_list():
		if String(c.class) == cls:
			return load(c.path) as GDScript
	return null


func _static_now(k: String) -> Variant:
	var parts := k.split(".")
	var s := _class_script(parts[0])
	return s.get(parts[1]) if s else null


## After every file, leak or not: what the systems made on the root (SYSTEM_NODES) taken away, and
## the FOLLOWERS put back as they were before it. How many nodes went.
func free_system_nodes(root: Window) -> int:
	for k: String in _followers:
		var was: Variant = _followers[k]
		if was != null and FOLLOWERS[k] != "" and _static_now(k) != was:
			var parts := k.split(".")
			_class_script(parts[0]).call(FOLLOWERS[k], was)
	var n := 0
	for c in root.get_children():
		if SYSTEM_NODES.has(String(c.name)) and not c.is_queued_for_deletion():
			# (freed now, not queued: a sound's delayed play, a SceneTreeTimer from the file, is let go with
			# its player instead of playing it out of the tree in the next file)
			c.free()
			n += 1
	return n

extends BridgeLab
## Issue #562 (bodies disappearing): watches every man (HumanBody) for the two ways he can go from
## the player's view: leaving the tree (freed or taken out), and staying in it but not drawn (hidden,
## off the camera's layers, a part through the ground, a part gone to a non-number). Lab only: it
## changes nothing in the game. README.md beside it has the runs and what they found.
##
##   bv_watch [out=/abs/file.jsonl]   start (again: clears what's been seen)
##   bv_report                        what's been seen so far, grouped by cause
##   bv_flee [chance]                 every OutlawBrain's flee_chance (1: whoever can, runs)
##   bv_parts NAME                    a man's root, his pelvis, how far apart, what's drawn

const HELP := {
	"bv_watch": "bv_watch [out=FILE.jsonl] -> log every man leaving the tree or not drawn (#562)",
	"bv_report": "bv_report -> what bv_watch has seen, grouped by cause",
	"bv_flee": "bv_flee [chance=1] -> every OutlawBrain's flee_chance",
	"bv_throw": "bv_throw NAME X Y Z -> he goes limp with that push (m/s), as a blast throws a man",
	"bv_parts": "bv_parts NAME -> his root and his pelvis (where he really is), what's drawn",
}

## Below the ground this far (m), a part has gone through it.
const BELOW := 2.0
## How often the drawing check runs (s).
const CHECK_EVERY := 1.0

var _on := false
var _out := ""
var _seen: Array[Dictionary] = []  ## every event, as written
var _snap := {}  ## HumanBody -> his last tick's state (what he was doing when he went)
var _known := {}  ## HumanBody -> true once connected
var _not_drawn := {}  ## HumanBody -> the reasons last reported (each change reported once)
var _hours_at := -1  ## the physics frame hours last passed (Events.hours_passed)
var _hours_why := &""
var _check := 0.0
var _flee := -1.0  ## bv_flee's chance, given to every man as he comes too (-1: left as he is)
var _left := {}  ## HumanBody -> his last tick's state as his brain said he'd left town (left_town)


func _cmd_bv_watch(a: Array) -> Dictionary:
	for w: String in a:
		if w.begins_with("out="):
			_out = w.substr(4)
	_seen.clear()
	_snap.clear()
	_not_drawn.clear()
	if _out != "":
		var f := FileAccess.open(_out, FileAccess.WRITE)
		if f:
			f.close()
	if not Events.hours_passed.is_connected(_on_hours):
		Events.hours_passed.connect(_on_hours)
	_on = true
	_connect_all()
	return {"watching": _known.size()}


func _cmd_bv_report(_a: Array) -> Dictionary:
	var by := {}
	for e: Dictionary in _seen:
		var k := "%s: %s" % [e.kind, e.cause]
		by[k] = int(by.get(k, 0)) + 1
	return {"events": _seen.size(), "by_cause": by, "last": _seen.slice(maxi(0, _seen.size() - 8))}


func _cmd_bv_flee(a: Array) -> Dictionary:
	var c := float(a[0]) if a.size() > 0 else 1.0
	_flee = c
	_connect_all()
	var n := 0
	for man in _men():
		var b := man.get_node_or_null(^"Brain")
		if b is OutlawBrain:
			(b as OutlawBrain).flee_chance = c
			n += 1
	return {"brains": n, "flee_chance": c}


func _cmd_bv_throw(a: Array) -> Dictionary:
	if a.size() < 4:
		return {"ok": false, "error": HELP.bv_throw}
	for man in _men():
		if String(man.person_id) == a[0] or man.name == a[0]:
			man.go_limp(Vector3(float(a[1]), float(a[2]), float(a[3])))
			return {"thrown": String(man.person_id)}
	return {"ok": false, "error": "no man %s" % a[0]}


func _cmd_bv_parts(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": HELP.bv_parts}
	for man in _men():
		if String(man.person_id) == a[0] or man.name == a[0]:
			var st := _state(man)
			st["outside_box_m"] = snappedf(_outside_box(man), 0.01)
			st["not_drawn"] = _why_not_drawn(man)
			return st
	return {"ok": false, "error": "no man %s" % a[0]}


func _physics_process(delta: float) -> void:
	if not _on and _flee < 0.0:
		return
	_connect_all()
	if not _on:
		return
	for k: Variant in _known.keys():
		if not is_instance_valid(k):
			_known.erase(k)
			_snap.erase(k)
			_not_drawn.erase(k)
			_left.erase(k)
			continue
		var man := k as HumanBody
		if man.is_inside_tree():
			_snap[man] = _state(man)
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	for k: Variant in _known.keys():
		var man := k as HumanBody
		if not man.is_inside_tree():
			continue
		var why := _why_not_drawn(man)
		var was: Array = _not_drawn.get(man, [])
		if why != was:
			_not_drawn[man] = why
			if not why.is_empty():
				_log({"kind": "not_drawn", "cause": ", ".join(PackedStringArray(why))}, _snap.get(man, {}))
			elif not was.is_empty():
				_log({"kind": "drawn_again", "cause": ", ".join(PackedStringArray(was))}, _snap.get(man, {}))


func _connect_all() -> void:
	for man in _men():
		if _known.has(man):
			continue
		_known[man] = true
		man.tree_exiting.connect(_on_exiting.bind(man))
		var b := man.get_node_or_null(^"Brain")
		if b is OutlawBrain and _flee >= 0.0:
			(b as OutlawBrain).flee_chance = _flee
		if b is OutlawBrain:
			(b as OutlawBrain).left_town.connect(_on_left_town.bind(man))


func _men() -> Array[HumanBody]:
	var out: Array[HumanBody] = []
	for n in get_tree().get_nodes_in_group(&"people"):
		if n is HumanBody:
			out.append(n)
	for n in PeopleTick.people():
		if is_instance_valid(n) and not n in out:
			out.append(n)
	return out


func _on_left_town(man: HumanBody) -> void:
	_left[man] = _snap.get(man, {})


func _on_hours(_h: float, why: StringName) -> void:
	_hours_at = Engine.get_physics_frames()
	_hours_why = why


## He's going from the tree: what he was doing on his last tick says which way out it was (the
## free itself is deferred, so a stack here shows only the engine's flush).
func _on_exiting(man: HumanBody) -> void:
	if not _on or not is_inside_tree() or get_tree().root.is_queued_for_deletion():
		return
	var s: Dictionary = _snap.get(man, {})
	if is_instance_valid(man):
		s = _state(man)  # this tick's, where it can still be read
	var cause := "unknown"
	var frame := Engine.get_physics_frames()
	if man.is_queued_for_deletion():
		if _left.has(man):
			var before: Dictionary = _left[man]
			if _hours_at >= 0 and frame - _hours_at <= 2:
				cause = "left town: hours passed (%s), freed where he stood" % _hours_why
			elif before.get("step", "") == "leave":
				cause = "left town: walked his leave route to its end"
			else:
				cause = "left town: leave step with no route, freed where he stood (was %s, %s)" % [before.get("mood", "?"), before.get("step", "?")]
			s["before"] = before
			var town := get_tree().get_first_node_in_group(&"town_life")
			if town != null and town.get("places") is Waypoints and is_instance_valid(man):
				var edge: Vector3 = (town.places as Waypoints).at(&"west_edge")
				if edge.is_finite():
					s["from_west_edge_m"] = snappedf(edge.distance_to(man.global_position), 0.1)
		else:
			cause = "queue_free (not his brain's leaving)"
	else:
		cause = "taken out of the tree (remove_child / scene change)"
	var stack := get_stack()
	_log({"kind": "left_tree", "cause": cause, "stack": stack.slice(0, 6)}, s)


func _log(e: Dictionary, s: Dictionary) -> void:
	e["frame"] = Engine.get_physics_frames()
	e["t"] = snappedf(Time.get_ticks_msec() / 1000.0, 0.01)
	e.merge(s)
	_seen.append(e)
	if _out != "":
		var f := FileAccess.open(_out, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
			f.store_line(JSON.stringify(e))
			f.close()


## What he is this tick: who, alive, limp, his mind's mood and step, where his root and his pelvis
## are, and whether you'd see him (in the camera's view, nothing solid between).
func _state(man: HumanBody) -> Dictionary:
	var out := {"name": String(man.person_id), "node": String(man.name), "alive": man.physiology.alive if man.physiology else null,
		"limp": man.limp, "prone": man.prone, "root": _arr(man.global_position)}
	var pelvis := man.parts.get(&"pelvis") as Node3D
	var at := man.global_position
	if pelvis != null and is_instance_valid(pelvis):
		at = pelvis.global_position
		out["pelvis"] = _arr(at)
		out["root_to_pelvis_m"] = snappedf(man.global_position.distance_to(at), 0.01)
	var b := man.get_node_or_null(^"Brain")
	if b is OutlawBrain:
		var ob := b as OutlawBrain
		out["mood"] = OutlawBrain.Mood.keys()[ob.mood]
		out["step"] = String(ob.agenda[0].do) if not ob.agenda.is_empty() else ""
		out["route_n"] = ob._route.size()
		out["hold"] = not ob.hold.is_empty()
	elif b != null:
		out["brain"] = b.get_class() if b.get_script() == null else (b.get_script() as Script).get_global_name()
	var cam := get_viewport().get_camera_3d() if player == null else player.camera
	if cam != null and is_instance_valid(cam):
		out["dist_m"] = snappedf(cam.global_position.distance_to(at), 0.1)
		out["in_view"] = _in_view(cam, man, at + Vector3.UP * 0.3)
	return out


func _in_view(cam: Camera3D, man: HumanBody, p: Vector3) -> bool:
	if not cam.is_position_in_frustum(p) or cam.global_position.distance_to(p) > 200.0:
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, p, Layers.WORLD)
	var ex: Array[RID] = []
	for part: Variant in man.parts.values():
		if part is CollisionObject3D:
			ex.append((part as CollisionObject3D).get_rid())
	q.exclude = ex
	return cam.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Why he isn't drawn ([] if he is): hidden, off the camera's layers, a part under the ground or at
## a non-number.
func _why_not_drawn(man: HumanBody) -> Array:
	var why: Array = []
	if not man.is_visible_in_tree():
		why.append("root hidden")
	var cam := player.camera if player != null else get_viewport().get_camera_3d()
	var meshes: Array = man.find_children("*", "MeshInstance3D", true, false)
	var shown := 0
	var on_layer := 0
	for mi: MeshInstance3D in meshes:
		if not mi.is_visible_in_tree():
			continue
		shown += 1
		if cam == null or (mi.layers & cam.cull_mask) != 0:
			on_layer += 1
	if meshes.size() > 0 and shown == 0:
		why.append("every mesh hidden")
	elif shown > 0 and on_layer == 0:
		why.append("no mesh on the camera's layers")
	# The skin's culling box (HumanBody's skin meshes carry a fixed custom_aabb about his root): a
	# part well outside it is drawn only while that box is on screen.
	var out_m := _outside_box(man)
	if out_m > 0.3:
		why.append("parts %.1f m outside the skin's culling box" % out_m)
	var ground := get_tree().get_first_node_in_group(&"ground") as Ground
	for sid: StringName in [&"pelvis", &"head", &"chest"]:
		var part := man.parts.get(sid) as Node3D
		if part == null or not is_instance_valid(part):
			continue
		var p := part.global_position
		if not p.is_finite():
			why.append("%s at a non-number" % sid)
			continue
		if ground != null and p.y < ground.height_at(p.x, p.z) - BELOW:
			why.append("%s %.1f m under the ground" % [sid, ground.height_at(p.x, p.z) - p.y])
	return why


## How far (m) his furthest part is outside his skin meshes' culling box (0: all inside).
static func _outside_box(man: HumanBody) -> float:
	if man.skeleton == null:
		return 0.0
	var worst := 0.0
	for mi: Node in man.skeleton.get_children():
		if not mi is MeshInstance3D or not (mi as MeshInstance3D).is_visible_in_tree():
			continue
		var box := (mi as MeshInstance3D).custom_aabb
		if box.size == Vector3.ZERO:
			continue
		var inv := (mi as MeshInstance3D).global_transform.affine_inverse()
		for part: Variant in man.parts.values():
			if not is_instance_valid(part):
				continue
			var p: Vector3 = inv * (part as Node3D).global_position
			var c := p.clamp(box.position, box.end)
			worst = maxf(worst, c.distance_to(p))
		return worst  # every piece has the same box
	return worst


static func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

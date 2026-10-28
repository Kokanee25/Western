extends Node
## Every man of the gang who goes down in a fight (issue #446: bodies that keep moving into the
## world): how fast and which way he was going, what stood in his path within 2 m, how far he
## travelled once limp (his centre of mass, level), and what he touched and broke on the way.
## `gf_fight ... falls=1` adds it; the fight's record gets `falls` (one entry a man down). The
## fight's own end doesn't cut a fall short: the bridge waits (up to TRACK_S) for the last one.
##
## It reads only: his parts' contacts are reported while he falls (contact_monitor, as BodyImpacts
## turns on near timber), which costs a little frame but moves nothing.

## A fall is followed this long after he goes limp (s), or until he's still.
const TRACK_S := 4.0
## Still: his centre of mass under this (m/s) for STILL_S.
const STILL_SPEED := 0.08
const STILL_S := 0.5
## What's ahead of him: a sphere this big cast this far along his level velocity, at these heights
## over his feet (knee, hip, chest).
const PATH_M := 2.0
const PATH_R := 0.2
const PATH_UP := [0.5, 0.95, 1.3]
## A member broken this near one of his parts (m), while he's falling, is his.
const BREAK_NEAR := 0.8

var men: Array = []  ## HumanBody (the gang)
var name_of: Callable  ## HumanBody -> his id
var falls: Array = []  ## the records, in the order they went down
var _before := {}  ## HumanBody -> how he was moving on his last tick on his feet
var _live: Array = []  ## [HumanBody, record, state] being followed
var _t := 0.0


func _ready() -> void:
	Events.person_fell.connect(_on_fell)
	Events.member_broken.connect(_on_broken)


func _exit_tree() -> void:
	if Events.person_fell.is_connected(_on_fell):
		Events.person_fell.disconnect(_on_fell)
	if Events.member_broken.is_connected(_on_broken):
		Events.member_broken.disconnect(_on_broken)


## Nobody's still being followed.
func finished() -> bool:
	return _live.is_empty()


func _physics_process(delta: float) -> void:
	_t += delta
	for man in men:
		if not is_instance_valid(man) or (man as HumanBody).limp:
			continue
		var h := man as HumanBody
		_before[h] = {"move_speed": h.move_speed, "gait": String(h.gait), "stumbling": h.stumbling > 0.0,
				"v": h._velocity_now, "facing": -h.global_basis.z, "prone": h.prone}
	for f: Array in _live.duplicate():
		_follow(f, delta)


func _on_fell(p: Node, conscious: bool) -> void:
	if not p in men or not is_instance_valid(p):
		return
	var man := p as HumanBody
	if not man.limp:
		return  # down on his belly (go_prone), still crawling: his fall is when he goes limp
	var was: Dictionary = _before.get(man, {})
	var com := _com(man)
	var v: Vector3 = com[1]
	var flat := Vector3(v.x, 0.0, v.z)
	var rec := {"id": name_of.call(man), "t": snappedf(_t, 0.01), "conscious": conscious, "alive": man.physiology.alive,
		"gait": String(was.get("gait", "")), "move_speed": snappedf(float(was.get("move_speed", 0.0)), 0.01),
		"stumbling": bool(was.get("stumbling", false)), "prone": bool(was.get("prone", false)),
		# What the ragdoll took over: his centre of mass's velocity on the tick he went limp.
		"speed": snappedf(flat.length(), 0.01), "v": _arr(v),
		"heading_deg": snappedf(rad_to_deg(atan2(-flat.x, -flat.z)), 1.0) if flat.length() > 0.05 else null,
		"facing_vs_heading_deg": snappedf(rad_to_deg((was.get("facing", flat) as Vector3).angle_to(flat)), 1.0) if flat.length() > 0.05 and was.has("facing") else null,
		"at": _arr(com[0]), "ahead": _ahead(man, com[0], flat)}
	falls.append(rec)
	for rb: RigidBody3D in _parts(man):
		rb.contact_monitor = true
		rb.max_contacts_reported = maxi(rb.max_contacts_reported, 8)
	_live.append([man, rec, {"start": com[0], "last": com[0], "path": 0.0, "far": 0.0, "still": 0.0,
			"age": 0.0, "touched": {}, "broke": [], "peak_speed": flat.length(), "props": _props_near(com[0])}])


## The kit props standing within PROPS_NEAR of him (furniture he might knock loose).
const PROPS_NEAR := 3.0


func _props_near(at: Vector3) -> Array:
	var out: Array = []
	for st in get_tree().get_nodes_in_group(&"structures"):
		if st is KitProp and not (st as KitProp).loose and (st as Node3D).global_position.distance_to(at) < PROPS_NEAR:
			out.append(st)
	return out


## What stands in the way of where he's going: the nearest thing a sphere at knee, hip and chest
## height meets along his level velocity within PATH_M.
func _ahead(man: HumanBody, com: Vector3, flat: Vector3) -> Variant:
	if flat.length() < 0.2:
		return null
	var space := man.get_world_3d().direct_space_state
	var dir := flat.normalized()
	var feet := Vector3(com.x, man.global_position.y, com.z)
	var shape := SphereShape3D.new()
	shape.radius = PATH_R
	var best: Dictionary = {}
	for up: float in PATH_UP:
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * up - dir * 0.15)
		q.motion = dir * (PATH_M + 0.15)
		q.collision_mask = Layers.WORLD
		var frac := space.cast_motion(q)
		if frac[1] >= 1.0:
			continue
		var d := (PATH_M + 0.15) * frac[1] - 0.15
		if not best.is_empty() and d >= float(best.dist):
			continue
		q.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * up - dir * 0.15 + q.motion * frac[1])
		q.motion = Vector3.ZERO
		var rest := space.get_rest_info(q)
		if rest.is_empty():
			continue
		var o := instance_from_id(int(rest.collider_id))
		best = {"dist": snappedf(maxf(d, 0.0), 0.01), "up": up, "what": _describe(o)}
	return null if best.is_empty() else best


func _follow(f: Array, delta: float) -> void:
	var man: HumanBody = f[0]
	var rec: Dictionary = f[1]
	var s: Dictionary = f[2]
	s.age += delta
	if not is_instance_valid(man):
		_close(f)
		return
	var com := _com(man)
	var at: Vector3 = com[0]
	var v: Vector3 = com[1]
	var step := Vector2(at.x - s.last.x, at.z - s.last.z).length()
	s.path += step
	s.last = at
	s.far = maxf(s.far, Vector2(at.x - s.start.x, at.z - s.start.z).length())
	s.peak_speed = maxf(s.peak_speed, Vector2(v.x, v.z).length())
	for rb: RigidBody3D in _parts(man):
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		if st == null:
			continue
		for i in st.get_contact_count():
			var o := st.get_contact_collider_object(i)
			if o == null or (o is RigidBody3D and o.has_meta(&"human_body") and o.get_meta(&"human_body") == man):
				continue
			var d := _describe(o)
			var key := "%s|%s" % [d.get("structure", d.get("node", "")), d.get("member", d.get("kind", ""))]
			var e: Dictionary = s.touched.get(key, {})
			if e.is_empty():
				e = d.duplicate()
				e["first_t"] = snappedf(s.age, 0.01)
				e["speed"] = 0.0
				e["impulse"] = 0.0
				s.touched[key] = e
			e.speed = maxf(float(e.speed), snappedf(rb.linear_velocity.length(), 0.01))
			e.impulse = snappedf(float(e.impulse) + st.get_contact_impulse(i).length(), 0.01)
	s.still = s.still + delta if v.length() < STILL_SPEED else 0.0
	if s.age >= TRACK_S or s.still >= STILL_S:
		_close(f)


func _close(f: Array) -> void:
	var rec: Dictionary = f[1]
	var s: Dictionary = f[2]
	var start: Vector3 = s.start
	var last: Vector3 = s.last
	rec["travel"] = snappedf(Vector2(last.x - start.x, last.z - start.z).length(), 0.01)
	rec["travel_far"] = snappedf(s.far, 0.01)
	rec["path"] = snappedf(s.path, 0.01)
	rec["followed_s"] = snappedf(s.age, 0.01)
	rec["peak_speed"] = snappedf(s.peak_speed, 0.01)
	rec["end"] = _arr(last)
	rec["drop"] = snappedf(start.y - last.y, 0.01)
	rec["touched"] = (s.touched as Dictionary).values()
	rec["broke"] = s.broke
	rec["props_loosed"] = (s.props as Array).filter(func(p: Variant) -> bool: return is_instance_valid(p) and (p as KitProp).loose) \
			.map(func(p: KitProp) -> String: return "%s (%s)" % [p.name, p.kit_id])
	_live.erase(f)


func _on_broken(id: StringName) -> void:
	if _live.is_empty():
		return
	# (Member ids repeat from structure to structure: every one of that id is looked at.)
	var found: Array[StructureMember] = []
	for st in get_tree().get_nodes_in_group(&"structures"):
		var m = (st as Structure).members.get(id)
		if m is StructureMember and is_instance_valid(m):
			found.append(m)
	for f: Array in _live:
		var man: HumanBody = f[0]
		if not is_instance_valid(man):
			continue
		for m in found:
			var box := m.world_aabb().grow(BREAK_NEAR)
			if _parts(man).any(func(rb: RigidBody3D) -> bool: return box.has_point(rb.global_position)):
				var s := m.get_parent() as Node
				(f[2].broke as Array).append({"t": snappedf(f[2].age, 0.01), "member": String(id), "kind": String(m.kind),
					"structure": String(s.name) if s else "", "kit": String(s.get(&"kit_id")) if s is KitProp else ""})
				return


## What a collider is, for the record: a structure's member (its structure, kind, id; a kit prop's
## kit), a man, the ground, rubble, anything else by its node's name.
func _describe(o: Object) -> Dictionary:
	if o is StructureMember:
		var m := o as StructureMember
		var s := m.get_parent()
		var d := {"structure": String(s.name) if s else "", "member": String(m.member_id), "kind": String(m.kind)}
		if s is KitProp:
			d["kit"] = String((s as KitProp).kit_id)
		return d
	if o is RigidBody3D and o.has_meta(&"human_body"):
		return {"node": "man", "kind": "man"}
	if o is RigidBody3D and (o as Node).is_in_group(&"rubble"):
		return {"node": "rubble", "kind": "rubble"}
	if o is Node:
		var n := o as Node
		return {"node": String(n.name), "kind": (n.get_script() as Script).resource_path.get_file().get_basename() if n.get_script() else n.get_class()}
	return {"node": "?", "kind": "?"}


func _parts(man: HumanBody) -> Array:
	return man.parts.values().filter(func(p: Variant) -> bool: return p is RigidBody3D and is_instance_valid(p))


## His centre of mass and its velocity (his parts weighed).
func _com(man: HumanBody) -> Array:
	var m := 0.0
	var at := Vector3.ZERO
	var v := Vector3.ZERO
	for rb: RigidBody3D in _parts(man):
		m += rb.mass
		at += rb.global_position * rb.mass
		v += rb.linear_velocity * rb.mass
	if m <= 0.0:
		return [man.global_position, Vector3.ZERO]
	return [at / m, v / m]


func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

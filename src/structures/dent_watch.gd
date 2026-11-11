class_name DentWatch
extends Node
## Finds the blows that dent plates (issue #770; the rules are Dents'): one in a scene, its
## watched bodies (a coach gone loose: `watch(rb, structure)`) read for contacts every tick. Each
## contact on a plate does work closing it: half its impulse times the speed the two met at (last
## tick's, along the impulse: a plastic knock in one tick is exactly 1/2 m v^2 of the pair's reduced
## mass, Goldsmith, "Impact"); a resting or sliding contact closes at nothing and does none. A
## plate's blow lasts while it's struck; when it ends a DentTuning.share of its work goes into it.
## What struck it may say how wide it is (`dent_radius` meta) and along what (`dent_axis()` and
## `dent_length` on it: a log's trough); `striker(rb)` keeps its speed each tick.
## Balls dent too (`Events.bullet_hit`: the energy the iron took, times `ball_share`).

signal dented(member: StructureMember, result: Dictionary, joules: float)

var _bodies := {}  ## RigidBody3D -> Structure
var _open := {}  ## plate member -> its blow so far
## Every dent it made: {"t", "member", "joules" (the blow's, before the share), "depth", "torn", "by"}.
var made: Array[Dictionary] = []
var _tick := 0
## Print every blow closed (the lab's --debug).
var debug := false


func _ready() -> void:
	add_to_group(&"dent_watch")
	Events.bullet_hit.connect(_on_bullet_hit)


## The scene's watch (made if there's none).
static func of(tree: SceneTree) -> DentWatch:
	var w := tree.get_first_node_in_group(&"dent_watch") as DentWatch
	if w == null:
		w = DentWatch.new()
		w.name = "DentWatch"
		tree.current_scene.add_child(w) if tree.current_scene else tree.root.add_child(w)
	return w


## Read `rb`'s contacts (its members `s`'s).
func watch(rb: RigidBody3D, s: Structure) -> void:
	if rb == null or not is_instance_valid(rb):
		return
	rb.contact_monitor = true
	rb.max_contacts_reported = 128
	rb.set_meta(&"dent_watch", true)
	_bodies[rb] = s


func _physics_process(delta: float) -> void:
	_tick += 1
	var dt := Dents.t()
	var gap := maxi(int(round(dt.contact_gap_s / maxf(delta, 1e-4))), 1)
	var seen := {}
	for held: Variant in _bodies.keys():
		if not is_instance_valid(held):
			_bodies.erase(held)
			continue
		var rb := held as RigidBody3D
		if rb.sleeping:
			continue
		var s: Structure = _bodies[rb]
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		if st == null:
			continue
		for i in st.get_contact_count():
			var j := st.get_contact_impulse(i)
			var jl := j.length()
			if jl < 1e-4:
				continue
			var m := Dents.member_of_shape(s, rb, st.get_contact_local_shape(i))
			if m == null or not Dents.can_dent(m):
				continue
			var other := st.get_contact_collider_object(i)
			var at := st.get_contact_collider_position(i)
			# The work this impulse did closing the contact: half of it times the speed they met
			# at (last tick's, before the solver stopped them), along the impulse.
			var close := -(_velocity_at(rb, at) - _velocity_at(other, at)).dot(j / jl)
			if close <= 0.0:
				continue
			var e := 0.5 * jl * close
			var blow: Dictionary = _open.get_or_add(m, {"e": 0.0, "pt": Vector3.ZERO, "push": Vector3.ZERO,
					"by": other, "first": _tick, "last": _tick})
			blow.e += e
			blow.pt += at * e
			blow.push += j
			blow.last = _tick
			if other is RigidBody3D and e > float(blow.get("by_e", 0.0)):
				blow.by = other
				blow.by_e = e
		seen[rb] = true
	for m: Variant in _open.keys():
		var blow: Dictionary = _open[m]
		if _tick - int(blow.last) > gap or not is_instance_valid(m):
			_open.erase(m)
			if is_instance_valid(m):
				_close(m, blow)
	# Each watched body's and each striker's speed, for next tick's contacts.
	_last.clear()
	for rb: Variant in seen:
		_keep(rb)
	for rb: Variant in _strikers:
		if is_instance_valid(rb):
			_keep(rb)


var _last := {}  ## body -> [linear, angular, centre of mass (world)] last tick
## Bodies that strike watched ones (their speed kept each tick: the log).
var _strikers: Array = []


## Keep `rb`'s speed each tick (something that may strike a watched body).
func striker(rb: RigidBody3D) -> void:
	if not _strikers.has(rb):
		_strikers.append(rb)


func _keep(rb: RigidBody3D) -> void:
	_last[rb] = [rb.linear_velocity, rb.angular_velocity, rb.global_transform * rb.center_of_mass]


func _velocity_at(o: Object, at: Vector3) -> Vector3:
	if o is RigidBody3D and is_instance_valid(o):
		var rb := o as RigidBody3D
		var k: Array = _last.get(rb, [rb.linear_velocity, rb.angular_velocity, rb.global_transform * rb.center_of_mass])
		return (k[0] as Vector3) + (k[1] as Vector3).cross(at - (k[2] as Vector3))
	return Vector3.ZERO


## A blow on a plate over: its energy's share into it.
func _close(m: StructureMember, blow: Dictionary) -> void:
	var dt := Dents.t()
	var e := float(blow.e)
	if debug:
		print("blow on %s by %s: %.0f J" % [String(m.member_id), String(blow.by.name) if is_instance_valid(blow.by) and blow.by is Node else "?", e])
	if e < dt.least_joules:
		return
	var other: Object = blow.by if is_instance_valid(blow.by) else null
	var radius := float(other.get_meta(&"dent_radius", -1.0)) if other else -1.0
	var length := float(other.get_meta(&"dent_length", 0.0)) if other else 0.0
	var along: Vector3 = other.call(&"dent_axis") if other and other.has_method(&"dent_axis") else Vector3.ZERO
	var into := e * dt.share
	var res := Dents.dent(m, (blow.pt as Vector3) / e, into, blow.push, radius, along, length)
	if not res.is_empty():
		made.append({"t": Time.get_ticks_msec(), "tick": int(blow.first), "member": String(m.member_id),
				"joules": e, "into": into, "depth": float(res.depth), "torn": bool(res.torn),
				"by": String((other as Node).name) if other is Node else "ground"})
		dented.emit(m, res, into)


func _on_bullet_hit(info: Dictionary) -> void:
	var collider: Object = info.get("collider")
	var spent := float(info.get("energy_before", 0.0)) - float(info.get("energy_after", 0.0))
	if spent <= 0.0:
		return
	var m: StructureMember = collider as StructureMember
	if m == null and collider is RigidBody3D and _bodies.has(collider):
		m = _nearest_plate(collider as RigidBody3D, _bodies[collider], info.position)
	if m == null or not Dents.can_dent(m):
		return
	var into := spent * Dents.t().ball_share
	var res := Dents.dent(m, info.position, into, info.get("direction", Vector3.ZERO), 0.03)
	if not res.is_empty():
		made.append({"t": Time.get_ticks_msec(), "tick": _tick, "member": String(m.member_id), "joules": spent,
				"into": into, "depth": float(res.depth), "torn": bool(res.torn), "by": "ball"})
		dented.emit(m, res, into)


func _nearest_plate(rb: RigidBody3D, s: Structure, at: Vector3) -> StructureMember:
	var best: StructureMember = null
	var best_d := 0.5
	for c in rb.get_children():
		if not c is MeshInstance3D:
			continue
		var m: StructureMember = s.members.get(c.get_meta(&"member", &""))
		if m and Dents.can_dent(m):
			var d := (c as Node3D).global_position.distance_to(at)
			if d < best_d:
				best = m
				best_d = d
	return best

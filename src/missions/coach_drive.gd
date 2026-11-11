class_name CoachDrive
extends Node3D
## A coach on the road (the coach heist, issue #770): driven, it's a kit prop moved along its
## heading each tick at the team's walk (kinematic, as the train's cars are a sim's), its guards
## seated in it and carried with it. When something heavy is about to strike it (a striker's box,
## swept by its speed a few ticks on, meets the coach's), or it goes loose any other way (a blast),
## it's handed to physics as TrainWreck hands a derailed car: `KitProp.go_loose` with the drive's
## velocity, so Jolt meets the blow with the whole coach; its plates watched for dents (DentWatch);
## its guards go limp a tick apart (a ragdoll made is ~30 ms here) and are thrown about inside by
## the box; the team pulls on at its walk through the traces (springs on the trace hooks), and a
## trace pulled past its strength breaks at its hook.

signal handed_off(bodies: Array)
signal trace_broke(hook: StringName, newtons: float)

## The team's walk up the grade (m/s): a laden coach's four-in-hand on a climb.
@export var speed := 1.4
## A trace's stiffness (N/m: leather, ~2.5 m long) and what it holds before it or its hook gives
## (N: two-ply harness leather ~40 mm x 12 mm at ~20 MPa is ~9.6 kN).
@export var trace_stiffness := 40000.0
@export var trace_breaks := 9000.0
## The traces' length from the hook to the horses' collars (m).
@export var trace_length := 2.5
## How far ahead (ticks) a striker's sweep is looked at.
const LOOK_TICKS := 3

var coach: KitProp
var heading := Vector3.LEFT
var driving := false
var loose := false
## What may strike it (the log).
var strikers: Array[RigidBody3D] = []
## The ground's height under a point (x, z) -> y, or none: driven, the coach is set on it at its
## axles (`AXLES`, its own x: front, hind), pitched to the grade (the South Road climbs ~7 % to the
## coach cut, #794). Without, it's driven level.
var ground := Callable()
const AXLES := Vector2(-1.45, 1.03)
## Its seated men: [{"man", "local"}] (local: his transform in the coach's space).
var riders: Array[Dictionary] = []
var bodies: Array[RigidBody3D] = []
var events: Array[Dictionary] = []
var time := 0.0
var _traces := {}  ## hook member id -> {"anchor": Vector3 (where its horse is), "on": bool}
var _limp_queue: Array[HumanBody] = []
var _last_xf := Transform3D.IDENTITY


## Drive `c` (in the tree, standing) along its front (the coach's -x, the pole's end).
func start(c: KitProp) -> void:
	coach = c
	c.mass_by_members = true  # (its plates high up decide whether it goes over)
	c.breaks_up = false  # (a coach takes a jolt whole: what's struck hard still breaks)
	heading = -c.global_basis.x.normalized()
	driving = true
	_last_xf = c.global_transform
	c.went_loose.connect(_on_went_loose)
	for id: StringName in c.members:
		if String(id).contains("trace_hook_"):
			var m: StructureMember = c.members[id]
			_traces[id] = {"anchor": m.global_position + heading * trace_length, "on": true}


## Seat `man` at a seat of the kit file's `seats_at` (coach space): his feet on the floor under
## it, facing the seat's `yaw` (degrees, -z turned about y: the box's two face forward) or, without
## one, across the coach (the benches face each other), sitting back.
func seat(man: HumanBody, at: Vector3, floor_y: float, yaw := NAN) -> void:
	var local := Transform3D(Basis.IDENTITY, Vector3(at.x, floor_y, at.z))
	var face := Vector3(-signf(at.x) if absf(at.x) > 0.1 else -1.0, 0.0, 0.0)
	if not is_nan(yaw):
		face = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3.FORWARD
	man.global_transform = coach.global_transform * local
	man.face(man.global_position + coach.global_basis * face)
	man.set_pose(&"sit_back")
	riders.append({"man": man, "local": coach.global_transform.affine_inverse() * man.global_transform})


func _physics_process(delta: float) -> void:
	if coach == null or not is_instance_valid(coach):
		return
	time += delta
	if not loose and _strike_coming(delta):
		hand_off("struck")
	elif not loose and driving:
		coach.global_position += heading * speed * delta
		if ground.is_valid():
			_on_ground()
	if not loose:
		for r: Dictionary in riders:
			var man := r.man as HumanBody
			if is_instance_valid(man) and not man.limp:
				man.global_transform = coach.global_transform * (r.local as Transform3D)
				man.set_pose(&"sit_back")
	if driving:
		for id: StringName in _traces:
			_traces[id].anchor += heading * speed * delta
	if loose:
		_pull_traces()
		if not _limp_queue.is_empty():
			var man: HumanBody = _limp_queue.pop_front()
			if is_instance_valid(man) and not man.limp:
				for rb in bodies:
					if is_instance_valid(rb):
						_ride(man, rb, false)
				man.go_limp()
				events.append({"t": time, "what": "thrown", "who": String(man.person_id)})


## Set on the ground at its axles, pitched to the grade, its side kept level.
func _on_ground() -> void:
	var at := coach.global_position
	var f := at + heading * -AXLES.x
	var h := at - heading * AXLES.y
	var yf := float(ground.call(f.x, f.z))
	var yh := float(ground.call(h.x, h.z))
	f.y = yf
	h.y = yh
	var x := (h - f).normalized()
	var z := x.cross(Vector3.UP).normalized()
	at.y = yh + (yf - yh) * AXLES.y / (AXLES.y - AXLES.x)
	coach.global_transform = Transform3D(Basis(x, z.cross(x), z), at)


## A striker's box, swept along its speed LOOK_TICKS ahead, meets the coach's.
func _strike_coming(delta: float) -> bool:
	var box := coach_box()
	for s in strikers:
		if not is_instance_valid(s) or s.freeze:
			continue
		var v := s.linear_velocity - (heading * speed if driving else Vector3.ZERO)
		if v.length() < 0.3:
			continue
		var sb := _box_of(s)
		var ahead := sb
		ahead.position += v * delta * LOOK_TICKS
		if box.intersects(sb.merge(ahead)):
			return true
	return false


## The coach's box in the world (its kit file's bounds, turned and placed).
func coach_box() -> AABB:
	return coach.global_transform * PropKit.bounds(coach.definition)


static func _box_of(rb: RigidBody3D) -> AABB:
	var out := AABB()
	var first := true
	for c in rb.get_children():
		var cs := c as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var b := cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


## To physics: the whole coach one body (or as many as aren't touching) at the drive's velocity,
## its plates watched, its riders kept from shoving it till each goes limp.
func hand_off(why: String) -> void:
	if loose:
		return
	loose = true
	var made: Array[RigidBody3D] = []
	if not coach.loose:
		made = coach.go_loose(heading * speed)
	_loose_carried()
	_take_bodies(made)
	events.append({"t": time, "what": "handed_off", "why": why, "bodies": bodies.size()})


## What it carries (the strongbox under the rear bench) goes loose with it, inside it, at its
## speed: left standing it'd be a fixed thing in the coach's way till its floor check found the
## floor gone.
func _loose_carried() -> void:
	for c in coach.get_children():
		var p := c as KitProp
		if p and not p.loose:
			p.go_loose(heading * speed if driving else Vector3.ZERO)


func _on_went_loose() -> void:
	if loose:
		return
	loose = true
	_loose_carried.call_deferred()
	events.append({"t": time, "what": "handed_off", "why": "went loose"})
	_take_bodies.call_deferred([] as Array[RigidBody3D])


func _take_bodies(made: Array[RigidBody3D]) -> void:
	bodies = made.duplicate()
	if bodies.is_empty():
		for rb in coach.rubble:
			if is_instance_valid(rb):
				bodies.append(rb)
	var watch := DentWatch.of(get_tree())
	for rb in bodies:
		watch.watch(rb, coach)
	for s in strikers:
		if is_instance_valid(s):
			watch.striker(s)
	for r: Dictionary in riders:
		var man := r.man as HumanBody
		if is_instance_valid(man) and not man.limp:
			for rb in bodies:
				_ride(man, rb, true)
			_limp_queue.append(man)
	handed_off.emit(bodies)


## A rider's posed parts don't shove the coach while he sits in it (TrainWreck._ride), nor his
## upright blocker (the capsule that keeps the player out of him, a fixed body standing through the
## bench and the roof: at the hand-off it threw the coach ~2,000 N.s a contact, #794).
static func _ride(man: HumanBody, rb: RigidBody3D, on: bool) -> void:
	var with: Array[PhysicsBody3D] = []
	for seg in man.parts:
		with.append(man.parts[seg] as PhysicsBody3D)
	with.append(man.get_node_or_null(^"Blocker") as PhysicsBody3D)
	for part in with:
		if part == null or not is_instance_valid(part):
			continue
		if on:
			rb.add_collision_exception_with(part)
		else:
			rb.remove_collision_exception_with(part)


## Each trace still on pulls its hook toward its horse; past its strength it breaks.
func _pull_traces() -> void:
	for id: StringName in _traces:
		var tr: Dictionary = _traces[id]
		if not tr.on:
			continue
		var hook := _hook_node(id)
		if hook == null:
			tr.on = false
			continue
		var rb := hook.get_parent() as RigidBody3D
		var to: Vector3 = (tr.anchor as Vector3) - hook.global_position
		var stretch := to.length() - trace_length
		if stretch <= 0.0:
			continue
		var f := trace_stiffness * stretch
		if f > trace_breaks:
			tr.on = false
			events.append({"t": time, "what": "trace_broke", "hook": String(id), "newtons": f})
			trace_broke.emit(id, f)
			continue
		rb.apply_force(to.normalized() * f, hook.global_position - rb.global_position)


func _hook_node(id: StringName) -> Node3D:
	for rb in bodies:
		if not is_instance_valid(rb):
			continue
		for c in rb.get_children():
			if c is CollisionShape3D and c.get_meta(&"member", &"") == id:
				return c
	return null


func traces_on() -> int:
	var n := 0
	for id: StringName in _traces:
		if _traces[id].on:
			n += 1
	return n


## The heaviest of its bodies (the coach's box and gear), or null.
func main_body() -> RigidBody3D:
	var best: RigidBody3D = null
	for rb in bodies:
		if is_instance_valid(rb) and (best == null or rb.mass > best.mass):
			best = rb
	return best


## How far over it leans (degrees from upright).
func lean() -> float:
	var rb := main_body()
	var up := rb.global_basis.y if rb else coach.global_basis.y
	return rad_to_deg(up.normalized().angle_to(Vector3.UP))

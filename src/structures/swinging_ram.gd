class_name SwingingRam
extends Node3D
## A battering ram over a road (the coach heist, Sean's call on #791): a log (RollingLog, green
## pine) hung on two ropes from a timber gallows frame that straddles the road, held back up the
## bank by a trip rope tied off at a stake with a toggle pin. Shoot the pin (or break it any way) and
## the log swings down and strikes sideways at the bottom of its swing, `bottom_y` up: on a coach's
## upper plates it both tips it and dents them, which the rolling log could only do one of.
##
## Its space: the origin on the ground under the log's middle at the bottom of its swing, the road
## along x, the log pulled back toward -z (up the bank) and swinging toward +z. The ropes are fixed
## length (a rope pulls, never pushes: each tick the log's two sling points are held within
## `rope_length` + its radius of their anchors under the frame's caps by an impulse along the rope;
## Erin Catto's sequential impulses, "Iterative Dynamics with Temporal Coherence", GDC 2005), not the
## rope system the roadmap puts after the demo. The frame is a kit prop of members, so a ball, a
## blast or the log breaks it as any timber; a rope whose cap breaks, or whose frame goes loose,
## lets go.

signal released

## The log (RollingLog's): Sean's B, 0.6 x 6 m green ponderosa pine, ~1.25 t.
@export var log_radius := 0.3
@export var log_length := 6.0
## Its middle's height at the bottom of its swing (m): a coach's upper plates (1.7-2.4 m).
@export var bottom_y := 2.0
## The ropes from the caps' undersides to the top of the log (m).
@export var rope_length := 5.0
## How far its middle is held up above the bottom of its swing (m): ~8 m/s at the bottom, sqrt(2 g h).
@export var pull_up := 3.3
## The frame's legs from the swing's line: back (up the bank, -z) and fore (+z), m.
@export var leg_back := 1.9
@export var leg_fore := 3.9
## The legs' feet above the origin's ground (m; a leg on a bank stands higher): back, fore.
@export var foot_back := 0.0
@export var foot_fore := 0.0
## The bents stand this far beyond the log's ends (m).
@export var bent_gap := 0.35
## Where the trip rope is tied off (the stake's foot, in the ram's space; the default: back up
## the bank 2.5 m behind the held log, on the ground under it: give its height).
@export var trip_at := Vector3.INF
## How hard a stretched rope is pulled back in a tick (Baumgarte's share of the stretch).
@export var rope_bias := 0.3
## Rope sweeps a tick (sequential impulses over the two ropes).
const ROPE_PASSES := 4
## Timber for the frame: 12 x 12 in legs and caps, 8 x 8 braces.
const LEG := 0.3
const BRACE := 0.2

var log_body: RollingLog
var frame: KitProp
var trip: KitProp
## The rope anchors (frame space) and the sling points on the log's axis (log space).
var anchors: Array[Vector3] = []
var slings: Array[Vector3] = []
var _cut: Array[bool] = [false, false]
var _rope_len: Array[float] = [0.0, 0.0]
## The most either rope has pulled (N) since let go, and the tick it did.
var most_tension := 0.0
var tension: Array[float] = [0.0, 0.0]
var _ropes: Array[MeshInstance3D] = []
var _trip_rope: MeshInstance3D
var _made := 0
static var _count := 0


func _init() -> void:
	name = "SwingingRam"


## The frame, the log held back and the trip, built where it stands (call once it's in the tree).
func build() -> void:
	_count += 1
	_made = _count
	var bx := log_length * 0.5 + bent_gap
	var top := bottom_y + log_radius + rope_length
	anchors = [Vector3(-bx + 0.0, top, 0.0), Vector3(bx, top, 0.0)]
	slings = [Vector3(-(log_length * 0.5 - 0.3), 0.0, 0.0), Vector3(log_length * 0.5 - 0.3, 0.0, 0.0)]
	# Each rope as long as from its anchor to its sling with the log hanging at the bottom (they
	# slant in from the bents: the log swings about the anchors' line, `pivot_length` from it).
	_rope_len = [anchors[0].distance_to(Vector3(slings[0].x, bottom_y, 0.0)),
			anchors[1].distance_to(Vector3(slings[1].x, bottom_y, 0.0))]
	frame = PropKit.spawn(_frame_def(bx, top), StringName("ram_frame_%d" % _made))
	add_child(frame)
	log_body = RollingLog.new()
	log_body.radius = log_radius
	log_body.length = log_length
	add_child(log_body)
	# Discrete contacts: Jolt's continuous (cast) collision resolves the blow outside the contacts it
	# reports, so the dent watch saw none (#794); at ~8 m/s a tick is 13 cm into a 1.4 m coach.
	log_body.continuous_cd = false
	log_body.global_transform = global_transform * Transform3D(Basis.IDENTITY, held_at())
	if trip_at == Vector3.INF:
		var h := held_at()
		trip_at = Vector3(0.0, 0.0, h.z - 2.5)
	trip = PropKit.spawn(_trip_def(), StringName("ram_trip_%d" % _made))
	add_child(trip)
	trip.position = trip_at
	log_body.hold_by(trip, ["pin"])
	log_body.released.connect(_on_released)
	for i in 2:
		_ropes.append(_rope_mesh())
	_trip_rope = _rope_mesh()


## Where the log's middle is held (ram space): up its arc by `pull_up`, toward -z.
func held_at() -> Vector3:
	var l := pivot_length()
	var up := clampf(pull_up, 0.0, l * 0.95)
	var ang := acos((l - up) / l)
	return Vector3(0.0, bottom_y + up, -l * sin(ang))


## From the anchors' line to the log's axis (m).
func pivot_length() -> float:
	return rope_length + log_radius


## Its speed at the bottom of its swing without losses: sqrt(2 g h).
func lossless_speed() -> float:
	return sqrt(2.0 * 9.81 * pull_up)


func is_held() -> bool:
	return log_body != null and log_body.held


## Let go, as a ball through the pin would.
func release() -> void:
	if trip:
		var m: StructureMember = trip.members.get(StringName("%s/pin" % trip.structure_id))
		if m and not m.broken:
			trip.break_member(m, Vector3(0.0, 0.5, 1.0))
	if log_body.held:
		log_body.release()


## The pin (to aim at).
func pin_position() -> Vector3:
	var m: StructureMember = trip.members.get(StringName("%s/pin" % trip.structure_id)) if trip else null
	return m.global_position if m else Vector3.INF


func _on_released() -> void:
	most_tension = 0.0
	if _trip_rope:
		_trip_rope.visible = false
	released.emit()


# --- The ropes --------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if log_body == null or not is_instance_valid(log_body) or log_body.freeze:
		return
	_check_cuts()
	var st := PhysicsServer3D.body_get_direct_state(log_body.get_rid())
	if st == null or st.sleeping:
		return
	var m_inv := 1.0 / maxf(log_body.mass, 1.0)
	var i_inv := st.inverse_inertia_tensor
	var com := st.transform.origin + st.center_of_mass
	var v := st.linear_velocity
	var w := st.angular_velocity
	var acc: Array[float] = [0.0, 0.0]
	for _pass in ROPE_PASSES:
		for i in 2:
			if _cut[i]:
				continue
			var a := global_transform * anchors[i]
			var p := st.transform * slings[i]
			var d := p - a
			var len := d.length()
			var stretch := len - _rope_len[i]
			if stretch <= 0.0 or len < 1e-4:
				continue
			var n := d / len
			var r := p - com
			var vp := v + w.cross(r)
			var want := -rope_bias * stretch / delta
			var vn := vp.dot(n)
			if vn <= want:
				continue
			var rn := r.cross(n)
			var k := m_inv + n.dot((i_inv * rn).cross(r))
			var lam := (vn - want) / k  # (the impulse's size along -n: a pull)
			var j := -n * lam
			v += j * m_inv
			w += i_inv * r.cross(j)
			acc[i] += lam
	st.linear_velocity = v
	st.angular_velocity = w
	for i in 2:
		tension[i] = acc[i] / delta
		most_tension = maxf(most_tension, tension[i])


## A rope lets go when the cap it hangs from breaks, or the frame goes loose.
func _check_cuts() -> void:
	if frame == null or not is_instance_valid(frame):
		_cut = [true, true]
		return
	for i in 2:
		if _cut[i]:
			continue
		var m: StructureMember = frame.members.get(StringName("%s/cap_%d" % [frame.structure_id, i]))
		if frame.loose or m == null or m.broken:
			_cut[i] = true


func ropes_on() -> int:
	return _cut.count(false)


func _process(_delta: float) -> void:
	if log_body == null or not is_instance_valid(log_body):
		return
	for i in 2:
		var mi := _ropes[i]
		mi.visible = not _cut[i]
		if mi.visible:
			var a := global_transform * anchors[i]
			var p := log_body.global_transform * slings[i]
			# Drawn to the top of the log, where the sling goes round it.
			_lay(mi, a, p + (a - p).normalized() * log_radius)
	if _trip_rope and _trip_rope.visible and trip:
		_lay(_trip_rope, log_body.global_position, pin_position())


func _rope_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.02
	cm.height = 1.0
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.53, 0.38)
	mat.roughness = 1.0
	mi.material_override = mat
	mi.top_level = true
	add_child(mi)
	return mi


static func _lay(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	if l < 1e-3:
		mi.visible = false
		return
	var y := d / l
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mi.global_transform = Transform3D(Basis(x, y * l, z), (a + b) * 0.5)


# --- The frame and the trip -------------------------------------------------------------------------

## Two bents straddling the road beyond the log's ends (legs, a cap across, knee braces), tied
## along the road at the caps' ends; the ropes hang from the caps' undersides over the swing's line.
func _frame_def(bx: float, top: float) -> StringName:
	var id := StringName("ram_frame_%d" % _made)
	var ms: Array = []
	var cap_len := leg_back + leg_fore + LEG
	var cap_z := (leg_fore - leg_back) * 0.5
	for i in 2:
		var x := (-1.0 if i == 0 else 1.0) * bx
		var hb := top - foot_back
		var hf := top - foot_fore
		ms.append({"id": "leg_b_%d" % i, "kind": "post", "size": [LEG, hb, LEG], "at": [x, foot_back + hb * 0.5, -leg_back]})
		ms.append({"id": "leg_f_%d" % i, "kind": "post", "size": [LEG, hf, LEG], "at": [x, foot_fore + hf * 0.5, leg_fore]})
		ms.append({"id": "cap_%d" % i, "kind": "beam", "size": [LEG, LEG, cap_len], "at": [x, top + LEG * 0.5, cap_z]})
		# Knee braces from each leg up to the cap, 45 degrees, 1.2 m along.
		var k := 1.2 * sqrt(0.5)
		ms.append({"id": "knee_b_%d" % i, "kind": "trim", "size": [BRACE, 1.2, BRACE],
				"at": [x, top - k * 0.5, -leg_back + LEG * 0.5 + k * 0.5], "rot": [45.0, 0.0, 0.0]})
		ms.append({"id": "knee_f_%d" % i, "kind": "trim", "size": [BRACE, 1.2, BRACE],
				"at": [x, top - k * 0.5, leg_fore - LEG * 0.5 - k * 0.5], "rot": [-45.0, 0.0, 0.0]})
	for z in [-leg_back, leg_fore]:
		ms.append({"id": "tie_%s" % ("b" if z < 0.0 else "f"), "kind": "beam", "size": [2.0 * bx + LEG, BRACE, BRACE],
				"at": [0.0, top + LEG + BRACE * 0.5, z]})
	PropKit._defs[id] = {"id": String(id), "kind": "members", "wood": "framing", "look": "wood:framing",
		"_doc": "SwingingRam's gallows frame: two bents over the road, the ropes from their caps", "members": ms}
	return id


## The stake the trip rope is tied off at, and its oak toggle pin through the chain (a ball splits it).
func _trip_def() -> StringName:
	var id := &"ram_trip"
	if not PropKit._defs.has(id):
		PropKit._defs[id] = {"id": "ram_trip", "kind": "members", "wood": "oak", "look": "wood:dark_oak",
			"splits_below": 0.97, "_doc": "SwingingRam's trip: a stake and the chain's toggle pin", "members": [
				{"id": "stake", "kind": "post", "size": [0.12, 0.8, 0.12], "at": [0.0, 0.4, 0.0]},
				{"id": "pin", "kind": "trim", "size": [0.035, 0.035, 0.25], "at": [0.0, 0.7, 0.08]},
			]}
	return id


## What it is now, for a lab or the bridge.
func state() -> Dictionary:
	var p := to_local(log_body.global_position) if log_body else Vector3.ZERO
	return {"held": is_held(), "at": [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)],
		"speed": snappedf(log_body.linear_velocity.length(), 0.01) if log_body else 0.0,
		"ropes": ropes_on(), "most_tension_n": roundf(most_tension), "lossless": snappedf(lossless_speed(), 0.01)}

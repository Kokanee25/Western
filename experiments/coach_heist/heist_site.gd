extends Node3D
## The coach heist lab's site (issues #770, #794): the road along x, the bank above it on the -z side
## (1:1.5, `drop` m high, from the road's edge or from a `step` m crib at its foot), a far bank on +z,
## and the coach (`baron_coach`) on the road, driven by a CoachDrive, four guards seated in it and
## the driver and messenger on its box. What strikes it (`striker`):
##   ram   (the default since #791, Sean's call) a SwingingRam: log B on two ropes from a gallows frame
##         over the road, held back up the bank by its trip pin, striking sideways at the bottom of
##         its swing (`bottom_y`, 2.0 m: the upper plates)
##   roll  (#784's 1B 2C) the log on a deck on the bank's lip held by two wedges and a chained stake's
##         toggle pin, rolling down the bank and off the step (`step` 2.5, `ledge` 0.6)
## Built by `build(opts)`; the runner and the bridge read its numbers.

const ROAD_HALF := 2.5  ## the road 5 m wide, its edges at z +-2.5
const SLOPE := 1.5  ## horizontal per vertical, both banks
const DECK := 4.0  ## the deck's depth back from the lip (m)
const FAR_BANK := 8.0

var opts := {}
var striker := "ram"
var ram: SwingingRam
var step := 2.5
var drop := 5.5
## The step's flat top (m, a crib's top course) between the bank's foot and the step's face.
var ledge := 0.0
var coach: KitProp
var drive: CoachDrive
var log_body: RollingLog
var deck: KitProp
var guards: Array[HumanBody] = []
var watch: DentWatch
var lip_z := 0.0  ## where the bank's top meets the deck (z)
var foot_z := 0.0  ## where the bank meets the step's top, or the road (z)
var _mat_cache := {}

## What it found: the log's speed at the lip of the step (and its drop), at the hit; the coach's
## lean; head blows to the guards.
var log_at_foot := {}
var log_at_face := {}
var log_at_hit := {}
var max_lean := 0.0
## The ram's log at the bottom of its swing (first crossing its line), and the riders on the box
## and the strongbox at the end.
var ram_at_bottom := {}
var head_blows: Array[Dictionary] = []
var released_at := -1.0
var coach_kg := 0.0
var t := 0.0


func build(o: Dictionary) -> void:
	opts = o
	striker = String(o.get("striker", "ram"))
	step = float(o.get("step", 0.0 if striker == "ram" else 2.5))
	drop = float(o.get("drop", 6.0 if striker == "ram" else 5.5))
	ledge = float(o.get("ledge", 0.0)) if step > 0.0 else 0.0
	foot_z = -ROAD_HALF - ledge
	lip_z = foot_z - drop * SLOPE
	watch = DentWatch.new()
	watch.name = "DentWatch"
	add_child(watch)
	_ground()
	if bool(o.get("with_log", true)):
		if striker == "ram":
			_ram()
		else:
			_deck_and_log()
	if bool(o.get("with_coach", true)):
		_coach(Vector3(float(o.get("coach_x", 0.0)), 0.0, float(o.get("coach_z", 0.0))))


func _physics_process(delta: float) -> void:
	t += delta
	# The ambush: the log let go as the coach comes to the mark (its middle `release_at_x` short of
	# the log's line: where it'll be when the log, ~2.7 s down the bank, gets there).
	if opts.has("release_at_x") and released_at < 0.0 and coach and log_body and log_body.held \
			and coach.position.x <= float(opts.release_at_x):
		release_log()
	if ram and released_at >= 0.0 and ram_at_bottom.is_empty() and log_body \
			and ram.to_local(log_body.global_position).z >= 0.0:
		ram_at_bottom = {"t": t - released_at, "speed": log_body.linear_velocity.length(),
				"y": ram.to_local(log_body.global_position).y, "tension_n": ram.most_tension}
	if striker != "ram" and log_body and not log_body.freeze:
		var p := to_local(log_body.global_position)
		if log_at_face.is_empty() and step > 0.0 and p.z >= -ROAD_HALF:
			log_at_face = {"t": t, "speed": log_body.linear_velocity.length(), "vz": log_body.linear_velocity.z, "vy": log_body.linear_velocity.y, "y": p.y}
		if log_at_foot.is_empty() and p.z >= foot_z:
			log_at_foot = {"t": t, "speed": log_body.linear_velocity.length(), "vz": log_body.linear_velocity.z,
					"y": p.y, "drop": (step + drop + log_body.radius) - p.y}
	if drive and drive.loose:
		max_lean = maxf(max_lean, drive.lean())


# --- The ground ------------------------------------------------------------------------------------

func _ground() -> void:
	var road := _box(Vector3(80.0, 1.0, 60.0), Vector3(0.0, -0.5, 0.0), Color(0.55, 0.47, 0.36))
	road.name = "Road"
	var h := step + drop
	var w := 16.0
	# The step: a crib of rock and timber from the road up to the bank's foot, its face at the road's edge.
	if step > 0.0:
		var back := drop * SLOPE + DECK + 2.0 + ledge
		_box(Vector3(w, step, back), Vector3(0.0, step * 0.5, -ROAD_HALF - back * 0.5), Color(0.5, 0.42, 0.33))
	# The bank above it, 1:1.5, and the deck behind its lip.
	_prism([Vector2(foot_z, step), Vector2(lip_z, h), Vector2(lip_z, step)], w, Color(0.6, 0.5, 0.38))
	_box(Vector3(w, h - step, DECK + 2.0), Vector3(0.0, step + (h - step) * 0.5, lip_z - (DECK + 2.0) * 0.5), Color(0.6, 0.5, 0.38))
	# The far bank, its foot at the road's other edge.
	_prism([Vector2(ROAD_HALF, 0.0), Vector2(ROAD_HALF + FAR_BANK * SLOPE, FAR_BANK), Vector2(ROAD_HALF + FAR_BANK * SLOPE, 0.0)], w, Color(0.6, 0.5, 0.38))


func _box(size: Vector3, at: Vector3, c: Color) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = Layers.WORLD | Layers.WALK
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	sb.add_child(mi)
	add_child(sb)
	sb.position = at
	return sb


## A prism along x (`w` long) of the (z, y) outline.
func _prism(zy: Array, w: float, c: Color) -> StaticBody3D:
	var pts := PackedVector3Array()
	for x in [-w * 0.5, w * 0.5]:
		for p: Vector2 in zy:
			pts.append(Vector3(x, p.y, p.x))
	var sb := StaticBody3D.new()
	sb.collision_layer = Layers.WORLD | Layers.WALK
	var cs := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	cs.shape = shape
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = shape.get_debug_mesh()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := pts[0]
	var b := pts[1]
	var d := pts[2]
	var a2 := pts[3]
	var b2 := pts[4]
	var d2 := pts[5]
	for tri in [[a, b, d], [a2, d2, b2], [a, a2, b2], [a, b2, b], [b, b2, d2], [b, d2, d], [d, d2, a2], [d, a2, a]]:
		for p: Vector3 in tri:
			st.add_vertex(p)
	st.generate_normals()
	mi.mesh = st.commit()
	mi.material_override = _mat(c)
	(mi.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	sb.add_child(mi)
	add_child(sb)
	return sb


func _mat(c: Color) -> StandardMaterial3D:
	if not _mat_cache.has(c):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 1.0
		_mat_cache[c] = m
	return _mat_cache[c]


# --- The log on its deck ---------------------------------------------------------------------------

func _deck_and_log() -> void:
	var r := float(opts.get("log_r", 0.3))
	var length := float(opts.get("log_len", 6.0))
	var h := step + drop
	# The holds: two oak wedges under its downhill side and a stake with the chain's oak toggle pin.
	var wz := lip_z - 0.12
	var id := &"heist_log_deck"
	if not PropKit._defs.has(id):
		PropKit._defs[id] = {"id": "heist_log_deck", "kind": "members", "wood": "oak", "look": "wood:dark_oak",
			"splits_below": 0.97, "members": [
				{"id": "wedge_l", "kind": "post", "size": [0.25, 0.12, 0.14], "at": [-length * 0.3, 0.06, 0.0]},
				{"id": "wedge_r", "kind": "post", "size": [0.25, 0.12, 0.14], "at": [length * 0.3, 0.06, 0.0]},
				{"id": "stake", "kind": "post", "size": [0.1, 0.7, 0.1], "at": [0.0, 0.35, -2.0 * r - 0.3]},
				{"id": "chain_pin", "kind": "trim", "size": [0.25, 0.035, 0.035], "at": [0.0, 0.62, -2.0 * r - 0.3]},
			]}
	deck = PropKit.spawn(id, &"heist_deck")
	add_child(deck)
	deck.position = Vector3(0.0, h, wz)
	log_body = RollingLog.new()
	log_body.radius = r
	log_body.length = length
	add_child(log_body)
	# On the lip: its middle a hair over the bank, the wedges under its downhill side.
	log_body.position = Vector3(0.0, h + r, lip_z + 0.02)
	log_body.hold_by(deck, ["wedge_l", "wedge_r", "chain_pin"])
	log_body.released.connect(_on_released)


func _on_released(nudge := true) -> void:
	released_at = t
	# Over the lip it goes: the last hold out, it tips off the deck's edge.
	if nudge:
		log_body.linear_velocity = global_basis * Vector3(0.0, 0.0, 0.4)


## Every hold broken out, as balls into them would (the bridge's `ch_release`).
func release_log() -> void:
	if ram:
		ram.release()
		return
	if deck == null:
		log_body.release()
		return
	for id in ["wedge_l", "wedge_r", "chain_pin"]:
		var m: StructureMember = deck.members.get(StringName("%s/%s" % [deck.structure_id, id]))
		if m and not m.broken:
			deck.break_member(m, Vector3(0.0, 0.5, 1.0))
	if log_body.held:
		log_body.release()


# --- The ram ---------------------------------------------------------------------------------------

## The z the ram's swing bottoms out at: its log's face a hair off the coach's near plates (their
## outer face 0.708 m from its middle) where the coach drives (`coach_z`).
func ram_line_z() -> float:
	return float(opts.get("coach_z", 0.0)) - 0.708 - float(opts.get("log_r", 0.3)) - float(opts.get("ram_gap", 0.02))


## The ground's height at `z` across the road (the banks' slopes; flat road between).
func ground_y(z: float) -> float:
	if z < foot_z:
		return step + minf((foot_z - z) / SLOPE, drop)
	if z > ROAD_HALF:
		return minf((z - ROAD_HALF) / SLOPE, FAR_BANK)
	return step if z < -ROAD_HALF else 0.0


func _ram() -> void:
	ram = SwingingRam.new()
	ram.log_radius = float(opts.get("log_r", 0.3))
	ram.log_length = float(opts.get("log_len", 6.0))
	ram.bottom_y = float(opts.get("bottom_y", 2.0))
	ram.rope_length = float(opts.get("rope", 5.0))
	ram.pull_up = float(opts.get("pull_up", 3.3))
	var z0 := ram_line_z()
	ram.position = Vector3(float(opts.get("ram_x", 0.0)), 0.0, z0)
	ram.leg_back = z0 - (-ROAD_HALF - 0.4)
	ram.leg_fore = (ROAD_HALF + 0.4) - z0
	ram.foot_back = ground_y(-ROAD_HALF - 0.4)
	ram.foot_fore = ground_y(ROAD_HALF + 0.4)
	add_child(ram)
	var held := ram.held_at()
	var tz := held.z - 2.5
	ram.trip_at = Vector3(0.0, ground_y(z0 + tz), tz)
	ram.build()
	log_body = ram.log_body
	log_body.released.connect(_on_released.bind(false))


# --- The coach -------------------------------------------------------------------------------------

func coach_id() -> StringName:
	return &"baron_coach"


func _coach(at: Vector3) -> void:
	coach = PropKit.spawn(coach_id(), &"heist_coach")
	add_child(coach)
	coach.position = at
	coach_kg = coach.mass()
	drive = CoachDrive.new()
	drive.name = "CoachDrive"
	drive.speed = float(opts.get("speed", 1.4))
	add_child(drive)
	drive.start(coach)
	drive.driving = bool(opts.get("drive", true))
	if log_body:
		drive.strikers.append(log_body)
	drive.handed_off.connect(func(_b: Array) -> void:
		var mb: RigidBody3D = drive.main_body()
		if mb:
			_body_from_coach = mb.global_transform.affine_inverse() * coach.global_transform
		if log_body:
			log_at_hit = {"t": t, "after_release": t - released_at, "speed": log_body.linear_velocity.length(), "vz": log_body.linear_velocity.z, "vy": log_body.linear_velocity.y,
					"y": to_local(log_body.global_position).y, "x": to_local(log_body.global_position).x - coach.position.x})
	if int(opts.get("guards", 4)) > 0:
		_guards(int(opts.get("guards", 4)))


func _guards(n: int) -> void:
	var seats: Array = coach.definition.get("seats_at", [])
	var k := 0
	var box := bool(opts.get("box", true))
	for s: Dictionary in seats:
		var who := String(s.get("who", ""))
		if (who == "" and k >= n) or (who != "" and not box):
			continue
		var man := HumanBody.new()
		man.name = who.to_pascal_case() if who != "" else "Guard%d" % k
		man.body_model = &"outlaw"
		man.has_gun = false
		man.start_holstered = true
		man.rng_seed = 7700 + guards.size() + int(opts.get("seed", 0)) * 10
		man.person_id = StringName(who if who != "" else "guard_%d" % k)
		add_child(man)
		var at := PropKit.vec(s.at)
		# On the box his feet are on the footboard's line, a seat's drop below it; inside, the floor.
		drive.seat(man, at, at.y - 0.405 if who != "" else 1.105, float(s.get("yaw", NAN)))
		man.hit.connect(func(info: Dictionary) -> void:
			if info.get("kind") == &"blow" and info.get("segment") == &"head":
				head_blows.append({"who": String(man.person_id), "joules": float(info.get("joules", 0.0)),
						"stun_s": OutlawBrain.head_stun_seconds(info)}))
		guards.append(man)
		if who == "":
			k += 1


## Whether `p` (world) is inside the coach's body (its box, upper works, under the roof), as it lies now.
func in_coach(p: Vector3) -> bool:
	var rb: RigidBody3D = drive.main_body() if drive else null
	var xf := coach.global_transform
	if rb:
		# The loose body carries the coach's space as it was at the hand-off.
		xf = rb.global_transform * _body_from_coach
	var local := xf.affine_inverse() * p
	return absf(local.x) < 1.31 and absf(local.z) < 0.72 and local.y > 1.0 and local.y < 2.45


var _body_from_coach := Transform3D.IDENTITY


## Where to let the log go so it meets the coach's middle: the drive's lead (m ahead of the log's
## line the coach is when it's released) for a roll taking `roll_s`.
func lead_for(roll_s: float) -> float:
	return drive.speed * roll_s if drive else 0.0


## What it found, as one row.
func result() -> Dictionary:
	var out := {"step": step, "drop": drop, "released_at": released_at,
		"ledge": ledge, "log_kg": log_body.mass if log_body else 0.0, "log_at_foot": log_at_foot, "log_at_face": log_at_face, "log_at_hit": log_at_hit,
		"lossless_at_foot": RollingLog.rolling_speed(drop),
		"max_lean": max_lean, "over": max_lean > 60.0,
		"traces_on": drive.traces_on() if drive else 0, "events": drive.events if drive else [],
		"dents": watch.made, "head_blows": head_blows, "guards": []}
	for man in guards:
		if is_instance_valid(man):
			var pelvis: Node3D = man.parts.get(&"pelvis", man) if man.parts else man
			(out.guards as Array).append({"who": String(man.person_id), "limp": man.limp,
					"conscious": man.physiology.is_conscious(), "in_coach": in_coach(pelvis.global_position),
					"y": snappedf(pelvis.global_position.y, 0.01)})
	var sb: KitProp = coach.carried("strongbox") if coach else null
	if sb and is_instance_valid(sb):
		var at := sb.global_position
		for rb in sb.rubble:
			if is_instance_valid(rb):
				at = rb.global_transform * rb.center_of_mass
		out["strongbox"] = {"loose": sb.loose, "in_coach": in_coach(at), "y": snappedf(at.y, 0.01)}
	if ram:
		out["ram"] = ram.state()
		out["ram_at_bottom"] = ram_at_bottom
	if coach:
		out["coach"] = String(coach.kit_id)
		out["coach_kg"] = coach_kg
	return out

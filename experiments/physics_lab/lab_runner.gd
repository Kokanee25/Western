extends Node3D
## The ragdoll lab's runner (docs/prompts/01_Testing_Lab.md): builds one fixture and the real
## Salt Creek man (HumanBody, the MakeHuman outlaw body), does what the scenario says before he
## goes limp, calls the production HumanBody.go_limp() untouched, and logs every physics tick.
## Measurement only: nothing here changes how he falls, except the lab's own named impulses,
## which are logged as such. Started by lab.gd (a -s script can't name game classes).

const LAB_DIR := "res://experiments/physics_lab/"
## Thresholds for the automated flags. Provisional: set from the first baseline run and printed
## with each summary so a reader can see what tripped (README.md, "Thresholds").
const T := {
	"settle_speed": 0.05, "settle_spin": 0.3, "settle_ticks": 30,
	"penetration": 0.03, "self_overlap": 0.04, "joint_gap": 0.03,
	"jump_m": 0.25, "jump_deg": 45.0, "launch_speed": 8.0, "launch_up": 1.5,
	"bounce_up": 0.4, "swing_over": 10.0, "twist_over": 10.0, "hyperextend": 10.0,
	"jitter_speed": 0.08,
}

var scenario: Dictionary
var out_dir := ""
var render := false
var views: Array = ["front", "side", "three"]
var view_size := Vector2i(480, 360)
var every := 2
var cam_distance := 3.2
## --follow: the cameras keep him in shot across the ground (for footage of a running man), at
## the same offset, eased; without it they stay where he started (for comparing frames).
var follow := false
## --mocap: he walks and runs by the motion-capture clips (HumanBody.mocap_gait, an experiment).
var mocap := false
## --old-flinch: a "hit" kicks him as the flinch did before 2026-10-18 (for comparing).
var old_flinch := false
var _follow_cams: Array = []  ## [Camera3D, offset, up, where it looks]
var model := &"outlaw"
## Several men side by side (the performance runs): each one is logged in the summary only.
var count := 1
## The performance runs: no per-tick measuring (its queries would be counted as his cost).
var light := false
var done := false
var summary := {}

var _world: Node3D
var _men: Array[HumanBody] = []
var _tick := 0
var _limp_tick := -1
var _hit_tick := -1  ## a "knock" scenario: when the ball hit (he may stumble on before he's limp)
var _last_us := 0
var _frame_us: Array[int] = []
var _ticks_csv: FileAccess
var _segs_csv: FileAccess
var _events: Array[Dictionary] = []
var _prev := {}  ## segment -> [pos, basis] last tick (man 0)
var _ref := {}  ## segment -> reference taken as he goes limp
var _rest_overlap := {}  ## "a|b" -> overlap at limp
var _flags := {}
var _cams: Array = []
var _viewports: Array = []
var _start_xf := Transform3D.IDENTITY
var _speed_before := Vector3.ZERO
var _com_v_now := Vector3.ZERO
var _peak := {"penetration": 0.0, "self_overlap": 0.0, "joint_gap": 0.0, "speed": 0.0, "up": 0.0}
var _asleep_by_second: Array[int] = []
var _settle_run := 0
var _settled_tick := -1
var _sleep_flips := 0
var _last_sleep := {}
var _com_min_y := INF
## Kneeling as he falls (2026-10-21): ticks with both shins down on the floor and his seat up off it.
var _kneel_ticks := 0
var _ref_facing := Vector3.FORWARD  ## the way he faced as he went limp
## His mesh (2026-10-21, the Studio's men): every body shares the anatomy's capsules, so what can
## differ between men is the skinned mesh. How deep any vertex of his body, and of his worn hat, goes
## under the floor (ground fixtures), sampled ten times a second once he's down and at the end.
var _mesh_peak := {"body": 0.0, "hat": 0.0, "body_part": "", "hat_t": -1.0}
var _mesh_cache := {}  ## MeshInstance3D -> [verts, bones, weights, per-vertex count, is hat]
## Ground fixtures only (the floor at y 0): the stairs and the slope have no one floor height.
const KNEEL_SHIN := 0.14  ## a shin's centre under this: it lies along the floor
const KNEEL_SEAT := 0.28  ## the pelvis's centre over this: he's up on his knees, not lying
var _shapes := {}  ## segment -> Array of [CollisionShape3D, a, b, r] (rest-centred capsule ends)
var _pairs: Array = []  ## non-adjacent segment pairs


func _ready() -> void:
	process_physics_priority = -100
	HumanBody.mocap_gait = mocap
	DirAccess.make_dir_recursive_absolute(out_dir)
	_world = Node3D.new()
	_world.name = "LabWorld"
	add_child(_world)
	_build_fixture(String(scenario.get("fixture", "ground")))
	_light()
	var yaw := deg_to_rad(float(scenario.get("yaw", 0.0)))
	_start_xf = Transform3D(Basis(Vector3.UP, yaw), _start_point())
	count = maxi(count, int(scenario.get("men", 1)))
	for i in count:
		var man := HumanBody.new()
		man.name = "Man%d" % i
		# "gun": armed (drawn at the start; pre "pose": "aim" to aim it).
		man.has_gun = bool(scenario.get("gun", false))
		man.start_holstered = not man.has_gun
		man.body_model = model
		man.rng_seed = int(scenario.get("seed", 1))
		man.person_id = StringName("lab_%d" % i)
		_world.add_child(man)
		# "men": several men in a row ("spacing" m apart, his right), every one going down the
		# same way; man 0 is the one logged tick by tick, the rest in the summary.
		var gap := float(scenario.get("spacing", 1.2))
		man.global_transform = Transform3D(_start_xf.basis, _start_xf.origin + _start_xf.basis.x * gap * i)
		_men.append(man)
	if not light:
		_ticks_csv = FileAccess.open(out_dir.path_join("ticks.csv"), FileAccess.WRITE)
		_ticks_csv.store_line("tick,t,phase,com_x,com_y,com_z,com_vx,com_vy,com_vz,max_speed,max_penetration,max_self_overlap,max_joint_gap,awake,contacts,contact_impulse_sum,frame_ms")
		_segs_csv = FileAccess.open(out_dir.path_join("segments.csv"), FileAccess.WRITE)
		_segs_csv.store_line("tick,t,segment,px,py,pz,qx,qy,qz,qw,vx,vy,vz,wx,wy,wz,vel_source,sleeping,contacts,contact_impulse,penetration,self_overlap,swing,twist,swing_limit,twist_limit,bend,joint_gap,step_m,step_deg")
	if render:
		_build_cameras()
	_last_us = Time.get_ticks_usec()


func _start_point() -> Vector3:
	match String(scenario.get("fixture", "ground")):
		"slope":
			return Vector3(0, _slope_y(0.0), 0)
		"stairs":
			return Vector3(0, STAIR_TOP, 0)
	return Vector3.ZERO


# --- Fixtures ------------------------------------------------------------------------------------

const SLOPE_DEG := 20.0
const STAIR_TOP := 0.72  ## four risers of 18 cm, treads 28 cm, going down ahead of him (-z)


func _slope_y(z: float) -> float:
	# Falls away ahead of him (-z): downhill.
	return z * tan(deg_to_rad(SLOPE_DEG))


func _box(at: Vector3, size: Vector3, colour := Color(0.55, 0.53, 0.5), rot := Basis(), body: CollisionObject3D = null) -> CollisionObject3D:
	var b: CollisionObject3D = body if body else StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mi.material_override = mat
	b.add_child(mi)
	if body:
		# Part of a body that already stands somewhere: the box goes in its own space.
		cs.transform = Transform3D(rot, at)
		mi.transform = Transform3D(rot, at)
		return b
	_world.add_child(b)
	b.global_transform = Transform3D(rot, at)
	return b


func _build_fixture(kind: String) -> void:
	if kind != "slope":
		_box(Vector3(0, -0.5, 0), Vector3(40, 1, 40), Color(0.45, 0.42, 0.38))
	match kind:
		"wall":
			_box(Vector3(0, 1.4, 0.55), Vector3(4, 2.8, 0.15))
		"doorway":
			# A door 0.9 m wide in a wall just behind him: he's pushed back and to his right.
			_box(Vector3(-1.45, 1.3, 0.5), Vector3(2.0, 2.6, 0.15))
			_box(Vector3(1.45, 1.3, 0.5), Vector3(2.0, 2.6, 0.15))
			_box(Vector3(0, 2.4, 0.5), Vector3(0.9, 0.4, 0.15))
		"slope":
			var l := 12.0
			var rot := Basis(Vector3.RIGHT, -deg_to_rad(SLOPE_DEG))
			# The top face passes through the origin at z = 0, going down toward -z.
			var n := rot * Vector3.UP
			_box(-n * 0.5, Vector3(8, 1, l), Color(0.45, 0.42, 0.38), rot)
		"stairs":
			_box(Vector3(0, STAIR_TOP * 0.5, 1.5), Vector3(3, STAIR_TOP, 3.0))  # the landing he stands on
			for i in 4:
				var top := STAIR_TOP - 0.18 * (i + 1)
				if top <= 0.0:
					break
				_box(Vector3(0, top * 0.5, -0.14 - 0.28 * i), Vector3(3, top, 0.28))
		"table":
			_table(Vector3(0, 0, -0.75))
		"table_side":
			# Beside him on his left: he falls sideways, his arm across it, his feet on the floor.
			_table(Vector3(-0.85, 0, 0))
		"chair":
			_chair(Vector3(0, 0, 0.5))
		"seat", "seat_table":
			# A fixed seat under him (production's chairs and benches are static props) and, for
			# seat_table, a table before him: he sits (pre "pose": "sit") and goes down off it.
			_box(Vector3(0, 0.22, 0.05), Vector3(0.45, 0.44, 0.45), Color(0.4, 0.27, 0.17))
			if kind == "seat_table":
				_table(Vector3(0, 0, -0.75))


func _table(at: Vector3) -> void:
	_box(at + Vector3(0, 0.74, 0), Vector3(1.2, 0.05, 0.8), Color(0.42, 0.28, 0.18))
	for sx in [-0.55, 0.55]:
		for sz in [-0.35, 0.35]:
			_box(at + Vector3(sx, 0.36, sz), Vector3(0.06, 0.72, 0.06), Color(0.35, 0.24, 0.15))


func _chair(at: Vector3) -> void:
	# A loose chair (6 kg) on the world layer, as a movable thing in the room would be. Production's
	# chairs are static props (PropLibrary boxes, StaticBatch): this is the lab's own.
	var rb := RigidBody3D.new()
	rb.name = "Chair"
	rb.mass = 6.0
	rb.collision_layer = Layers.WORLD
	rb.collision_mask = Layers.WORLD | Layers.BODY_PARTS
	_world.add_child(rb)
	rb.global_position = at
	_box(Vector3(0, 0.45, 0), Vector3(0.45, 0.04, 0.45), Color(0.4, 0.27, 0.17), Basis(), rb)
	_box(Vector3(0, 0.7, 0.21), Vector3(0.45, 0.5, 0.04), Color(0.4, 0.27, 0.17), Basis(), rb)
	for sx in [-0.2, 0.2]:
		for sz in [-0.2, 0.2]:
			_box(Vector3(sx, 0.22, sz), Vector3(0.04, 0.44, 0.04), Color(0.35, 0.24, 0.15), Basis(), rb)


func _light() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	_world.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.64, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	_world.add_child(env)


# --- Cameras -------------------------------------------------------------------------------------

func _focus() -> Vector3:
	var pre: Dictionary = scenario.get("pre", {})
	var travel := 0.0
	if pre.get("do", "") in ["walk", "run"]:
		travel = float(pre.get("speed", 0.0)) * float(pre.get("seconds", 0.0))
	var push: Array = scenario.get("push", [0, 0, 0])
	var lean := Vector3(push[0], 0, push[2]).normalized() * 0.6 if Vector3(push[0], 0, push[2]).length() > 0.01 else Vector3.ZERO
	# "focus_y": the height the cameras look at (a man on his feet: ~0.9).
	return _start_xf.origin + _start_xf.basis * (Vector3(0, 0, -travel) + lean) + Vector3.UP * float(scenario.get("focus_y", 0.5))


func _build_cameras() -> void:
	var f := _focus()
	var b := _start_xf.basis
	var dd := cam_distance
	var at := {"front": -b.z * dd, "side": b.x * dd, "three": (-b.z + b.x).normalized() * dd, "top": Vector3.UP * dd * 1.2 + b.z * 0.01}
	for v: String in views:
		var sv := SubViewport.new()
		sv.size = view_size
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(sv)
		var cam := Camera3D.new()
		cam.fov = 50.0
		sv.add_child(cam)
		var off: Vector3 = at.get(v, at.front)
		cam.look_at_from_position(f + off + Vector3.UP * (0.3 if v != "top" else 0.0), f, Vector3.UP if v != "top" else -b.z)
		cam.current = true
		_follow_cams.append([cam, off + Vector3.UP * (0.3 if v != "top" else 0.0), Vector3.UP if v != "top" else -b.z, f])
		_viewports.append([v, sv])
		DirAccess.make_dir_recursive_absolute(out_dir.path_join("frames").path_join(v))


func _save_frames() -> void:
	if follow and not _men.is_empty():
		var com := _com(_men[0])
		for c: Array in _follow_cams:
			var f: Vector3 = c[3]
			f = f.lerp(Vector3(com.x, f.y, com.z), 0.25)
			c[3] = f
			(c[0] as Camera3D).look_at_from_position(f + (c[1] as Vector3), f, c[2])
	await RenderingServer.frame_post_draw
	for pair: Array in _viewports:
		var img: Image = (pair[1] as SubViewport).get_texture().get_image()
		img.save_png(out_dir.path_join("frames").path_join(pair[0]).path_join("%04d.png" % _tick))


# --- The run -------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if done:
		return
	var now := Time.get_ticks_usec()
	var frame_ms := (now - _last_us) / 1000.0
	_last_us = now
	_frame_us.append(now)
	var pre: Dictionary = scenario.get("pre", {})
	var pre_ticks := int(round(float(pre.get("seconds", 0.5)) * 60.0))
	if not light:
		_record(frame_ms)
	if _tick < pre_ticks:
		_before(pre, delta)
	elif _limp_tick < 0:
		# "knock": a ball that drops him, as HumanBody.take_bullet has it (HumanBody._knocked): on
		# the move he may stumble on first. The lab's "limp" is when he actually goes limp.
		var knock: Dictionary = scenario.get("knock", {})
		if not knock.is_empty() and _hit_tick < 0:
			_hit_tick = _tick
			for man in _men:
				var part := man.parts[StringName(knock.segment)] as Node3D
				var p: Array = knock.get("point", [0, 0, 0])
				var d: Array = knock.get("dir", [0, 0, 1])
				var at := part.global_transform * Vector3(p[0], p[1], p[2])
				var dw := (_start_xf.basis * Vector3(d[0], d[1], d[2])).normalized()
				var given := float(knock.get("momentum", 4.5))
				if man.has_method(&"_knocked"):
					man._knocked(StringName(knock.segment), at, dw, given)
				else:
					# An older HumanBody (comparing): what its take_bullet did, down where he stood.
					man.go_limp()
					var rb := man.parts[StringName(knock.segment)] as RigidBody3D
					rb.apply_impulse(dw * given, at - rb.global_position)
					if man.has_method(&"_hunch"):
						man._hunch(StringName(knock.segment), at, dw)
		# "cause": what puts him down, through the game's own entry point: a blast (take_blast, a
		# charge of "kg" at "from" in his frame from his feet), a limb torn off (sever_limb) or a
		# blow (take_blow: "joules", "momentum", on "segment" along "dir"). He goes down only if
		# it puts him down; the lab's "limp" is when he does.
		var cause: Dictionary = scenario.get("cause", {})
		if not cause.is_empty() and _hit_tick < 0:
			_hit_tick = _tick
			for man in _men:
				match String(cause.kind):
					"blast":
						var f: Array = cause.get("from", [0, 0, -1])
						var at := man.global_transform * Vector3(f[0], f[1], f[2])
						var info: Dictionary = man.take_blast(at, float(cause.get("kg", 0.15)))
						if man == _men[0]:
							_events.append({"tick": _tick, "kind": "blast", "source": "HumanBody.take_blast", "at": _v(at),
									"kg": cause.get("kg", 0.15), "harm": info.get("harm", []), "down": info.get("knocked_down", false)})
					"sever":
						man.sever_limb(StringName(cause.segment))
					"blow":
						var part := man.parts[StringName(cause.segment)] as Node3D
						var d: Array = cause.get("dir", [0, 0, 1])
						man.take_blow(part, float(cause.joules), part.global_position, (_start_xf.basis * Vector3(d[0], d[1], d[2])).normalized(),
								float(cause.get("momentum", -1.0)))
		var waiting := not knock.is_empty() or not cause.is_empty()
		if not waiting or _men[0].limp:
			_go_limp()
	if _limp_tick >= 0:
		_after(delta)
	if _limp_tick >= 0 and (_tick - _limp_tick) % 60 == 0:
		var n := 0
		for man in _men:
			for c in man.get_children():
				if c is RigidBody3D and (c as RigidBody3D).sleeping:
					n += 1
		_asleep_by_second.append(n)
	if render and _tick % every == 0:
		_save_frames()
	_tick += 1
	var total := pre_ticks + int(round(float(scenario.get("seconds", 6.0)) * 60.0))
	if _tick > total:
		_finish()


## Once he's down: "drag" (hauled by the collar, HumanBody.drag_toward, by a man walking off at
## "speed" along "dir" in his frame from "start" for "seconds", as the gang's rescues do) and
## "later" (more of the lab's impulses at "t" seconds after he went down: balls into a man going
## down or lying there).
func _after(delta: float) -> void:
	var t := (_tick - _limp_tick) / 60.0
	var drag: Dictionary = scenario.get("drag", {})
	if not drag.is_empty() and t >= float(drag.get("start", 1.5)) and t < float(drag.get("start", 1.5)) + float(drag.get("seconds", 3.0)):
		var d: Array = drag.get("dir", [0, 0, 1])
		var dw := (_start_xf.basis * Vector3(d[0], d[1], d[2])).normalized()
		for man in _men:
			if not drag.has("_holder"):
				var chest := man.parts[&"chest"] as Node3D
				drag["_holder"] = chest.global_position + dw * 0.5
			drag["_holder"] = (drag["_holder"] as Vector3) + dw * float(drag.get("speed", 1.2)) * delta
			man.drag_toward(Vector3((drag["_holder"] as Vector3).x, 0.0, (drag["_holder"] as Vector3).z), delta)
	for imp: Dictionary in scenario.get("later", []):
		if _tick - _limp_tick == int(round(float(imp.t) * 60.0)):
			for man in _men:
				var rb := man.parts.get(StringName(imp.segment)) as RigidBody3D
				if rb == null:
					continue
				var p: Array = imp.get("point", [0, 0, 0])
				var j: Array = imp.get("impulse", [0, 0, 0])
				var jw := _start_xf.basis * Vector3(j[0], j[1], j[2])
				rb.apply_impulse(jw, rb.global_transform * Vector3(p[0], p[1], p[2]) - rb.global_position)
			_events.append({"tick": _tick, "kind": "lab_impulse_later", "source": "the lab (scenarios.json)",
					"segment": imp.segment, "impulse_Ns": imp.get("impulse", [])})


func _before(pre: Dictionary, delta: float) -> void:
	# "hit": a ball that doesn't drop him, at "at" seconds into the run: as the game has it, nothing
	# from the ball itself (no flinch, no wince: Sean, 2026-10-18), or with --old-flinch the kick he
	# got before (_flinch_from).
	var hit: Dictionary = pre.get("hit", {})
	if not hit.is_empty() and _tick == int(round(float(hit.get("at", 1.0)) * 60.0)):
		_hit_tick = _tick
		for man in _men:
			var part := man.parts[StringName(hit.segment)] as Node3D
			var p: Array = hit.get("point", [0, 0, 0])
			var d: Array = hit.get("dir", [0, 0, 1])
			var at := part.global_transform * Vector3(p[0], p[1], p[2])
			var dw := (_start_xf.basis * Vector3(d[0], d[1], d[2])).normalized()
			if hit.get("ball", false):
				# A real .45 ball through take_bullet (wound, pain, torn muscle: what it does to
				# him, HumanBody._favour_step); "stays_up" takes the knockdown roll away.
				if hit.get("stays_up", true):
					man.physiology.tuning = man.physiology.tuning.duplicate()
					man.physiology.tuning.knockdown_max = 0.0
				var t_rev: RevolverTuning = load("res://config/revolver.tres")
				man.take_bullet(part, at - dw * 0.15, dw, 0.5 * t_rev.bullet_mass * t_rev.muzzle_velocity * t_rev.muzzle_velocity,
						t_rev.bullet_diameter * 0.5, t_rev.bullet_mass, 5.0)
				continue
			# "pain": what the wound hurts (Physiology.pain), as a real one would.
			man.physiology.pain = float(hit.get("pain", 0.0))
			if old_flinch:
				man._flinch_from(StringName(hit.segment), at, dw, float(hit.get("momentum", 4.5)))
	for man in _men:
		match String(pre.get("do", "stand")):
			"walk", "run":
				var speed := float(pre.get("speed", 1.4))
				man.walk_to(man.global_position - _start_xf.basis.z * 5.0, speed, delta)
			"crouch":
				man.set_pose(&"crouch")
			"pose":
				man.set_pose(StringName(pre.get("pose", "stand")))
			_:
				pass


func _go_limp() -> void:
	_limp_tick = _tick
	var push_local: Array = scenario.get("push", [0, 0, 0])
	var push := _start_xf.basis * Vector3(push_local[0], push_local[1], push_local[2])
	var man0 := _men[0]
	# What he was carrying the tick before (the parts are AnimatableBodies moved by the script:
	# the engine gives them no velocity, so it's from his position).
	# _record has already run this tick: its centre-of-mass velocity is last tick's walk.
	_speed_before = _com_v_now
	# "dead": killed outright as he goes (a ball through the brain): his tone goes in an instant
	# (HumanBody.TONE_FADE_DEAD), where a "blackout" goes limp alive and keeps it a little longer.
	if scenario.get("dead", false):
		for man in _men:
			man.physiology._die(&"brain")
	for man in _men:
		man.go_limp(push)
	# Read what go_limp left in the bodies before the solver has run: the push it gives every part,
	# and the chest's extra (push * 4 plus a random level kick, HumanBody._rng).
	var total_after := Vector3.ZERO
	var mass := 0.0
	var chest_v := Vector3.ZERO
	var chest_m := 0.0
	for sid: StringName in man0.parts:
		var rb := man0.parts[sid] as RigidBody3D
		var v: Vector3 = PhysicsServer3D.body_get_state(rb.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)
		total_after += v * rb.mass
		mass += rb.mass
		if sid == &"chest":
			chest_v = v
			chest_m = rb.mass
		rb.contact_monitor = true
		rb.max_contacts_reported = 8
	var chest_extra := (chest_v - push) * chest_m
	var random_part := chest_extra - push * 4.0
	_events.append({"tick": _tick, "kind": "go_limp", "source": "production HumanBody.go_limp()",
			"push_arg": _v(push), "push_given_every_part_mps": _v(push),
			"chest_extra_impulse_Ns": _v(chest_extra), "chest_push_x4_Ns": _v(push * 4.0),
			"chest_random_impulse_Ns": _v(random_part),
			"momentum_before_Ns": _v(_speed_before * mass), "speed_before_mps": _v(_speed_before),
			"momentum_after_Ns": _v(total_after), "mass_kg": mass,
			"note": "speed_before is the man's own movement (walk_to moves him by script); go_limp sets every part's velocity to push, so that momentum is replaced, not kept"})
	for imp: Dictionary in scenario.get("impulses", []):
		var sid := StringName(imp.segment)
		var rb := man0.parts.get(sid) as RigidBody3D
		if rb == null:
			push_error("lab: no segment %s" % sid)
			continue
		var p: Array = imp.get("point", [0, 0, 0])
		var j: Array = imp.get("impulse", [0, 0, 0])
		var at_world := rb.global_transform * Vector3(p[0], p[1], p[2])
		var jw := _start_xf.basis * Vector3(j[0], j[1], j[2])
		for man in _men:
			var r := man.parts.get(sid) as RigidBody3D
			r.apply_impulse(jw, r.global_transform * Vector3(p[0], p[1], p[2]) - r.global_position)
		_events.append({"tick": _tick, "kind": "lab_impulse", "source": "the lab (scenarios.json)",
				"segment": String(sid), "at_world": _v(at_world), "impulse_Ns": _v(jw)})
		# "hunch": as a ball that knocks him down does (HumanBody.take_bullet): he curls round it.
		if imp.get("hunch", false):
			for man in _men:
				if man.has_method(&"_hunch"):
					man._hunch(sid, man.parts[sid].global_transform * Vector3(p[0], p[1], p[2]), jw.normalized())
	_take_reference(man0)


func _take_reference(man: HumanBody) -> void:
	_ref_facing = -man.global_basis.z
	var anat := man.anatomy
	for sid: StringName in man.parts:
		var rb := man.parts[sid] as Node3D
		var parent: StringName = anat.segments[sid].parent
		var r := {"xf": rb.global_transform}
		if parent != &"":
			var pb := man.parts[parent] as Node3D
			r.rel = (pb.global_basis.orthonormalized().inverse() * rb.global_basis.orthonormalized()).get_rotation_quaternion()
			# The joint: where the child's top capsule end meets the parent (anatomy's rest pivot).
			var joint_world := _joint_point(man, sid)
			# The production joint's own anchor where it has one (go_limp puts Joint_<segment> at
			# the standing pivot): any other point drifts apart as the joint turns.
			var jn := man.get_node_or_null("Joint_%s" % sid) as Node3D
			if jn:
				joint_world = jn.global_position
				r.anchor = "production joint"
			else:
				r.anchor = "anatomy capsule end (no joint node)"
			r.joint_in_parent = pb.global_transform.affine_inverse() * joint_world
			r.joint_in_child = rb.global_transform.affine_inverse() * joint_world
			r.axis_child = (rb.global_basis.orthonormalized().inverse() * (rb.global_position - joint_world)).normalized()
		_ref[sid] = r
	_shapes.clear()
	for sid: StringName in man.parts:
		var arr: Array = []
		for c in (man.parts[sid] as Node).get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape is CapsuleShape3D:
				var cs := c as CollisionShape3D
				var cap := cs.shape as CapsuleShape3D
				var half := cap.height * 0.5 - cap.radius
				arr.append([cs, cs.transform * Vector3(0, -half, 0), cs.transform * Vector3(0, half, 0), cap.radius])
		_shapes[sid] = arr
	_pairs.clear()
	var ids: Array = man.parts.keys()
	for i in ids.size():
		for k in range(i + 1, ids.size()):
			var a: StringName = ids[i]
			var b: StringName = ids[k]
			if anat.segments[a].parent == b or anat.segments[b].parent == a:
				continue
			if anat.segments[a].parent != &"" and anat.segments[a].parent == anat.segments[b].parent:
				continue  # siblings at one joint (both thighs on the pelvis) touch at rest
			_pairs.append([a, b])
	for pr: Array in _pairs:
		_rest_overlap["%s|%s" % pr] = _overlap(man, pr[0], pr[1])


func _joint_point(man: HumanBody, sid: StringName) -> Vector3:
	# HumanBody kept the pivot positions only while standing; the anatomy's rest pivot of a segment
	# is the end of its first capsule nearest its parent's centre.
	var s: Dictionary = man.anatomy.segments[sid]
	var c: Array = s.capsules[0]
	var parent_c := man.anatomy.segment_center(s.parent)
	var a: Vector3 = c[0]
	var b: Vector3 = c[1]
	var rest := a if a.distance_to(parent_c) < b.distance_to(parent_c) else b
	var rb := man.parts[sid] as Node3D
	return rb.global_transform * (rest - man.anatomy.segment_center(sid))


# --- Measuring -----------------------------------------------------------------------------------

func _com(man: HumanBody) -> Vector3:
	var s := Vector3.ZERO
	var m := 0.0
	for sid: StringName in man.parts:
		var n := man.parts[sid] as Node3D
		var mm := float(n.get_meta(&"mass", 5.0))
		s += n.global_position * mm
		m += mm
	return s / maxf(m, 1e-6)


func _record(frame_ms: float) -> void:
	var man := _men[0]
	var t := _tick / 60.0
	var limp := _limp_tick >= 0
	var phase := "limp" if limp else "before"
	var com := _com(man)
	var com_v: Vector3 = (com - _prev.get(&"__com", com)) * 60.0
	_prev[&"__com"] = com
	_com_v_now = com_v
	var max_speed := 0.0
	var max_pen := 0.0
	var max_self := 0.0
	var max_gap := 0.0
	var awake := 0
	var contacts := 0
	var cimp := 0.0
	var space := get_world_3d().direct_space_state
	for sid: StringName in man.parts:
		var n := man.parts[sid] as Node3D
		var pos := n.global_position
		var q := n.global_basis.orthonormalized().get_rotation_quaternion()
		var prev: Array = _prev.get(sid, [pos, q])
		var step_m := pos.distance_to(prev[0])
		var step_deg := rad_to_deg((prev[1] as Quaternion).angle_to(q))
		_prev[sid] = [pos, q]
		var v := (pos - (prev[0] as Vector3)) * 60.0
		var w := Vector3.ZERO
		var src := "finite_diff"
		var sleeping := false
		var nc := 0
		var ci := 0.0
		if n is RigidBody3D:
			var rb := n as RigidBody3D
			v = rb.linear_velocity
			w = rb.angular_velocity
			src = "engine"
			sleeping = rb.sleeping
			if not sleeping:
				awake += 1
			if _last_sleep.has(sid) and _last_sleep[sid] != sleeping:
				_sleep_flips += 1
			_last_sleep[sid] = sleeping
			var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
			if st:
				nc = st.get_contact_count()
				for i in nc:
					ci += st.get_contact_impulse(i).length()
		contacts += nc
		cimp += ci
		max_speed = maxf(max_speed, v.length())
		var pen := _penetration(space, man, sid) if limp else 0.0
		max_pen = maxf(max_pen, pen)
		var self_o := 0.0
		var swing := 0.0
		var twist := 0.0
		var bend := 0.0
		var gap := 0.0
		var lim: Array = [0, 0]
		if limp:
			for pr: Array in _pairs:
				if (pr[0] == sid or pr[1] == sid) and not _torn_off(man, pr[0]) and not _torn_off(man, pr[1]):
					var o := _overlap(man, pr[0], pr[1]) - float(_rest_overlap["%s|%s" % pr])
					self_o = maxf(self_o, o)
			var r: Dictionary = _ref[sid]
			# A limb torn off has no joint to measure against (sever_limb frees it).
			var torn := _torn_off(man, sid)
			if r.has("rel") and not torn:
				var parent: StringName = man.anatomy.segments[sid].parent
				var pb := man.parts[parent] as Node3D
				var rel := (pb.global_basis.orthonormalized().inverse() * n.global_basis.orthonormalized()).get_rotation_quaternion()
				var d: Quaternion = (r.rel as Quaternion).inverse() * rel
				var axis: Vector3 = r.axis_child
				var turned := d * axis
				swing = rad_to_deg(axis.angle_to(turned))
				# Swing-twist split of d about the limb's axis: the twist is the part of d about it.
				var along := axis * Vector3(d.x, d.y, d.z).dot(axis)
				var tw := Quaternion(along.x, along.y, along.z, d.w).normalized()
				twist = rad_to_deg(2.0 * atan2(Vector3(tw.x, tw.y, tw.z).dot(axis), tw.w))
				if twist > 180.0:
					twist -= 360.0
				var key := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
				lim = HumanBody.JOINT_LIMITS.get(key, [30, 10])
				var cf: Dictionary = man.get(&"cone_frames") if man.get(&"cone_frames") != null else {}
				if cf.has(sid):
					# A cone centred on the joint's anatomical middle (HumanBody.CONE_CENTRE): the
					# swing from there, against its span.
					var jw: Vector3 = pb.global_transform * (r.joint_in_parent as Vector3)
					var dir_p: Vector3 = pb.global_basis.orthonormalized().inverse() * (n.global_position - jw)
					swing = rad_to_deg(dir_p.angle_to(cf[sid].centre))
					lim = [cf[sid].span, lim[1]]
					# Twist as the joint reads it: from the cone's middle, about the limb.
					var rel_c := (pb.global_basis.orthonormalized().inverse() * n.global_basis.orthonormalized()).get_rotation_quaternion()
					var dc: Quaternion = (cf[sid].turn as Quaternion).inverse() * rel_c
					var ax: Vector3 = cf[sid].axis
					var al := ax * Vector3(dc.x, dc.y, dc.z).dot(ax)
					var twq := Quaternion(al.x, al.y, al.z, dc.w).normalized()
					twist = rad_to_deg(2.0 * atan2(Vector3(twq.x, twq.y, twq.z).dot(ax), twq.w))
					if twist > 180.0:
						twist -= 360.0
				var jp: Vector3 = pb.global_transform * (r.joint_in_parent as Vector3)
				var jc: Vector3 = n.global_transform * (r.joint_in_child as Vector3)
				gap = jp.distance_to(jc)
				if key == &"shin" or key == &"forearm":
					var right := pb.global_basis.x.normalized()
					var a := -pb.global_basis.y.normalized()
					var b := -n.global_basis.y.normalized()
					bend = rad_to_deg(a.signed_angle_to(b, right))
		max_self = maxf(max_self, self_o)
		max_gap = maxf(max_gap, gap)
		if limp:
			_check(sid, t, v, w, pen, self_o, swing, twist, lim, bend, gap, step_m, step_deg)
		if _segs_csv:
			_segs_csv.store_line(",".join(PackedStringArray([_tick, "%.4f" % t, sid,
					"%.4f" % pos.x, "%.4f" % pos.y, "%.4f" % pos.z, "%.5f" % q.x, "%.5f" % q.y, "%.5f" % q.z, "%.5f" % q.w,
					"%.4f" % v.x, "%.4f" % v.y, "%.4f" % v.z, "%.4f" % w.x, "%.4f" % w.y, "%.4f" % w.z, src,
					int(sleeping), nc, "%.4f" % ci, "%.4f" % pen, "%.4f" % self_o, "%.2f" % swing, "%.2f" % twist,
					lim[0], lim[1], "%.2f" % bend, "%.4f" % gap, "%.4f" % step_m, "%.2f" % step_deg])))
	if limp:
		_peak.penetration = maxf(_peak.penetration, max_pen)
		_peak.self_overlap = maxf(_peak.self_overlap, max_self)
		_peak.joint_gap = maxf(_peak.joint_gap, max_gap)
		if _tick > _limp_tick + 1:
			_peak.speed = maxf(_peak.speed, max_speed)
		_peak.up = maxf(_peak.up, com_v.y)
		_com_min_y = minf(_com_min_y, com.y)
		if _flat_floor() and _kneeling(man):
			_kneel_ticks += 1
		if _flat_floor() and (_tick - _limp_tick) % 6 == 0:
			var md := _mesh_depth(man)
			if md.body > _mesh_peak.body:
				_mesh_peak.body = md.body
				_mesh_peak.body_part = md.body_part
			if md.hat > _mesh_peak.hat:
				_mesh_peak.hat = md.hat
				_mesh_peak.hat_t = t - _limp_tick / 60.0
		# Settling: every part slow and hardly turning for half a second.
		var still := true
		for sid: StringName in man.parts:
			var rb := man.parts[sid] as RigidBody3D
			if rb and (rb.linear_velocity.length() > T.settle_speed or rb.angular_velocity.length() > T.settle_spin):
				still = false
				break
		_settle_run = _settle_run + 1 if still else 0
		if _settle_run >= T.settle_ticks and _settled_tick < 0:
			_settled_tick = _tick - T.settle_ticks + 1
		if _settled_tick < 0 and com_v.y > T.bounce_up and com.y > _com_min_y + 0.02 and _tick > _limp_tick + 10:
			_flag("bounce", t, "centre of mass rose at %.2f m/s after coming down" % com_v.y)
		if com_v.y > T.launch_up and _tick > _limp_tick + 1:
			_flag("launch", t, "centre of mass going up at %.2f m/s" % com_v.y)
		if _settled_tick >= 0 and _tick > _settled_tick + T.settle_ticks:
			if max_speed > T.jitter_speed:
				_flag("jitter_after_settle", t, "a part moving %.2f m/s after he'd settled" % max_speed)
	if _ticks_csv:
		_ticks_csv.store_line(",".join(PackedStringArray([_tick, "%.4f" % t, phase, "%.4f" % com.x, "%.4f" % com.y, "%.4f" % com.z,
				"%.4f" % com_v.x, "%.4f" % com_v.y, "%.4f" % com_v.z, "%.4f" % max_speed, "%.4f" % max_pen,
				"%.4f" % max_self, "%.4f" % max_gap, awake, contacts, "%.4f" % cimp, "%.3f" % frame_ms])))


func _check(sid: StringName, t: float, v: Vector3, _w: Vector3, pen: float, self_o: float, swing: float, twist: float,
		lim: Array, bend: float, gap: float, step_m: float, step_deg: float) -> void:
	var s := String(sid)
	if pen > T.penetration:
		_flag("ground_penetration", t, "%s %.3f m into the world" % [s, pen], sid)
	if self_o > T.self_overlap:
		_flag("self_overlap", t, "%s %.3f m into another part of him (beyond its rest overlap)" % [s, self_o], sid)
	if gap > T.joint_gap:
		_flag("joint_separation", t, "%s %.3f m off its joint" % [s, gap], sid)
	if _tick > _limp_tick + 1 and (step_m > T.jump_m or step_deg > T.jump_deg):
		_flag("discontinuity", t, "%s moved %.2f m / %.0f deg in one tick" % [s, step_m, step_deg], sid)
	if _tick > _limp_tick + 1 and v.length() > T.launch_speed:
		_flag("launch", t, "%s at %.1f m/s" % [s, v.length()], sid)
	var key := s.trim_suffix("_r").trim_suffix("_l")
	if key == "shin" or key == "forearm":
		# _knee_bend's sign (tests/test_bodies.gd): a knee bends negative, an elbow positive.
		var wrong := bend if key == "shin" else -bend
		if wrong > T.hyperextend:
			_flag("limb_inversion", t, "%s bent %.0f deg the wrong way" % [s, wrong], sid)
	elif lim[0] > 0:
		if swing > float(lim[0]) + T.swing_over:
			_flag("swing_past_limit", t, "%s swung %.0f deg (limit %d)" % [s, swing, lim[0]], sid)
		if absf(twist) > float(lim[1]) + T.twist_over:
			_flag("twist_past_limit", t, "%s twisted %.0f deg (limit %d)" % [s, twist, lim[1]], sid)


func _flag(kind: String, t: float, what: String, sid := &"") -> void:
	var f: Dictionary = _flags.get(kind, {"count": 0, "first_t": t, "first": what, "worst": what, "segments": {}})
	f.count += 1
	if sid != &"":
		f.segments[String(sid)] = true
	_flags[kind] = f


func _penetration(space: PhysicsDirectSpaceState3D, man: HumanBody, sid: StringName) -> float:
	var deepest := 0.0
	var n := man.parts[sid] as Node3D
	for e: Array in _shapes.get(sid, []):
		var cs := e[0] as CollisionShape3D
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cs.shape
		q.transform = n.global_transform * cs.transform
		q.collision_mask = Layers.WORLD
		q.margin = 0.0
		var pts := space.collide_shape(q, 16)
		for i in range(0, pts.size() - 1, 2):
			deepest = maxf(deepest, (pts[i] as Vector3).distance_to(pts[i + 1]))
	return deepest


func _overlap(man: HumanBody, a: StringName, b: StringName) -> float:
	# How far two parts' capsules overlap (r1 + r2 - the distance between their axes), from the
	# shapes alone: the parts don't collide with each other (mask WORLD), so the engine reports nothing.
	var na := man.parts[a] as Node3D
	var nb := man.parts[b] as Node3D
	var best := -INF
	for ea: Array in _shapes.get(a, []):
		for eb: Array in _shapes.get(b, []):
			var d := _seg_dist(na.global_transform * (ea[1] as Vector3), na.global_transform * (ea[2] as Vector3),
					nb.global_transform * (eb[1] as Vector3), nb.global_transform * (eb[2] as Vector3))
			best = maxf(best, float(ea[3]) + float(eb[3]) - d)
	return maxf(best, 0.0)


static func _seg_dist(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var pts := Geometry3D.get_closest_points_between_segments(p1, q1, p2, q2)
	return pts[0].distance_to(pts[1])


static func _v(v: Vector3) -> Array:
	return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]


## The skinned mesh's deepest vertex under the floor (y 0), body and hat apart (m; 0 above it).
func _mesh_depth(man: HumanBody) -> Dictionary:
	var out := {"body": 0.0, "hat": 0.0, "body_part": ""}
	var sk := man.skeleton
	if sk == null:
		return out
	var by_skin := {}  ## Skin -> Array[Transform3D] per bind (its bone's pose times its bind pose)
	for key: String in man.skin_meshes:
		var mi := man.skin_meshes[key] as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null:
			continue
		if not _mesh_cache.has(mi):
			var a := mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var bones = a[Mesh.ARRAY_BONES]
			var weights = a[Mesh.ARRAY_WEIGHTS]
			var per := 0 if bones == null or verts.is_empty() else int(bones.size() / verts.size())
			_mesh_cache[mi] = [verts, bones, weights, per, key.get_slice("/", 0) in HumanBody.HAT_SHAPES]
		var c: Array = _mesh_cache[mi]
		if mi.skin != null and not by_skin.has(mi.skin):
			var arr: Array[Transform3D] = []
			for k in mi.skin.get_bind_count():
				var bone := mi.skin.get_bind_bone(k)
				if bone < 0:
					bone = sk.find_bone(String(mi.skin.get_bind_name(k)))
				arr.append(sk.global_transform * sk.get_bone_global_pose(maxi(bone, 0)) * mi.skin.get_bind_pose(k))
			by_skin[mi.skin] = arr
		var poses: Array = by_skin.get(mi.skin, [])
		var verts: PackedVector3Array = c[0]
		var per: int = c[3]
		var hat: bool = c[4]
		var step := 1 if verts.size() < 4000 else 3
		for v in range(0, verts.size(), step):
			var p := Vector3.ZERO
			if per == 0:
				p = mi.global_transform * verts[v]
			else:
				for k in per:
					var w: float = c[2][v * per + k]
					if w > 0.0:
						var bi: int = c[1][v * per + k]
						if bi < poses.size():
							p += (poses[bi] * verts[v]) * w
			if -p.y > (out.hat if hat else out.body):
				if hat:
					out.hat = -p.y
				else:
					out.body = -p.y
					out.body_part = key
	return out


func _torn_off(man: HumanBody, sid: StringName) -> bool:
	var s := sid
	while s != &"":
		if man.physiology.severed_segments.has(s):
			return true
		s = man.anatomy.segments[s].parent
	return false


func _flat_floor() -> bool:
	return not String(scenario.get("fixture", "ground")) in ["stairs", "slope"]


func _kneeling(man: HumanBody) -> bool:
	for sid in [&"shin_l", &"shin_r"]:
		var n := man.parts.get(sid) as Node3D
		if n == null or n.global_position.y > KNEEL_SHIN:
			return false
	return (man.parts[&"pelvis"] as Node3D).global_position.y > KNEEL_SEAT


## How he lies at the end: on his back, face down or on his side (the chest's front, -z, against
## up); his seat's height; up on his knees; each knee's bend; and how deep each hand lies in his
## thighs or trunk (the capsules' raw overlap, nothing subtracted).
func _rest(man: HumanBody) -> Dictionary:
	var chest := man.parts[&"chest"] as Node3D
	# His front as he went limp (the way he faced), carried in the chest's own frame.
	var ref_b: Basis = (_ref[&"chest"].xf as Transform3D).basis.orthonormalized()
	var front_local := ref_b.inverse() * (_ref_facing)
	var front := (chest.global_basis.orthonormalized() * front_local).normalized()
	var up := front.dot(Vector3.UP)
	var lying := "back" if up > 0.5 else ("face_down" if up < -0.5 else "side")
	var hands := {}
	for h in [&"hand_l", &"hand_r"]:
		var deepest := 0.0
		for other in [&"thigh_l", &"thigh_r", &"pelvis", &"abdomen", &"chest"]:
			if man.parts.has(h) and man.parts.has(other):
				deepest = maxf(deepest, _overlap(man, h, other))
		hands[String(h)] = snappedf(deepest, 0.001)
	var knees := {}
	for sid in [&"shin_l", &"shin_r"]:
		var n := man.parts.get(sid) as Node3D
		var th := man.parts.get(StringName("thigh" + String(sid).right(2))) as Node3D
		if n and th:
			knees[String(sid)] = snappedf(rad_to_deg((-th.global_basis.y).angle_to(-n.global_basis.y)), 0.1)
	var md := _mesh_depth(man) if _flat_floor() else {}
	return {"mesh_below_floor_m": snappedf(md.get("body", 0.0), 0.001), "mesh_below_floor_where": md.get("body_part", ""),
			"hat_below_floor_m": snappedf(md.get("hat", 0.0), 0.001), "hat_off": man.hat_off, "has_hat": man.hat_body != null or man.hat_off,
			"mesh_peak_below_floor_m": snappedf(_mesh_peak.body, 0.001), "mesh_peak_where": _mesh_peak.body_part,
			"hat_peak_below_floor_m": snappedf(_mesh_peak.hat, 0.001),
			"lying": lying, "chest_front_up": snappedf(up, 0.01),
			"seat_h": snappedf((man.parts[&"pelvis"] as Node3D).global_position.y, 0.001) if _flat_floor() else null,
			"kneeling": _kneeling(man) if _flat_floor() else null, "knee_bend": knees, "hand_in_body": hands,
			"kneel_s": snappedf(_kneel_ticks / 60.0, 0.01) if _flat_floor() else null}


## Several men: each one's ending, and how deep any part of one lies in another man.
func _men_rest() -> Array:
	var out := []
	for i in _men.size():
		var man := _men[i]
		var deepest := 0.0
		for k in _men.size():
			if k == i:
				continue
			for a: StringName in man.parts:
				for b: StringName in _men[k].parts:
					deepest = maxf(deepest, _overlap_between(man, a, _men[k], b))
		var awake := 0
		for sid: StringName in man.parts:
			if man.parts[sid] is RigidBody3D and not (man.parts[sid] as RigidBody3D).sleeping:
				awake += 1
		out.append({"limp": man.limp, "seat_h": snappedf((man.parts[&"pelvis"] as Node3D).global_position.y, 0.001),
				"in_another_m": snappedf(deepest, 0.001), "awake_parts": awake})
	return out


func _overlap_between(ma: HumanBody, a: StringName, mb: HumanBody, b: StringName) -> float:
	var na := ma.parts[a] as Node3D
	var nb := mb.parts[b] as Node3D
	if na.global_position.distance_to(nb.global_position) > 0.8:
		return 0.0
	var best := 0.0
	for ca in na.get_children():
		if not (ca is CollisionShape3D and (ca as CollisionShape3D).shape is CapsuleShape3D):
			continue
		for cb in nb.get_children():
			if not (cb is CollisionShape3D and (cb as CollisionShape3D).shape is CapsuleShape3D):
				continue
			var sa := (ca as CollisionShape3D).shape as CapsuleShape3D
			var sb := (cb as CollisionShape3D).shape as CapsuleShape3D
			var xa := na.global_transform * (ca as CollisionShape3D).transform
			var xb := nb.global_transform * (cb as CollisionShape3D).transform
			var ha := sa.height * 0.5 - sa.radius
			var hb := sb.height * 0.5 - sb.radius
			var d := _seg_dist(xa * Vector3(0, -ha, 0), xa * Vector3(0, ha, 0), xb * Vector3(0, -hb, 0), xb * Vector3(0, hb, 0))
			best = maxf(best, sa.radius + sb.radius - d)
	return best


# --- Finishing -----------------------------------------------------------------------------------

func _finish() -> void:
	done = true
	if _ticks_csv:
		_ticks_csv.close()
	if _segs_csv:
		_segs_csv.close()
	var limp_t := _limp_tick / 60.0
	var shapes := 0
	var joints := 0
	var sleeping := 0
	var bodies := 0
	for man in _men:
		for c in man.get_children():
			if c is Joint3D:
				joints += 1
			elif c is RigidBody3D:
				bodies += 1
				if (c as RigidBody3D).sleeping:
					sleeping += 1
				for s in c.get_children():
					if s is CollisionShape3D:
						shapes += 1
	var ms: Array[float] = []
	for i in range(1, _frame_us.size()):
		ms.append((_frame_us[i] - _frame_us[i - 1]) / 1000.0)
	summary = {
		"scenario": scenario.name, "group": scenario.get("group", ""), "fixture": scenario.get("fixture", "ground"),
		"men": count, "limp_t": limp_t, "hit_t": (_hit_tick / 60.0) if _hit_tick >= 0 else limp_t,
		"settle_s": (_settled_tick - _limp_tick) / 60.0 if _settled_tick >= 0 else null,
		"all_asleep_at_end": sleeping == bodies, "asleep_at_end": sleeping, "bodies": bodies,
		"sleep_flips": _sleep_flips, "shapes": shapes, "joints": joints,
		"peak": _peak, "final_com": _v(_com(_men[0])), "start": _v(_start_xf.origin),
		"final_com_local": _v(_start_xf.affine_inverse() * _com(_men[0])),
		"events": _events, "raw_flags": _flags, "raw_thresholds": T,
		"raw_note": "raw_flags count every tick over a threshold, transients included; analyse.py gives the flags (persistence rules, thresholds.json)",
		"frame_ms": _stats(ms),
		"frame_ms_standing": _stats(ms.slice(10, _limp_tick - 1)),
		"frame_ms_collapse_3s": _stats(ms.slice(_limp_tick - 1, _limp_tick + 179)),
		"frame_ms_after_5s": _stats(ms.slice(_limp_tick + 299)),
		"asleep_by_second": _asleep_by_second,
		"rest": _rest(_men[0]) if _limp_tick >= 0 else {},
		"men_rest": _men_rest() if _men.size() > 1 else [],
	}
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.close()


static func _stats(ms: Array[float]) -> Dictionary:
	if ms.is_empty():
		return {}
	var s := ms.duplicate()
	s.sort()
	var total := 0.0
	for m in s:
		total += m
	return {"mean": total / s.size(), "p50": s[s.size() / 2], "p99": s[mini(s.size() - 1, int(s.size() * 0.99))], "max": s[-1], "n": s.size()}

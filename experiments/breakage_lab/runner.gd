extends Node
## The breakage lab's runner (README.md beside this file; docs/briefs/labs.md "Breakage lab";
## roadmap 3.3a): one scenario in the running game's street, measured. It finds the target as the
## game built it (a saloon chair, the store's door...), fires the production weapons' loads down a
## fixed line (Ballistics.fire / fire_charge with config/revolver.tres and config/shotgun.tres),
## sets down a real lit stick (DynamiteStick, Blast.detonate), or drops a man (HumanBody.go_limp),
## and logs what broke and where, the pieces, how far they flew, what caught, physics faults and
## the frame. **Measurement only:** nothing here changes how the game plays. Started by bridge.gd.
##
## What the lab does to the street before it measures (its own setup, logged in the summary):
## everyone in town is taken out (TownLife stopped, its people freed: they'd walk into the shots),
## the player stands 80 m south out of every blast's reach, the clock is set and stopped, Prof's
## timers are on. Then only the lab's own men (a bystander for a blast, the man for the table).

const LAB := "res://experiments/breakage_lab/"
const PLAYER_AWAY := Vector3(0.0, 0.2, 80.0)
## The settle rule for a man (as the ragdoll lab's): every part under these for 30 ticks.
const SETTLE_SPEED := 0.05
const SETTLE_SPIN := 0.3
const SETTLE_TICKS := 30
## Seconds after the event the middle frame of a sheet is taken.
const MID_SHOT := 0.15
## A FireSystem frame at least this long with nothing hot is its periodic grid rebuild.
const GRID_MS := 5.0
## The surface scan's cells (m).
const SCAN_STEP := 0.1


class ErrorCatcher:
	extends Logger
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var text := "%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function]
		_mutex.lock()
		if error_type == ERROR_TYPE_WARNING:
			if warnings.size() < 40:
				warnings.append(text)
		elif errors.size() < 40:
			errors.append(text)
		_mutex.unlock()


var lab: BridgeLab
var scenario := ""
var seed_value := 1
var body := &"bold_cowboy_s0"
var seconds := 8.0
var out_dir := ""
## Rendered: before / just after / at the end frames from the target's camera (needs a renderer).
var shots := false
## Holes drawn by the shader, no voxel carving (as without the native plugin; perf_bench's
## --no-voxels): for telling the carving's worker threads apart from the rest.
var no_voxels := false
## A look sequence (`frames=0,0.1,...`): shots this many game seconds after the event, every frame
## drawn between (implies shots).
var sequence: Array = []

var _data := {}
var _spec := {}
var _thr := {}
var _street: Node3D
var _building: Node3D
var _target: Node3D
var _target_kind := ""  # prop (one box), kit (a KitProp: members), member, ground
var _aim := Vector3.ZERO
var _heading := Vector3.FORWARD
var _event_at := Vector3.ZERO
var _event_tick := -1
var _pieces: Array[Dictionary] = []
var _men: Array[Dictionary] = []
var _hits: Array[Dictionary] = []
var _blasts: Array[Dictionary] = []
var _frames: Array[Dictionary] = []
var _lab_us := 0
var _last_us := 0
var _fire_log: Array[Dictionary] = []
var _ignited := {}  # member -> [id, structure, seconds after the event]
var _before := {}  # member -> {broken, holes, carved}
var _analysis_before := {}  # structure -> StructuralAnalysis
var _lamps: Array[OilLamp] = []
var _stick: DynamiteStick
var _catcher: ErrorCatcher
var _measuring := false
var _shot_paths := {}
var _draws := {}
var _setup := {}
var _scan_before := {}
var _surface_summary_cache := {}


## The scenarios this lab knows: TARGET_WEAPON for every target and weapon, then the extras.
static func names() -> Array:
	var d := data()
	var out := []
	for t: String in d.targets:
		for w: String in weapons_of(d, t):
			out.append("%s_%s" % [t, w])
	for e: String in d.extras:
		out.append(e)
	return out


## A target's weapons: its own list if it has one (the surfaces), else every weapon but the ones
## marked `only_listed` (a charge lying on the target makes sense for a floor, not a bottle).
static func weapons_of(d: Dictionary, target: String) -> Array:
	var t: Dictionary = d.targets[target]
	if t.has("weapons"):
		return t.weapons
	return (d.weapons as Dictionary).keys().filter(func(w: String) -> bool: return not d.weapons[w].get("only_listed", false))


static func data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAB + "scenarios.json"))
	return parsed if parsed is Dictionary else {}


## One scenario's whole definition: its target's and weapon's entries merged (empty if unknown).
static func spec_of(name: String, d: Dictionary) -> Dictionary:
	if d.extras.has(name):
		var e: Dictionary = (d.extras[name] as Dictionary).duplicate(true)
		var t: Dictionary = (d.targets[e.target] as Dictionary).duplicate(true)
		t.merge(e, true)
		t["target_name"] = e.target
		t["weapon"] = {"drop": e.drop}
		return t
	for t: String in d.targets:
		if name.begins_with(t + "_") and name.substr(t.length() + 1) in weapons_of(d, t):
			var s: Dictionary = (d.targets[t] as Dictionary).duplicate(true)
			s["target_name"] = t
			s["weapon_name"] = name.substr(t.length() + 1)
			s["weapon"] = (d.weapons[s.weapon_name] as Dictionary).duplicate()
			return s
	return {}


func run() -> Dictionary:
	_data = data()
	_spec = spec_of(scenario, _data)
	_thr = _data.get("thresholds", {})
	if _spec.is_empty():
		return {"ok": false, "error": "no scenario %s (breakage_list)" % scenario}
	_street = lab.street as Node3D
	DirAccess.make_dir_recursive_absolute(out_dir)
	_catcher = ErrorCatcher.new()
	OS.add_logger(_catcher)
	_quiet_town()
	await lab.seconds(0.5)
	_building = _street.get_node_or_null(NodePath(String(_spec.building))) as Node3D
	_target = _find_target(_building, _spec.find)
	if _target == null:
		return _fail("no target %s in %s" % [JSON.stringify(_spec.find), _spec.building])
	_target_kind = "member" if _target is StructureMember else ("ground" if _spec.find.has("ground") else ("kit" if _target is KitProp else "prop"))
	_aim = _target_point()
	_heading = _level(_building.global_basis * _v(_spec.get("from", [0, 0, -1])))
	_snapshot_before()
	var w: Dictionary = _spec.weapon
	var line := {}
	if w.has("gun"):
		line = _line_check(_aim + _heading * float(w.distance))
	var charge := Vector3.INF
	if w.has("dynamite"):
		charge = _charge_point(float(w.dynamite))
		if _target is StructureMember and _spec.get("surface", false):
			_setup["by_rule"] = _by_rule(charge, Blast.t().tnt_per_stick)
		_setup["blast_query"] = _blast_query(charge, Blast.t().tnt_per_stick)
		_man("bystander", _floor_point(_building.global_transform * _v(_spec.bystander), 1.0), charge, false)
	if w.has("drop"):
		_man("dropped", Vector3.ZERO, Vector3.ZERO, true)
	await lab.seconds(1.0)  # the men stood (or lying) still, Fittings has looked
	_hook()
	if shots:
		await _shot("before")
		# Drawn only for its three frames (lavapipe takes seconds a frame); with --fixed-fps every
		# frame is one physics step whether it's drawn or not, so the run is the same.
		RenderingServer.render_loop_enabled = false
	# A second of the street as it is, for the frame's baseline.
	_measuring = true
	await lab.seconds(1.0)
	# The event.
	_event_tick = Engine.get_physics_frames()
	if w.has("gun"):
		_fire(String(w.gun), _aim + _heading * float(w.distance), _aim)
		_event_at = _aim
	elif w.has("dynamite"):
		_stick = DynamiteStick.make(_street, charge, Vector3.ZERO, 0.0)
		_stick.fuse_left = 0.02
		_stick.light()
		_event_at = charge
		_stick.went_off.connect(func() -> void: _event_tick = Engine.get_physics_frames())
	elif w.has("drop"):
		_drop_man()
		_event_at = _aim
	if not sequence.is_empty():
		# Drawn every frame from the event on (the dust is GPU particles: they move only while
		# frames are drawn), a shot at each moment asked for (game seconds after the event).
		RenderingServer.render_loop_enabled = true
		for t: float in sequence:
			while Engine.get_physics_frames() - _event_tick < int(round(t * 60.0)):
				await get_tree().physics_frame
			await _shot("t%05.2f" % t, false)
		await lab.seconds(maxf(seconds - float(sequence[-1]), 0.0))
	elif shots:
		await lab.seconds(MID_SHOT)
		await _shot("mid")
		await lab.seconds(maxf(seconds - MID_SHOT, 0.0))
		await _shot("after")
	else:
		await lab.seconds(seconds)
	_measuring = false
	_unhook()
	OS.remove_logger(_catcher)
	return _summarise(line, charge)


func _fail(why: String) -> Dictionary:
	_unhook()
	if _catcher:
		OS.remove_logger(_catcher)
	return {"ok": false, "error": why}


# --- Setup ---------------------------------------------------------------------------------------

## Everyone out of the street, the player far off, the clock set and stopped, the timers on.
func _quiet_town() -> void:
	var gone := 0
	for tl in get_tree().get_nodes_in_group(&"town_life"):
		(tl as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for spawner in _street.find_children("*", "OutlawSpawner", true, false):
		(spawner as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for p in get_tree().get_nodes_in_group(&"people"):
		if p is HumanBody:
			(p as Node).queue_free()
			gone += 1
	if lab.player:
		lab.player.global_position = PLAYER_AWAY
		lab.player.velocity = Vector3.ZERO
	var clock := _street.find_child("DayCycle", true, false) as DayCycle
	if clock:
		clock.set_time(float(_spec.get("hour", 21)))
		clock.set_time_scale(0.0)
	Prof.on = true
	Prof._sum.clear()
	if no_voxels:
		StructureMember.voxel_damage_tuning().enabled = false
	# Seeded: the ricochets' draws (Ballistics), and the men (rng_seed); the shotgun's pattern is
	# drawn from this seed too (_fire). Blast seeds itself from where it goes off.
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if ballistics:
		ballistics._rng.seed = 1873 + seed_value
	_setup = {"people_removed": gone, "player_at": lab.arr(PLAYER_AWAY), "hour": _spec.get("hour", 21), "clock": "stopped",
			"voxels": StructureMember.voxels_available() and not no_voxels, "seed": seed_value}


func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _level(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 1e-4 else Vector3.FORWARD


## The thing the scenario names, as the game built it: a prop by its id nearest a point (a drawn
## prop's one box, or a kit prop: PropLibrary hands out a KitProp, a Structure of members, for a
## kit file marked in_game), or a member by id or by kind nearest a point (building space).
func _find_target(building: Node3D, find: Dictionary) -> Node3D:
	if building == null:
		return null
	if find.has("member"):
		return (building as Structure).get_member(StringName(find.member)) if building is Structure else null
	if find.has("ground"):
		return _street.get_node_or_null(^"Ground") as Node3D
	var near := building.global_transform * _v(find.get("near", [0, 0, 0]))
	var best: Node3D = null
	var best_d := INF
	if find.has("prop"):
		for n in building.find_children("*", "Node3D", true, false):
			if (n is StaticBody3D or n is KitProp) and n.get_meta(&"prop_id", &"") == StringName(find.prop):
				var d := (n as Node3D).global_position.distance_to(near)
				if d < best_d:
					best_d = d
					best = n
		return best
	for m: StructureMember in (building as Structure).get_members():
		if find.has("kind") and m.kind != StringName(find.kind):
			continue
		if find.has("id_has") and not String(m.member_id).contains(find.id_has):
			continue
		var d := m.global_position.distance_to(near) if not find.has("near") else _nearest_on(m, near).distance_to(near)
		if d < best_d:
			best_d = d
			best = m
	return best


func _target_point() -> Vector3:
	var aim := _v(_spec.get("aim", [0, 0, 0]))
	if _target_kind == "ground":
		return _building.global_transform * _v(_spec.find.ground) + aim
	if _target_kind == "member":
		var near := _building.global_transform * _v(_spec.find.get("near", [0, 0, 0])) if _spec.find.has("near") else _target.global_position
		# The face toward the shooter, at the chosen point (the board's middle across its height).
		var p := _nearest_on(_target as StructureMember, near) if _spec.find.has("near") else _target.global_position
		return p + _building.global_basis * aim
	return (_target as Node3D).global_transform * aim


## A point on the floor (or ground) under `p`: the first solid surface down from `up` above it.
func _floor_point(p: Vector3, up: float) -> Vector3:
	var space := _street.get_world_3d().direct_space_state
	var from := Vector3(p.x, _floor_height_guess() + up, p.z)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 6.0, Layers.WORLD)
	var hit := space.intersect_ray(q)
	return Vector3(p.x, (hit.position as Vector3).y if not hit.is_empty() else 0.0, p.z)


## Where the stick lies: on the floor (or ground) `d` m out along the line from the target; at 0,
## against it (a wall) or on it (a floor, a roof: `charge_on` looks down from just above the aim).
func _charge_point(d: float) -> Vector3:
	var at := _aim + _heading * maxf(d, DynamiteStick.RADIUS + 0.01)
	var p := _floor_point(at, 0.3)
	if d <= 0.0 and _spec.get("charge_on", false):
		var space := _street.get_world_3d().direct_space_state
		var from := Vector3(_aim.x, _aim.y + 0.6, _aim.z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 2.0, Layers.WORLD))
		if not hit.is_empty():
			p = hit.position
	return p + Vector3.UP * (DynamiteStick.RADIUS + 0.004)


func _floor_height_guess() -> float:
	return float(_building.get(&"floor_top")) if _building and _building.get(&"floor_top") != null else 0.0


## Is the line from the shooter to the aim point clear? The first thing along it.
func _line_check(shooter_xz: Vector3) -> Dictionary:
	var shooter := _floor_point(shooter_xz, 1.0) + Vector3.UP * 1.5
	var space := _street.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(shooter, _aim + (_aim - shooter).normalized() * 0.05, Layers.BULLETS)
	var hit := space.intersect_ray(q)
	var first := _describe(hit.collider) if not hit.is_empty() else "nothing"
	var clear: bool = not hit.is_empty() and (hit.collider == _target or (_target_kind in ["prop", "kit"] and (_target as Node).is_ancestor_of(hit.collider as Node)))
	return {"shooter": lab.arr(shooter), "first_hit": first, "clear": clear,
			"first_hit_at": lab.arr(hit.position) if not hit.is_empty() else null}


func _describe(o: Object) -> String:
	if o == null or not is_instance_valid(o):
		return "freed"
	if o is StructureMember:
		var m := o as StructureMember
		return "%s:%s" % [(m.get_parent() as Node).name, m.member_id]
	if o is Node and (o as Node).has_meta(&"prop_id"):
		return "prop:%s" % (o as Node).get_meta(&"prop_id")
	if o is Node and (o as Node).has_meta(&"oil_lamp"):
		return "lamp_hitbox"
	if o is Node and (o as Node).has_meta(&"human_body"):
		return "man:%s" % (o as Node).get_meta(&"segment", &"?")
	return (o as Node).name if o is Node else str(o)


## A man of the lab's own (the body is the lab's option, never the game's default): standing at
## `feet` facing `faces`, or (drop) lying on his back over the table, to go limp.
func _man(role: String, feet: Vector3, faces: Vector3, drop: bool) -> void:
	var man := HumanBody.new()
	man.name = "Lab_%s" % role
	man.has_gun = false
	man.body_model = body
	man.rng_seed = seed_value
	man.person_id = StringName("lab_" + role)
	_street.add_child(man)
	var xf := Transform3D.IDENTITY
	if drop:
		# On his back, head toward the room's middle, his middle `drop` m over the table's top (a
		# kit table's top from its members' bounds, as a drawn one's from its box).
		var box := PropLibrary.bounds_of(_target as Node3D)
		var top := (_target as Node3D).global_position.y + (box.end.y if box.size != Vector3.ZERO else PropLibrary.size_of(&"card_table").y)
		# His head along the building's x, his face up (his -z), his back down.
		var along := _level(_building.global_basis * Vector3(1, 0, 0))
		var lying := Basis(along.cross(Vector3.DOWN), along, Vector3.DOWN)
		var mid := Vector3((_target as Node3D).global_position.x, top + float(_spec.weapon.drop), (_target as Node3D).global_position.z)
		# His middle is about a metre up from his feet.
		xf = Transform3D(lying, mid - along * 1.0)
	else:
		var look := _level(faces - feet)
		xf = Transform3D(Basis.looking_at(look, Vector3.UP), feet)
	man.global_transform = xf
	_men.append({"node": man, "role": role, "start": xf.origin, "peak_speed": 0.0, "peak_speed_part": "",
			"sunk_max": 0.0, "sunk_run": 0, "sunk_flag_ticks": 0, "settled_tick": -1, "settle_run": 0,
			"harm": [], "knocked_down": false, "min_y": INF})


func _drop_man() -> void:
	(_men[0].node as HumanBody).go_limp(Vector3.ZERO)


## The game's own loads, down the line, as the player's guns fire them (no aim wobble: a fixed line).
func _fire(gun: String, shooter_xz: Vector3, at: Vector3) -> void:
	var shooter := _floor_point(shooter_xz, 1.0) + Vector3.UP * 1.5
	var dir := (at - shooter).normalized()
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var none: Array[RID] = []
	if gun == "revolver":
		var t: RevolverTuning = load("res://config/revolver.tres")
		var b := ballistics.fire(shooter, dir, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, none)
		b.form = t.form_factor
	else:
		var t: ShotgunTuning = load("res://config/shotgun.tres")
		var rng := RandomNumberGenerator.new()
		rng.seed = 40 + seed_value
		ballistics.fire_charge(shooter, dir, t.pellets, deg_to_rad(t.pattern_degrees), t.muzzle_velocity, t.pellet_mass,
				t.pellet_diameter, none, rng, t.blast_joules, t.blast_reach)
	Events.shot_fired.emit(shooter, dir, null)


func _snapshot_before() -> void:
	for s in _structures_near(_aim, 25.0):
		for m: StructureMember in s.get_members():
			_before[m] = {"broken": m.broken, "holes": m.holes.size(), "carved": m.voxels != null, "burning": m.burning}
		_analysis_before[s] = StructuralAnalysis.new(s.tuning).analyse(s)
	for lamp in _street.find_children("*", "OilLamp", true, false):
		if (lamp as Node3D).global_position.distance_to(_aim) < 15.0:
			_lamps.append(lamp as OilLamp)
	if _spec.get("surface", false) or _target_kind == "ground":
		_scan_before = _scan()
	_setup["target"] = _describe(_target)
	_setup["target_node"] = String(_target.name)
	_setup["target_at"] = lab.arr(_target.global_position)
	_setup["aim"] = lab.arr(_aim)


## What Blast.detonate looks at from here (`Blast.gather`), against everything in its reach (one
## uncapped query): how many it takes, whether the target is among them, and how many members
## within 1 m, 2 m and where timber can break it leaves out. (Before 2026-10-21's fix Blast took one
## query capped at 1024 colliders, in the engine's order: the baseline has those numbers.)
func _blast_query(at: Vector3, kg: float) -> Dictionary:
	var space := _street.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = Blast.reach(kg)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.collision_mask = Layers.WORLD | Layers.DEBRIS | Layers.BODY_PARTS
	var looked := {}
	for c: Object in Blast.gather(_street, at, kg):
		looked[c.get_instance_id()] = true
	var target_found := _target is CollisionObject3D and looked.has((_target as Object).get_instance_id())
	if _target is KitProp:
		target_found = (_target as KitProp).get_members().any(func(m: StructureMember) -> bool: return looked.has(m.get_instance_id()))
	var all := space.intersect_shape(q, 1 << 20)
	var radii := [1.0, 2.0, Blast.break_reach(kg)]
	var near := [0, 0, 0]
	var missed := [0, 0, 0]
	for f in all:
		if not f.collider is StructureMember:
			continue
		var d := _nearest_on(f.collider as StructureMember, at).distance_to(at)
		for i in radii.size():
			if d <= radii[i]:
				near[i] += 1
				if not looked.has(f.collider_id):
					missed[i] += 1
	return {"reach_m": snappedf(shape.radius, 0.1), "break_reach_m": snappedf(radii[2], 0.01), "in_reach": all.size(),
			"found": looked.size(), "target_found": target_found,
			"members_within_1_2_break_m": near, "left_out_within_1_2_break_m": missed}


func _structures_near(at: Vector3, r: float) -> Array[Structure]:
	var out: Array[Structure] = []
	for s in get_tree().get_nodes_in_group(&"structures"):
		if s is Structure and _street.is_ancestor_of(s):
			var box := _box_of_structure(s as Structure)
			if box.grow(r).has_point(at):
				out.append(s as Structure)
	return out


func _box_of_structure(s: Structure) -> AABB:
	var box := AABB(s.global_position, Vector3.ZERO)
	for m: StructureMember in s.get_members():
		box = box.expand(m.global_position)
	return box


# --- The surface ---------------------------------------------------------------------------------

## The surface round the target, cell by cell (SCAN_STEP apart, `scan_m` either way): for a wall,
## floor, roof or boardwalk, which cells of its plane are closed by a standing member of the
## target's own kind (a ray through the plane; anything else it meets, rubble, a joist behind,
## is looked past); for the ground, how high the ground is (a ray down; only the ground counts).
func _scan() -> Dictionary:
	var space := _street.get_world_3d().direct_space_state
	var half := float(_spec.get("scan_m", 3.0))
	var n := int(round(half / SCAN_STEP))
	var out := {}
	var u: Vector3
	var v: Vector3
	var normal: Vector3
	if _target_kind == "ground":
		u = Vector3.RIGHT
		v = Vector3.BACK
		normal = Vector3.UP
	else:
		var m := _target as StructureMember
		var thin := 0
		for i in 3:
			if m.size[i] < m.size[thin]:
				thin = i
		normal = m.global_basis[thin].normalized()
		u = m.global_basis[(thin + 1) % 3].normalized()
		v = m.global_basis[(thin + 2) % 3].normalized()
	var kind: StringName = (_target as StructureMember).kind if _target is StructureMember else &""
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			var p := _aim + u * (i * SCAN_STEP) + v * (j * SCAN_STEP)
			if _target_kind == "ground":
				p.y = 0.0
				var h: Variant = _ray_to(space, p + Vector3.UP * 1.5, p + Vector3.DOWN * 1.5, func(c: Object) -> int:
						return 1 if c == _target else (0 if c is StaticBody3D and not c is StructureMember else -1))
				if h != null:
					out[Vector2i(i, j)] = (h as Vector3).y
			else:
				var h: Variant = _ray_to(space, p + normal * 0.3, p - normal * 0.3, func(c: Object) -> int:
						return 1 if c is StructureMember and (c as StructureMember).kind == kind and not (c as StructureMember).broken else -1)
				out[Vector2i(i, j)] = h != null
	return out


## The first hit `judge` takes (1: this one; 0: stop, nothing; -1: look past it), or null.
func _ray_to(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, judge: Callable) -> Variant:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	var ex: Array[RID] = []
	for k in 6:
		q.exclude = ex
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return null
		var verdict: int = judge.call(hit.collider)
		if verdict == 1:
			return hit.position
		if verdict == 0:
			return null
		ex.append(hit.rid)
	return null


## What Blast's own rule (blast_demand) would break of the target's surface, if its query found
## every member: the members of the target's kind in its building within 4 m, how many go, the
## face they'd open (whole members: the frame breaks a member or doesn't) and how far it reaches.
func _by_rule(at: Vector3, kg: float) -> Dictionary:
	var timber: TimberTuning = load("res://config/timber.tres")
	var m0 := _target as StructureMember
	var s := m0.get_parent() as Structure
	var n := 0
	var area := 0.0
	var reach := 0.0
	var looked := 0
	for m: StructureMember in s.get_members():
		if m.kind != m0.kind or m.broken or _nearest_on(m, at).distance_to(at) > 4.0:
			continue
		looked += 1
		var r := blast_demand(m, at, kg, timber)
		if float(r.ratio) > 1.0 and not r.get("bedded", false):
			n += 1
			var sz := m.size
			var dims := [sz.x, sz.y, sz.z]
			dims.sort()
			area += dims[1] * dims[2]
			var half := m.axis() * m.length() * 0.5
			reach = maxf(reach, maxf((m.global_position + half).distance_to(at), (m.global_position - half).distance_to(at)))
	return {"members_looked": looked, "would_break": n, "face_m2": snappedf(area, 0.01), "reaches_m": snappedf(reach, 0.01)}


func _surface_summary() -> Dictionary:
	if _scan_before.is_empty():
		return {}
	var after := _scan()
	var cell := SCAN_STEP * SCAN_STEP
	if _target_kind == "ground":
		var deepest := 0.0
		var lowered := 0
		var raised := 0.0
		var reach := 0.0
		for k: Vector2i in _scan_before:
			if not after.has(k):
				continue
			var dh: float = float(after[k]) - float(_scan_before[k])
			if dh < -0.02:
				lowered += 1
				reach = maxf(reach, Vector2(k).length() * SCAN_STEP)
			deepest = minf(deepest, dh)
			raised = maxf(raised, dh)
		var scorch := []
		for d in get_tree().get_nodes_in_group(&"scorch_marks"):
			if d is Decal and _flat((d as Node3D).global_position - _event_at) < 3.0:
				scorch.append(snappedf((d as Decal).size.x, 0.01))
		return {"kind": "ground", "crater_depth_m": snappedf(-deepest, 0.001), "lowered_m2": snappedf(lowered * cell, 0.01),
				"crater_radius_m": snappedf(reach, 0.01), "rim_m": snappedf(raised, 0.001), "scorch_m": scorch,
				"scan_m": _spec.get("scan_m", 3.0)}
	var closed := 0
	var opened := 0
	var near := 0
	var far := 0.0
	for k: Vector2i in _scan_before:
		if not _scan_before[k]:
			continue
		closed += 1
		if not after.get(k, true):
			opened += 1
			var r := Vector2(k).length() * SCAN_STEP
			far = maxf(far, r)
			if r <= 1.0:
				near += 1
	return {"kind": String((_target as StructureMember).kind), "closed_before_m2": snappedf(closed * cell, 0.01),
			"opened_m2": snappedf(opened * cell, 0.01), "opened_within_1m_m2": snappedf(near * cell, 0.01),
			"farthest_opening_m": snappedf(far, 0.01), "scan_m": _spec.get("scan_m", 3.0)}


# --- During the run ------------------------------------------------------------------------------

var _hooks: Array = []
var _kit_broken := {}  # a kit target's member id -> true: broken while it stood


func _hook() -> void:
	var tree := get_tree()
	var on_node := func(n: Node) -> void: _on_node_added(n)
	tree.node_added.connect(on_node)
	_hooks.append([tree.node_added, on_node])
	var on_hit := func(info: Dictionary) -> void: _on_bullet_hit(info)
	Events.bullet_hit.connect(on_hit)
	_hooks.append([Events.bullet_hit, on_hit])
	var on_body := func(info: Dictionary) -> void: _on_body_hit(info)
	Events.body_hit.connect(on_body)
	_hooks.append([Events.body_hit, on_body])
	var on_blast := func(at: Vector3, kg: float) -> void: _blasts.append({"at": lab.arr(at), "kg": kg, "tick": Engine.get_physics_frames()})
	Events.exploded.connect(on_blast)
	_hooks.append([Events.exploded, on_blast])
	if _target is KitProp:
		# Going loose drops every member it has left (broken, as rubble): only what breaks while it
		# still stands is broken by the blow (KitProp.go_loose sets `loose` before it drops them).
		var kit := _target as KitProp
		var on_broken := func(id: StringName) -> void:
			if is_instance_valid(kit) and not kit.loose and kit.members.has(id):
				_kit_broken[id] = true
		Events.member_broken.connect(on_broken)
		_hooks.append([Events.member_broken, on_broken])


func _unhook() -> void:
	for h: Array in _hooks:
		if (h[0] as Signal).is_connected(h[1]):
			(h[0] as Signal).disconnect(h[1])
	_hooks.clear()


func _on_node_added(n: Node) -> void:
	if not n is RigidBody3D or n.has_meta(&"human_body") or n is DynamiteStick:
		return
	var rb := n as RigidBody3D
	var kind := "other"
	for g: String in ["rubble", "wood_chips", "glass_shards", "fallen"]:
		if rb.is_in_group(StringName(g)):
			kind = {"rubble": "rubble", "wood_chips": "chip", "glass_shards": "glass", "fallen": "fitting"}[g]
	_pieces.append({"node": rb, "kind": kind, "name": String(rb.name), "tick": Engine.get_physics_frames(),
			"start": Vector3.INF, "peak_speed": 0.0, "max_dist": 0.0, "from_event": 0.0, "min_y": INF, "sunk_max": 0.0, "sunk_run": 0,
			"sunk_flag": false, "flips": 0, "last_sleep": false, "end": Vector3.INF, "end_speed": 0.0, "asleep": false,
			"freed_tick": -1, "mass": 0.0, "longest": 0.0, "volume": 0.0, "members": []})


func _on_bullet_hit(info: Dictionary) -> void:
	_hits.append({"at": lab.arr(info.position), "what": _describe(info.collider), "penetrated": info.get("penetrated", false),
			"ricochet": info.get("ricochet", false), "j_before": snappedf(float(info.get("energy_before", 0.0)), 0.1),
			"j_after": snappedf(float(info.get("energy_after", 0.0)), 0.1), "tick": Engine.get_physics_frames() - _event_tick})


func _on_body_hit(info: Dictionary) -> void:
	for m in _men:
		if info.get("person") == m.node:
			(m.harm as Array).append_array(info.get("harm", []))
			if info.get("knocked_down", false):
				m.knocked_down = true


func _physics_process(_delta: float) -> void:
	if not _measuring:
		return
	var t0 := Time.get_ticks_usec()
	var tick := Engine.get_physics_frames()
	var after := tick - _event_tick if _event_tick >= 0 else -1
	var space := _street.get_world_3d().direct_space_state
	for p in _pieces:
		_watch_piece(p, space, tick, after)
	for m in _men:
		_watch_man(m, space, tick)
	if after >= 0 and after % 30 == 0:
		_watch_fire(after)
	_lab_us += Time.get_ticks_usec() - t0


func _watch_piece(p: Dictionary, space: PhysicsDirectSpaceState3D, tick: int, after: int) -> void:
	if p.freed_tick >= 0:
		return
	# Checked before it's typed: assigning a freed piece to a typed variable is a script error.
	var rb: RigidBody3D = p.node if is_instance_valid(p.node) else null
	if rb == null or not rb.is_inside_tree():
		p.freed_tick = tick
		return
	var at := rb.global_position
	if p.start == Vector3.INF:
		p.start = at
		p.mass = rb.mass
		var size := _shape_size(rb)
		p.longest = maxf(size.x, maxf(size.y, size.z))
		p.volume = size.x * size.y * size.z
		p.members = rb.get_meta(&"members", [])
	var v := rb.linear_velocity.length()
	p.peak_speed = maxf(p.peak_speed, v)
	p.max_dist = maxf(p.max_dist, _flat(at - p.start))
	p.min_y = minf(p.min_y, at.y)
	if rb.sleeping != p.last_sleep:
		p.flips += 1
		p.last_sleep = rb.sleeping
	p.end = at
	p.from_event = _flat(at - _event_at)
	p.end_speed = v
	p.asleep = rb.sleeping or rb.freeze
	# Sunk into the world: how deep its box sits in what it touches (every third tick; small
	# chips are left out: they're frozen where they land, by design).
	if (tick + p.tick) % 3 == 0 and p.mass >= 0.05:
		var depth := _depth_into_world(rb, space)
		p.sunk_max = maxf(p.sunk_max, depth)
		p.sunk_run = p.sunk_run + 1 if depth > float(_thr.get("sunk_m", 0.03)) else 0
		if p.sunk_run >= int(_thr.get("sunk_ticks", 3)):
			p.sunk_flag = true


func _watch_man(m: Dictionary, space: PhysicsDirectSpaceState3D, tick: int) -> void:
	var man: HumanBody = m.node
	if not is_instance_valid(man):
		return
	var still := true
	var deepest := 0.0
	for sid: StringName in man.parts:
		var part := man.parts[sid] as Node3D
		if part == null or not is_instance_valid(part):
			continue
		m.min_y = minf(m.min_y, part.global_position.y)
		if part is RigidBody3D:
			var rb := part as RigidBody3D
			var v := rb.linear_velocity.length()
			if v > m.peak_speed:
				m.peak_speed = v
				m.peak_speed_part = String(sid)
			if v > SETTLE_SPEED or rb.angular_velocity.length() > SETTLE_SPIN:
				still = false
			if tick % 2 == 0:
				deepest = maxf(deepest, _depth_into_world(rb, space))
		else:
			still = false
	if man.limp:
		m.settle_run = m.settle_run + 1 if still else 0
		if m.settle_run >= SETTLE_TICKS and m.settled_tick < 0:
			m.settled_tick = tick - SETTLE_TICKS
		elif not still:
			m.settled_tick = -1
	if tick % 2 == 0:
		m.sunk_max = maxf(m.sunk_max, deepest)
		m.sunk_run = m.sunk_run + 1 if deepest > float(_thr.get("sunk_m", 0.03)) else 0
		if m.sunk_run >= int(_thr.get("sunk_ticks", 3)):
			m.sunk_flag_ticks += 1


func _watch_fire(after: int) -> void:
	var fire := FireSystem.find(get_tree())
	if fire == null:
		return
	var burning := fire.burning_members()
	for m in burning:
		if not _ignited.has(m) and not bool((_before.get(m, {}) as Dictionary).get("burning", false)):
			_ignited[m] = ["%s:%s" % [(m.get_parent() as Node).name, m.member_id], snappedf(after / 60.0, 0.1)]
	_fire_log.append({"s": snappedf(after / 60.0, 0.1), "burning": burning.size(), "spills": fire.spills.size()})


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _measuring and _last_us > 0:
		var tick := Engine.get_physics_frames()
		var prof := {}
		for k: StringName in Prof._sum:
			prof[String(k)] = snappedf(float(Prof._sum[k]) / 1000.0, 0.001)
		var fire := FireSystem.find(get_tree())
		_frames.append({"tick": tick, "after": tick - _event_tick if _event_tick >= 0 else -1,
				"ms": (now - _last_us) / 1000.0, "lab_ms": _lab_us / 1000.0, "prof": prof,
				"hot": fire.active.size() if fire else 0,
				"active": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS),
				"pieces": _pieces.size()})
	Prof._sum.clear()
	_lab_us = 0
	_last_us = now


func _shape_size(rb: RigidBody3D) -> Vector3:
	var box := AABB()
	var any := false
	for cs: CollisionShape3D in rb.find_children("*", "CollisionShape3D", false, false):
		if cs.shape is BoxShape3D:
			var half := (cs.shape as BoxShape3D).size * 0.5
			var b := cs.transform * AABB(-half, half * 2.0)
			box = b if not any else box.merge(b)
			any = true
	return box.size if any else Vector3.ZERO


## How deep a body's shapes sit in the world (WORLD layer; the ground, members, props, rubble).
func _depth_into_world(rb: RigidBody3D, space: PhysicsDirectSpaceState3D) -> float:
	var deepest := 0.0
	for cs: CollisionShape3D in rb.find_children("*", "CollisionShape3D", false, false):
		if cs.disabled or cs.shape == null:
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cs.shape
		q.transform = cs.global_transform
		q.collision_mask = Layers.WORLD
		q.exclude = [rb.get_rid()]
		var pts := space.collide_shape(q, 8)
		for i in range(0, pts.size() - 1, 2):
			deepest = maxf(deepest, (pts[i] as Vector3).distance_to(pts[i + 1]))
	return deepest


func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


# --- Pictures ------------------------------------------------------------------------------------

func _shot(which: String, pause_after := true) -> void:
	RenderingServer.render_loop_enabled = true
	var cam: Dictionary = _spec.camera
	var at := _building.global_transform * _v(cam.at)
	var look := _building.global_transform * _v(cam.look)
	await lab.bridge._cmd_camera([at.x, at.y, at.z, look.x, look.y, look.z, float(cam.get("fov", 60))])
	var path := out_dir.path_join("%s.png" % which)
	var r: Dictionary = await lab.bridge._cmd_screenshot([path])
	_shot_paths[which] = {"path": path, "ok": r.get("ok", false),
			"s": snappedf((Engine.get_physics_frames() - _event_tick) / 60.0, 0.01) if which != "before" else -1.0}
	_draws[which] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	if which != "after" and pause_after:
		RenderingServer.render_loop_enabled = false


# --- The summary ---------------------------------------------------------------------------------

func _summarise(line: Dictionary, charge: Vector3) -> Dictionary:
	var timber: TimberTuning = load("res://config/timber.tres")
	var out := {"scenario": scenario, "target": _spec.target_name, "weapon": _spec.get("weapon_name", "drop"),
			"body": String(body) if not _men.is_empty() else "", "seed": seed_value, "setup": _setup, "seconds": seconds}
	if not line.is_empty():
		out["line"] = line
	if charge != Vector3.INF:
		out["charge"] = {"at": lab.arr(charge), "kg": Blast.t().tnt_per_stick,
				"to_target_m": snappedf(_nearest_point_of_target(charge).distance_to(charge), 0.01),
				"went_off": not _blasts.is_empty()}
	out["hits"] = _hits.slice(0, 40)
	_surface_summary_cache = _surface_summary()
	out["surface"] = _surface_summary_cache
	out["target_result"] = _target_result(timber, charge)
	out["broken"] = _broken(timber)
	out["pieces"] = _piece_summary()
	out["fire"] = _fire_summary()
	out["men"] = _men_summary()
	out["frame"] = _frame_summary()
	if shots:
		out["shots"] = _shot_paths
		out["draw_calls"] = _draws
	out["errors"] = _catcher.errors
	out["warnings"] = _catcher.warnings.slice(0, 10)
	out["flags"] = _flags(out)
	out["fingerprint"] = _fingerprint(out)
	_write(out)
	return out


func _nearest_point_of_target(p: Vector3) -> Vector3:
	if _target_kind == "member" and is_instance_valid(_target):
		return _nearest_on(_target as StructureMember, p)
	return _aim


## The target: held, holed, broken, shattered, smashed, moved or fell; for a member, how hard it was
## worked against its wood's strength (config/timber.tres, the USDA Wood Handbook's figures).
func _target_result(timber: TimberTuning, charge: Vector3) -> Dictionary:
	var r := {"what": _describe(_target) if is_instance_valid(_target) else _setup.target}
	if _target_kind == "ground":
		r["kind"] = "the street's ground (a flat WorldBoundaryShape3D under a plane mesh)"
		var sf: Dictionary = _surface_summary_cache
		r["result"] = "crater %.2f m deep" % sf.crater_depth_m if float(sf.get("crater_depth_m", 0.0)) > 0.02 else "no crater"
		return r
	if _target_kind == "kit":
		return _kit_result(r, timber, charge)
	if _target_kind == "prop":
		var still := is_instance_valid(_target) and _target.is_inside_tree()
		r["kind"] = "static prop (one box, PropLibrary)"
		r["still_there"] = still
		r["moved_m"] = snappedf((_target as Node3D).global_position.distance_to(_v(_setup.target_at)), 0.001) if still else null
		var fell := _pieces.filter(func(p: Dictionary) -> bool: return p.kind == "fitting" and p.name == "Fallen" + String(_setup.target_node))
		r["fell_as_fitting"] = not fell.is_empty()
		if not fell.is_empty():
			r["result"] = "fell (what held it gave way)"
		else:
			r["result"] = "holds" if still and float(r.moved_m) < 0.01 else "moved"
		var lamp: Array = _target.find_children("*", "OilLamp", true, false) if still else []
		var lamps := _lamps.filter(func(l: OilLamp) -> bool: return is_instance_valid(l) and l.broken)
		r["lamps_smashed"] = lamps.size()
		if _spec.target_name == "lamp" or not lamp.is_empty():
			var own: OilLamp = null
			for l in _lamps:
				if is_instance_valid(l) and l.global_position.distance_to(_v(_setup.target_at)) < 0.4:
					own = l
			r["lamp_lit_before"] = own != null
			r["lamp_smashed"] = own != null and own.broken
			if own and own.broken:
				r["result"] = "smashed"
		return r
	var m := _target as StructureMember
	var b: Dictionary = _before.get(m, {})
	r["kind"] = "member %s, %s (%s)" % [m.kind, m.wood, "x".join([snappedf(m.size.x, 0.001), snappedf(m.size.y, 0.001), snappedf(m.size.z, 0.001)])]
	var wood := timber.wood(m.wood)
	r["wood"] = {"id": m.wood, "bending_MPa": float(wood.bending) / 1e6, "stiffness_GPa": float(wood.stiffness) / 1e9}
	r["broken"] = m.broken
	r["holes"] = m.holes.size() - int(b.get("holes", 0))
	r["carved"] = m.voxels != null and not bool(b.get("carved", false))
	if m.voxels != null:
		r["section_left"] = snappedf(m.voxel_section.x, 0.001)
	var s := m.get_parent() as Structure
	var a0: StructuralAnalysis = _analysis_before.get(s)
	if a0:
		r["utilisation_before"] = snappedf(float(a0.utilisation.get(m.member_id, 0.0)), 0.001)
		r["mode"] = a0.mode.get(m.member_id, &"")
	if not m.broken and s:
		var a1 := StructuralAnalysis.new(s.tuning).analyse(s)
		r["utilisation_after"] = snappedf(float(a1.utilisation.get(m.member_id, 0.0)), 0.001)
	if charge != Vector3.INF:
		r["blast"] = blast_demand(m, charge, Blast.t().tnt_per_stick, timber)
	r["result"] = ("shattered" if m.kind == &"glass" else "broken") if m.broken else ("holed" if r.holes > 0 or r.carved else "holds")
	if m.has_meta(&"cut"):
		var c: Vector2 = m.get_meta(&"cut")
		r["cut_m"] = snappedf(c.y - c.x, 0.01)
		r["result"] = "cut (%.1f m torn out)" % (c.y - c.x)
	return r


## A kit prop (KitProp: its legs, top and rails are members): which of its members broke, were cut,
## holed or carved, whether it went loose (tipped, knocked, its floor gone, thrown by the blast) and
## how far what's left of it went; for a blast, the member Blast's own rule works hardest.
func _kit_result(r: Dictionary, timber: TimberTuning, charge: Vector3) -> Dictionary:
	var kit := _target as KitProp
	r["kind"] = "kit prop %s (%d members)" % [kit.kit_id, kit.get_members().size()]
	var broken := []
	var holed := []
	var worst := {}
	for m: StructureMember in kit.get_members():
		var b: Dictionary = _before.get(m, {"broken": false, "holes": 0, "carved": false})
		var tag := String(m.member_id).trim_prefix(String(kit.structure_id) + "/")
		if _kit_broken.has(m.member_id):
			broken.append(tag)
		elif m.holes.size() > int(b.holes) or (m.voxels != null and not b.carved):
			holed.append(tag)
		if charge != Vector3.INF and not b.broken:
			var d := blast_demand(m, charge, Blast.t().tnt_per_stick, timber)
			if worst.is_empty() or float(d.ratio) > float(worst.ratio):
				d["member"] = tag
				worst = d
	r["members_broken"] = broken
	r["members_holed"] = holed
	r["loose"] = kit.loose
	if not worst.is_empty():
		r["blast"] = worst
	var start := _v(_setup.target_at)
	var moved := 0.0
	for rb in kit.rubble:
		if is_instance_valid(rb):
			moved = maxf(moved, _flat(rb.global_position - start))
	r["moved_m"] = snappedf(moved if kit.loose else kit.global_position.distance_to(start), 0.001)
	if not broken.is_empty():
		r["result"] = "broken (%d of %d members%s)" % [broken.size(), kit.get_members().size(), ", the rest loose" if kit.loose else ""]
	elif kit.loose:
		r["result"] = "thrown %.1f m" % moved if moved > 0.3 else "went loose"
	else:
		r["result"] = "holed" if not holed.is_empty() else "holds"
	return r


## Blast._member_response's sums for one member (src/blast/blast.gd), without its side effects:
## glass by reflected pressure against BlastTuning.glass_kpa; timber by the kick the blast gives it
## (impulse² / 2m) against what it soaks up bending (fb² / 2E × volume × absorb_factor), over the
## whole length and over the hand-span nearest the charge. Over 1 breaks.
static func blast_demand(m: StructureMember, at: Vector3, kg: float, timber: TimberTuning) -> Dictionary:
	var tn := Blast.t()
	var near := _nearest_on(m, at)
	var dist := maxf(near.distance_to(at), 0.03)
	if m.kind == &"glass":
		var side := Blast.overpressure_kpa(kg, dist)
		var kpa := side * Blast.reflection(side)
		return {"distance_m": snappedf(dist, 0.01), "reflected_kpa": snappedf(kpa, 0.1), "breaks_at_kpa": tn.glass_kpa,
				"ratio": snappedf(kpa / tn.glass_kpa, 0.01)}
	var length := m.length()
	var cs := m.cross_section()
	var total := Blast.face_impulse(m, at, kg)
	var mass := maxf(m.weight(timber) / 9.81, 0.05)
	var kick := total * total / (2.0 * mass)
	var wood := timber.wood(m.wood)
	var fb: float = wood.bending
	var e: float = wood.stiffness
	var capacity := fb * fb / (2.0 * e) * cs.x * cs.y * length * tn.absorb_factor
	var span := minf(tn.local_span, length)
	var near_j := Blast.face_impulse(m, at, kg, span)
	var share := span / maxf(length, 1e-4)
	var near_kick := near_j * near_j / (2.0 * mass * share)
	var ratio := maxf(kick / capacity, near_kick / (capacity * share))
	return {"distance_m": snappedf(dist, 0.01), "impulse_Ns": snappedf(total, 0.01), "kick_J": snappedf(kick, 0.01),
			"capacity_J": snappedf(capacity, 0.01), "ratio": snappedf(ratio, 0.01), "bedded": Blast._bedded(m)}


static func _nearest_on(m: StructureMember, at: Vector3) -> Vector3:
	var local := m.global_transform.affine_inverse() * at
	var half := m.size * 0.5
	var c := Vector3(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y), clampf(local.z, -half.z, half.z))
	return m.global_transform * c


## Every member that broke, was holed or was carved: by building, kind, and how far from the event.
func _broken(timber: TimberTuning) -> Dictionary:
	var by_kind := {}
	var list := []
	var holed := 0
	var cut_n := 0
	var structures := {}
	for key in _before:
		if not is_instance_valid(key):
			continue
		var m := key as StructureMember
		var b: Dictionary = _before[key]
		var newly_broken: bool = m.broken and not b.broken
		var newly_holed: bool = m.holes.size() > int(b.holes) or (m.voxels != null and not b.carved)
		if newly_holed and not newly_broken:
			holed += 1
		if not newly_broken:
			continue
		if m.has_meta(&"cut"):
			cut_n += 1
		var s := m.get_parent() as Structure
		var kind_wood := "%s/%s" % [m.kind, m.wood]
		by_kind[kind_wood] = int(by_kind.get(kind_wood, 0)) + 1
		structures[String(s.name)] = int(structures.get(String(s.name), 0)) + 1
		var a0: StructuralAnalysis = _analysis_before.get(s)
		list.append({"id": "%s:%s" % [s.name, m.member_id], "kind": m.kind, "wood": m.wood,
				"m_from_event": snappedf(_nearest_on(m, _event_at).distance_to(_event_at) if not m.has_meta(&"snapped") else m.global_position.distance_to(_event_at), 0.01),
				"utilisation_before": snappedf(float(a0.utilisation.get(m.member_id, 0.0)), 0.01) if a0 else null,
				"snapped": m.has_meta(&"snapped")})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.m_from_event < b.m_from_event)
	return {"count": list.size(), "cut": cut_n, "holed_not_broken": holed, "by_kind": by_kind, "by_building": structures,
			"nearest": list.slice(0, 25), "furthest_m": list[-1].m_from_event if not list.is_empty() else 0.0}


func _piece_summary() -> Dictionary:
	var by_kind := {}
	var largest := {}
	var dists: Array[float] = []
	var rows := []
	for p in _pieces:
		if p.start == Vector3.INF:
			continue
		var k: String = p.kind
		var e: Dictionary = by_kind.get_or_add(k, {"n": 0, "kg": 0.0, "max_m": 0.0, "lands_m": 0.0, "peak_mps": 0.0, "freed": 0})
		e.n += 1
		e.kg = snappedf(e.kg + p.mass, 0.001)
		e.max_m = snappedf(maxf(e.max_m, p.max_dist), 0.01)
		e.lands_m = snappedf(maxf(e.lands_m, p.from_event), 0.01)
		e.peak_mps = snappedf(maxf(e.peak_mps, p.peak_speed), 0.1)
		if p.freed_tick >= 0:
			e.freed += 1
		dists.append(p.max_dist)
		if largest.is_empty() or p.mass > largest.kg:
			largest = {"kind": k, "kg": snappedf(p.mass, 0.001), "longest_m": snappedf(p.longest, 0.001), "members": p.members}
		rows.append(p)
	dists.sort()
	return {"count": rows.size(), "by_kind": by_kind, "largest": largest,
			"median_m": snappedf(dists[dists.size() / 2], 0.01) if not dists.is_empty() else 0.0,
			"max_m": snappedf(dists[-1], 0.01) if not dists.is_empty() else 0.0}


func _fire_summary() -> Dictionary:
	var fire := FireSystem.find(get_tree())
	var caught := []
	for key in _ignited:
		caught.append({"id": _ignited[key][0], "after_s": _ignited[key][1]})
	return {"caught": caught.slice(0, 20), "caught_count": caught.size(), "burning_at_end": fire.burning_members().size() if fire else 0,
			"spills_at_end": fire.spills.size() if fire else 0, "log": _fire_log.slice(0, 20),
			"lamps_smashed": _lamps.filter(func(l: OilLamp) -> bool: return is_instance_valid(l) and l.broken).size()}


func _men_summary() -> Array:
	var out := []
	for m in _men:
		var man: HumanBody = m.node
		var e := {"role": m.role, "body": String(body), "has_model": PeopleBodies.has_model(body),
				"whole": PeopleBodies.report(body).get("whole", false), "start": lab.arr(m.start)}
		if not is_instance_valid(man):
			e["freed"] = true
			out.append(e)
			continue
		var tris := 0
		for mi: MeshInstance3D in man.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh:
				for si in mi.mesh.get_surface_count():
					var arrays := mi.mesh.surface_get_arrays(si)
					var idx: Variant = arrays[Mesh.ARRAY_INDEX]
					tris += (idx as PackedInt32Array).size() / 3 if idx != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		e["triangles"] = tris
		e["parts"] = man.parts.size()
		e["distance_to_event_m"] = snappedf((m.start as Vector3).distance_to(_event_at), 0.01)
		e["harm"] = m.harm
		e["knocked_down"] = m.knocked_down
		e["limp"] = man.limp
		e["alive"] = man.physiology.alive if man.physiology else null
		e["conscious"] = man.physiology.is_conscious() if man.physiology else null
		e["severed"] = man.physiology.severed_segments.keys() if man.physiology else []
		e["peak_part_mps"] = snappedf(m.peak_speed, 0.01)
		e["peak_part"] = m.peak_speed_part
		e["sunk_max_m"] = snappedf(m.sunk_max, 0.001)
		e["sunk_ticks"] = m.sunk_flag_ticks
		e["settle_s"] = snappedf((m.settled_tick - _event_tick) / 60.0, 0.01) if m.settled_tick >= 0 else null
		var pelvis := man.parts.get(&"pelvis") as Node3D
		if pelvis and is_instance_valid(pelvis):
			e["pelvis_end"] = lab.arr(pelvis.global_position)
			if m.role == "dropped" and is_instance_valid(_target):
				var top := (_target as Node3D).global_position.y + PropLibrary.size_of(&"card_table").y
				var on := _flat(pelvis.global_position - (_target as Node3D).global_position) < 0.75 and pelvis.global_position.y > top - 0.05
				e["rests_on_table"] = on
				e["pelvis_over_top_m"] = snappedf(pelvis.global_position.y - top, 0.01)
		out.append(e)
	return out


## The frame, by tick from the event (a stick's: the tick it went off, not the tick it was lit): the
## event's own frame, the next one (where a building settles: `Structure.settle` runs deferred,
## outside every Prof timer), the first second, 1–3 s, and the street before it.
func _frame_summary() -> Dictionary:
	var pre: Array[float] = []
	var first: Array[float] = []
	var next: Array[float] = []
	var event_ms := 0.0
	var event_prof := {}
	var next_ms := 0.0
	var next_prof := {}
	var lab_total := 0.0
	var sys_sum := {}
	var sys_n := 0
	var grid := []
	for f in _frames:
		var after: int = int(f.tick) - _event_tick
		var game := maxf(float(f.ms) - float(f.lab_ms), 0.0)
		lab_total += float(f.lab_ms)
		# FireSystem redoes its grid every 2 s, burning or not (~15 ms here): a frame that's only
		# that, with nothing hot, is counted apart so it isn't put down to the event.
		var fire_ms := float((f.prof as Dictionary).get("fire", 0.0))
		if fire_ms >= GRID_MS and int(f.hot) == 0:
			grid.append(snappedf(fire_ms, 0.1))
			game -= fire_ms
		if after < -2:
			pre.append(game)
		elif after < 0:
			continue  # a stick's fuse burning
		elif after == 0:
			event_ms = game
			event_prof = f.prof
		elif after == 1:
			next_ms = game
			next_prof = f.prof
		elif after < 60:
			first.append(game)
			for k: String in f.prof:
				sys_sum[k] = float(sys_sum.get(k, 0.0)) + float(f.prof[k])
			sys_n += 1
		elif after < 180:
			next.append(game)
	var sys := {}
	for k: String in sys_sum:
		if sys_sum[k] / maxf(sys_n, 1) >= 0.05:
			sys[k] = snappedf(sys_sum[k] / maxf(sys_n, 1), 0.01)
	var active_end := int(_frames[-1].active) if not _frames.is_empty() else 0
	var active_pre := int(_frames[0].active) if not _frames.is_empty() else 0
	var base := float(_stats(pre).get("mean", 0.0))
	var added := event_ms + next_ms - 2.0 * base
	for x in first:
		added += x - base
	return {"note": "wall clock per frame, headless, this workspace's core (x0.65 for Sean's), the lab's own measuring taken out, and FireSystem's grid rebuilds with nothing hot (fire_grid_ms)",
			"before_ms": _stats(pre), "added_ms_first_1s": snappedf(added, 0.1), "fire_grid_ms": grid,
			"event_frame_ms": snappedf(event_ms, 0.01), "event_frame_systems": _top(event_prof, 6),
			"next_frame_ms": snappedf(next_ms, 0.01), "next_frame_systems": _top(next_prof, 6),
			"first_1s_ms": _stats(first), "first_1s_systems": sys, "1_to_3s_ms": _stats(next),
			"awake_bodies_before": active_pre, "awake_bodies_end": active_end, "lab_ms_total": snappedf(lab_total, 0.1)}


func _stats(a: Array[float]) -> Dictionary:
	if a.is_empty():
		return {}
	var s := a.duplicate()
	s.sort()
	var mean := 0.0
	for x in s:
		mean += x
	return {"mean": snappedf(mean / s.size(), 0.01), "p99": snappedf(s[mini(int(s.size() * 0.99), s.size() - 1)], 0.01),
			"max": snappedf(s[-1], 0.01), "n": s.size()}


func _top(prof: Dictionary, n: int) -> Dictionary:
	var keys := prof.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return prof[a] > prof[b])
	var out := {}
	for k: String in keys.slice(0, n):
		out[k] = prof[k]
	return out


## The flags (thresholds in scenarios.json): they flag; they don't judge (README.md).
func _flags(out: Dictionary) -> Array:
	var flags := []
	var line: Dictionary = out.get("line", {})
	if not line.is_empty() and not line.clear:
		flags.append("line_blocked: the first thing on the shooter's line is %s, not the target" % line.first_hit)
	for p in _pieces:
		if p.start == Vector3.INF:
			continue
		var label := "%s %s (%.2f kg)" % [p.kind, p.name, p.mass]
		if p.sunk_flag:
			flags.append("sunk: %s %.3f m into the world" % [label, p.sunk_max])
		if p.min_y < float(_thr.get("below_ground_m", -0.05)):
			flags.append("below_ground: %s down to y %.2f" % [label, p.min_y])
		if p.peak_speed > float(_thr.get("flung_mps", 20.0)) and p.mass >= float(_thr.get("flung_min_kg", 0.5)):
			flags.append("flung: %s at %.1f m/s" % [label, p.peak_speed])
		if p.max_dist > float(_thr.get("far_m", 12.0)):
			flags.append("far: %s flew %.1f m" % [label, p.max_dist])
		if p.freed_tick < 0 and not p.asleep and p.end_speed < 0.3 and p.flips >= int(_thr.get("jitter_flips", 4)):
			flags.append("jitter: %s woke and slept %d times, awake at the end" % [label, p.flips])
	var awake := _pieces.filter(func(p: Dictionary) -> bool: return p.start != Vector3.INF and p.freed_tick < 0 and not p.asleep)
	if not awake.is_empty():
		flags.append("awake_at_end: %d piece(s) still moving or awake after %.0f s (fastest %.2f m/s)" % [awake.size(), seconds,
				awake.map(func(p: Dictionary) -> float: return p.end_speed).max()])
	for m in out.men:
		if m.get("sunk_ticks", 0) > 0:
			flags.append("man_sunk: %s's parts %.3f m into the world for %d ticks" % [m.role, m.sunk_max_m, m.sunk_ticks])
		if m.get("peak_part_mps", 0.0) > float(_thr.get("part_flung_mps", 12.0)):
			flags.append("man_flung: %s's %s at %.1f m/s" % [m.role, m.peak_part, m.peak_part_mps])
		if m.get("limp", false) and m.get("settle_s") == null:
			flags.append("man_unsettled: %s never came to rest" % m.role)
		if not m.get("has_model", true):
			flags.append("no_model: %s has no assets/people/%s.glb (BodyMesh stood in)" % [m.role, m.body])
	if not _catcher.errors.is_empty():
		flags.append("errors: %d logged (first: %s)" % [_catcher.errors.size(), _catcher.errors[0]])
	return flags


## What two runs of the same seed must agree on (run.py --repeat compares them).
func _fingerprint(out: Dictionary) -> Dictionary:
	var ids := []
	for e: Dictionary in out.broken.nearest:
		ids.append(e.id)
	var ends := PackedFloat64Array()
	for p in _pieces:
		if p.end != Vector3.INF:
			ends.append_array([p.end.x, p.end.y, p.end.z])
	var men := []
	for m in _men:
		var man: HumanBody = m.node
		var pel := man.parts.get(&"pelvis") as Node3D if is_instance_valid(man) else null
		men.append(lab.arr(pel.global_position) if pel and is_instance_valid(pel) else null)
	return {"broken": out.broken.count, "broken_ids": ids, "pieces": out.pieces.count, "caught": out.fire.caught_count,
			"piece_ends": Array(ends).map(func(x: float) -> float: return snappedf(x, 0.001)), "men": men,
			"target": out.target_result.result}


func _write(out: Dictionary) -> void:
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	var pc := FileAccess.open(out_dir.path_join("pieces.csv"), FileAccess.WRITE)
	pc.store_line("kind,name,spawn_tick,kg,longest_m,start_x,start_y,start_z,end_x,end_y,end_z,max_m,peak_mps,min_y,sunk_max_m,flips,asleep,freed_tick")
	for p in _pieces:
		if p.start == Vector3.INF:
			continue
		pc.store_line("%s,%s,%d,%.4f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.2f,%.3f,%.4f,%d,%s,%d" % [p.kind, p.name,
				p.tick - _event_tick, p.mass, p.longest, p.start.x, p.start.y, p.start.z, p.end.x, p.end.y, p.end.z,
				p.max_dist, p.peak_speed, p.min_y, p.sunk_max, p.flips, p.asleep, p.freed_tick - _event_tick if p.freed_tick >= 0 else -1])
	pc.close()
	var fc := FileAccess.open(out_dir.path_join("frames.csv"), FileAccess.WRITE)
	fc.store_line("tick,after,ms,lab_ms,game_ms,active,pieces,top_systems")
	for fr in _frames:
		fc.store_line("%d,%d,%.3f,%.3f,%.3f,%d,%d,%s" % [fr.tick, fr.after, fr.ms, fr.lab_ms, maxf(fr.ms - fr.lab_ms, 0.0),
				fr.active, fr.pieces, " ".join(_top(fr.prof, 4).keys().map(func(k: String) -> String: return "%s=%.2f" % [k, fr.prof[k]]))])
	fc.close()

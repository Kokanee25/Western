extends Node3D
## The falls lab's runner (issue #759; falls.gd starts it): for each height and pose, `men` men
## dropped at once side by side (6 m apart, nothing between them), let go limp in the air turned to
## the pose (a tilt of up to 15 deg each way drawn by his seed, so no two land alike), watched for
## `seconds`, then his body run on alone for ten minutes (Physiology.step) to see who dies of it.
## Writes <out>/falls.json (every man) and <out>/falls.md (the table against Sean's on #762).

var args := {}
var heights: Array[float] = [1.0, 2.0, 3.0, 4.5, 6.0, 9.0, 12.0, 15.0, 22.0]
var poses: Array[String] = ["feet", "back", "head"]
var men := 20
var seconds := 4.0
var seed_base := 1
var out := ""
## --onto=roof|porch|floor: each man lands on a bay of the game's members (lab_roof.gd) with its top
## at 3 m, the height his fall is counted from it; none: the ground.
var onto := ""
const BED_TOP := 3.0
var _beds: Array = []  ## each man's bay
var _timber: TimberTuning

var _cells: Array = []  ## [height, pose]
var _cell := -1
var _tick := 0
var _men: Array[HumanBody] = []
var _falls := {}  ## HumanBody -> Array of last_fall dictionaries
var _rows: Array = []
const SPACING := 6.0
const AFTER_S := 600.0


func _ready() -> void:
	if args.has("heights"):
		heights.clear()
		for h in String(args.heights).split(","):
			heights.append(float(h))
	if args.has("poses"):
		poses.assign(String(args.poses).split(","))
	men = int(args.get("men", men))
	seconds = float(args.get("seconds", seconds))
	seed_base = int(args.get("seed", seed_base))
	out = String(args.get("out", "build/falls_lab/run"))
	onto = String(args.get("onto", ""))
	# --body-stop=M: TimberTuning.body_stop for this run (a large one holds every board, to read
	# each man's `need`: the stop below which his landing would have broken one).
	if args.has("body-stop"):
		_timber = StructuralAnalysis.load_tuning()  # (held: an unheld resource is loaded afresh)
		_timber.body_stop = float(args["body-stop"])
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(out)
	for p in poses:
		for h in heights:
			_cells.append([h, p])
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SPACING * men + 40.0, 1.0, 60.0)
	cs.shape = box
	ground.add_child(cs)
	add_child(ground)
	ground.position = Vector3(SPACING * men * 0.5, -0.5, 0.0)
	_next_cell()


func _next_cell() -> void:
	for m in _men:
		m.queue_free()
	_men.clear()
	for b in _beds:
		b.queue_free()
	_beds.clear()
	_falls.clear()
	_cell += 1
	_tick = 0
	if _cell >= _cells.size():
		_finish()
		return
	var h: float = _cells[_cell][0]
	for i in men:
		var man := HumanBody.new()
		man.name = "Faller%d" % i
		man.body_model = &"outlaw"
		man.has_gun = false
		man.start_holstered = true
		man.rng_seed = seed_base * 1000 + i
		man.person_id = StringName("fall_%d" % i)
		add_child(man)
		var dice := RandomNumberGenerator.new()
		dice.seed = hash(["falls_lab", seed_base, i])
		var base := 0.0
		if onto != "":
			var bed: Structure = load("res://experiments/falls_lab/lab_roof.gd").new()
			bed.set(&"kind", onto)
			bed.set(&"top", BED_TOP)
			bed.name = "Bed%d" % i
			bed.structure_id = StringName("bed_%d" % i)
			add_child(bed)
			# (The porch roof runs from its front at z 0 out to -2.2: centred under him.)
			bed.global_position = Vector3(SPACING * i, 0.0, 1.1 if onto == "porch" else 0.0)
			_beds.append(bed)
			base = BED_TOP
		man.global_transform = Transform3D(Basis(Vector3.UP, dice.randf_range(-PI, PI)), Vector3(SPACING * i, base + h, 0.0))
		_falls[man] = []
		man.fell_from.connect(func(f: Dictionary) -> void: (_falls[man] as Array).append(f.duplicate(true)))
		_men.append(man)


func _physics_process(_delta: float) -> void:
	if _cell < 0 or _cell >= _cells.size():
		return
	_tick += 1
	if _tick == 2:
		_drop()
	elif _tick > 2 + int(seconds * 60.0):
		_score()
		_next_cell()


## Limp in the air, turned to the pose about his middle, his lowest part at the height.
func _drop() -> void:
	var h: float = _cells[_cell][0]
	var pose: String = _cells[_cell][1]
	for i in _men.size():
		var man := _men[i]
		man.go_limp(Vector3.ZERO)
		var dice := RandomNumberGenerator.new()
		dice.seed = hash(["falls_lab_tilt", seed_base, i])
		var turn := {"feet": 0.0, "back": 90.0, "head": 180.0}[pose] as float
		var tilt := Basis(Vector3.RIGHT, deg_to_rad(turn + dice.randf_range(-15.0, 15.0))) \
				* Basis(Vector3.FORWARD, deg_to_rad(dice.randf_range(-15.0, 15.0)))
		var r := man.global_basis * tilt * man.global_basis.inverse()
		var com := Vector3.ZERO
		var m := 0.0
		for sid: StringName in man.parts:
			var rb := man.parts[sid] as RigidBody3D
			if rb:
				com += rb.global_position * rb.mass
				m += rb.mass
		com /= m
		var low := INF
		for sid: StringName in man.parts:
			var rb := man.parts[sid] as RigidBody3D
			if rb == null:
				continue
			rb.global_transform = Transform3D(r * rb.global_basis, com + r * (rb.global_position - com))
			low = minf(low, rb.global_position.y - float(man.anatomy.segments[sid].radius) - 0.06)
		for sid: StringName in man.parts:
			var rb := man.parts[sid] as RigidBody3D
			if rb == null:
				continue
			rb.global_position += Vector3.UP * (h + (BED_TOP if onto != "" else 0.0) - low)
			rb.linear_velocity = Vector3.ZERO
			rb.angular_velocity = Vector3.ZERO


func _score() -> void:
	var h: float = _cells[_cell][0]
	var pose: String = _cells[_cell][1]
	for k in _men.size():
		var man := _men[k]
		var p := man.physiology
		var broke: Array = []
		var through := false
		if onto != "":
			for mm: StructureMember in (_beds[k] as Structure).get_members():
				if mm.broken:
					broke.append(String(mm.member_id).get_file())
			through = (man.parts[&"pelvis"] as Node3D).global_position.y < BED_TOP - 0.5
		var harm: Array = []
		var kinds: Array = []
		var speed := 0.0
		var joules := 0.0
		for f: Dictionary in _falls[man]:
			harm.append_array(Array(f.harm))
			kinds.append(String(f.kind))
			speed = maxf(speed, float(f.speed))
			joules += float(f.joules)
		var t := 0.0
		while p.alive and t < AFTER_S:
			p.step(1.0)
			t += 1.0
		var need := 0.0
		if man._impacts != null:
			need = man._impacts.peak_need
		_rows.append({"drawn": drawn(man), "need": snappedf(need, 0.001), "onto": onto, "broke": broke, "through": through, "pelvis_y": snappedf((man.parts[&"pelvis"] as Node3D).global_position.y, 0.01), "height": h, "pose": pose, "seed": man.rng_seed, "landings": kinds, "speed": speed,
				"joules": snappedf(joules, 1.0), "harm": harm, "dead": not p.alive,
				"died_after_s": t if not p.alive else -1.0, "cause": String(p.cause_of_death),
				"broken": p.broken.keys().map(func(k: Variant) -> String: return String(k)),
				"cut": p.cut.keys().map(func(k: Variant) -> String: return String(k)),
				"torn": p.torn.keys().map(func(k: Variant) -> String: return String(k)),
				"blows": (_falls[man] as Array).map(func(f: Dictionary) -> Dictionary: return f.blows)})


## Still drawn where he lies (#562's fix: his skin's culling box follows his parts): every part
## inside every skin mesh's box, the meshes shown.
static func drawn(man: HumanBody) -> bool:
	if not is_instance_valid(man) or not man.is_inside_tree() or not man.is_visible_in_tree() or man.skeleton == null:
		return false
	var any := false
	for mi: Node in man.skeleton.get_children():
		if not (mi is MeshInstance3D) or (mi as MeshInstance3D).custom_aabb.size == Vector3.ZERO:
			continue
		any = true
		var box := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).custom_aabb
		for sid: StringName in man.parts:
			if not box.grow(0.05).has_point((man.parts[sid] as Node3D).global_position):
				return false
	return any


func _finish() -> void:
	var f := FileAccess.open(out.path_join("falls.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_rows, "  "))
	f.close()
	print("falls lab: %d men into %s" % [_rows.size(), out])
	get_tree().quit(0)

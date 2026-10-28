extends BridgeLab
## The body lab's dev bridge commands (README.md beside this file; docs/briefs/labs.md): put a man
## of any model in the street with no brain, shoot him at a marked spot from a range or set a stick
## off near him, treat him, and read what the wounds crossed and where his blood is going. The same
## bench (wound_bench.gd) as the lab's command line. Debug builds only, as the bridge is.

const Bench := preload("res://experiments/body_lab/wound_bench.gd")

const HELP := {
	"body_spawn": "body_spawn MODEL X Y Z [YAW] -> a man of that model (assets/people/<id>.glb) standing there, no brain",
	"body_shoot": "body_shoot PERSON SPOT [revolver|shotgun] [RANGE] -> a perfect aim at thigh|neck|upper_arm|chest|belly|hand from RANGE m (5) in front of him; what it crossed",
	"body_blast": "body_blast PERSON [DIST] -> a stick of dynamite on the ground DIST m (3) in front of him; what it did",
	"body_treat": "body_treat PERSON tourniquet|packing|doctor -> treat him now (as the game's tending does); what it could do",
	"body_read": "body_read PERSON -> his wounds, what they crossed, what he can do, and his blood run forward from now under each treatment",
	"body_drag": "body_drag PERSON DX DZ [SECONDS] [BLEED] -> he goes limp (bleeding BLEED ml/s from the chest, 3) and is dragged DX DZ metres over SECONDS (3): the smear he leaves",
	"body_where": "body_where PERSON -> where his head, chest and pelvis are, and the blood he's lost (ml)",
	"body_meshes": "body_meshes PERSON -> each drawn mesh of him: its name, layers, shader and transparency",
	"body_probe": "body_probe PERSON SEG SIZE [parent|world] [TEXTURE] -> a plain red test decal SIZE m on his body layer at that part (world-placed, or parented to its visual)",
	"body_marks": "body_marks [PREFIX] -> the blood marks in the world (first 40; PREFIX: only textures named so, e.g. splat) and what the floor is at the saloon",
}

var _spawned := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = int(Bench.data().seed)


func _man(a: Array) -> HumanBody:
	return person(String(a[0])) if a.size() > 0 else null


func _cmd_body_spawn(a: Array) -> Dictionary:
	if a.size() < 4:
		return {"ok": false, "error": HELP.body_spawn}
	var model := StringName(a[0])
	if not PeopleBodies.has_model(model):
		return {"ok": false, "error": "no assets/people/%s.glb" % model}
	_spawned += 1
	var m := HumanBody.new()
	m.has_gun = false
	m.body_model = model
	m.rng_seed = 900 + _spawned
	m.person_id = StringName("body%d" % _spawned)
	m.name = "Body%d" % _spawned
	m.enter(street, vec(a, 1), deg_to_rad(-float(a[4])) if a.size() >= 5 else 0.0)
	await physics_frames(3)
	return {"person": String(m.person_id), "model": String(model)}


func _cmd_body_shoot(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null or a.size() < 2 or not Bench.data().spots.has(String(a[1])):
		return {"ok": false, "error": HELP.body_shoot}
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if ballistics == null:
		return {"ok": false, "error": "no Ballistics in the scene"}
	var spot: Dictionary = Bench.data().spots[String(a[1])]
	var g := Bench.gun(String(a[2]) if a.size() > 2 else "revolver")
	var r := float(a[3]) if a.size() > 3 else 5.0
	var eye := m.global_position - m.global_basis.z * r + Vector3(0, float(Bench.data().eye_height), 0)
	var before := m.wounds.size()
	Bench.fire(ballistics, eye, Bench.spot_world(m, spot), g, _rng)
	await seconds(0.5)
	var new: Array = m.wounds.slice(before)
	var crossed := {}
	for w: Dictionary in new:
		for h: Dictionary in w.get("hits", []):
			crossed[String(h.id)] = String(h.effect)
	return {"wounds": new.map(func(w: Dictionary) -> Dictionary: return Bench.wound_row(w)), "crossed": crossed,
			"on_target": (spot.aims_for as Array).filter(func(id: String) -> bool: return crossed.has(id)), "down": m.limp or m.prone}


func _cmd_body_blast(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null:
		return {"ok": false, "error": HELP.body_blast}
	var d := float(a[1]) if a.size() > 1 else 3.0
	var at := m.global_position - m.global_basis.z * d + Vector3(0, float(Bench.data().dynamite.height), 0)
	var before := m.wounds.size()
	Blast.detonate(street, at, Blast.t().tnt_per_stick)
	await seconds(0.5)
	return {"wounds": m.wounds.slice(before).map(func(w: Dictionary) -> Dictionary: return Bench.wound_row(w)),
			"severed": m.physiology.severed_segments.keys().map(func(k: StringName) -> String: return String(k)), "down": m.limp}


func _cmd_body_treat(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null or a.size() < 2 or not String(a[1]) in ["tourniquet", "packing", "doctor"]:
		return {"ok": false, "error": HELP.body_treat}
	return {"did": Bench.treat(m.physiology, String(a[1])), "bleed_ml_s": snappedf(m.physiology.total_bleed_rate(), 0.01)}


func _cmd_body_read(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null:
		return {"ok": false, "error": HELP.body_read}
	return {"model": String(m.body_model), "wounds": m.wounds.map(func(w: Dictionary) -> Dictionary: return Bench.wound_row(w)),
			"injuries": Bench.injuries(m.physiology), "abilities": Bench.abilities(m.physiology),
			"from_now": Bench.outcomes(m.physiology.to_dict(), 0.0)}


func _cmd_body_drag(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null or a.size() < 3:
		return {"ok": false, "error": HELP.body_drag}
	var by := Vector3(float(a[1]), 0.0, float(a[2]))
	var secs := float(a[3]) if a.size() > 3 else 3.0
	if m.physiology.bleeds.is_empty():
		m.physiology.apply_trace({"segment": &"chest", "track_cm": 12.0, "hits": []})
	m.physiology.bleeds[0].rate = float(a[4]) if a.size() > 4 else 3.0
	if not m.limp:
		m.go_limp()
		await seconds(2.5)
	var v := by / secs
	var frames := int(secs * Engine.physics_ticks_per_second)
	for i in frames:
		for sid: StringName in [&"chest", &"abdomen", &"pelvis"]:
			var rb := m.parts[sid] as RigidBody3D
			rb.linear_velocity = Vector3(v.x, rb.linear_velocity.y, v.z)
		await physics_frames(1)
	await seconds(0.5)
	var marks := get_tree().get_nodes_in_group(&"blood_marks").filter(func(n: Node) -> bool:
		return (n as Decal).texture_albedo.resource_path.get_file().begins_with("smear"))
	return {"smears": marks.size(), "at": arr((m.parts[&"pelvis"] as Node3D).global_position)}


func _cmd_body_marks(a: Array) -> Dictionary:
	var out := []
	var only := String(a[0]) if a.size() > 0 else ""
	for n in get_tree().get_nodes_in_group(&"blood_drying"):
		var d := n as Decal
		if d != null and d.is_inside_tree() and (only == "" or d.texture_albedo.resource_path.get_file().begins_with(only)):
			out.append([d.name, d.texture_albedo.resource_path.get_file(), arr(d.global_position), arr(d.size), d.cull_mask, d.visible])
	var floors := []
	var space := World.space(street)
	var q := PhysicsRayQueryParameters3D.create(Vector3(10.5, 2.0, 3.5), Vector3(10.5, -1.0, 3.5), Layers.WORLD)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		floors.append([str(hit.collider), arr(hit.position)])
	return {"marks": out.slice(0, 40), "count": out.size(), "floor": floors}


func _cmd_body_where(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null:
		return {"ok": false, "error": HELP.body_where}
	return {"head": arr((m.parts[&"head"] as Node3D).global_position), "chest": arr((m.parts[&"chest"] as Node3D).global_position),
			"pelvis": arr((m.parts[&"pelvis"] as Node3D).global_position), "lost_ml": snappedf(m.physiology.tuning.blood_ml - m.physiology.blood_ml, 1.0),
			"down": m.limp or m.prone, "soaks": m._pool_soaks.keys().map(func(k: StringName) -> Array:
				var d := m._pool_soaks[k] as Decal
				return [String(k), arr((m.parts[k] as Node3D).global_position), arr(d.global_position), arr(d.global_basis.y), arr(d.size), d.is_inside_tree(), d.visible])}


func _cmd_body_meshes(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null:
		return {"ok": false, "error": HELP.body_meshes}
	var out := []
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		if not mi.is_visible_in_tree():
			continue
		var mat := mi.material_override
		var sh := ""
		if mat is ShaderMaterial and (mat as ShaderMaterial).shader:
			sh = (mat as ShaderMaterial).shader.resource_path.get_file()
		out.append([String(mi.name), mi.layers, sh, mi.transparency, str(mat.get_class()) if mat else "none", mi.cast_shadow])
	return {"meshes": out}


func _cmd_body_probe(a: Array) -> Dictionary:
	var m := _man(a)
	if m == null or a.size() < 3:
		return {"ok": false, "error": HELP.body_probe}
	var sid := StringName(a[1])
	var part := m.parts[sid] as Node3D
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.0, 0.0, 1.0))
	var d := Decal.new()
	d.texture_albedo = PixelArt.blood(String(a[4]), 23, false, 32) if a.size() > 4 else ImageTexture.create_from_image(img)
	d.cull_mask = Layers.VIS_BODY
	d.size = Vector3.ONE * float(a[2])
	if a.size() > 3 and String(a[3]) == "parent":
		(m.visuals[sid] as Node3D).add_child(d)
	else:
		street.add_child(d)
	d.global_position = part.global_position
	return {"at": arr(d.global_position), "vis": arr((m.visuals[sid] as Node3D).global_position), "part": arr(part.global_position)}

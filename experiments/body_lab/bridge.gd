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

extends RefCounted
## The gore lab's sheet (docs/briefs/gore-lab.md): a row of men, one injury each, done to them at
## the start and drawn close a few seconds on (the `gore` scenario; `--render` for the frames).
## Each setup is [name, segment the close-up looks at, what's done to him].

const SETUPS := ["point_blank", "contact", "knife_throat", "knife_belly", "glass", "splinter",
		"burns", "blast_ears", "nosebleed", "jaw", "bandaged", "sling", "amputated", "scar",
		"gangrene", "wrist_drop", "dead", "handprint", "trail", "flattened", "ear_off", "nose_off", "jaw_away"]

## Where the close-up looks, by setup.
const LOOK := {"point_blank": &"chest", "contact": &"chest", "knife_throat": &"neck", "knife_belly": &"abdomen",
		"glass": &"forearm_r", "splinter": &"thigh_l", "burns": &"chest", "blast_ears": &"head",
		"nosebleed": &"head", "jaw": &"head", "bandaged": &"thigh_r", "sling": &"chest", "amputated": &"upper_arm_r",
		"scar": &"forearm_r", "gangrene": &"forearm_l", "wrist_drop": &"hand_r", "dead": &"chest",
		"handprint": &"hand_r", "trail": &"pelvis", "flattened": &"thigh_r", "ear_off": &"head", "nose_off": &"head",
		"jaw_away": &"head"}


static func _at(man: HumanBody, seg: StringName, rest: Vector3) -> Vector3:
	var part := man.parts[seg] as Node3D
	return part.global_transform * (rest - man.anatomy.segment_center(seg))


static func _shoot(man: HumanBody, seg: StringName, rest: Vector3, travelled := 5.0, energy := 300.0, kind := &"") -> Dictionary:
	var part := man.parts[seg] as Node3D
	var at := _at(man, seg, rest)
	var fwd := -man.global_basis.z
	return man.take_bullet(part, at + fwd * 0.3, -fwd, energy, 0.0057, 0.0165 if kind == &"" else 0.002, travelled, -1.0, kind)


## Do one setup to `man` (standing, at the start). `world` for anything put in the world.
static func apply(setup: String, man: HumanBody, world: Node3D) -> void:
	var p := man.physiology
	var hour: float = p.tuning.game_hour_seconds
	match setup:
		"point_blank":
			_shoot(man, &"chest", Vector3(0.05, 1.3, -0.1), 0.2, 450.0)
		"contact":
			_shoot(man, &"chest", Vector3(-0.05, 1.3, -0.1), 0.01, 450.0)
		"knife_throat":
			var neck := man.parts[&"neck"] as Node3D
			man.take_knife(neck, _at(man, &"neck", Vector3(0.06, 1.5, -0.04)), man.global_basis.z, false, 0.035, -man.global_basis.x, 0.12)
		"knife_belly":
			var belly := man.parts[&"abdomen"] as Node3D
			man.take_knife(belly, _at(man, &"abdomen", Vector3(0.04, 1.05, -0.15)), man.global_basis.z, true, 0.12)
		"glass":
			var arm := man.parts[&"forearm_r"] as Node3D
			man.take_cut(arm, arm.global_position - man.global_basis.z * 0.1, man.global_basis.z, 0.012, true)
		"splinter":
			for i in 3:
				_shoot(man, &"thigh_l", Vector3(-0.09, 0.62 + i * 0.06, -0.05), 2.0, 6.0, &"splinter")
		"burns":
			man.physiology.burn(1.0)
			man.burn_marks(1.2, man.global_position - man.global_basis.z * 2.0 + Vector3.UP)
		"blast_ears":
			p.eardrums_burst[&"r"] = true
			p.eardrums_burst[&"l"] = true
			p.airway_blood = true
		"nosebleed":
			p.blow(&"head", 40.0, RandomNumberGenerator.new())
		"jaw":
			p.jaw_broken = true
			man.signs_now()._spit_in = 0.2
		"bandaged":
			_shoot(man, &"thigh_r", Vector3(0.0975, 0.7, 0.0))
			p.apply_pressure(&"thigh_r")
			p.apply_tourniquet(&"thigh_r")
		"sling":
			p.broken[&"humerus_l"] = true
			p.apply_pressure(&"upper_arm_l")
		"amputated":
			man.amputate(&"forearm_r")
		"scar":
			var arm := man.parts[&"forearm_r"] as Node3D
			man.take_knife(arm, arm.global_position - man.global_basis.z * 0.04, man.global_basis.z, false, 0.01, Vector3.UP, 0.08)
			_shoot(man, &"forearm_r", Vector3(0.23, 0.98, -0.03))
			p.infections.clear()
			man._heal(HumanBody.HEAL_GAME_DAYS * 24.0 * hour + 1.0)
		"gangrene":
			_shoot(man, &"forearm_l", Vector3(-0.23, 0.98, -0.03))
			p.contaminate(&"forearm_l", true)
			for i in 120:
				p.step(hour)
		"wrist_drop":
			p.cut[&"radial_nerve_r"] = true
		"dead":
			_shoot(man, &"chest", Vector3(0.05, 1.3, -0.1))
			p.blood_ml = 1500.0
			p.step(0.1)
			man.signs_now()._dead_for = 1e9
		"handprint":
			var wall := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(0.1, 2.5, 2.5)
			shape.shape = box
			wall.add_child(shape)
			var mesh := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = box.size
			mesh.mesh = bm
			wall.add_child(mesh)
			world.add_child(wall)
			wall.global_position = (man.parts[&"hand_r"] as Node3D).global_position + man.global_basis.x * 0.07
			man.signs_now()._bloody["r"] = WoundSigns.PRINTS_PER_HAND
		"trail":
			_shoot(man, &"thigh_r", Vector3(0.13, 0.7, -0.03))
		"flattened":
			_shoot(man, &"thigh_r", Vector3(0.0975, 0.66, 0.0), 5.0, 475.0)
		"ear_off":
			var head := man.parts[&"head"] as Node3D
			var at := _at(man, &"head", Vector3(0.087, 1.635, 0.0))
			man.take_bullet(head, at - man.global_basis.z * 0.3, man.global_basis.z, 475.0, 0.0057)
		"nose_off":
			var head := man.parts[&"head"] as Node3D
			var at := _at(man, &"head", Vector3(0.0, 1.625, -0.09))
			man.take_bullet(head, at - man.global_basis.z * 0.3, man.global_basis.z, 120.0, 0.0057)
		"jaw_away":
			var head := man.parts[&"head"] as Node3D
			var at := _at(man, &"head", Vector3(0.0, 1.551, -0.06))
			man.take_bullet(head, at - man.global_basis.z * 0.3, man.global_basis.z, 900.0, 0.0057)


## Each tick after: a man in the trail walks on.
static func tick(setup: String, man: HumanBody, dt: float) -> void:
	# (His hand would go straight over his ear or his face: kept off it for the picture.)
	if setup in ["ear_off", "nose_off", "jaw_away"]:
		man._grab.clear()
	if setup == "trail" and not man.limp:
		man.walk_to(man.global_position + man.global_basis.x * 5.0, 1.0, dt, false)

extends TestCase
## The sound lab (experiments/sound_lab/): its scenarios read, its bridge commands load, and a
## sound placed as the game places one is described as the lab's table describes it.

const Runner := preload("res://experiments/sound_lab/runner.gd")


func test_every_scenario_has_a_definition() -> void:
	var d := Runner.data()
	var names := Runner.names()
	var guns := 0
	for place: String in d.guns.places:
		guns += (d.guns.places[place].listeners as Dictionary).size()
	check_eq(names.size(), guns * (d.guns.weapons as Array).size() + (d.scenarios as Dictionary).size(), "the guns and the rest")
	for n: String in names:
		var s := Runner.spec_of(n, d)
		check(not s.is_empty() and s.has("kind"), "%s has a kind" % n)
	check_eq(Runner.spec_of("revolver_street_20", d).weapon, "revolver", "a gun's name gives its weapon")
	check(Runner.spec_of("revolver_street_99", d).is_empty(), "an unknown listener has none")


func test_its_bridge_commands_load() -> void:
	var lab: Variant = load("res://experiments/sound_lab/bridge.gd").new()
	check(lab is BridgeLab, "bridge.gd is a BridgeLab")
	var cmds: Dictionary = (lab as BridgeLab).commands()
	for c in ["sound", "sound_list", "sound_find", "sound_inventory"]:
		check(cmds.has(c) and (lab as Object).has_method("_cmd_" + c), "it answers %s" % c)
	(lab as Node).free()


## Godot's inverse-distance model as the lab reports it: unit_size / distance, capped at max_db.
func test_it_describes_a_placed_sound() -> void:
	var world := Node3D.new()
	add_child(world)
	var ears := Node3D.new()
	world.add_child(ears)
	var p := AudioStreamPlayer3D.new()
	p.stream = SynthSounds.get_sound(&"gunshot")
	p.unit_size = 25.0
	p.max_db = 6.0
	world.add_child(p)
	p.global_position = Vector3(50, 0, 0)
	var r: Node = Runner.new()
	r._listener_node = ears
	r._street = world
	var d: Dictionary = r._describe_start(p)
	check_eq(d.sound, "gunshot", "the sound is named")
	check_near(d.godot_db_at_ears, linear_to_db(25.0 / 50.0), 0.1, "50 m at unit_size 25 is −6 dB")
	p.global_position = Vector3(5, 0, 0)
	d = r._describe_start(p)
	check_near(d.godot_db_at_ears, 6.0, 0.01, "5 m is capped at max_db")
	r.free()
	world.queue_free()

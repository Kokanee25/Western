extends TestCase
## The perception lab (experiments/perception_lab/): its scenarios read, every judged case says why,
## and its bridge commands load. The lab measures the game; this keeps it from drifting quietly.

const Runner := preload("res://experiments/perception_lab/runner.gd")


func test_every_case_is_written_out() -> void:
	var d := Runner.data()
	check(not d.is_empty(), "scenarios.json reads")
	var names := Runner.case_names()
	check(names.size() >= 20, "the five groups' cases (%d)" % names.size())
	var seen := {}
	for g: String in Runner.groups():
		for c: Dictionary in (d[g].cases as Array):
			check(not seen.has(c.name), "%s is named once" % c.name)
			seen[c.name] = true
			check(String(c.get("why", "")) != "", "%s says why its expectations are what they are" % c.name)
	for role: String in d.roles:
		check((d.bodies as Array).has(d.roles[role]), "the %s is one of the Studio's men" % role)


func test_sight_cases_judge_every_light() -> void:
	var d := Runner.data()
	for c: Dictionary in (d.sight.cases as Array):
		var ex: Dictionary = c.expect
		for light: String in d.sight.lights:
			check(ex.has(light) or ex.has("all"), "%s has an expectation for %s" % [c.name, light])


func test_its_bridge_commands_load() -> void:
	var lab: Variant = load("res://experiments/perception_lab/bridge.gd").new()
	check(lab is BridgeLab, "bridge.gd is a BridgeLab")
	var cmds: Dictionary = (lab as BridgeLab).commands()
	for c in ["perception", "perception_list", "perception_probe", "perception_known"]:
		check(cmds.has(c) and (lab as Object).has_method("_cmd_" + c), "it answers %s" % c)
	(lab as Node).free()


func test_bearing_error() -> void:
	var from := Vector3.ZERO
	check_near(Runner._bearing_error(from, Vector3(10, 0, 0), Vector3(10, 0, 0)), 0.0, 0.01, "dead on")
	check_near(Runner._bearing_error(from, Vector3(10, 0, 0), Vector3(0, 0, 10)), 90.0, 0.01, "square off")
	check_near(Runner._bearing_error(from, Vector3(10, 0, 0), Vector3(-10, 0, 0)), 180.0, 0.01, "behind")

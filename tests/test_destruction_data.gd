extends TestCase
## The masonry lab's engine-neutral data (config/destruction/, docs/destruction/destruction-spec.md;
## brief docs/briefs/masonry-lab.md): the files parse, every material has what the spec reads, the
## numbers make joints give before units (but adobe's, which crumble together), the timber is the
## game's `framing`, and the test pieces only name materials that exist.

const MATERIALS := "res://config/destruction/materials.json"
const STRUCTURES := "res://config/destruction/structures/"
const MASONRY := ["adobe", "rubble_stone", "cut_stone", "fired_brick"]
const UNIT_KEYS := ["density", "compression", "tension", "stiffness", "size"]
const KEYS := ["unit", "mortar", "wall_k", "joint_thickness", "bond", "wall", "element",
		"small_hit", "big_hit", "arch", "never", "dust_colour", "sound_set", "burns", "sources"]


func _json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	check(data is Dictionary, "%s parses" % path)
	return data if data is Dictionary else {}


func test_every_material_has_what_the_spec_reads() -> void:
	var d := _json(MATERIALS)
	check_eq(int(d.get("format", 0)), 1, "format 1")
	var mats: Dictionary = d.get("materials", {})
	for id in MASONRY + ["timber_in_masonry"]:
		check(mats.has(id), "%s is listed" % id)
	var sources: Dictionary = d.get("sources", {})
	for id in MASONRY:
		var m: Dictionary = mats.get(id, {})
		for k in KEYS:
			check(m.has(k), "%s has %s" % [id, k])
		for k in UNIT_KEYS:
			check(m.unit.has(k), "%s's unit has %s" % [id, k])
		check_eq(m.unit.size.size(), 3, "%s's unit is [along, high, deep]" % id)
		check(d.mortars.has(m.mortar), "%s's mortar %s exists" % [id, m.mortar])
		check(not bool(m.burns), "%s doesn't burn" % id)
		for s in m.sources:
			check(sources.has(s), "%s's source %s is listed" % [id, s])
	for k in ["min_bearing_share", "crack_warn", "crack_wide", "blast_dynamic_factor"]:
		check(d.solver.has(k), "the solver's %s" % k)


## destruction-spec.md section 5: a joint gives under ~tension x joint / face of push; a unit
## cracks at 1.33 x its tension x (deep / along)². Stone and brick break along their mortar; adobe
## units and joints are about as weak as each other, so it crumbles.
func test_joints_give_before_units_but_adobe_crumbles() -> void:
	var d := _json(MATERIALS)
	for id in MASONRY:
		var m: Dictionary = d.materials[id]
		var mortar: Dictionary = d.mortars[m.mortar]
		var along := float(m.unit.size[0]) * float(m.element.units_along)
		var high := float(m.unit.size[1]) * float(m.element.units_high)
		var deep := float(m.unit.size[2])
		var face := along * high
		var bonded := along * deep + high * deep  # one bed and one head joint
		var joint_p := float(mortar.tension) * bonded / face
		var unit_p := 1.33 * float(m.unit.tension) * pow(deep / float(m.unit.size[0]), 2.0)
		if id == "adobe":
			check(unit_p < 3.0 * joint_p, "adobe's units crack near its joints' push (%.0f vs %.0f Pa)" % [unit_p, joint_p])
		elif id != "fired_brick":  # a brick clump's crack is the clump splitting at its own joints
			check(unit_p > 5.0 * joint_p, "%s breaks at the mortar (unit %.0f Pa, joint %.0f Pa)" % [id, unit_p, joint_p])


func test_timber_in_masonry_is_the_games_framing() -> void:
	var t: Dictionary = _json(MATERIALS).materials.timber_in_masonry.timber
	var framing: Dictionary = TimberTuning.new().wood(&"framing")
	for k in ["density", "bending", "compression", "stiffness"]:
		check_near(float(t[k]), float(framing[k]), 1e-6 * float(framing[k]), "timber %s as framing's" % k)


func test_the_test_pieces_name_real_materials_and_bear_their_lintels() -> void:
	var d := _json(MATERIALS)
	var mats: Dictionary = d.materials
	var bearing_min := float(mats.timber_in_masonry.bearing_min)
	for file in ["wall_panel.json", "wall_door_lintel.json"]:
		var s := _json(STRUCTURES + file)
		check_eq(int(s.get("format", 0)), 1, "%s format 1" % file)
		for id in s.get("swap_materials", []):
			check(mats.has(id), "%s swaps to %s, which exists" % [file, id])
		var timbers := {}
		for t in s.timbers:
			check(mats.has(t.material), "%s's %s is a material" % [file, t.id])
			timbers[t.id] = t
		for w in s.walls:
			check(mats.has(w.material), "%s's wall %s is a material" % [file, w.id])
			var length := Vector2(w.to[0] - w.from[0], w.to[1] - w.from[1]).length()
			var thick := float(w.get("thick", mats[w.material].wall.thick_typical))
			for o in w.openings:
				check(o.x[0] >= 0.0 and o.x[1] <= length and o.y[1] <= float(w.top), "%s's %s inside its wall" % [file, o.id])
				if o.has("lintel"):
					var t: Dictionary = timbers.get(o.lintel, {})
					check(not t.is_empty(), "%s's %s has its lintel" % [file, o.id])
					if t.is_empty():
						continue
					check(o.x[0] - t.x[0] >= bearing_min - 1e-6 and t.x[1] - o.x[1] >= bearing_min - 1e-6,
							"%s's lintel bears at least %.2f m each side" % [file, bearing_min])
					check(float(t.section[1]) * float(t.pieces) <= thick + 1e-6, "%s's lintel fits the wall" % file)

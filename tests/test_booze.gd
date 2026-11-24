extends TestCase
## The game's own booze (#1222, docs/briefs/booze.md; tools/props/booze.py): every bottle kit wears each of
## its brands' labels (its `variants`, drawn from glb:booze_bottles on the one label sheet), a dressing
## entry names the brand it places (`variant`, a row's `variants`), and the stencilled casks are the plain
## casks' members with the stencil laid on their heads.

const BOTTLES := [&"liquor_quart", &"liquor_quart_flint", &"liquor_flask", &"bitters_bottle", &"bitters_cabin",
		&"gin_case_bottle", &"wine_bottle", &"beer_bottle", &"patent_medicine_bottle", &"ginger_beer_bottle"]
const CASKS := {&"whiskey_barrel_lowry": &"whiskey_barrel", &"whiskey_barrel_burnt_hollow": &"whiskey_barrel",
		&"whiskey_barrel_brandauer": &"whiskey_barrel", &"beer_keg_riedl": &"beer_keg", &"beer_keg_side_riedl": &"beer_keg_side"}

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


## The kit's label part (its "%d" look) for variant n.
func _label_part(def: Dictionary, n: int) -> String:
	for key: String in def.get("looks", {}):
		if key.contains("%d"):
			return key % n
	return ""


func _has_part(g: GlassProp, part: String) -> bool:
	for mi: MeshInstance3D in g.model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name) == part and mi.mesh != null:
			return true
	return false


func test_every_bottle_wears_each_of_its_brands() -> void:
	var total := 0
	for id: StringName in BOTTLES:
		var def := PropKit.definition(id)
		var n := int(def.get("variants", 0))
		check(n > 0 and n == (def.get("brands", []) as Array).size(), "%s: a label a brand (%d)" % [id, n])
		total += n
		for v in n:
			var g := PropKit.make(id) as GlassProp
			g.variant = v
			world.add_child(g)
			check(_has_part(g, _label_part(def, v)), "%s wears label %d (%s)" % [id, v, def.brands[v]])
			# One label part only: the others aren't drawn.
			check(not _has_part(g, _label_part(def, (v + 1) % n)) or n == 1, "%s draws only its own label" % id)
			g.queue_free()
	# The 53 approved (#1223): 50 bottled brands (Lowry's a barrel head only; "Nervous Twitter" a line on
	# Haskett's and Quill's, "Rectified From High Wines" on Brandauer's head), three also in a pint flask.
	check_eq(total, 50 + 3, "every brand's label on a bottle")


func test_a_dressing_entry_names_its_brand() -> void:
	var placed := PropDressing.place(world, [
		{"id": "one", "kit": "liquor_quart", "variant": 4, "at": [0.0, 0.0, 0.0]},
		{"id": "shelf", "at": [1.0, 0.0, 0.0], "row": {"kits": ["bitters_bottle", "beer_bottle"], "variants": [2, 5], "count": 4, "step": [0, 0, 0.2]}},
	], 0.0)
	var one := placed["one"] as GlassProp
	check_eq(one.variant, 4, "the entry's variant")
	check(_has_part(one, "LabelQuart4"), "it wears that label")
	check_eq((placed["shelf_2"] as GlassProp).variant, 2, "a row's variants in turn with its kits")
	check_eq((placed["shelf_3"] as GlassProp).variant, 5, "a row's variants in turn with its kits")
	check(_has_part(placed["shelf_3"], "LabelBeer5"), "the beer wears its brand's label")


func test_the_stencilled_casks_are_the_casks_with_their_heads_lettered() -> void:
	for id: StringName in CASKS:
		var def := PropKit.definition(id)
		var base := PropKit.definition(CASKS[id])
		check_eq(PropKit.expand(def).size(), PropKit.expand(base).size(), "%s: the same members as %s" % [id, CASKS[id]])
		var dressed := 0
		for m: Dictionary in def.members:
			for d: Dictionary in m.get("dress", []):
				if String(d.get("look", "")) == "pbr:booze_labels":
					dressed += 1
					check(PropKit.model_part("booze_bottles", String(d.draw.part)) != null, "%s: its stencil part %s is in the model" % [id, d.draw.part])
		check(dressed >= 1, "%s: its head lettered" % id)
		check_eq(def.get("contents", {}), base.get("contents", {}), "%s holds what %s holds" % [id, CASKS[id]])
	var cask := PropKit.spawn(&"whiskey_barrel_burnt_hollow")
	world.add_child(cask)
	await physics_frames(2)
	check(is_instance_valid(cask) and cask.get_child_count() > 0, "a stencilled barrel builds")

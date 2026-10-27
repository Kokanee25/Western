class_name TownLife
extends Node3D
## The people of the test street and their day. The storekeeper minds his counter and the barkeep
## his bar from the start (wiping it down when it's quiet); a while later three riders come in from the west (Brody, a cool hand
## who leads; Lyle, a hothead; and the Kid, green and jumpy), drink, and two of them go and lean on
## the storekeeper. Nobody's an enemy: what happens is up to you. U brings them in now.

## Seconds before the gang rides in.
@export var gang_arrives := 45.0
## How long they drink before trouble, and how long they lean on the storekeeper.
@export var drink_seconds := 40.0
@export var harass_seconds := 50.0
## Their second drink, before they ride out.
@export var after_seconds := 40.0

var places := Waypoints.test_street()
var storekeeper: HumanBody
var barkeep: HumanBody
var widow: HumanBody
var sheriff: HumanBody
var doctor: HumanBody
var colter: HumanBody
var miner: HumanBody
var working_girl: HumanBody
var rancher: HumanBody
var gang: Array[HumanBody] = []
var _t := 0.0
var _arrived := false

const GANG := [
	{"id": &"brody", "temper": 0.2, "nerve": 0.95, "proud": true, "leads": true, "bar": &"bar_0", "model": &"bold_cowboy_s3_talking",
			"shirt": Color(0.5, 0.46, 0.4), "coat": Color(0.2, 0.17, 0.14, 1.0), "hat": Color(0.12, 0.1, 0.09)},
	{"id": &"lyle", "temper": 0.9, "nerve": 0.7, "proud": true, "bar": &"bar_1", "model": &"hothead_lyle_s2_talking",
			"shirt": Color(0.55, 0.28, 0.22), "coat": Color(0.0, 0.0, 0.0, 0.0), "hat": Color(0.32, 0.26, 0.18)},
	{"id": &"kid", "temper": 0.45, "nerve": 0.3, "proud": false, "bar": &"bar_2", "model": &"young_drifter_s3_talking",
			"shirt": Color(0.62, 0.62, 0.56), "coat": Color(0.0, 0.0, 0.0, 0.0), "hat": Color(0.45, 0.38, 0.28)},
]


func _ready() -> void:
	add_to_group(&"town_life")
	# What boots, spills and blood leave on the boards (deferred: the town's still being put together).
	(func() -> void: FloorMarks.ensure(get_parent())).call_deferred()
	_spawn_townsfolk.call_deferred()


func _process(delta: float) -> void:
	var t := Prof.start()
	_process_step(delta)
	Prof.stop(&"town_life", t)


func _process_step(delta: float) -> void:
	if not _arrived:
		_t += delta
		if _t >= gang_arrives or Input.is_action_just_pressed(&"debug_gang"):
			bring_gang()
	elif Input.is_action_just_pressed(&"debug_gang") and gang.all(func(g) -> bool: return not is_instance_valid(g)):
		bring_gang()


func _spawn_townsfolk() -> void:
	storekeeper = _civilian(&"storekeeper", &"store_keeper", places.at(&"store_counter") + TownLayout.facing_toward(&"Store", Vector3(-1.0, 0.0, 0.0)) + Vector3.UP * 1.4, 101,
			Color(0.8, 0.78, 0.7), Color(0.3, 0.3, 0.32), &"storekeeper_s1_talking")
	barkeep = _civilian(&"barkeep", &"behind_bar", places.at(&"bar_1") + TownLayout.facing_toward(&"Saloon", Vector3(-1.0, 0.0, 0.0)) + Vector3.UP * 1.4, 102,
			Color(0.85, 0.84, 0.8), Color(0.15, 0.14, 0.13), &"barkeep_s2_talking")
	_give_cloth.call_deferred(barkeep)
	widow = _civilian(&"widow", &"store_aisle", places.at(&"store_counter") + Vector3.UP * 1.4, 103,
			Color(0.55, 0.28, 0.2), Color(0, 0, 0, 0), &"widow_s6_talking")
	# The sheriff (the Studio's sean_s2, Sean as him) in front of his jail, watching the street. A
	# civilian's mind for now: no gun, no law yet.
	sheriff = _civilian(&"sheriff", &"jail_front", TownLayout.point(&"StreetDressing/Jail", Vector3(3.2, 1.4, -9.0)), 104,
			Color(0.85, 0.8, 0.7), Color(0.2, 0.2, 0.22), &"sean_s3_talking")
	# The doctor (the Studio's doctor_s1) in front of his office, watching the street. A civilian's
	# mind for now: his doctoring is to come.
	doctor = _civilian(&"doctor", &"doctor_front", TownLayout.point(&"Doctor", Vector3(3.0, 1.4, -9.0)), 105,
			Color(0.85, 0.8, 0.7), Color(0.4, 0.15, 0.15), &"doctor_s2_talking")
	# His building is the node "Doctor": named so, he'd be renamed by the engine, differently each
	# run, and a bug report's replay couldn't find him again.
	doctor.name = "TheDoctor"
	# The fourth Colter (the Studio's colter_rider_s1, the one who "knows" you, DESIGN.md §6) waiting
	# in front of the livery. A civilian's mind for now, unarmed: riding with the gang is to come.
	colter = _civilian(&"colter", &"livery_front", TownLayout.point(&"StreetDressing/Livery", Vector3(5.0, 1.4, -9.0)), 106,
			Color(0.6, 0.15, 0.12), Color(0.55, 0.42, 0.28), &"colter_rider_s2_talking")
	# A miner (the Studio's miner_s4, a background one-off; Sean, 2026-10-23) in front of the assay
	# office, where the mine's ore is weighed. A civilian's mind, unarmed.
	miner = _civilian(&"miner", &"assay_front", TownLayout.point(&"StreetDressing/Assay", Vector3(3.0, 1.4, -9.0)), 107,
			Color(0.3, 0.42, 0.6), Color(0, 0, 0, 0), &"miner_s4_talking")
	# The working girl upstairs at the saloon (the Studio's working_girl_s2; DESIGN.md §5), downstairs
	# for now by its front windows, looking into the room (Sean, 2026-10-24). A civilian's mind.
	working_girl = _civilian(&"working_girl", &"saloon_window", TownLayout.point(&"Saloon", Vector3(5.0, 1.4, 4.5)), 108,
			Color(0.9, 0.86, 0.78), Color(0.62, 0.42, 0.4), &"working_girl_s2_talking")
	# The Mexican rancher (the Studio's mexican_rancher_s1; DESIGN.md mission 4, the vaquero's horses)
	# along the livery's front from the fourth Colter, looking in at its doors. A civilian's mind.
	rancher = _civilian(&"rancher", &"livery_side", TownLayout.point(&"StreetDressing/Livery", Vector3(8.5, 1.4, 2.0)), 109,
			Color(0.88, 0.82, 0.7), Color(0.45, 0.3, 0.2), &"mexican_rancher_s1_talking")


func _civilian(id: StringName, at: StringName, faces: Vector3, seed_value: int, shirt: Color, vest: Color,
		model := &"outlaw") -> HumanBody:
	var man := HumanBody.new()
	man.body_model = model
	man.name = String(id).capitalize()
	man.person_id = id
	man.rng_seed = seed_value
	man.has_gun = false
	man.shirt_color = shirt
	man.vest_color = vest
	man.hat_color = Color(0, 0, 0, 0)
	man.bandana_color = Color(0, 0, 0, 0)
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = places.at(at)
	brain.faces = faces
	man.add_child(brain)
	man.enter(get_parent(), places.at(at), HumanBody.yaw_toward(places.at(at), faces))
	man.face(faces)
	return man


## The barkeep's bar cloth over his shoulder and his mop and bucket in their corner, and his chores:
## mopping the floor when it's dirty, wiping the bar when it's quiet (MopFloor, WipeBar;
## docs/briefs/barkeep-rag.md, mopping.md).
func _give_cloth(man: HumanBody) -> void:
	if not is_instance_valid(man) or not man.is_inside_tree():
		return
	var cloth := PropKit.make(&"bar_cloth") as ClothProp
	get_parent().add_child(cloth)
	await get_tree().physics_frame
	if not is_instance_valid(man) or not is_instance_valid(cloth):
		return
	cloth.hang_on(man, "l")
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	if brain == null:
		return
	var wipe := WipeBar.new(man, cloth, brain.post, brain.faces)
	wipe.places = places
	# His mop and bucket in the corner behind the bar's near end; he mops the floor when it's dirty
	# and quiet (MopFloor; docs/briefs/mopping.md), before he'd wipe the bar.
	var home := TownLayout.point(&"Saloon", MOP_CORNER)
	var bucket := PropKit.make(&"mop_bucket") as MopBucket
	get_parent().add_child(bucket)
	bucket.global_position = home
	var mop := PropKit.make(&"mop") as MopProp
	get_parent().add_child(mop)
	await get_tree().physics_frame
	if not is_instance_valid(man):
		return
	var lean := TownLayout.facing_toward(&"Saloon", Vector3(0.12, 1.0, 0.1))
	mop.stand_at(home + TownLayout.facing_toward(&"Saloon", Vector3(0.18, 0.0, 0.2)) + Vector3.UP * 0.06, lean)
	var mopping := MopFloor.new(man, mop, bucket, brain.post, home)
	mopping.places = places
	mopping.home_lean = lean
	mopping.outside = TownLayout.point(&"Saloon", Vector3(5.0, 0.0, -4.5))
	brain.chores = [mopping, wipe]


## Where the barkeep's mop and bucket stand (the saloon's space: the corner behind the bar's near end).
const MOP_CORNER := Vector3(9.25, 0.78, 1.3)


## Three riders in from the west, a few paces apart, with a day planned (`only`: just these).
func bring_gang(only: Array = []) -> void:
	_arrived = true
	gang.clear()
	var ids: Array[StringName] = []
	for g: Dictionary in GANG:
		ids.append(g.id)
	for i in GANG.size():
		var g: Dictionary = GANG[i]
		if not only.is_empty() and not only.has(g.id):
			continue
		var man := HumanBody.new()
		man.name = String(g.id).capitalize()
		man.person_id = g.id
		man.rng_seed = 200 + i
		man.shirt_color = g.shirt
		man.coat_color = g.coat
		man.hat_color = g.hat
		man.body_model = g.get("model", man.body_model)
		var brain := OutlawBrain.new()
		brain.name = "Brain"
		brain.temper = g.temper
		brain.nerve = g.nerve
		brain.proud = g.proud
		brain.leads = g.get("leads", false)
		var friends: Array[StringName] = []
		for other in ids:
			if other != g.id:
				friends.append(other)
		brain.friends = friends
		brain.places = places
		brain.bar_spot = g.bar
		brain.agenda = _plan(g, i)
		man.add_child(brain)
		# Facing east, into town.
		man.enter(get_parent(), places.at(&"west_edge") + Vector3(-1.6 * i, 0.0, 0.6 * (i % 2)), -PI * 0.5)
		gang.append(man)


## The day: in to the saloon and a drink; then Lyle and the Kid go over to the store and lean on
## the storekeeper (Lyle draws on him) while Brody stays at the bar; a last drink; out west.
func _plan(g: Dictionary, i: int) -> Array[Dictionary]:
	var bar: StringName = g.bar
	var face := places.at(bar) + TownLayout.facing_toward(&"Saloon", Vector3(2.0, 0.0, 0.0)) + Vector3.UP * 1.2
	var plan: Array[Dictionary] = [
		{"do": &"go", "to": bar},
		{"do": &"drink", "seconds": drink_seconds + i * 2.0, "face": face},
	]
	if g.id == &"brody":
		# While the other two are at the store he takes his whiskey to a card table and sits back with
		# it (Seating: the saloon's kit chairs; Sean, 2026-10-22).
		plan.append({"do": &"drink", "seconds": harass_seconds + 25.0, "face": face, "first": false, "sit": true})
	else:
		var spot := &"store_counter" if g.id == &"lyle" else &"store_aisle"
		plan.append({"do": &"go", "to": spot})
		plan.append({"do": &"harass", "who": storekeeper, "seconds": harass_seconds, "rough": g.id == &"lyle",
				"draw_after": 14.0})
		plan.append({"do": &"go", "to": bar})
	plan.append({"do": &"drink", "seconds": after_seconds, "face": face, "first": false})
	plan.append({"do": &"leave"})
	return plan

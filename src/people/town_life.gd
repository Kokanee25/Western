class_name TownLife
extends Node3D
## The people of the test street and their day. The storekeeper minds his counter and the barkeep
## his bar from the start; a while later three riders come in from the west (Brody, a cool hand
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
var gang: Array[HumanBody] = []
var _t := 0.0
var _arrived := false

const GANG := [
	{"id": &"brody", "temper": 0.2, "nerve": 0.95, "proud": true, "bar": &"bar_0",
			"shirt": Color(0.5, 0.46, 0.4), "coat": Color(0.2, 0.17, 0.14, 1.0), "hat": Color(0.12, 0.1, 0.09)},
	{"id": &"lyle", "temper": 0.9, "nerve": 0.7, "proud": true, "bar": &"bar_1",
			"shirt": Color(0.55, 0.28, 0.22), "coat": Color(0.0, 0.0, 0.0, 0.0), "hat": Color(0.32, 0.26, 0.18)},
	{"id": &"kid", "temper": 0.45, "nerve": 0.3, "proud": false, "bar": &"bar_2",
			"shirt": Color(0.62, 0.62, 0.56), "coat": Color(0.0, 0.0, 0.0, 0.0), "hat": Color(0.45, 0.38, 0.28)},
]


func _ready() -> void:
	_spawn_townsfolk.call_deferred()


func _process(delta: float) -> void:
	if not _arrived:
		_t += delta
		if _t >= gang_arrives or Input.is_action_just_pressed(&"debug_gang"):
			bring_gang()
	elif Input.is_action_just_pressed(&"debug_gang") and gang.all(func(g) -> bool: return not is_instance_valid(g)):
		bring_gang()


func _spawn_townsfolk() -> void:
	storekeeper = _civilian(&"storekeeper", &"store_keeper", places.at(&"store_counter") + Vector3(-1.0, 1.4, 0.0), 101,
			Color(0.8, 0.78, 0.7), Color(0.3, 0.3, 0.32))
	barkeep = _civilian(&"barkeep", &"behind_bar", places.at(&"bar_1") + Vector3(1.0, 1.4, 0.0), 102,
			Color(0.85, 0.84, 0.8), Color(0.15, 0.14, 0.13))


func _civilian(id: StringName, at: StringName, faces: Vector3, seed_value: int, shirt: Color, vest: Color) -> HumanBody:
	var man := HumanBody.new()
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
	get_parent().add_child(man)
	man.global_position = places.at(at)
	man.face(faces)
	return man


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
		var brain := OutlawBrain.new()
		brain.name = "Brain"
		brain.temper = g.temper
		brain.nerve = g.nerve
		brain.proud = g.proud
		var friends: Array[StringName] = []
		for other in ids:
			if other != g.id:
				friends.append(other)
		brain.friends = friends
		brain.places = places
		brain.bar_spot = g.bar
		brain.agenda = _plan(g, i)
		man.add_child(brain)
		get_parent().add_child(man)
		man.global_position = places.at(&"west_edge") + Vector3(-1.6 * i, 0.0, 0.6 * (i % 2))
		man.rotation.y = -PI * 0.5  # facing east, into town
		gang.append(man)


## The day: in to the saloon and a drink; then Lyle and the Kid go over to the store and lean on
## the storekeeper (Lyle draws on him) while Brody stays at the bar; a last drink; out west.
func _plan(g: Dictionary, i: int) -> Array[Dictionary]:
	var bar: StringName = g.bar
	var face := places.at(bar) + Vector3(-2.0, 1.2, 0.0)
	var plan: Array[Dictionary] = [
		{"do": &"go", "to": bar},
		{"do": &"drink", "seconds": drink_seconds + i * 2.0, "face": face},
	]
	if g.id == &"brody":
		plan.append({"do": &"drink", "seconds": harass_seconds + 25.0, "face": face, "first": false})
	else:
		var spot := &"store_counter" if g.id == &"lyle" else &"store_aisle"
		plan.append({"do": &"go", "to": spot})
		plan.append({"do": &"harass", "who": storekeeper, "seconds": harass_seconds, "rough": g.id == &"lyle",
				"draw_after": 14.0})
		plan.append({"do": &"go", "to": bar})
	plan.append({"do": &"drink", "seconds": after_seconds, "face": face, "first": false})
	plan.append({"do": &"leave"})
	return plan

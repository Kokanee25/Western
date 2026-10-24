class_name StreetMatch
## The street painting's shot, staged in the test street: docs/concept/street-golden-hour.png.
## You stand in the street at golden hour with the revolver out at the hip, looking down the street
## into the low sun; the near false front with its porch and boardwalk is on your left, the far side
## of the street (in shadow, backlit) on your right. The test street runs east-west and the sun sets
## in the west, a little south (DayCycle), so you look west and the north side (the store's) is the
## lit left-hand side, as the painting has it. tools/screenshots.gd view `shot_match_street`,
## tools/judge.py compares it with the painting (next to `shot_match_saloon`).

## The hour: the sun a hand's width over the horizon, as in the painting.
const HOUR := 17.72
## Where your feet are, and the point you look at, in the saloon's own space (its front-left
## corner the origin, its front facing -Z), so the shot follows the saloon wherever the town's
## layout puts it (config/town.json). Fitted by eye to the painting (2026-10-02, on the old street):
## the street's vanishing point ~55% across and a little below the middle, the saloon's porch and
## big board down the left; you stand in the street off its far end, 6 m out from its front.
const FEET_IN_SALOON := Vector3(15.5, 0.0, -9.6)
const LOOK_IN_SALOON := Vector3(-35.3, 4.6, -1.2)
## The painting's lens: about 62° top to bottom (the game's own is 75°).
const FOV := 62.0
## Eye height above the feet (the player's camera stands 1.6 m up).
const EYE_HEIGHT := 1.6


## Get the street ready for the picture: the outlaw on the range and the gang out of the way, the
## townsfolk calm.
static func stage(street: Node3D) -> void:
	var spawner := street.find_child("OutlawSpawn", true, false)
	if spawner and spawner.get(&"outlaw"):
		(spawner.get(&"outlaw") as Node).queue_free()
	var town := street.find_child("TownLife", true, false)
	if town:
		town.set(&"gang_arrives", 1e9)
	# The townsfolk at their ease: the gun at your hip would otherwise be a gun on a man down the
	# street (his hands up and "Don't shoot!" in the picture).
	for f: Array in StreetDressing.FOLK:
		var man := street.find_child(f[0], true, false)
		var brain := man.get_node_or_null(^"Brain") if man else null
		if brain:
			brain.process_mode = Node.PROCESS_MODE_DISABLED
	_extras(street)


## The painting's street is busy: people under every porch and a crowd down the far end. Staged
## for the picture only, like the saloon shot's extras (no brains; the street in play keeps its
## own townsfolk, StreetDressing.FOLK, within the people budget). StreetDressing.FOLK's layout:
## [name, where on the old street, a point he faces, pose, shirt, vest, coat, hat, look]; all
## clear of the road's middle and the gang's way in (z -9). (2026-10-13, Sean: "the scenes are
## empty".)
const EXTRAS := [
	["StoreManB", Vector3(-16.9, 0.38, -1.05), Vector3(-12.0, 1.5, -6.0), &"stand", Color(0.66, 0.58, 0.46), Color(0.32, 0.12, 0.09),
			Color(0, 0, 0, 0), Color(0.2, 0.15, 0.1), {"hair": Color(0.24, 0.16, 0.09), "moustache": &"handlebar", "beard": &"none", "age": 0.45}],
	["RoadMan", Vector3(-25.5, 0.0, -6.2), Vector3(0.0, 1.5, -6.5), &"stand", Color(0.8, 0.74, 0.62), Color(0.16, 0.12, 0.1),
			Color(0.42, 0.3, 0.18, 1.0), Color(0.3, 0.22, 0.14), {"hair": Color(0.16, 0.11, 0.07), "moustache": &"walrus", "beard": &"stubble", "age": 0.5}],
	["FarManC", Vector3(-41.0, 0.0, -6.4), Vector3(-41.0, 1.5, -12.0), &"stand", Color(0.86, 0.84, 0.78), Color(0.22, 0.16, 0.11),
			Color(0, 0, 0, 0), Color(0.16, 0.12, 0.09), {"hair": Color(0.2, 0.14, 0.09), "moustache": &"trim", "beard": &"none", "age": 0.4}],
	["FarManD", Vector3(-44.5, 0.0, -11.6), Vector3(-30.0, 1.5, -11.0), &"stand", Color(0.58, 0.48, 0.36), Color(0.14, 0.12, 0.1),
			Color(0.3, 0.24, 0.17, 1.0), Color(0.12, 0.1, 0.08), {"hair": Color(0.12, 0.09, 0.07), "moustache": &"walrus", "beard": &"full", "age": 0.6}],
	["FarManE", Vector3(-48.0, 0.0, -6.0), Vector3(-60.0, 1.5, -6.5), &"stand", Color(0.72, 0.66, 0.54), Color(0.26, 0.2, 0.13),
			Color(0, 0, 0, 0), Color(0.22, 0.16, 0.1), {"hair": Color(0.28, 0.18, 0.1), "moustache": &"handlebar", "beard": &"stubble", "age": 0.35}],
]


## Nearer, placed in the world (your feet are at x 20.5 looking down the street to -x; the saloon's
## side is +z): two men talking at the road's edge on the saloon's side, one on the jail's side
## watching you come. [name, where, a point he faces, pose, shirt, vest, coat, hat, look]
const NEAR_EXTRAS := [
	["TalkerA", Vector3(9.0, 0.0, -5.6), Vector3(8.1, 1.5, -6.2), &"stand", Color(0.84, 0.8, 0.7), Color(0.28, 0.2, 0.13),
			Color(0, 0, 0, 0), Color(0.24, 0.18, 0.12), {"hair": Color(0.2, 0.13, 0.08), "moustache": &"walrus", "beard": &"stubble", "age": 0.5}],
	["TalkerB", Vector3(8.1, 0.0, -6.2), Vector3(9.0, 1.5, -5.6), &"stand", Color(0.6, 0.52, 0.4), Color(0.16, 0.12, 0.1),
			Color(0.34, 0.25, 0.16, 1.0), Color(0.14, 0.11, 0.09), {"hair": Color(0.12, 0.09, 0.07), "moustache": &"handlebar", "beard": &"none", "age": 0.45}],
	["JailSideMan", Vector3(3.0, 0.0, -12.4), Vector3(20.0, 1.5, -10.0), &"stand", Color(0.76, 0.7, 0.58), Color(0.2, 0.15, 0.1),
			Color(0.4, 0.3, 0.2, 1.0), Color(0.28, 0.2, 0.13), {"hair": Color(0.18, 0.12, 0.08), "moustache": &"walrus", "beard": &"full", "age": 0.6}],
]


static func _extras(street: Node3D) -> void:
	for i in NEAR_EXTRAS.size():
		var e: Array = NEAR_EXTRAS[i]
		var near := _extra(street, e, 351 + i)
		if near:
			near.global_position = e[1]
			near.face(e[2])
			near.set_pose(e[3])
	for i in EXTRAS.size():
		var e: Array = EXTRAS[i]
		var man := _extra(street, e, 301 + i)
		if man:
			man.global_position = StreetDressing.post_of(e)
			man.face(TownLayout.carry(e[1]) * (e[2] as Vector3))
			man.set_pose(e[3])


## A staged man of EXTRAS' layout in the street, dressed, no brain; null if he's there already.
static func _extra(street: Node3D, e: Array, seed: int) -> HumanBody:
	if street.find_child(e[0], true, false):
		return null
	var man := HumanBody.new()
	man.name = e[0]
	man.person_id = StringName(String(e[0]).to_snake_case())
	man.rng_seed = seed
	man.has_gun = false
	man.body_model = ShotMatch.STUDIO_FOLK[seed % ShotMatch.STUDIO_FOLK.size()]  # a Studio man (Sean, 2026-10-24)
	man.shirt_color = e[4]
	man.vest_color = e[5]
	man.coat_color = e[6]
	man.hat_color = e[7]
	man.bandana_color = Color(0, 0, 0, 0)
	man.look = e[8]
	street.add_child(man)
	return man


## Your eye and the point you look at, in the world.
static func camera_transform() -> Transform3D:
	var eye := feet() + Vector3.UP * EYE_HEIGHT
	return Transform3D(Basis.looking_at(look() - eye, Vector3.UP), eye)


## Where your feet are in the street, and the point you look at.
static func feet() -> Vector3:
	return TownLayout.transform_of(&"Saloon") * FEET_IN_SALOON


static func look() -> Vector3:
	return TownLayout.transform_of(&"Saloon") * LOOK_IN_SALOON


## Stand the player at the painting's viewpoint with the revolver out at the hip. The gun stays in
## hand (the painting shows it); the gun in hand keeps the camera level on the head and eases the
## lens to its resting fov, so the turn and pitch go on the player and head, and the lens on the gun.
static func frame_camera(player: Player) -> void:
	player.global_position = feet()
	player.velocity = Vector3.ZERO
	var t := camera_transform()
	var fwd := -t.basis.z
	player.rotation = Vector3(0.0, atan2(-fwd.x, -fwd.z), 0.0)
	var was := player.input_enabled
	player.input_enabled = true
	player.add_look(Vector2(0.0, rad_to_deg(asin(fwd.y)) - player.get_pitch_degrees()))
	player.input_enabled = was
	player.camera.transform = Transform3D.IDENTITY  # a staged view may have moved it on the head
	for w: WeaponViewmodel in player.weapons:
		w._base_fov = FOV
	player.camera.fov = FOV

class_name StreetMatch
## The street painting's shot, staged in the test street: docs/concept/street-golden-hour.png.
## You stand in the street at golden hour with the revolver out at the hip, looking down the street
## into the low sun; the near false front with its porch and boardwalk is on your left, the far side
## of the street (in shadow, backlit) on your right. The test street runs east-west and the sun sets
## in the west, a little south (DayCycle), so you look west and the north side (the store's) is the
## lit left-hand side, as the painting has it. tools/screenshots.gd view `shot_match_street`,
## tools/judge.py compares it with the painting (next to `shot_match_saloon`).

## The hour: the sun a hand's width over the horizon, as in the painting.
const HOUR := 17.9
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

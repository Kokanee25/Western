class_name StreetMatch
## The street painting's shot, staged in the test street: docs/concept/street-golden-hour.png.
## You stand in the street at golden hour with the revolver out at the hip, looking down the street
## into the low sun; the near false front with its porch and boardwalk is on your left, the far side
## of the street (in shadow, backlit) on your right. The test street runs east-west and the sun sets
## in the west, a little south (DayCycle), so you look west and the north side (the store's) is the
## lit left-hand side, as the painting has it. tools/screenshots.gd view `shot_match_street`,
## tools/judge.py compares it with the painting (next to `shot_match_saloon`).

## The hour: the sun a hand's width over the horizon, as in the painting.
const HOUR := 18.05
## Where your feet are, and the point you look at (world space, test street).
## Fitted by eye to the painting (2026-10-01): the street's vanishing point ~59% across and a
## little below the middle, the near false front's porch filling the left third.
const FEET := Vector3(7.6, 0.0, -4.6)
const LOOK := Vector3(-41.5, 5.1, 4.86)
## The painting's lens: about 62° top to bottom (the game's own is 75°).
const FOV := 62.0
## Eye height above the feet (the player's camera stands 1.6 m up).
const EYE_HEIGHT := 1.6


## Get the street ready for the picture: the outlaw on the range and the gang out of the way.
static func stage(street: Node3D) -> void:
	var spawner := street.find_child("OutlawSpawn", true, false)
	if spawner and spawner.get(&"outlaw"):
		(spawner.get(&"outlaw") as Node).queue_free()
	var town := street.find_child("TownLife", true, false)
	if town:
		town.set(&"gang_arrives", 1e9)


## Your eye and the point you look at, in the world.
static func camera_transform() -> Transform3D:
	var eye := FEET + Vector3.UP * EYE_HEIGHT
	return Transform3D(Basis.looking_at(LOOK - eye, Vector3.UP), eye)


## Stand the player at the painting's viewpoint with the revolver out at the hip. The gun stays in
## hand (the painting shows it); the gun in hand keeps the camera level on the head and eases the
## lens to its resting fov, so the turn and pitch go on the player and head, and the lens on the gun.
static func frame_camera(player: Player) -> void:
	player.global_position = FEET
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

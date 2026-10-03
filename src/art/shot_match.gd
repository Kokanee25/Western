class_name ShotMatch
## The painting's shot, staged for real: docs/concept/saloon-night.png. You're sat at a round card
## table in the saloon at night; a man sits at the table's left side, leaning in on his forearms
## with a tin cup in his hand, turned to you; the lamp burns between you, a bottle stands to the
## right, your own cup is in front of you. Every change to how people look is judged against the
## painting from here, in lamplight (tools/screenshots.gd view `shot_match_saloon`, and
## tools/side_by_side.py puts the two together). F5 in the game can jump here too (debug place).

## The card table at the back of the saloon we take over (world space, test street), and how far
## the whole set (table, props, him, your seat) is turned about it from the way it was fitted
## (degrees about Y): the set turns as one, so his fit to the painting holds, and only the room
## behind him changes. Turned (2026-10-01) so you look up the room toward the street as the
## painting does: the doors on your left, the stairs and balcony ahead, the bar on your right; and
## moved (2026-10-02) up the room beside the bar, so the tall front door is on your left with the
## moon in it, the back bar and its mirror fill the right and the balcony stands over the middle.
const TABLE := Vector3(5.36, 0.0, -23.61)
const ROOM_YAW := -72.8
const TABLE_HEIGHT := 0.76
const TABLE_RADIUS := 0.7
## Where your eyes are, sat down, relative to the table's centre on the floor: a little right of
## it and back from its edge; and where you look. Fitted to the painting (2026-09-29): his eyes land
## where the painting has them (0.39 across, 0.40 down) at the painting's size (eye to chin 106 of
## its 941 px), and the props below are where the painting's pixels fall on the table top.
const EYE := Vector3(-0.504, 1.15, -1.034)
const LOOK := Vector3(0.385, 1.093, -0.362)
## The painting's lens is longer than the game's: about 48° top to bottom (77° across).
const FOV := 48.0
## Where he sits relative to the table: its left side (+X is your left, looking +Z). Fitted with his
## pose below (2026-10-01): his outline from your seat onto the painting's man's, his eyes onto its
## eyes and the cup in his hand onto its cup.
const SEAT := Vector3(0.778, 0.0, -0.467)
## Turned this far to his left from square to you (degrees), fitted with SEAT.
const TURN := 6.75
## Where the cup sits in his right hand (the hand's own space: its palm faces -X, the fingers run
## down -Y and curl towards the palm, the thumb is -Z).
const CUP_IN_HAND := Vector3(-0.05, -0.045, 0.02)
## Which generated body the seated man wears (assets/people/<model>.glb): the Tripo man
## (`stranger`, tools/blender/fit_tripo.py; the default since 2026-10-03) or the MakeHuman
## `outlaw`; tools/screenshots.gd --model=.
static var model: StringName = &"stranger"


## Build the scene in the test street (clearing that table's own props) and seat the man.
## Returns him. `man` may be passed (a HumanBody not yet in the tree) to seat someone else.
static func stage(street: Node3D, man: HumanBody = null) -> HumanBody:
	var set := rig(street)
	var t := set.origin
	_clear_props(street, t)
	var root := Node3D.new()
	root.name = "ShotMatch"
	street.add_child(root)
	root.global_transform = set
	_table(root)
	_chair(root, SEAT + Vector3(0.1, 0.0, 0.07), 53.0)
	# On the table: the lamp beside him, the bottle nearer you on the right, your cup, his ashtray.
	# (The painting's lamp is about twice ours for a seated eye; ours stays the game's lamp.)
	var lamp := OilLamp.new()
	lamp.name = "TableLamp"
	lamp.lit_from_hour = 0
	lamp.lit_until_hour = 24
	# The game's lamp (the painted man's light, paint_look, was tuned under it; mosaic-tiles' 2.6
	# was tried for the key on his face).
	lamp.energy = 1.5
	lamp.light_range = 7.0
	# Less of the room's smoke lit by it: a light a few centimetres inside the chimney lit the air
	# round the glass white, where the painting's chimney glows amber.
	lamp.haze = 0.4
	root.add_child(lamp)
	lamp.position = Vector3(0.183, TABLE_HEIGHT, -0.011)
	_bottle(root, Vector3(-0.152, TABLE_HEIGHT, -0.006))
	_cup(root, Vector3(0.027, TABLE_HEIGHT, -0.434))
	_ashtray(root, Vector3(0.239, TABLE_HEIGHT, -0.523))
	if man == null:
		man = HumanBody.new()
		man.name = "SeatedMan"
		man.person_id = &"stranger"  # his own clothes (materials are cached per person)
		man.body_model = model
		man.rng_seed = 7
		man.coat_color = Color(0.36, 0.25, 0.16, 1.0)
		man.vest_color = Color(0.2, 0.15, 0.11)
		man.shirt_color = Color(0.82, 0.77, 0.66)
		man.hat_color = Color(0.27, 0.19, 0.13)
		man.bandana_color = Color(0.1, 0.08, 0.07)
		# His dark hair to the collar, as the painting has it.
		var look: Dictionary = man.look.duplicate()
		look["hair_long"] = true
		man.look = look
	street.add_child(man)
	man.global_position = set * SEAT
	# Nearly square to you, as the painting's man sits.
	man.face(set * Vector3(EYE.x, 1.0, EYE.z))
	man.global_rotation.y += deg_to_rad(TURN)
	man.set_pose(&"sit_lean")
	# His head as the painting has it: looking you in the eye, chin up a touch, turned a little and
	# tipped toward his left shoulder; his chest turned a touch to his left; his right arm and wrist
	# set so the mug in his palm sits where the painting's does with the back of his hand towards
	# you (fitted with SEAT and TURN: his outline on the painting's man's, both his eyes on its eyes,
	# the cup on its cup, his palm in front of the mug).
	man.pose_offsets = {&"head": Vector3(8.5, -8.5, 13.75), &"neck": Vector3(0.0, -5.5, 0.0),
			&"chest": Vector3(0.0, 4.5, 0.0), &"upper_arm_r": Vector3(1.5, 6.5, 0.0),
			&"forearm_r": Vector3(8.0, -6.5, 0.0), &"hand_r": Vector3(10.0, -12.5, -12.5)}
	_cup_in_hand(man)
	_extras(street)
	return man


## The painting's room has people in it: three men at cards in front of the door, one at the
## piano, two drinking at the bar with a barman behind it, one up on the balcony and one on the stair (the town's own
## barkeep stands further down the bar). Staged for the picture only (no brains): who's in the
## saloon in play is TownLife's business.
const EXTRAS := [
	# [name, saloon-space position, saloon-space point he faces, pose, shirt, vest, coat, hat, look]
	["CardPlayerA", Vector3(4.53, 0.0, 2.93), Vector3(4.75, 1.0, 3.7), &"sit", Color(0.78, 0.74, 0.64), Color(0.2, 0.16, 0.12), Color(0, 0, 0, 0), Color(0.16, 0.12, 0.1),
			{"hair": Color(0.15, 0.1, 0.07), "moustache": &"walrus", "beard": &"stubble", "age": 0.5, "brows": 0.7}],
	["CardPlayerB", Vector3(5.52, 0.0, 3.49), Vector3(4.75, 1.0, 3.7), &"sit", Color(0.62, 0.5, 0.36), Color(0.3, 0.2, 0.12), Color(0, 0, 0, 0), Color(0.24, 0.18, 0.12),
			{"hair": Color(0.3, 0.2, 0.1), "moustache": &"handlebar", "beard": &"none", "age": 0.6, "brows": 0.6}],
	["CardPlayerC", Vector3(3.98, 0.0, 3.91), Vector3(4.75, 1.0, 3.7), &"sit", Color(0.84, 0.82, 0.76), Color(0.12, 0.1, 0.09), Color(0, 0, 0, 0), Color(0.1, 0.09, 0.08),
			{"hair": Color(0.1, 0.08, 0.06), "moustache": &"walrus", "beard": &"full", "age": 0.45, "brows": 0.8}],
	["PianoPlayer", Vector3(2.95, 0.0, 1.25), Vector3(2.95, 1.2, 0.0), &"sit", Color(0.86, 0.84, 0.78), Color(0.22, 0.14, 0.1), Color(0, 0, 0, 0), Color(0, 0, 0, 0),
			{"hair": Color(0.2, 0.14, 0.09), "moustache": &"trim", "beard": &"none", "age": 0.35, "brows": 0.5}],
	["ManAtTheBar", Vector3(7.12, 0.0, 4.35), Vector3(8.5, 1.4, 4.0), &"stand", Color(0.55, 0.5, 0.42), Color(0.18, 0.14, 0.1), Color(0.3, 0.25, 0.18, 1.0), Color(0.2, 0.15, 0.1),
			{"hair": Color(0.18, 0.12, 0.08), "moustache": &"walrus", "beard": &"stubble", "age": 0.5, "brows": 0.7}],
	["SecondAtTheBar", Vector3(7.1, 0.0, 3.35), Vector3(8.5, 1.4, 3.6), &"stand", Color(0.74, 0.7, 0.6), Color(0.24, 0.16, 0.1), Color(0, 0, 0, 0), Color(0.12, 0.1, 0.08),
			{"hair": Color(0.12, 0.09, 0.07), "moustache": &"handlebar", "beard": &"none", "age": 0.4, "brows": 0.6}],
	["Barman", Vector3(8.85, 0.0, 4.1), Vector3(7.0, 1.4, 4.6), &"stand", Color(0.88, 0.86, 0.8), Color(0.14, 0.12, 0.1), Color(0, 0, 0, 0), Color(0, 0, 0, 0),
			{"hair": Color(0.1, 0.08, 0.06), "moustache": &"handlebar", "beard": &"none", "age": 0.45, "brows": 0.7}],
	["ManOnTheBalcony", Vector3(8.9, 2.3, 1.25), Vector3(5.0, 3.3, 3.5), &"stand", Color(0.7, 0.64, 0.52), Color(0.16, 0.13, 0.1), Color(0, 0, 0, 0), Color(0.14, 0.11, 0.09),
			{"hair": Color(0.12, 0.09, 0.07), "moustache": &"walrus", "beard": &"stubble", "age": 0.4, "brows": 0.8}],
	["ManOnTheStair", Vector3(7.0, 1.16, 0.55), Vector3(9.0, 2.4, 0.55), &"stand", Color(0.6, 0.22, 0.18), Color(0.2, 0.12, 0.1), Color(0, 0, 0, 0), Color(0.18, 0.13, 0.1),
			{"hair": Color(0.22, 0.12, 0.06), "moustache": &"trim", "beard": &"stubble", "age": 0.3, "brows": 0.6}],
]
## The card game's table in front of the door (saloon space), with its own lamp.
const CARD_TABLE := Vector3(4.75, 0.0, 3.7)


static func _extras(street: Node3D) -> void:
	var saloon := street.find_child("Saloon", true, false) as FalseFrontBuilding
	if saloon == null:
		return
	var f := saloon.floor_top
	var props := saloon.get_node_or_null(^"Props")
	if props and saloon.has_method(&"_place"):
		var at := CARD_TABLE + Vector3(0, f, 0)
		saloon.call(&"_place", props, &"card_table", at, 15.0)
		var lamp := saloon.call(&"_place", props, &"oil_lamp", at + Vector3(0.1, PropLibrary.size_of(&"card_table").y, -0.05), 0.0) as Node3D
		var light := lamp.get_node_or_null(^"Light") as OilLamp if lamp else null
		if light:
			light.energy = 0.6
			light.light_range = 3.5
		saloon.call(&"_place", props, &"whiskey_bottle", at + Vector3(-0.2, PropLibrary.size_of(&"card_table").y, 0.15), 0.0)
	for i in EXTRAS.size():
		var e: Array = EXTRAS[i]
		var man := HumanBody.new()
		man.name = e[0]
		man.person_id = StringName(String(e[0]).to_snake_case())
		man.rng_seed = 31 + i
		man.has_gun = false
		man.use_paint = false
		man.shirt_color = e[4]
		man.vest_color = e[5]
		man.coat_color = e[6]
		man.hat_color = e[7]
		man.bandana_color = Color(0, 0, 0, 0)
		man.look = e[8]
		street.add_child(man)
		man.global_position = saloon.to_global((e[1] as Vector3) + Vector3(0, f, 0))
		man.face(saloon.to_global((e[2] as Vector3) + Vector3(0, f, 0)))
		man.set_pose(e[3])


## Put the player's eye at the painting's viewpoint with its lens. Every gun goes out of his hands
## first: the gun in hand drives the camera (kick and aim zoom, `WeaponViewmodel._animate_camera`),
## and left selected it pulls the lens back to 75° and levels the view within a second.
static func frame_camera(player: Player, street: Node3D) -> void:
	hands_off_camera(player)
	player.camera.global_transform = camera_transform(street)
	player.camera.fov = FOV


## Take every gun out of the player's hands so a staged camera keeps its lens and aim.
static func hands_off_camera(player: Player) -> void:
	for w: WeaponViewmodel in player.weapons:
		w.selected = false
		w.drawn = false
		w.visible = false


## Your eye and the point you look at, in the world.
static func camera_transform(street: Node3D) -> Transform3D:
	var set := rig(street)
	var eye := set * EYE
	return Transform3D(Basis.looking_at(set * LOOK - eye, Vector3.UP), eye)


## The set's place: the table's centre on the floor, turned by ROOM_YAW. EYE, LOOK, SEAT and the
## props are in this space.
static func rig(street: Node3D) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(ROOM_YAW)), Vector3(TABLE.x, _floor_at(street, TABLE), TABLE.z))


static func _floor_at(street: Node3D, at: Vector3) -> float:
	var space := street.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2.0, at + Vector3.DOWN * 1.0, Layers.WORLD)
	var hit := space.intersect_ray(q)
	return (hit.position as Vector3).y if not hit.is_empty() and (hit.position as Vector3).y < 0.8 else 0.38


static func _clear_props(street: Node3D, t: Vector3) -> void:
	var saloon := street.find_child("Saloon", true, false)
	var props := saloon.get_node_or_null(^"Props") if saloon else null
	if props == null:
		return
	for p in props.get_children():
		var d := Vector2((p as Node3D).global_position.x - t.x, (p as Node3D).global_position.z - t.z).length()
		if d < 2.4:
			p.free()


## Props on the texel grid (PixelArt.material: lit tile by tile), textured by position in their own space.
static func _mat(key: String, tex: Texture2D, tint := Color.WHITE, rough := 0.9, metal := 0.0) -> ShaderMaterial:
	var m := PixelArt.material(tex, tint, PixelArt.Mapping.TRIPLANAR, Vector3.ZERO, rough, metal, 0.5)
	m.resource_name = key
	return m


static func _mesh(parent: Node3D, n: String, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## A round card table: a thick top of dark boards on a turned pedestal and four splayed feet.
static func _table(root: Node3D) -> void:
	# Darkened under the lamp it stands next to (the judge: the painting's table is a deep orange).
	var wood := _mat("table", PixelArt.wood("shot_table", Color(0.36, 0.22, 0.12), 61, 2, 4, 0.9), Color(0.46, 0.38, 0.33))
	var body := StaticBody3D.new()
	body.name = "Table"
	root.add_child(body)
	var top := CylinderMesh.new()
	top.top_radius = TABLE_RADIUS
	top.bottom_radius = TABLE_RADIUS - 0.02
	top.height = 0.045
	top.radial_segments = 20
	_mesh(body, "Top", top, Vector3(0, TABLE_HEIGHT - 0.022, 0), wood)
	var skirt := CylinderMesh.new()
	skirt.top_radius = TABLE_RADIUS - 0.05
	skirt.bottom_radius = TABLE_RADIUS - 0.05
	skirt.height = 0.08
	skirt.radial_segments = 20
	_mesh(body, "Skirt", skirt, Vector3(0, TABLE_HEIGHT - 0.085, 0), wood)
	var post := CylinderMesh.new()
	post.top_radius = 0.07
	post.bottom_radius = 0.1
	post.height = TABLE_HEIGHT - 0.12
	post.radial_segments = 8
	_mesh(body, "Pedestal", post, Vector3(0, (TABLE_HEIGHT - 0.12) * 0.5, 0), wood)
	for k in 4:
		var foot := BoxMesh.new()
		foot.size = Vector3(0.07, 0.06, 0.42)
		var mi := _mesh(body, "Foot%d" % k, foot, Vector3.ZERO, wood)
		mi.transform = Transform3D(Basis(Vector3.UP, k * PI * 0.5 + PI * 0.25), Vector3(0, 0.03, 0)) \
				* Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.2))
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = TABLE_RADIUS
	cyl.height = 0.05
	shape.shape = cyl
	shape.position = Vector3(0, TABLE_HEIGHT - 0.025, 0)
	body.add_child(shape)


## A plain spindle-back chair, seat 0.45 m up, facing `yaw` degrees.
static func _chair(root: Node3D, at: Vector3, yaw: float) -> void:
	var wood := _mat("chair", PixelArt.wood("shot_chair", Color(0.3, 0.19, 0.11), 67, 1, 2, 0.8))
	var chair := Node3D.new()
	chair.name = "Chair"
	root.add_child(chair)
	chair.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)
	var seat := BoxMesh.new()
	seat.size = Vector3(0.44, 0.04, 0.42)
	_mesh(chair, "Seat", seat, Vector3(0, 0.45, 0), wood)
	for x in [-0.19, 0.19]:
		for z in [-0.18, 0.18]:
			var leg := BoxMesh.new()
			leg.size = Vector3(0.04, 0.45, 0.04)
			_mesh(chair, "Leg", leg, Vector3(x, 0.225, z), wood)
		var upright := BoxMesh.new()
		upright.size = Vector3(0.04, 0.5, 0.04)
		_mesh(chair, "Back", upright, Vector3(x, 0.72, 0.19), wood)
	var rail := BoxMesh.new()
	rail.size = Vector3(0.42, 0.07, 0.03)
	_mesh(chair, "Rail", rail, Vector3(0, 0.93, 0.19), wood)


## Your tin mug (PropModels.cup).
static func _cup(root: Node3D, at: Vector3) -> Node3D:
	var cup := Node3D.new()
	cup.name = "Cup"
	PropModels.cup(cup)
	root.add_child(cup)
	cup.position = at
	return cup


## A labelled whiskey bottle in dark glass (PropModels.bottle).
static func _bottle(root: Node3D, at: Vector3) -> void:
	var bottle := Node3D.new()
	bottle.name = "Bottle"
	PropModels.bottle(bottle, 0)
	root.add_child(bottle)
	bottle.position = at


static func _ashtray(root: Node3D, at: Vector3) -> void:
	var t := CylinderMesh.new()
	t.top_radius = 0.06
	t.bottom_radius = 0.055
	t.height = 0.025
	t.radial_segments = 10
	_mesh(root, "Ashtray", t, at + Vector3(0, 0.012, 0), _mat("iron", PixelArt.metal("shot_iron", Color(0.22, 0.2, 0.18), 79, 0.8), Color.WHITE, 0.7, 0.6))


## Once he's settled into the pose, stand the cup up (a man holds his whiskey level).
static func _upright(cup: Node3D) -> void:
	if not is_instance_valid(cup):
		return
	await cup.get_tree().create_timer(0.6).timeout
	if is_instance_valid(cup):
		cup.global_basis = Basis.IDENTITY


## His tin cup, in his right hand (that arm lies across the table in front of him). CUP_IN_HAND is
## the cup's middle; the model stands on its bottom, half its height below.
static func _cup_in_hand(man: HumanBody) -> void:
	var hand := man.parts.get(&"hand_r") as Node3D
	if hand == null:
		return
	var held := Node3D.new()
	held.name = "HeldCup"
	hand.add_child(held)
	held.position = CUP_IN_HAND
	var model := Node3D.new()
	PropModels.cup(model)
	model.position = Vector3(0, -0.05, 0)
	held.add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.layers = Layers.VIS_BODY
	_upright.call_deferred(held)
	man.curl_hand("r", 0.7)

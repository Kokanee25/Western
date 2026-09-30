class_name ShotMatch
## The painting's shot, staged for real: docs/concept/saloon-night.png. You're sat at a round card
## table in the saloon at night; a man sits at the table's left side, leaning in on his forearms
## with a tin cup in his hand, turned to you; the lamp burns between you, a bottle stands to the
## right, your own cup is in front of you. Every change to how people look is judged against the
## painting from here, in lamplight (tools/screenshots.gd view `shot_match_saloon`, and
## tools/side_by_side.py puts the two together). F5 in the game can jump here too (debug place).

## The card table at the back of the saloon we take over (world space, test street).
const TABLE := Vector3(8.8, 0.0, -25.0)
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
## Where he sits relative to the table: its left side (+X is your left, looking +Z).
const SEAT := Vector3(0.79, 0.0, -0.37)


## Build the scene in the test street (clearing that table's own props) and seat the man.
## Returns him. `man` may be passed (a HumanBody not yet in the tree) to seat someone else.
static func stage(street: Node3D, man: HumanBody = null) -> HumanBody:
	var floor_y := _floor_at(street, TABLE)
	var t := Vector3(TABLE.x, floor_y, TABLE.z)
	_clear_props(street, t)
	var root := Node3D.new()
	root.name = "ShotMatch"
	street.add_child(root)
	root.global_position = t
	_table(root)
	_chair(root, SEAT + Vector3(0.1, 0.0, 0.07), 53.0)
	# On the table: the lamp beside him, the bottle nearer you on the right, your cup, his ashtray.
	# (The painting's lamp is about twice ours for a seated eye; ours stays the game's lamp.)
	var lamp := OilLamp.new()
	lamp.name = "TableLamp"
	lamp.lit_from_hour = 0
	lamp.lit_until_hour = 24
	lamp.energy = 1.5
	lamp.light_range = 7.0
	root.add_child(lamp)
	lamp.position = Vector3(0.183, TABLE_HEIGHT, -0.011)
	_bottle(root, Vector3(-0.152, TABLE_HEIGHT, -0.006))
	_cup(root, Vector3(0.027, TABLE_HEIGHT, -0.434))
	_ashtray(root, Vector3(0.239, TABLE_HEIGHT, -0.523))
	if man == null:
		man = HumanBody.new()
		man.name = "SeatedMan"
		man.person_id = &"stranger"  # his own clothes (materials are cached per person)
		man.rng_seed = 7
		man.coat_color = Color(0.36, 0.25, 0.16, 1.0)
		man.vest_color = Color(0.2, 0.15, 0.11)
		man.shirt_color = Color(0.82, 0.77, 0.66)
		man.hat_color = Color(0.27, 0.19, 0.13)
		man.bandana_color = Color(0.1, 0.08, 0.07)
	street.add_child(man)
	man.global_position = t + SEAT
	# Square to you, as the painting's man sits.
	man.face(t + Vector3(EYE.x, 1.0, EYE.z))
	man.set_pose(&"sit_lean")
	# His head as the painting has it: looking you in the eye, chin up a touch, tipped toward his
	# left shoulder.
	man.pose_offsets = {&"head": Vector3(6.0, 0.0, 12.0)}
	_cup_in_hand(man)
	return man


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
	var t := Vector3(TABLE.x, _floor_at(street, TABLE), TABLE.z)
	var eye := t + EYE
	return Transform3D(Basis.looking_at(t + LOOK - eye, Vector3.UP), eye)


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
		if d < 1.4:
			p.free()


static func _mat(key: String, tex: Texture2D, tint := Color.WHITE, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_texture = tex
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.roughness = rough
	m.metallic = metal
	PixelArt.track(m)
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
	var wood := _mat("table", PixelArt.wood("shot_table", Color(0.36, 0.22, 0.12), 61, 2, 4, 0.9))
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


static func _tin() -> StandardMaterial3D:
	return _mat("tin", PixelArt.metal("shot_tin", Color(0.55, 0.55, 0.52), 71, 0.5), Color.WHITE, 0.45, 0.8)


static func _cup(root: Node3D, at: Vector3) -> MeshInstance3D:
	var cup := CylinderMesh.new()
	cup.top_radius = 0.04
	cup.bottom_radius = 0.036
	cup.height = 0.1
	cup.radial_segments = 10
	return _mesh(root, "Cup", cup, at + Vector3(0, 0.05, 0), _tin())


static func _bottle(root: Node3D, at: Vector3) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.2, 0.1, 0.04, 0.92)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.15
	glass.metallic_specular = 0.8
	var b := CylinderMesh.new()
	b.top_radius = 0.043
	b.bottom_radius = 0.045
	b.height = 0.2
	b.radial_segments = 10
	_mesh(root, "Bottle", b, at + Vector3(0, 0.1, 0), glass)
	var neck := CylinderMesh.new()
	neck.top_radius = 0.014
	neck.bottom_radius = 0.04
	neck.height = 0.1
	neck.radial_segments = 8
	_mesh(root, "BottleNeck", neck, at + Vector3(0, 0.25, 0), glass)
	var label := CylinderMesh.new()
	label.top_radius = 0.046
	label.bottom_radius = 0.046
	label.height = 0.08
	label.radial_segments = 10
	var paper := _mat("label", PixelArt.painted("shot_label", Color(0.78, 0.7, 0.52), Color(0.5, 0.4, 0.3), 73, 0.5))
	_mesh(root, "Label", label, at + Vector3(0, 0.1, 0), paper)


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


## His tin cup, in his right hand (that arm lies across the table in front of him).
static func _cup_in_hand(man: HumanBody) -> void:
	var hand := man.parts.get(&"hand_r") as Node3D
	if hand == null:
		return
	var cup := CylinderMesh.new()
	cup.top_radius = 0.04
	cup.bottom_radius = 0.036
	cup.height = 0.1
	cup.radial_segments = 10
	var mi := _mesh(hand, "HeldCup", cup, Vector3(0.0, -0.06, -0.05), _tin())
	mi.layers = Layers.VIS_BODY
	_upright.call_deferred(mi)
	man.curl_hand("r", 0.7)

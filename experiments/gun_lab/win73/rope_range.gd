extends RefCounted
## The rope range (#734 step 2, the rope shot): a raised stand 3 m up on posts with a rail (the
## Boardwalk part, as the valley's high walks), and two gallows posts out east of it, each with a
## rope and a 40 kg sack hung on it (Joe's stand-in): 30 m and 60 m from the stand's front. Out past
## the shooting range's boards, clear of their lines (z +12). A rope cut through drops its sack;
## a fresh one is hung 4 s later. F5's last stop (`DebugSpawns/RopeRange`) builds it the first time
## it's reached and puts you on the stand facing them; the gun-feel tests build it too.
##
##   load("res://experiments/gun_lab/win73/rope_range.gd").build(street)   # -> the range's node

## The stand's front edge (where you stand to shoot), on the ground east of town, and its top.
const STAND := Vector3(40.0, 0.0, 12.0)
const STAND_TOP := 3.0
## Each rope's distance from the stand's front along +X, and how far it stands to the side (m: the
## near gallows out of the far rope's line), and the gallows' arm height.
const RANGES := [30.0, 60.0]
const SIDE := {30.0: -3.0, 60.0: 3.0}
const ARM_HEIGHT := 4.2
const ROPE_LENGTH := 1.8


static func build(street: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "RopeRange"
	street.add_child(root)
	var g := TownLayout.ground_height(STAND.x, STAND.z)
	var walk = load("res://src/structures/boardwalk.gd").new()
	walk.structure_id = &"rope_stand"
	walk.length = 3.0
	walk.walk_depth = 3.0
	walk.top = STAND_TOP
	walk.on_posts = true
	walk.rail = true
	walk.max_riser = true
	walk.steps = [Vector2(1.5, 1.2)]
	# Its far end (x 3) at the front: you stand at x STAND.x looking east along the walk's length.
	# (Boardwalk runs along +X from its origin, its street edge at -Z: the steps on the north side.)
	walk.position = Vector3(STAND.x - 3.0, g, STAND.z + 1.5)
	root.add_child(walk)
	for d: float in RANGES:
		var at := Vector3(STAND.x + d, 0.0, STAND.z + float(SIDE[d]))
		at.y = TownLayout.ground_height(at.x, at.z)
		root.add_child(gallows(at, "Gallows%d" % int(d)))
	var fittings := street.get_node_or_null(^"Fittings")
	if fittings:
		fittings.call_deferred(&"collect")
	return root


## Where the shooter's eye is on the stand (standing at its front edge, facing +X).
static func eye(street_ground := 0.0) -> Vector3:
	return Vector3(STAND.x - 0.3, street_ground + STAND_TOP + 1.62, STAND.z)


## A post with an arm out over the rope (a plain gallows of 6x6 timber), the rope from the arm's end.
static func gallows(at: Vector3, n: String) -> Node3D:
	var g := Node3D.new()
	g.name = n
	g.position = at
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.28, 0.2)
	wood.roughness = 0.9
	var post_at := Vector3(0.0, ARM_HEIGHT * 0.5 + 0.075, 1.0)
	_timber(g, "Post", Vector3(0.15, ARM_HEIGHT + 0.15, 0.15), post_at, wood)
	_timber(g, "Arm", Vector3(0.15, 0.15, 1.3), Vector3(0.0, ARM_HEIGHT + 0.075, 0.45), wood)
	_timber(g, "Brace", Vector3(0.1, 0.1, 0.7), Vector3(0.0, ARM_HEIGHT - 0.3, 0.75), wood, Vector3(-45.0, 0.0, 0.0))
	var rope := Rope.new()
	rope.name = "Rope"
	rope.length = ROPE_LENGTH
	rope.mend_after = 4.0
	rope.position = Vector3(0.0, ARM_HEIGHT, 0.0)
	g.add_child(rope)
	return g


static func _timber(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.name = n
	body.collision_layer = Layers.WORLD
	body.position = pos
	body.rotation_degrees = rot
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)
	parent.add_child(body)


## The ropes it hung, nearest first.
static func ropes(range_root: Node) -> Array[Rope]:
	var out: Array[Rope] = []
	for d: float in RANGES:
		var r := range_root.get_node_or_null("Gallows%d/Rope" % int(d)) as Rope
		if r:
			out.append(r)
	return out

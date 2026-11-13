extends RefCounted
## Townsfolk for the valley's frame bench (#865, the review's R4: `perf_bench --world=valley
## --townsfolk=N`): N more men in the valley town, each a Studio man with a civilian's mind at a post
## on Main Street's walks, facing the street, so the bench measures the town the townsfolk brief
## (docs/briefs/townsfolk.md "What it costs") plans before it is built.
##
## Where they stand (`band`): "mix" (the default) puts half near you (within 25 m of `at`: PeopleTick
## ticks them every tick) and half far (70 to 120 m off down the street: every 4th tick past 60 m),
## the brief's 12-near-12-far town in small; "near" or "far" puts them all in one band (the per-man
## cost of each band). `around` is where the near ones gather (the saloon's yard at night, the street
## by day); the far ones are always on the street's walks.
##
##   var made: Array = ValleyTownsfolk.lay(valley, 10, Vector3(40, 0, 2), "mix")
## Untyped where it meets the game's classes: perf_bench (an -s script) loads it before autoloads.

## The Studio men the valley's folk are made of (config/valley_folk.json), turned over in order.
const MODELS := ["storekeeper_s1_talking", "miner_s4_talking", "mexican_rancher_s1_talking",
		"old_rancher_s3_talking", "young_drifter_s3_talking", "barkeep_s2_talking", "blacksmith_s1_talking",
		"bold_cowboy_s3_talking", "doctor_s2_talking", "heavy_factory", "oldtimer_factory", "young_factory"]
## Main Street's walks run along z = +-WALK_Z (the fronts 20.1 m apart, the walks 2.4 m deep).
const WALK_Z := 10.5
## Near: within this of `around` (m); far: this far down the street from `at` and on.
const NEAR := 22.0
const FAR_FROM := 70.0
const GAP := 3.0


static func lay(world: Node3D, n: int, at: Vector3, band := "mix", around := Vector3.INF) -> Array:
	if n <= 0:
		return []
	if around == Vector3.INF:
		around = at
	var near_n := n if band == "near" else (0 if band == "far" else (n + 1) / 2)
	var space: PhysicsDirectSpaceState3D = World.space(world)
	var folk = world.get("folk")
	var places = folk.places if folk else null
	var ground = world.get_node_or_null(^"Ground")
	var made := []
	for i in n:
		var near := i < near_n
		var post: Vector3
		var faces: Vector3
		if near:
			# On the walks either side of `around`, in from the street's edge, alternating sides,
			# spreading out along x (never more than NEAR off).
			var k := i
			var side := 1.0 if k % 2 == 0 else -1.0
			var dx := (float(k / 2) * GAP) * (1.0 if (k / 2) % 2 == 0 else -1.0)
			dx = clampf(dx, -NEAR + 2.0, NEAR - 2.0)
			post = Vector3(around.x + dx, 0.0, side * WALK_Z if absf(around.z) < WALK_Z else around.z + side * 3.0)
			faces = Vector3(post.x, 1.5, 0.0) if absf(around.z) < WALK_Z else around + Vector3.UP * 1.5
		else:
			# Down the street from `at`: west first, then east, both walks.
			var k := i - near_n
			var west := k % 2 == 0
			var along := FAR_FROM + float(k / 4) * GAP * 2.0
			var x: float = at.x - along if west else at.x + along
			x = clampf(x, -120.0, 126.0)
			var side := 1.0 if (k / 2) % 2 == 0 else -1.0
			post = Vector3(x, 0.0, side * WALK_Z)
			faces = Vector3(x, 1.5, 0.0)
		# Down from just above the ground (2.4 m: over a walk, under an awning or a roof), not from the sky.
		var g: float = ground.height_at(post.x, post.z) if ground else 0.0
		var q := PhysicsRayQueryParameters3D.create(Vector3(post.x, g + 2.4, post.z), Vector3(post.x, g - 2.0, post.z), Layers.STAND)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			post.y = (hit.position as Vector3).y
		var man := HumanBody.new()
		man.name = "Townsman%d" % i
		man.person_id = StringName("townsman_%d" % i)
		man.rng_seed = 9100 + i
		man.has_gun = false
		man.body_model = StringName(MODELS[i % MODELS.size()])
		man.hat_color = Color(0, 0, 0, 0)
		man.bandana_color = Color(0, 0, 0, 0)
		var brain := CivilianBrain.new()
		brain.name = "Brain"
		brain.post = post
		brain.faces = faces
		if places != null:
			brain.places = places
		man.add_child(brain)
		man.move_child(brain, 0)
		man.enter(world, post, HumanBody.yaw_toward(post, faces))
		man.set_meta(&"bench_band", &"near" if near else &"far")
		made.append(man)
	return made

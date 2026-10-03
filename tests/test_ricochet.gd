extends TestCase
## Ricochets: a ball striking at a shallow angle glances off, by what it hits: dirt and stone at
## a fair angle, wood only at a graze. It leaves flatter and slower, flattened and tumbling, still
## able to hurt someone; you hear it whine off, and whiz rather than snap going past you.

var world: Node3D
var ballistics: Ballistics
var hits: Array[Dictionary] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(200, 1, 200))  # hard-packed ground
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	hits.clear()
	Events.bullet_hit.connect(_on_hit)
	await physics_frames(2)


func after_each() -> void:
	Events.bullet_hit.disconnect(_on_hit)
	world.queue_free()
	await physics_frames(2)


func _on_hit(info: Dictionary) -> void:
	hits.append(info)


func _box(center: Vector3, size: Vector3, surface := &"") -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = center
	if surface != &"":
		b.set_meta(&"surface", surface)
	world.add_child(b)
	return b


## A revolver ball fired from 1.5 m up so that it meets the ground `degrees` steep, `metres` ahead.
func _at_ground(degrees: float, metres := 10.0) -> Ballistics.Bullet:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var a := deg_to_rad(degrees)
	var from := Vector3(0, metres * tan(a), 0)
	return ballistics.fire(from, Vector3(0, -sin(a), -cos(a)), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)


func _ricochets(surface := &"") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in hits:
		if h.get("ricochet", false) and (surface == &"" or h.get("surface", &"") == surface):
			out.append(h)
	return out


func test_a_ball_skips_off_the_ground_at_a_shallow_angle() -> void:
	var b := _at_ground(3.0)
	await wait_until(func() -> bool: return not b.alive or b.position.z < -40.0, 60 * 2)
	var r := _ricochets()
	check(not r.is_empty(), "it glanced off the dirt (%d hits)" % hits.size())
	if r.is_empty():
		return
	check_near((r[0].position as Vector3).z, -10.0, 0.5, "where it struck")
	check(b.position.z < -20.0, "and flew on (%s)" % str(b.position))
	check(b.tumbling, "flattened and tumbling")
	check(r[0].energy_after < r[0].energy_before * 0.7, "slower (%.0f J -> %.0f J)" % [r[0].energy_before, r[0].energy_after])
	check(r[0].energy_after > r[0].energy_before * 0.2, "but still dangerous")
	var out_dir := (b.path[b.path.size() - 1] - (r[0].position as Vector3)).normalized()
	var up_angle := rad_to_deg(asin(out_dir.y))
	check(up_angle > 0.0 and up_angle < 3.0, "leaving flatter than it came in (%.1f°)" % up_angle)


func test_steep_into_the_ground_it_stops() -> void:
	for k in 5:
		var b := _at_ground(40.0)
		await wait_until(func() -> bool: return not b.alive, 60)
	check(_ricochets().is_empty(), "at 40° it buries itself every time")


func test_how_often_depends_on_the_angle_and_what_it_hits() -> void:
	var count := func(deg: float) -> int:
		var n := 0
		for k in 20:
			hits.clear()
			var b := _at_ground(deg)
			await wait_until(func() -> bool: return not b.alive or b.position.z < -12.0, 60)
			if not _ricochets().is_empty():
				n += 1
		return n
	var graze: int = await count.call(2.0)
	var middling: int = await count.call(10.0)
	check(graze >= 18, "a graze nearly always skips (%d of 20)" % graze)
	check(middling > 2 and middling < 17, "near the limit it's a toss-up (%d of 20 at 10°)" % middling)


func test_wood_only_at_a_graze_stone_at_a_steeper_angle() -> void:
	var wall := Structure.new()
	wall.structure_id = &"t"
	wall.collapses = false
	world.add_child(wall)
	# A wall of boards and one of stone, side by side along the line of fire.
	wall.add_member("boards", &"board", &"weathered_pine", Vector3(0.05, 2.0, 12.0), Vector3(3, 1.2, -10))
	wall.add_member("stones", &"block", &"stone", Vector3(0.4, 2.0, 12.0), Vector3(-3, 1.2, -10))
	await physics_frames(2)
	var t: RevolverTuning = load("res://config/revolver.tres")
	# `face_x`: the wall's face; each shot meets it 10 m down range, `deg` steep, at `y` (each round
	# a little higher: a carved wall keeps its gouges, and a round down the last one's gouge meets
	# the far side of it square on).
	var shoot := func(face_x: float, deg: float, y: float) -> bool:
		hits.clear()
		var side := signf(face_x)
		var dir := Vector3(side * sin(deg_to_rad(deg)), 0, -cos(deg_to_rad(deg)))
		var from := Vector3(face_x - side * 10.0 * tan(deg_to_rad(deg)), y, 0.0)
		var b := ballistics.fire(from, dir, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
		await wait_until(func() -> bool: return not b.alive or b.position.z < -16.0, 60)
		return not _ricochets(&"wood" if side > 0.0 else &"stone").is_empty()  # off the wall, not the ground beyond
	var wood_graze := 0
	var wood_steep := 0
	var stone_steep := 0
	# Twenty of each (a glance is a chance: three in four at a 3° graze; with ten, one unlucky run
	# of the dice could fail it).
	for k in 20:
		if await shoot.call(2.975, 3.0, 0.3 + k * 0.045):
			wood_graze += 1
		if await shoot.call(2.975, 12.0, 1.25 + k * 0.045):
			wood_steep += 1
		if await shoot.call(-2.8, 12.0, 1.25 + k * 0.045):
			stone_steep += 1
	check(wood_graze >= 10, "a ball grazing the boards glances off them (%d of 20)" % wood_graze)
	check_eq(wood_steep, 0, "at 12° it digs into the wood")
	check(stone_steep >= 10, "but glances off the stone (%d of 20)" % stone_steep)
	var boards := wall.get_member(&"t/boards")
	check(boards.holes.size() >= 20, "the wood's marked where every one struck it (%d)" % boards.holes.size())


func test_a_ricochet_can_still_hurt_a_man() -> void:
	var man := HumanBody.new()
	world.add_child(man)
	man.global_position = Vector3(0, 0, -16)
	await physics_frames(3)
	var hurt := 0
	for k in 12:
		var b := _at_ground(2.0 + k * 0.1, 8.0)
		b.velocity = b.velocity.rotated(Vector3.UP, deg_to_rad(-1.5 + k * 0.25))
		await wait_until(func() -> bool: return not b.alive, 90)
	for w in man.wounds:
		hurt += 1
	check(hurt >= 1, "a ball skipping off the street into his legs wounds him (%d wounds, %d ricochets)" % [hurt, _ricochets().size()])


func test_you_hear_it_whine_off_and_whiz_past() -> void:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3(0.4, 0, -22)
	player.rotation = Vector3.ZERO
	var fx := ImpactEffects.new()
	world.add_child(fx)
	await physics_frames(5)
	var passes: Array[bool] = []
	var note := func(who: Node, _s: Node, _d: float, _at: Vector3, _v: float, tumbling: bool) -> void:
		if who == player:
			passes.append(tumbling)
	Events.near_miss.connect(note)
	var b := _at_ground(4.0, 10.0)
	await wait_until(func() -> bool: return not b.alive or b.position.z < -30.0, 60 * 2)
	Events.near_miss.disconnect(note)
	check(not _ricochets().is_empty(), "it glanced off the street in front of you")
	check(passes.size() == 1 and passes[0], "and went past you tumbling (%s)" % str(passes))
	var sounds := {}
	for n in fx.get_children():
		if n is AudioStreamPlayer3D:
			for id in [&"ricochet", &"zip", &"crack"]:
				if (n as AudioStreamPlayer3D).stream == SynthSounds.get_sound(id):
					sounds[id] = true
	check(sounds.has(&"ricochet"), "the whine where it struck")
	check(sounds.has(&"zip"), "a whiz going by, not a snap (%s)" % str(sounds.keys()))
	check(not sounds.has(&"crack"), "no snap")

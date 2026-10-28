extends TestCase
## The player's shove and kick (PlayerShove, issue #479) and a man taking a push (HumanBody.
## take_push): a shove staggers him and he catches it; a kick puts him down; a wounded man goes
## down to a shove; a rail or a step behind him takes his feet; the key's tap is a shove and its
## hold a kick; a kick at a wall hurts your foot; a kick is a deed.

var world: Node3D
var player: Player


func before_each() -> void:
	world = Node3D.new()
	world.name = "Arena"
	get_tree().root.add_child(world)
	_box(Vector3(40, 1, 40), Vector3(0, -0.5, 0))


func after_each() -> void:
	Input.action_release(&"shove")
	world.queue_free()
	await physics_frames(2)


func _box(size: Vector3, at: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	b.add_child(shape)
	b.position = at
	world.add_child(b)
	return b


## A man standing at `at`, facing -Z (his back to a player at the origin).
func _man(at := Vector3(0, 0, -1.0)) -> HumanBody:
	var man := HumanBody.new()
	man.position = at
	world.add_child(man)
	return man


func _chest(man: HumanBody) -> Vector3:
	return (man.parts[&"chest"] as Node3D).global_position


func test_a_shove_staggers_him_and_he_catches_it() -> void:
	var man := _man(Vector3.ZERO)
	await physics_frames(10)
	var start := man.global_position
	var r := man.take_push(_chest(man) + Vector3(0, 0, -0.12), Vector3(0, 0, 1), 55.0)
	check_eq(r, &"stagger", "55 N*s at his chest (0.69 m/s) staggers him")
	await physics_frames(90)
	check(not man.limp, "and he stays on his feet")
	var moved := man.global_position.z - start.z
	check(moved > 0.1 and moved < 0.6, "pushed back %.2f m along it" % moved)
	check(man.stumbling == 0.0, "the stagger's over")


func test_a_kick_puts_him_down_and_he_gets_up() -> void:
	var man := _man(Vector3.ZERO)
	await physics_frames(10)
	var r := man.take_push(_chest(man) + Vector3(0, -0.3, -0.12), Vector3(0, 0, 1), 145.0, 130.0)
	check_eq(r, &"down", "145 N*s (1.8 m/s) is past any step")
	check(man.limp and man.rise_ok, "down, unhurt past knowing it")
	await physics_frames(60)
	var pelvis := (man.parts[&"pelvis"] as Node3D).global_position
	check(pelvis.z > 0.2, "he went over along the kick (hips %.2f m)" % pelvis.z)


func test_a_wounded_man_goes_down_to_a_shove() -> void:
	var man := _man(Vector3.ZERO)
	await physics_frames(10)
	var whole := man.catch_speed()
	for id: StringName in man.physiology._muscles("leg", "r"):
		man.physiology.muscle_damage[id] = 0.9
	check(man.catch_speed() < whole * 0.6, "a torn thigh: he catches %.2f m/s, not %.2f" % [man.catch_speed(), whole])
	var r := man.take_push(_chest(man), Vector3(0, 0, 1), 55.0)
	check_eq(r, &"down", "the shove that staggers a whole man puts him over")


func test_a_rail_at_his_hips_stops_a_shove_not_a_kick() -> void:
	var man := _man(Vector3.ZERO)
	_box(Vector3(3, 0.06, 0.08), Vector3(0, 0.95, 0.45))  # a fixed rail at his hip, half a metre behind
	await physics_frames(10)
	var r := man.take_push(_chest(man), Vector3(0, 0, 1), 55.0)
	check_eq(r, &"stagger", "the shove alone he'd catch")
	await physics_frames(60)
	check(not man.limp, "and the rail stops him on his feet")
	var man2 := _man(Vector3(4, 0, 0))
	_box(Vector3(3, 0.06, 0.08), Vector3(4, 0.95, 0.45))
	await physics_frames(10)
	man2.take_push(_chest(man2) + Vector3(0, -0.3, 0), Vector3(0, 0, 1), 145.0, 130.0)
	await physics_frames(90)
	# (Over it or not is the rail's: the game's break under him, the lab's gallery runs; this one's
	# fixed, and he slumps against it.)
	check(man2.limp, "a kick puts him down against it")


func test_a_seat_behind_his_knees_takes_him_down() -> void:
	var man := _man(Vector3.ZERO)
	_box(Vector3(1.2, 0.45, 0.4), Vector3(0, 0.225, 0.5))  # a fixed bench behind him
	await physics_frames(10)
	man.take_push(_chest(man), Vector3(0, 0, 1), 55.0)
	await physics_frames(40)
	check(man.limp, "backing into it, it takes his legs and he goes down over it")


func test_a_step_down_behind_him_takes_his_feet() -> void:
	# He stands at the edge of a porch 0.3 m up.
	_box(Vector3(4, 0.3, 2), Vector3(0, 0.15, -0.8))
	var man := _man(Vector3(0, 0.3, 0.08))
	await physics_frames(20)
	var r := man.take_push(_chest(man), Vector3(0, 0, 1), 55.0)
	check_eq(r, &"stagger", "a shove")
	await physics_frames(60)
	check(man.limp, "stepping back off the edge he can't catch it")


func _player() -> void:
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	await physics_frames(10)


func test_the_key_tapped_shoves_and_held_kicks() -> void:
	await _player()
	var man := _man(Vector3(0, 0, -0.85))
	man.global_rotation.y = 0.0
	await physics_frames(10)
	var got: Array[Dictionary] = []
	player.shove.landed.connect(func(i: Dictionary) -> void: got.append(i))
	Input.action_press(&"shove")
	await physics_frames(2)
	Input.action_release(&"shove")
	await physics_frames(30)
	check(got.size() == 1 and got[0].move == &"shove", "a tap is a shove: %s" % [got])
	if got.size() == 1:
		check_eq(got[0].what, &"man", "it lands on him")
		check(float(got[0].momentum) > 40.0 and float(got[0].momentum) < 70.0, "two hands: %.0f N*s" % float(got[0].momentum))
	await physics_frames(90)
	man.global_position = Vector3(0, 0, -1.05)
	await physics_frames(5)
	Input.action_press(&"shove")
	await physics_frames(int(player.shove.tuning.hold_for_kick * 60.0) + 6)
	Input.action_release(&"shove")
	await physics_frames(40)
	check(got.size() == 2 and got[-1].move == &"kick", "held and let go, a kick: %s" % [got.back() if got.size() > 1 else null])
	if got.size() == 2:
		check(got[-1].result == &"down" and man.limp, "the kick puts him down (%s)" % got[-1].get("result"))


func test_a_miss_is_a_miss() -> void:
	await _player()
	var got: Array[Dictionary] = []
	player.shove.landed.connect(func(i: Dictionary) -> void: got.append(i))
	player.shove.wants = &"kick"
	await physics_frames(30)
	check(got.size() == 1 and got[0].what == &"miss", "nothing there: %s" % [got])


func test_a_kick_at_a_wall_hurts_your_foot() -> void:
	await _player()
	_box(Vector3(4, 3, 0.3), Vector3(0, 1.5, -0.9))
	var got: Array[Dictionary] = []
	player.shove.landed.connect(func(i: Dictionary) -> void: got.append(i))
	var pain := player.wounds.physiology.wound_pain
	player.shove.wants = &"kick"
	await physics_frames(30)
	check(got.size() == 1 and got[0].result == &"held", "the wall holds: %s" % [got])
	check(player.wounds.physiology.wound_pain > pain, "and your foot feels it")
	check(player.wounds.physiology.broken.is_empty(), "a little: nothing broken")


func test_a_hurt_leg_wont_kick() -> void:
	await _player()
	for id: StringName in player.wounds.physiology._muscles("leg", "r"):
		player.wounds.physiology.muscle_damage[id] = 1.0
	var got: Array[Dictionary] = []
	player.shove.landed.connect(func(i: Dictionary) -> void: got.append(i))
	player.shove.wants = &"kick"
	await physics_frames(30)
	var weak: bool = got.size() == 1 and (got[0].what == &"cant" or float(got[0].get("speed", 99.0)) < player.shove.tuning.kick_speed * 0.5)
	check(weak, "a torn thigh kicks weakly or not at all: %s" % [got])


func test_a_kick_is_a_deed() -> void:
	await _player()
	var man := _man(Vector3(0, 0, -1.05))
	await physics_frames(10)
	var deeds: Array = []
	var on := func(actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
		if actor == player:
			deeds.append([kind, target])
	Events.deed.connect(on)
	player.shove.wants = &"kick"
	await physics_frames(30)
	player.shove.wants = &"kick"
	await physics_frames(40)
	Events.deed.disconnect(on)
	check(deeds.size() >= 1 and deeds[0][0] == &"kick" and deeds[0][1] == man, "kicking him is a deed: %s" % [deeds])

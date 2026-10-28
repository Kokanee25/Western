extends TestCase
## Muscle tone that fades a region at a time as he goes limp (HumanBody.tone_style &"fade", issue
## #442; experiments/physics_lab/results/2026-10-28_tone): his legs give first, his arms last, each
## man in his own way and the same way every time; the springs are gone when the fade ends. Off by
## default (the game falls as before until Sean says). &"dying" adds what he does as he goes: a free
## hand finds a hole in his front, never one in his back.

var world: Node3D
var man: HumanBody


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	man = HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(2)


func after_each() -> void:
	HumanBody.tone_style = &""
	world.queue_free()
	await physics_frames(1)


func _end(seg: StringName) -> float:
	var w: Vector2 = man._tone_when[man._tone_index[seg]]
	return w.x + w.y


func test_off_by_default() -> void:
	check_eq(HumanBody.tone_style, &"", "the game's tone is today's until Sean turns the fade on")
	man.go_limp()
	check(man._tone_when.is_empty(), "no regions without the fade")


func test_legs_go_first_arms_last_and_the_springs_end() -> void:
	HumanBody.tone_style = &"fade"
	man.go_limp()
	check_eq(man._tone_when.size(), man._tone.size(), "every joint has its region's time")
	var legs := maxf(_end(&"shin_l"), _end(&"shin_r"))
	var arms := minf(_end(&"upper_arm_l"), _end(&"upper_arm_r"))
	# One man in five folds at the waist first (TONE_TRUNK_FIRST); seed 1 isn't one of them.
	check(legs < _end(&"abdomen"), "his legs let go before his trunk (%.2f / %.2f s)" % [legs, _end(&"abdomen")])
	check(legs < arms, "his legs let go before his arms (%.2f / %.2f s)" % [legs, arms])
	check(absf(_end(&"shin_l") - _end(&"shin_r")) > 0.05, "one leg goes before the other")
	await physics_frames(int((man._tone_until + 0.1) * 60.0))
	check(man._tone.is_empty(), "the springs are gone once the fade ends")
	await physics_frames(120)
	var chest := (man.parts[&"chest"] as Node3D).global_position
	check(chest.y < 0.5, "he's down (chest %.2f m up)" % chest.y)


func test_each_man_his_own_way_the_same_every_time() -> void:
	HumanBody.tone_style = &"fade"
	var a := man._tone_regions(false, false)
	var again := man._tone_regions(false, false)
	man.rng_seed = 2
	var b := man._tone_regions(false, false)
	check_eq(a, again, "the same man lets go the same way")
	check(a != b, "another man lets go his own way")
	var dead := man._tone_regions(true, false)
	check((dead[&"arms"] as Vector2).y < (b[&"arms"] as Vector2).y, "killed outright he goes quicker")


func test_dying_a_hand_finds_his_front_not_his_back() -> void:
	HumanBody.tone_style = &"dying"
	man.go_limp()
	var belly := man.parts[&"abdomen"] as Node3D
	# His back first (his front is -z): out of reach.
	man._hunch(&"abdomen", belly.global_transform * Vector3(0.0, 0.0, 0.12), belly.global_basis.z * -1.0)
	check(man._dying.is_empty(), "no hand goes round to a hole in his back")
	man._hunch(&"abdomen", belly.global_transform * Vector3(0.03, 0.0, -0.11), belly.global_basis.z)
	check_eq(man._dying.size(), 1, "a hand goes to the hole in his belly")
	await physics_frames(int((man._tone_until + 0.2) * 60.0))
	check(man._dying.is_empty(), "and comes away as his arm's tone goes")

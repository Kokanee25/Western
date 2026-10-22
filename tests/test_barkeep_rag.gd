extends TestCase
## The barkeep's rag (docs/briefs/barkeep-rag.md): the cloth (ClothProp, the kit's "cloth") hangs
## over his shoulder, is held, dropped, knocked off, picked up, burns and bloodies; his chore
## (WipeBar, in CivilianBrain) takes it off and wipes the bar when he's idle, stops for a customer,
## tosses it down at trouble and fetches it when it's lost. HumanBody.reach_to puts his hand there.

const POST := Vector3(0.0, 0.0, -0.74)
const FACES := Vector3(0.0, 1.4, 2.0)
const BAR_TOP := 1.095

var world: Node3D
var man: HumanBody
var brain: CivilianBrain
var cloth: ClothProp
var chore: WipeBar


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	var bar := PropKit.spawn(&"bar")
	world.add_child(bar)


func after_each() -> void:
	world.queue_free()
	man = null
	brain = null
	cloth = null
	chore = null
	await physics_frames(2)


## The barkeep behind the bar, his cloth over his shoulder; with `mind`, his brain and its chore
## (quick: a second idle and a short stretch).
func _barkeep(mind := true) -> void:
	man = HumanBody.new()
	man.body_model = &"barkeep_s2_talking"
	man.person_id = &"barkeep"
	man.rng_seed = 102
	man.has_gun = false
	if mind:
		brain = CivilianBrain.new()
		brain.name = "Brain"
		brain.post = POST
		brain.faces = FACES
		man.add_child(brain)
	world.add_child(man)
	man.global_position = POST
	man.face(FACES)
	cloth = PropKit.make(&"bar_cloth") as ClothProp
	world.add_child(cloth)
	await physics_frames(2)
	cloth.hang_on(man, "l")
	if mind:
		chore = WipeBar.new(man, cloth, POST, FACES)
		chore.tuning = chore.tuning.duplicate()
		chore.tuning.idle_before = 0.5
		chore.tuning.wipe_seconds = Vector2(1.5, 1.5)
		chore.tuning.glass_chance = 0.0
		chore.set(&"_rest", 0.0)
		brain.chore = chore


func _wiping() -> bool:
	return chore.step == WipeBar.Step.WIPE


func test_the_cloth_hangs_over_his_shoulder() -> void:
	await _barkeep(false)
	await physics_frames(90)
	var top := ClothProp.shoulder_top(man, "l")
	var r := cloth.height_range()
	check_eq(cloth.held, ClothProp.Held.SHOULDER, "it's over his shoulder")
	check(r.y < top.y + 0.04 and r.y > top.y - 0.05, "its top lies on his shoulder (%.3f by %.3f)" % [r.y, top.y])
	check(r.x < top.y - 0.08, "the rest hangs down off it (lowest %.3f)" % r.x)
	check(r.x > top.y - 0.3, "no further than half its length (lowest %.3f)" % r.x)
	check(cloth.centre().distance_to(top) < 0.2, "it's on him, not fallen off")
	man.global_position += Vector3(0.5, 0.0, 0.0)
	await physics_frames(30)
	check(cloth.centre().distance_to(ClothProp.shoulder_top(man, "l")) < 0.2, "it goes where he goes")


func test_his_hand_goes_where_a_deed_puts_it() -> void:
	await _barkeep(false)
	var at := Vector3(0.1, BAR_TOP + 0.03, -0.25)
	for i in 20:
		man.reach_to("r", at, Vector3.UP, 1.0)
		await physics_frames(1)
	check(man.palm("r").distance_to(at) < 0.04, "his palm is on the bar where it was put (%.3f off)" % man.palm("r").distance_to(at))
	# Out of reach: as far toward it as the arm goes, not back to his side.
	var far := Vector3(0.1, BAR_TOP + 0.03, 1.5)
	for i in 10:
		check(not man.can_reach("r", far) or i > 0, "the far end of the bar is out of his reach")
		man.reach_to("r", far, Vector3.UP, 1.0)
		await physics_frames(1)
	check(man.palm("r").z > -0.2, "his arm's out toward it (%.3f)" % man.palm("r").z)
	# Nobody renews it: the arm goes back to his pose.
	await physics_frames(20)
	check(man.palm("r").y < 1.1, "his hand's back by his side")


func test_held_dropped_and_it_lies_on_the_floor() -> void:
	await _barkeep(false)
	var top := ClothProp.shoulder_top(man, "l") + Vector3.UP * 0.02
	for i in 30:
		man.reach_to("r", top, Vector3.UP, 1.0)
		await physics_frames(1)
	cloth.hold(man, "r")
	check_eq(cloth.held, ClothProp.Held.HAND, "it's in his hand")
	check(cloth.pinned_points().size() >= ClothProp.GRIP_MIN, "his hand has it by a few points")
	var out := man.global_transform * Vector3(0.45, 1.2, 0.05)  # out at his side, clear of the bar
	for i in 40:
		man.reach_to("r", top.lerp(out, i / 30.0), Vector3.UP, 1.0)
		await physics_frames(1)
	check(cloth.centre().distance_to(out) < 0.3, "it comes away with his hand")
	check(cloth.height_range().x < out.y - 0.1, "and hangs from it")
	cloth.let_go()
	await physics_frames(150)
	var r := cloth.height_range()
	check_eq(cloth.held, ClothProp.Held.FREE, "let go, nobody has it")
	check(r.x > -0.01, "it's on the floor, not through it (%.3f)" % r.x)
	check(r.y < 0.12, "lying there (%.3f)" % r.y)


func test_a_shove_or_a_blast_knocks_it_off_his_shoulder() -> void:
	await _barkeep(false)
	await physics_frames(30)
	Events.deed.emit(null, &"shove", man, man.global_position)
	check_eq(cloth.held, ClothProp.Held.FREE, "a shove knocks it off")
	await physics_frames(120)
	check(cloth.height_range().y < BAR_TOP + 0.1, "it falls off him (onto the bar in front of him: %.3f)" % cloth.height_range().y)
	cloth.hang_on(man, "l")
	await physics_frames(30)
	Blast.detonate(world, man.global_position + Vector3(3.5, 0.3, 3.0), 0.03)
	await physics_frames(2)
	check_eq(cloth.held, ClothProp.Held.FREE, "a stick going off across the room blows it off")


func test_he_goes_down_and_it_comes_off_him() -> void:
	await _barkeep(false)
	await physics_frames(30)
	man.go_limp()
	await physics_frames(2)
	check_eq(cloth.held, ClothProp.Held.FREE, "it's off him as he goes")


func test_it_catches_burns_away_and_water_puts_it_out() -> void:
	var fire := FireSystem.new()
	world.add_child(fire)
	var a := PropKit.make(&"bar_cloth") as ClothProp
	a.definition = a.definition.duplicate()
	a.definition.burn_seconds = 3.0
	a.position = Vector3(0, 0.05, 2.0)
	world.add_child(a)
	await physics_frames(60)
	fire.spill(Vector3(0.3, 0.0, 2.0))
	var caught := await wait_until(func() -> bool: return a.burning, int((a.definition.catch_seconds + 1.0) * 60))
	check(caught, "in the flames it catches in about %.0f s" % a.definition.catch_seconds)
	check(fire.spills.size() == 2, "it's a fire of its own (FireSystem.small_fire)")
	check(int(fire.fire_near(a.centre(), 0.1).count) > 0, "people getting clear see it")
	var gone := await wait_until(func() -> bool: return a.burnt, 5 * 60)
	check(gone, "it burns away")
	check(not a.soft.visible, "nothing left of it")
	check(fire.spills.size() == 1, "its fire's out with it")
	# Another, put out with water.
	var b := PropKit.make(&"bar_cloth") as ClothProp
	b.position = Vector3(3.0, 0.05, 2.0)
	world.add_child(b)
	await physics_frames(10)
	b.ignite()
	await physics_frames(20)
	fire.douse(b.centre(), 0.5, 2.0)
	check(not b.burning, "a bucket on it puts it out")
	check(b.wet > 0.0, "and it's wet")


func test_burning_in_his_hand_he_drops_it() -> void:
	await _barkeep(false)
	world.add_child(FireSystem.new())
	cloth.hold(man, "r")
	cloth.ignite()
	await physics_frames(20)
	check_eq(cloth.held, ClothProp.Held.FREE, "nobody holds a burning rag")


func test_pressed_on_his_wound_it_bloodies() -> void:
	await _barkeep(false)
	# In his right hand down by his side, then a ball in his right flank: that hand goes to it.
	var hand_at := man.palm("r")
	cloth.place(Transform3D(Basis.IDENTITY, hand_at))
	cloth.hold(man, "r")
	var part := man.parts[&"abdomen"] as Node3D
	var side := man.global_basis.x
	var at := part.global_position + side * 0.11 - man.global_basis.z * 0.06
	var dir := (-side * 0.6 + man.global_basis.z * 0.8).normalized()
	man.take_bullet(part, at - dir * 0.05, dir, 250.0, 0.0057)
	check_eq(man.grab_side(), "r", "the hand with the cloth goes to the wound")
	await physics_frames(8 * 60)
	check(cloth.blood_ml > 0.5, "it takes up the blood under his hand (%.1f ml)" % cloth.blood_ml)
	check(cloth.bloodiness() > 0.0, "it's red where it's pressed")
	check(man.wound_under_hand("r") > 0.0 or man.physiology.alive == false, "his hand's on a bleeding wound")


func test_idle_he_takes_it_off_and_wipes_the_bar() -> void:
	await _barkeep()
	var wiping := await wait_until(_wiping, 6 * 60)
	check(wiping, "idle with nobody at the bar, he's wiping it")
	check(chore.cycles == 1, "one go started")
	check_eq(cloth.held, ClothProp.Held.HAND, "the cloth's in his hand")
	check(cloth.holder == man, "his")
	await physics_frames(30)
	var lowest := INF
	var palm_off := 0.0
	for i in 40:
		await physics_frames(1)
		lowest = minf(lowest, cloth.height_range().x)
		palm_off = maxf(palm_off, absf(man.palm("r").y - (BAR_TOP + chore.tuning.palm_above)))
	check(palm_off < 0.03, "his hand rides the bar top (%.3f off)" % palm_off)
	check(lowest > BAR_TOP - 0.06, "the cloth's on the bar, not through it (lowest %.3f)" % lowest)
	var bone := man.finger_bones[&"index_r"][0] as Node3D
	check(absf(bone.rotation_degrees.z) > 5.0, "his fingers are round it")
	check(chore.watching != Vector3.INF and chore.watching.distance_to(man.palm("r")) < 0.15, "he watches his hand")


func test_a_go_ends_with_it_back_over_his_shoulder() -> void:
	await _barkeep()
	chore.tuning.stretches = Vector2i(2, 2)
	var done := await wait_until(func() -> bool: return chore.stopped == &"done", 25 * 60)
	check(done, "he finishes")
	check_eq(chore.wiped, 2, "two stretches of bar")
	check_eq(cloth.held, ClothProp.Held.SHOULDER, "and puts it back over his shoulder")
	check(cloth.holder == man, "his")
	check(chore.step == WipeBar.Step.IDLE, "then rests")


func test_a_customer_stops_him() -> void:
	await _barkeep()
	await wait_until(_wiping, 6 * 60)
	var c := HumanBody.new()
	c.body_model = &"outlaw"
	c.has_gun = false
	c.rng_seed = 9
	world.add_child(c)
	c.global_position = Vector3(0.2, 0.0, 0.9)
	var back := await wait_until(func() -> bool: return chore.step == WipeBar.Step.IDLE, 3 * 60)
	check(back, "someone at the bar: he stops")
	check_eq(chore.stopped, &"customer", "for the customer")
	check_eq(cloth.held, ClothProp.Held.SHOULDER, "the cloth back over his shoulder")
	await physics_frames(3 * 60)
	check(chore.step == WipeBar.Step.IDLE, "and doesn't start again while he's there")
	c.global_position = Vector3(4.0, 0.0, 3.0)
	var again := await wait_until(_wiping, 6 * 60)
	check(again, "gone, he's back to wiping")


func test_trouble_and_the_cloth_is_tossed_down_then_fetched() -> void:
	await _barkeep()
	await wait_until(_wiping, 6 * 60)
	Events.noise.emit(Vector3(1.5, 1.2, 2.0), 1.0, &"gunshot", null)
	await physics_frames(2)
	check_eq(brain.mood, CivilianBrain.Mood.COWERING, "a shot close by: he cowers")
	check_eq(chore.stopped, &"trouble", "the chore stops")
	check_eq(cloth.held, ClothProp.Held.FREE, "the cloth tossed down")
	var fetched := await wait_until(func() -> bool: return cloth.held == ClothProp.Held.SHOULDER, 30 * 60)
	check(fetched, "calm again, he gets it and puts it back over his shoulder")


func test_knocked_out_of_his_hand_onto_the_floor_he_bends_for_it() -> void:
	await _barkeep()
	await wait_until(_wiping, 6 * 60)
	cloth.knock(Vector3(0.0, 1.0, -4.0) * cloth.soft.total_mass)
	await physics_frames(2)
	check(chore.step != WipeBar.Step.WIPE, "he stops wiping with an empty hand")
	var fetched := await wait_until(func() -> bool: return cloth.held == ClothProp.Held.SHOULDER, 12 * 60)
	check(fetched, "he picks it up and puts it back over his shoulder")
	check(cloth.holder == man, "his")

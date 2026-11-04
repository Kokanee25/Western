extends TestCase
## What you're told when you're hit, and when the gun won't do what you pressed (#607: the third
## blind playtest of D+ was told "Hit in the forearm" for a ball that went on into its gut, "Your
## ear finger's gone.", "It's pumping." for a bleed inside, "going pale with no wound to show for
## it" with a hole in it, nothing when its revolver was empty, and a near miss for every hit).

var world: Node3D
var player: Player
var shown: Array[String] = []


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
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	shown.clear()
	await physics_frames(3)
	player.wounds.shown.connect(func(t: String) -> void: shown.append(t))


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## A ball's way through you as the anatomy gives it: one trace a part, with what it did there.
func _trace(segment: StringName, hits: Array) -> Dictionary:
	var out := []
	for h: Array in hits:
		var st := player.wounds.anatomy.structure(h[0])
		out.append({"id": h[0], "kind": st.kind, "effect": h[1]})
	return {"segment": segment, "hits": out, "track_cm": 12.0, "radius": 0.0057}


func _words(traces: Array) -> String:
	var bleeds: Array = []
	for tr: Dictionary in traces:
		bleeds.append_array(player.wounds.physiology.apply_trace(tr))
	return player.wounds.hit_words(traces, bleeds)


func test_the_wound_that_matters_is_named() -> void:
	# Fight 8: in through the forearm, on into the gut. The gut's what you're told first.
	var w := _words([_trace(&"forearm_r", [[&"radius_r", &"broken"]]), _trace(&"abdomen", [[&"small_intestine", &"torn"]])])
	check(w.begins_with("Hit in the abdomen and the forearm."), "the gut first, then where it went in: %s" % w)
	check(w.contains("You're gut-shot."), "gut-shot: %s" % w)
	check(w.contains("Your forearm's broken."), "and the arm: %s" % w)


func test_a_chest_shot_through_the_arm_says_both() -> void:
	# Fight 3: told only of the chest, and then the gun went for "a broken upper arm".
	var w := _words([_trace(&"upper_arm_r", [[&"humerus_r", &"broken"]]), _trace(&"chest", [[&"lung_r", &"torn"]])])
	check(w.begins_with("Hit in the chest"), "the chest first: %s" % w)
	check(w.contains("A lung's holed.") and w.contains("Your upper arm's broken."), "and the arm, as the gun's reason says it: %s" % w)
	check(player.wounds.physiology.why_cant_hold("r").contains("upper arm"), "the reason the gun goes is the arm you were told of")


func test_an_ear_is_an_ear() -> void:
	var w := _words([_trace(&"head", [[&"ear_l", &"severed"]])])
	check(not w.contains("finger"), "no ear finger: %s" % w)
	check(w.contains("Your ear's shot off."), "your ear: %s" % w)
	w = _words([_trace(&"hand_r", [[&"index_r", &"severed"]])])
	check(w.contains("Your index finger's gone."), "a finger's a finger: %s" % w)


func test_pumping_only_when_it_pumps_out() -> void:
	# Fight 5: "Hit in the pelvis. It's pumping." while bleeding a little: the iliac bleeds inside.
	var w := _words([_trace(&"pelvis", [[&"iliac_r", &"cut"]])])
	check(not w.contains("pumping"), "an artery inside doesn't pump out: %s" % w)
	check(w.contains("You're bleeding inside."), "it bleeds inside: %s" % w)
	w = _words([_trace(&"thigh_l", [[&"femoral_l", &"cut"]])])
	check(w.contains("It's pumping."), "the femoral does: %s" % w)
	w = _words([_trace(&"forearm_l", [[&"median_nerve_l", &"cut"]])])
	check(not w.contains("pumping"), "a nerve doesn't bleed: %s" % w)


func test_pale_with_a_wound_to_show() -> void:
	var p := player.wounds.physiology
	_words([_trace(&"abdomen", [[&"liver", &"torn"]])])
	p.blood_ml *= 0.6  # (a good deal of it gone already)
	var d := p.describe()
	check(not d.contains("no wound to show"), "a hole in you is a wound to show: %s" % d)
	if p.shock() > 0.2:
		check(d.contains("bleeding inside"), "bleeding inside: %s" % d)


func test_out_of_cartridges_is_said() -> void:
	var gun := player.revolver()
	gun.needs_captured_mouse = false
	player.select_weapon(gun)
	gun.take_out()
	check(await wait_until(func() -> bool: return gun.is_ready_in_hand(), 90), "gun in hand")
	gun.state.belt = 0
	for i in gun.state.chambers.size():
		gun.state.chambers[i] = RevolverState.Chamber.EMPTY
	check_eq(gun.why_not(&"reload"), "you're out of cartridges", "why the reload won't load")
	Input.action_press(&"reload")
	await physics_frames(2)
	Input.action_release(&"reload")
	await physics_frames(2)
	check(shown.has("You're out of cartridges."), "said on the screen: %s" % str(shown))
	gun.state.belt = 6
	check_eq(gun.why_not(&"reload"), "", "with cartridges on the belt it loads")
	gun.put_away()
	await physics_frames(2)
	check_eq(gun.why_not(&"reload"), "your gun's put away", "put away")
	shown.clear()
	Input.action_press(&"reload")
	await physics_frames(2)
	Input.action_release(&"reload")
	await physics_frames(2)
	check(shown.has("Your gun's put away."), "said: %s" % str(shown))


func test_a_hit_isnt_a_near_miss_too() -> void:
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	player.global_position = Vector3(0, 0, -6)
	await physics_frames(2)
	var near := []
	var hit := []
	var on_near := func(p: Node, _s: Node, d: float, _at: Vector3, _v: float, _tum: bool) -> void:
		if p == player:
			near.append(d)
	var on_hit := func(info: Dictionary) -> void:
		if info.get("person") == player.wounds:
			hit.append(info)
	Events.near_miss.connect(on_near)
	Events.bullet_hit.connect(on_hit)
	var t: RevolverTuning = load("res://config/revolver.tres")
	ballistics.fire(Vector3(0, 1.3, 0), Vector3.FORWARD, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await physics_frames(20)
	Events.near_miss.disconnect(on_near)
	Events.bullet_hit.disconnect(on_hit)
	check(not hit.is_empty(), "the ball hit you")
	check(near.is_empty(), "and didn't also pass you: %s" % str(near))

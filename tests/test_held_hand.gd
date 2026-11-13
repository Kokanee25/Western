extends TestCase
## The hands holding the guns (#890): a MetaHuman's finger frames put into the painted men's, his
## rest curl measured, the holds chosen by whose arms you have; with the private arms file (never in
## this repo: tools/characters/fetch_arms.sh) both hands cut with his sleeves.

var _was := true


func before_each() -> void:
	_was = HeldHand.use_private


func after_each() -> void:
	HeldHand.use_private = _was
	HeldHand.reset()


## A right finger along -Z (hand space), its middle joint bent 30 degrees towards the palm (-X), its
## bones framed as a MetaHuman's are (+Y to the tip, the hinge flipped): after, each bone's +Y runs
## back along it, +Z is the hinge (-Y), and the bend is read as its rest curl.
func test_a_metahuman_finger_is_framed_as_the_painted_men_s() -> void:
	var rests := {}
	var bend := deg_to_rad(30.0)
	var o0 := Vector3(0.0, 0.0, 0.0)
	var o1 := Vector3(0.0, 0.0, -0.045)
	var d1 := Vector3(-sin(bend), 0.0, -cos(bend))
	var o2 := o1 + d1 * 0.03
	for f: String in HeldHand.FINGERS + ["thumb"]:
		var flipped := Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))   # +Y to the tip
		rests["finger_%s_r_0" % f] = Transform3D(flipped, o0)
		rests["finger_%s_r_1" % f] = Transform3D(flipped, o1)
		rests["finger_%s_r_2" % f] = Transform3D(flipped, o2)
	var curl: Dictionary = HeldHand._canonical_fingers(rests, "r")
	var b0: Basis = (rests["finger_middle_r_0"] as Transform3D).basis
	var b1: Basis = (rests["finger_middle_r_1"] as Transform3D).basis
	check(b0.y.dot(Vector3(0, 0, 1)) > 0.99, "bone 0's +Y runs back towards the wrist")
	check(b1.y.dot(-d1) > 0.99, "bone 1's +Y runs back along it")
	check(b1.z.dot(Vector3(0, -1, 0)) > 0.95, "its +Z is the knuckle's hinge")
	check(absf(b1.x.dot(b1.y.cross(b1.z)) - 1.0) < 1e-4, "a right-handed frame")
	check_near(float(curl["finger_middle_r_0"]), 0.0, 0.5, "bone 0 straight from the hand")
	check_near(float(curl["finger_middle_r_1"]), 30.0, 0.5, "bone 1's rest bend towards the palm")
	check((rests["finger_middle_r_1"] as Transform3D).origin.is_equal_approx(o1), "joints stay where they are")


## Without the MetaHuman arms the guns keep their own holds; with them, his.
func test_the_holds_follow_whose_arms_you_have() -> void:
	HeldHand.use_private = false
	HeldHand.reset()
	check(not HeldHand.metahuman(), "the painted arms when told")
	check(HeldHand.hold("colt.grip", HandModel.GRIP) == HandModel.GRIP, "the Colt's own grip")
	check(HeldHand.hold("win73.l_roll", 0.0) == 0.0, "the rifle's left hand unturned")
	HeldHand.use_private = true
	if not ResourceLoader.exists(HeldHand.PRIVATE_ARMS):
		check(not HeldHand.metahuman(), "no private file here: still the painted arms")
		return
	check(HeldHand.metahuman(), "the private file is in: his arms")
	check(HeldHand.hold("colt.grip", HandModel.GRIP) == HeldHand.MH_HOLDS["colt.grip"], "his grip on the Colt")


## The private arms (where they're fetched): each hand cut with its skin and its sleeve, his finger
## bones' rest curl read, and a pose that closes the hand moves its skin.
func test_the_metahuman_hands_are_cut_with_their_sleeves() -> void:
	HeldHand.use_private = true
	HeldHand.reset()
	if not HeldHand.metahuman():
		check(true, "no private arms file here (CI): nothing to cut")
		return
	for side in ["r", "l"]:
		var s := HeldHand.source(side)
		check((s.parts as Array).size() == 2, "%s: skin and sleeve" % side)
		check(int(s.triangles) > 10000, "%s: his arm whole (%d triangles)" % [side, int(s.triangles)])
		check(float((s.rest_curl as Dictionary)["finger_middle_%s_1" % side]) > 5.0, "%s: his rest hand half closed" % side)
	var h := HeldHand.new(true)
	add_child(h)
	h.build()
	var open := h.surface_points("finger_middle_r_2")
	h.grasp("middle", 80.0)
	var shut := h.surface_points("finger_middle_r_2")
	check(open.size() > 50 and open.size() == shut.size(), "the fingertip's skin found")
	check(open[0].distance_to(shut[0]) > 0.02, "closing the hand moves the fingertip's skin")
	h.queue_free()

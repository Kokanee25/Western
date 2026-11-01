class_name PostPose
extends RefCounted
## A man bladed behind a narrow post (a gallery's 8x8 timber), as Sean described it (issue #531,
## 2026-11-01): turned side-on to the threat with his left shoulder against the post's face, his
## left arm hanging beside it, the right upper arm down against his ribs, the elbow bent about
## square and the forearm across his stomach or lower chest, the revolver pointing along it out
## past the post's edge (his right of it as he looks at the threat). Point-fired, not aimed: the
## gun is too low to sight. His head turned to the threat, eye just past the edge; legs behind the
## post.
##
## Not one pose but a family (Sean: "I don't want the exact same pose and animation for everyone"):
## `dials(seed)` draws a man's own numbers (legs straight or staggered, a bit of chest or his
## backside showing, the forearm's height and line, the head's peek, and one in four just shooting
## in the regular way, arm out, as tucked in as he can), as the falls and FaceLife draw theirs.
## `make(body, d)` turns them into the joints' turns (degrees, POSES' axes), worked out from where
## the elbow and forearm have to be (in front of his belly, along the threat's line) rather than
## typed in, so his own anatomy's lengths decide the angles.
##
## The rig: he faces -Z, his right is +X; +Y turns the trunk and head to his left. The threat is
## to his left (-X) when bladed: `yaw(from, threat, d)` is the yaw that puts it there.
##
## Only a still pose so far (Sean: the pose first, then the cover that uses it). Not yet: entering
## it, holding it as he watches, shooting round the post, recoil, leaving; the brain doesn't pick
## it. `HumanBody.face` would turn him square again, so a brain using it must not call face().
##
## The point-fired shot (a rule, for when the brain shoots from it; not in OutlawBrain yet):
## pointed by the body's index, not the sights, so variant A's cone widens: spread x POINT_SPREAD
## plus POINT_SPREAD_ADD degrees, and no hold-over for range (he can't lay the sights over). Point
## shooting's practice (Fairbairn and Sykes, "Shooting to Live", 1942; the US Army's quick-kill
## and the FBI's close-quarters courses) puts it at a man's chest out to about 7 m and falling off
## past 10-15 m, about two and a half times the aimed group: 2.4 degrees calm becomes ~7.5. And he
## can only point where his forearm points: the threat within POINT_ARC degrees of it, or he
## shifts first.

const POINT_SPREAD := 2.5
const POINT_SPREAD_ADD := 1.5
const POINT_ARC := 25.0
## The gallery's posts (experiments/building_lab/saloon.json "post": 8x8 in).
const POST_WIDTH := 0.2
## Half the revolver's width about the middle of his hand (m): what has to clear the post's edge.
const GUN_HALF := 0.035


## The cone a point-fired shot spreads in (degrees), from what his aimed one would be.
static func point_spread(aimed_degrees: float) -> float:
	return aimed_degrees * POINT_SPREAD + POINT_SPREAD_ADD


## A man's own numbers for the pose, drawn from his seed.
static func dials(seed: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed, "post_pose"])
	var regular := r.randf() < 0.25
	var show_roll := r.randf()
	var show := &"none" if show_roll < 0.5 else (&"chest" if show_roll < 0.75 else &"backside")
	var d := {
		"style": &"regular" if regular else &"cross",
		"show": show,
		# How far he's turned from side-on toward the threat (degrees): a man showing his chest more.
		"turn": r.randf_range(40.0, 55.0) if regular else (r.randf_range(14.0, 22.0) if show == &"chest" else r.randf_range(0.0, 8.0)),
		# His trunk's twist toward the threat over the hips (degrees; abdomen and chest share it).
		"twist": r.randf_range(18.0, 26.0) if show == &"chest" else r.randf_range(4.0, 12.0),
		# The elbow's lowest height (m, on the rig at rest: the abdomen runs 1.0 to 1.16, the chest to
		# 1.37; make() raises it till the forearm clears his belly) and how far in toward his side it
		# sits (m): the forearm across his stomach or lower chest.
		"elbow_h": r.randf_range(1.10, 1.17),
		"elbow_in": r.randf_range(-0.005, 0.02),
		# The forearm's line off the threat's (degrees: + further to his left, + up).
		"hold_yaw": r.randf_range(-5.0, 4.0),
		"hold_pitch": r.randf_range(-5.0, 1.0),
		# The gun canted off level about the barrel (degrees).
		"cant": r.randf_range(-12.0, 12.0),
		# How far his eye is past the post's edge (m: he leans out enough to see, place_at), and the
		# chest's lean forward with it (degrees), the head tipped toward the post.
		"peek": r.randf_range(0.01, 0.04),
		"lean": r.randf_range(2.0, 6.0),
		"head_tilt": r.randf_range(0.0, 8.0),
		"head_short": r.randf_range(0.0, 10.0),  # his eyes do the rest of the turn
		"legs": &"staggered" if r.randf() < 0.4 else &"straight",
		"stagger": r.randf_range(8.0, 16.0),
		"knees": r.randf_range(0.0, 6.0),
		"left_hang": r.randf_range(1.0, 4.0),
		"left_bend": r.randf_range(4.0, 12.0),
	}
	return d


## The yaw (as Node3D.global_rotation.y) that blades him to the threat: side-on with it at his
## left, turned toward it by the dials' `turn`.
static func yaw(from: Vector3, threat: Vector3, d: Dictionary) -> float:
	return HumanBody.yaw_toward(from, threat) - deg_to_rad(90.0 - float(d.turn))


## The joints' turns for the pose (segment -> degrees, POSES' axes). His trunk stays behind the
## post (place_at centres it there); he leans out over it, forward, till his leading eye is `peek`
## past the post's edge (he has to see: Sean, "leans out enough to see, but tries to keep his head
## hidden").
static func make(body: HumanBody, d: Dictionary) -> Dictionary:
	var extra := 0.0
	var out := _build(body, d, extra)
	var need := POST_WIDTH * 0.5 + float(d.peek)
	for i in 20:
		if _eye_out(body, out, d) >= need or extra >= 24.0:
			break
		extra += 1.5
		out = _build(body, d, extra)
	return out


## How far his leading eye is out past his trunk's middle, across the threat's line toward his
## front (m, rig frame), in the pose `out`.
static func _eye_out(body: HumanBody, out: Dictionary, d: Dictionary) -> float:
	var xf := _fk(body, out)
	var l := deg_to_rad(90.0 - float(d.turn))
	var across := Vector3(cos(l), 0.0, -sin(l))  # square to the threat's line, toward his front
	var segs: Dictionary = body.anatomy.segments
	var lo := INF
	var hi := -INF
	for sid: StringName in [&"pelvis", &"abdomen", &"chest"]:
		var t: Transform3D = xf[sid]
		var rest: Vector3 = body._pivot_rest(sid)
		for c: Array in segs[sid].capsules:
			for p: Vector3 in [c[0], c[1]]:
				var a := (t * (p - rest)).dot(across)
				lo = minf(lo, a - float(c[2]))
				hi = maxf(hi, a + float(c[2]))
	var head: Transform3D = xf[&"head"]
	return (head * (_eye_rest(segs) - body._pivot_rest(&"head"))).dot(across) - (lo + hi) * 0.5


## Each segment's transform in the rig's frame for the pose `out` (degrees), from his anatomy's
## joints (the standing rig's pivots, unturned at rest).
static func _fk(body: HumanBody, out: Dictionary) -> Dictionary:
	var segs: Dictionary = body.anatomy.segments
	var xf := {}
	for sid: StringName in body.anatomy.segment_order():
		var r: Vector3 = out.get(sid, Vector3.ZERO) * (PI / 180.0)
		var local := Transform3D(Basis.from_euler(r, EULER_ORDER_YXZ), body._pivot_rest(sid))
		var parent: StringName = segs[sid].parent
		if parent != &"":
			local.origin -= body._pivot_rest(parent)
			xf[sid] = (xf[parent] as Transform3D) * local
		else:
			xf[sid] = local
	return xf


## His leading eye at rest (the right one: bladed, the threat at his left): on the head's capsule,
## a little to the side and in front of its middle.
static func _eye_rest(segs: Dictionary) -> Vector3:
	var s: Dictionary = segs[&"head"]
	return ((s.a as Vector3) + (s.b as Vector3)) * 0.5 + Vector3(0.032, 0.01, -float(s.radius) * 0.85)


static func _build(body: HumanBody, d: Dictionary, extra_lean: float) -> Dictionary:
	var segs: Dictionary = body.anatomy.segments
	var out := {}
	var turn: float = d.turn
	var twist: float = d.twist
	# The trunk: the twist over the hips, a little more in the chest; leaning forward to peek.
	var ab_y := twist * 0.4
	var ch_y := twist * 0.6
	var ab_x := -extra_lean * 0.45
	var ch_x := -float(d.lean) - extra_lean * 0.55
	var th_x := 0.0
	var sh_x := -float(d.knees)
	if d.show == &"backside":
		# Hips back, chest over: his seat out behind him past the post.
		ab_x -= 10.0
		ch_x -= 3.0
		th_x += 12.0
		sh_x -= 6.0
	out[&"abdomen"] = Vector3(ab_x, ab_y, 0.0)
	out[&"chest"] = Vector3(ch_x, ch_y, 0.0)
	# The head the rest of the way round to the threat (and tipped toward the post), less what his
	# eyes take.
	var head_left := 90.0 - turn - twist - float(d.head_short)
	# (His eyes kept near level over the trunk's lean.)
	out[&"neck"] = Vector3(-(ab_x + ch_x) * 0.4, head_left * 0.45, -float(d.head_tilt) * 0.4)
	out[&"head"] = Vector3(-(ab_x + ch_x) * 0.5, head_left * 0.55, -float(d.head_tilt) * 0.6)
	# Legs: together behind the post, or one back.
	var st := float(d.stagger) if d.legs == &"staggered" else 0.0
	out[&"thigh_r"] = Vector3(th_x - st, 0.0, 1.5)
	out[&"thigh_l"] = Vector3(th_x + st * 0.6, 0.0, -1.5)
	out[&"shin_r"] = Vector3(sh_x, 0.0, 0.0)
	out[&"shin_l"] = Vector3(sh_x - st * 0.5, 0.0, 0.0)
	out[&"foot_r"] = Vector3(-(th_x - st) - sh_x, 0.0, 0.0)
	out[&"foot_l"] = Vector3(-(th_x + st * 0.6) - (sh_x - st * 0.5), 0.0, 0.0)
	# The left arm hanging, doing nothing, against his side by the post.
	# (Hanging plumb whatever his trunk's lean, and with the gun across him back by part of his
	# turn toward the threat, so his hand doesn't reach the post before his shoulder does.)
	var back := turn * 0.4 if d.style == &"cross" else 0.0
	out[&"upper_arm_l"] = Vector3(-(ab_x + ch_x) - back, 0.0, float(d.left_hang))
	out[&"forearm_l"] = Vector3(float(d.left_bend), 0.0, 0.0)
	# The gun arm, in the chest's frame (the rig at rest; the chest's own turn goes on top).
	var chest_basis := Basis.from_euler(Vector3(deg_to_rad(ch_x), deg_to_rad(ch_y), 0.0), EULER_ORDER_YXZ)
	var ab_basis := Basis.from_euler(Vector3(deg_to_rad(ab_x), deg_to_rad(ab_y), 0.0), EULER_ORDER_YXZ)
	# The threat's line: (90 - turn) to the left of his facing with the hold's own error, level
	# but for it, then into the chest's frame (its turn and lean over the abdomen's).
	var left := deg_to_rad(90.0 - turn + float(d.hold_yaw))
	var pitch := deg_to_rad(float(d.hold_pitch))
	var threat_rig := Vector3(-sin(left) * cos(pitch), sin(pitch), -cos(left) * cos(pitch))
	var threat_dir := (ab_basis * chest_basis).inverse() * threat_rig
	var shoulder: Vector3 = segs[&"upper_arm_r"].a
	var elbow_rest: Vector3 = segs[&"forearm_r"].a
	var wrist_rest: Vector3 = segs[&"hand_r"].a
	var l1 := (elbow_rest - shoulder).length()
	var l2 := (wrist_rest - elbow_rest).length()
	var arm: Array
	if d.style == &"regular":
		# Arm out at the threat, the usual way, the elbow soft.
		var d2 := threat_dir
		var d1 := (d2 + Vector3.DOWN * 0.07).normalized()
		arm = [d1, d2]
	else:
		# The elbow by his ribs at its height, the upper arm as near hanging as it can; the forearm
		# along the threat's line from it, clear of his belly: raised till it is (a higher elbow
		# sits further forward, the upper arm less straight down).
		var h: float = d.elbow_h
		var chest_pivot: Vector3 = segs[&"chest"].a
		var trunk := _trunk_capsules(segs, chest_pivot, chest_basis, ab_basis)
		var fr: float = segs[&"forearm_r"].radius
		for i in 20:
			var e := _elbow(shoulder, l1, float(d.elbow_in), h)
			if _clearance(e, e + threat_dir * l2, fr, trunk) >= 0.005 or h >= 1.33:
				break
			h += 0.01
		var e := _elbow(shoulder, l1, float(d.elbow_in), h)
		arm = [(e - shoulder).normalized(), threat_dir]
	var d1: Vector3 = arm[0]
	var d2: Vector3 = arm[1]
	var hinge := d1.cross(d2)
	if hinge.length() < 0.05:
		hinge = d1.cross(Vector3.UP)
	hinge = hinge.normalized()
	var b1 := _aim(elbow_rest - shoulder, d1, hinge)
	var b2 := _aim(wrist_rest - elbow_rest, d2, hinge)
	# The hand: the gun's top (the hand's -Z) brought up level, then canted by his dial.
	var top := -b2.z
	var want_top := (Vector3.UP - d2 * Vector3.UP.dot(d2)).normalized()
	var roll := top.signed_angle_to(want_top, d2) + deg_to_rad(float(d.cant))
	var b3 := Basis(d2.normalized(), roll) * b2
	out[&"upper_arm_r"] = _deg(b1)
	out[&"forearm_r"] = _deg(b1.inverse() * b2)
	out[&"hand_r"] = _deg(b2.inverse() * b3)
	return out


## Where his elbow sits (rig at rest): `inward` of the shoulder toward his side, at height h, as
## far forward as the upper arm's length leaves it.
static func _elbow(shoulder: Vector3, l1: float, inward: float, h: float) -> Vector3:
	var dx := -inward + 0.012
	var dy := shoulder.y - h
	var dz2 := l1 * l1 - dx * dx - dy * dy
	return Vector3(shoulder.x + dx, h, -sqrt(maxf(dz2, 0.0)))


## The basis turning a limb from its rest line `rest` to `want`, its hinge (the turn that bends the
## next limb forward, +X at rest) to `hinge`.
static func _aim(rest: Vector3, want: Vector3, hinge: Vector3) -> Basis:
	var ry := -rest.normalized()
	var rx := (Vector3.RIGHT - ry * Vector3.RIGHT.dot(ry)).normalized()
	var a_rest := Basis(rx, ry, rx.cross(ry))
	var wy := -want.normalized()
	var wx := (hinge - wy * hinge.dot(wy)).normalized()
	var a_want := Basis(wx, wy, wx.cross(wy))
	return a_want * a_rest.inverse()


static func _deg(b: Basis) -> Vector3:
	var e := b.orthonormalized().get_euler(EULER_ORDER_YXZ)
	return Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z))


## The trunk's capsules (abdomen and chest) in the chest's frame: [a, b, radius] each.
static func _trunk_capsules(segs: Dictionary, chest_pivot: Vector3, chest_basis: Basis, ab_basis: Basis) -> Array:
	var out := []
	var ab_pivot: Vector3 = segs[&"abdomen"].a
	var to_chest := chest_basis.inverse()
	for c: Array in segs[&"chest"].capsules:
		out.append([c[0], c[1], c[2]])
	for c: Array in segs[&"abdomen"].capsules:
		# Into the rig's frame with the abdomen's turn, then into the chest's.
		var pa: Vector3 = ab_basis * ((c[0] as Vector3) - ab_pivot) + ab_pivot
		var pb: Vector3 = ab_basis * ((c[1] as Vector3) - ab_pivot) + ab_pivot
		var cp := ab_basis * (chest_pivot - ab_pivot) + ab_pivot
		out.append([to_chest * (ab_basis.inverse() * (pa - cp)) + chest_pivot, to_chest * (ab_basis.inverse() * (pb - cp)) + chest_pivot, c[2]])
	return out


## The gap between a forearm (a capsule from a to b, radius r) and the nearest trunk capsule (m;
## below 0 they overlap).
static func _clearance(a: Vector3, b: Vector3, r: float, trunk: Array) -> float:
	var best := INF
	for c: Array in trunk:
		best = minf(best, seg_distance(a, b, c[0], c[1]) - r - float(c[2]))
	return best


## The closest two segments come (p1-q1, p2-q2), sampled finely enough for capsules a body's size.
static func seg_distance(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var best := INF
	for i in 21:
		var p := p1.lerp(q1, i / 20.0)
		var seg := q2 - p2
		var t := clampf((p - p2).dot(seg) / maxf(seg.length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, p.distance_to(p2 + seg * t))
	return best


## His capsules where they are now, in the world: [segment, a, b, radius] each (from his joints'
## pivots: the standing rig, as posed).
static func capsules_now(body: HumanBody) -> Array:
	var out := []
	for sid: StringName in body.anatomy.segments:
		var pv := body.pivots.get(sid) as Node3D
		if pv == null:
			continue
		var xf := pv.global_transform
		var rest: Vector3 = body._pivot_rest(sid)
		for c: Array in body.anatomy.segments[sid].capsules:
			out.append([sid, xf * ((c[0] as Vector3) - rest), xf * ((c[1] as Vector3) - rest), float(c[2])])
	return out


## Move him (posed already) so his left shoulder is against the post's face toward him and his
## trunk behind it, centred on its width, then (if his lean hasn't put it there: make) out till his
## leading eye is `peek` m past its front edge and the gun in his hand clears it: a post of `width`
## standing at `post` (its foot), the threat at `threat`. The post's sides are taken square to the
## threat's line.
static func place_at(body: HumanBody, post: Vector3, threat: Vector3, peek := 0.02, width := POST_WIDTH, gap := 0.004) -> void:
	var to := threat - post
	to.y = 0.0
	var fwd := to.normalized()  # from the post toward the threat
	var across := Vector3.UP.cross(fwd)  # the post's width, from the threat's side
	var caps := capsules_now(body)
	# His trunk's middle across.
	var lo := INF
	var hi := -INF
	for c: Array in caps:
		if c[0] in [&"pelvis", &"abdomen", &"chest"]:
			for p: Vector3 in [c[1], c[2]]:
				lo = minf(lo, (p - post).dot(across) - float(c[3]))
				hi = maxf(hi, (p - post).dot(across) + float(c[3]))
	var shift := -(lo + hi) * 0.5
	# Which edge he looks round: the one on his front's side.
	var front := (-body.global_basis.z).dot(across)
	var edge_side := signf(front) if absf(front) > 0.1 else 1.0
	var eye_short := width * 0.5 + peek - edge_side * ((eye_now(body) - post).dot(across) + shift)
	if eye_short > 0.0:
		shift += edge_side * eye_short
	# ... and his gun hand far enough out that the revolver (GUN_HALF either side of his hand's
	# middle) clears the edge.
	for c: Array in caps:
		if c[0] == &"hand_r":
			for p: Vector3 in [c[1], c[2]]:
				var out_by := edge_side * ((p - post).dot(across) + shift) - width * 0.5 - GUN_HALF - gap
				if out_by < 0.0:
					shift -= edge_side * out_by
	# Then up to the post: his nearest part to the threat that's behind the post's width (a toe or
	# a hand out past its side doesn't stop him) against its face.
	var near := -INF
	for c: Array in caps:
		var r: float = c[3]
		for i in 11:
			var p: Vector3 = (c[1] as Vector3).lerp(c[2], i / 10.0) - post
			if absf(p.dot(across) + shift) < width * 0.5 + r:
				near = maxf(near, p.dot(fwd) + r)
	var move := fwd * (-width * 0.5 - gap - near) + across * shift
	body.global_position += Vector3(move.x, 0.0, move.z)


## His eye nearest the way he faces (the right one, bladed with the threat to his left), where it
## is now: on the head's capsule, a little to the side and in front of its middle.
static func eye_now(body: HumanBody) -> Vector3:
	var pv := body.pivots[&"head"] as Node3D
	return pv.global_transform * (_eye_rest(body.anatomy.segments) - body._pivot_rest(&"head"))

extends RefCounted
## A stair of members for any structure (the building lab's; waiting to be promoted into
## src/structures/ as Railing was): two stringers, treads and risers on them, a newel at the foot, a
## railing up its open side (Railing), posts under the stringers where a long one needs them, and
## the walking ramp the player's controller climbs (`Layers.WALK` only: a falling man meets the
## treads). Today's saloon stair (SaloonDressing._stair) is this, fixed to its own room.
##
##   Stair.build(s, "stair/hall", head, Vector3.BACK, Vector3.RIGHT, 1.02, 19, 0.1926, 0.254, {...})
##
## `head` is the top edge's corner on the upper floor (structure space, y the upper floor's top),
## `up` the way the stair climbs (level), `across` the way its width runs from `head`. It comes down
## `risers` risers of `rise` over `risers - 1` treads of `going`. The spec may set `rail` (the side
## the railing goes on: 1 for the far side across, -1 the near, 0 none), `posts` (feet of posts under
## the stringers, [along from the foot, across] in metres), `wood`, `look` and `stringer_look`.
## Returns {"members", "stringers", "ramp"}; the builder takes the ramp away when the stringers go.

const STRINGER := Vector2(0.05, 0.28)
const TREAD_T := 0.035
const NOSING := 0.025
const RISER_T := 0.02


static func build(s: Structure, id: String, head: Vector3, up: Vector3, across: Vector3, width: float, risers: int,
		rise: float, going: float, spec := {}) -> Dictionary:
	var wood: StringName = spec.get("wood", &"framing")
	var look: String = spec.get("look", "")
	var stringer_look: String = spec.get("stringer_look", look)
	var run := going * (risers - 1)
	var height := rise * risers
	var foot := head - up * run - Vector3.UP * height  # the bottom of the first riser, on the lower floor
	var out: Array[StructureMember] = []
	var stringers: Array[StructureMember] = []
	# The stringers: from the lower floor at the foot to the upper floor's edge at the head, their
	# top edge on the treads' nosings.
	var a := foot - up * going
	var b := head
	var along := b - a
	var length := along.length()
	var dir := along / length
	var side := across.normalized()
	var normal := side.cross(dir).normalized()
	if normal.y < 0.0:
		normal = -normal
	var basis := Basis(dir, normal, dir.cross(normal))
	for k in 2:
		var off := STRINGER.x * 0.5 if k == 0 else width - STRINGER.x * 0.5
		var c := (a + b) * 0.5 + side * off - normal * (STRINGER.y * 0.5 - 0.05)
		var m := s.add_member("%s/stringer_%d" % [id, k], &"rafter", wood, Vector3(length, STRINGER.y, STRINGER.x), c, basis)
		stringers.append(m)
		out.append(m)
		if stringer_look != "":
			PropKit.dress_member(m, {}, stringer_look)
		# On the ground a stringer's foot is set on a block (a sill: it rests on the ground).
		if foot.y <= Structure.GROUND_EPSILON:
			var fb := foot - up * (going * 0.5) + side * off
			out.append(s.add_member("%s/foot_%d" % [id, k], &"sill", wood, up.abs() * 0.3 + Vector3.UP * 0.1 + side.abs() * 0.12, fb + Vector3.UP * 0.05))
	# Treads and risers between the stringers.
	for i in risers - 1:
		var top := foot.y + rise * (i + 1)
		var front := foot + up * (going * i)  # the riser's face at this step
		var depth := going + NOSING
		var c := front + up * (depth * 0.5 - NOSING) + side * (width * 0.5)
		c.y = top - TREAD_T * 0.5
		var size := up.abs() * depth + Vector3.UP * TREAD_T + side.abs() * width
		var t := s.add_member("%s/tread/%02d" % [id, i], &"furniture_top", wood, size, c)
		out.append(t)
		var rc := front + up * (RISER_T * 0.5) + side * (width * 0.5)
		rc.y = top - TREAD_T - (rise - TREAD_T) * 0.5
		var r := s.add_member("%s/riser/%02d" % [id, i], &"board", wood, up.abs() * RISER_T + Vector3.UP * (rise - TREAD_T) + side.abs() * (width - 0.1), rc)
		out.append(r)
		if look != "":
			PropKit.dress_member(t, {}, look)
			PropKit.dress_member(r, {}, look)
	# Posts under the stringers.
	for p: Array in spec.get("posts", []):
		var at := foot + up * float(p[0]) + side * float(p[1])
		var t := clampf((at - a).dot(dir) / length, 0.0, 1.0)
		var under := a.lerp(b, t).y - STRINGER.y + 0.05
		var ph := under - foot.y
		if ph > 0.2:
			var m := s.add_member("%s/post/%d" % [id, out.size()], &"post", wood, Vector3(0.1, ph, 0.1), Vector3(at.x, foot.y + ph * 0.5, at.z))
			out.append(m)
	# The rail up the open side, on balusters standing on the stringer's top edge, from a newel at the foot.
	var rail_side: int = spec.get("rail", 1)
	if rail_side != 0:
		var off := width - STRINGER.x * 0.5 if rail_side > 0 else STRINGER.x * 0.5
		var newel_at := foot - up * (going * 0.6) + side * off
		# On a floor it stands as furniture does; on the ground it's set in it, as a post.
		var newel := s.add_member("%s/newel" % id, &"post" if foot.y <= Structure.GROUND_EPSILON else &"furniture_frame", wood, Vector3(0.11, 1.1, 0.11), newel_at + Vector3.UP * 0.55)
		out.append(newel)
		var posts: Array = []
		for i in risers - 1:
			var p := foot + up * (going * (i + 0.5)) + side * off
			p.y = foot.y + rise * (i + 1)
			posts.append(p)
		var ra := newel_at + Vector3.UP * 1.1
		var rb := head + side * off + Vector3.UP * 0.95
		var rails := Railing.build(s, id + "/rail", ra, rb, {"height": 0.0, "posts": posts, "baluster": 0.035,
				"rail": Vector2(0.065, 0.06), "overhang": 0.0, "wood": wood})
		out.append_array(rails)
		if look != "":
			PropKit.dress_member(newel, {"shape": "profile", "profile": "chamfered", "along": "y", "up": "z", "args": [0.012]}, look)
			for m in rails:
				if m.kind == &"trim":
					PropKit.dress_member(m, {"shape": "profile", "profile": "handrail", "along": "x", "up": "y"}, look)
				else:
					PropKit.dress_member(m, {}, look)
	# Something to walk up: the ramp on the treads' nosings, for walkers only.
	var ramp := StaticBody3D.new()
	ramp.name = "Ramp_" + id.validate_node_name().replace("/", "_")
	ramp.collision_layer = Layers.WALK
	ramp.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.05, width)
	shape.shape = box
	ramp.add_child(shape)
	s.add_child(ramp)
	ramp.transform = Transform3D(basis, (a + b) * 0.5 + side * (width * 0.5) - normal * 0.025)
	ramp.set_meta(&"stair", id)
	return {"members": out, "stringers": stringers, "ramp": ramp}

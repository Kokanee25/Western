class_name Railing
extends RefCounted
## A railing of members, for any structure: a balcony's, a stair's, a gallery's. Balusters stand
## on whatever floor is under each, with a rail on their tops in spans of no more than `SPAN`, each
## span its own member. A man thrown into it breaks the span he hits and the balusters under him
## (BodyImpacts), and the rest of it stands. All finish carpentry, nailed lightly, so it gives way at
## its nails before its wood (BodyImpacts.capacity). The ragdoll lab proved it (group Q, round 4).
##
##   Railing.build(s, "balcony/rail_x", a, b)                # level: balusters every 0.15 on a..b
##   Railing.build(s, "stair", foot, head, {"posts": [...]}) # sloped: balusters on given points
##
## `from` and `to` are the line the rail's top follows, less `height`: the floor's edge for a level
## rail. A spec may set `height` (0.95), `spacing` (0.15), `baluster` (0.035 square), `rail` (its
## width and depth, Vector2(0.08, 0.05)), `overhang` past the end balusters (0.04), `wood`
## (dark_trim), `span` (SPAN) and `posts` (each baluster's foot, in place of `spacing`).

## The longest span of rail between joints (m): a rail is cut and nailed about this often.
const SPAN := 1.2


static func build(s: Structure, id: String, from: Vector3, to: Vector3, spec := {}) -> Array[StructureMember]:
	var height: float = spec.get("height", 0.95)
	var bal: float = spec.get("baluster", 0.035)
	var rail: Vector2 = spec.get("rail", Vector2(0.08, 0.05))
	var overhang: float = spec.get("overhang", 0.04)
	var wood: StringName = spec.get("wood", &"dark_trim")
	var out: Array[StructureMember] = []
	var top_a := from + Vector3.UP * height
	var top_b := to + Vector3.UP * height
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var posts: Array = spec.get("posts", [])
	if posts.is_empty():
		var n := maxi(1, int(flat.length() / float(spec.get("spacing", 0.15))))
		for k in n + 1:
			posts.append(from.lerp(to, float(k) / n))
	# Each baluster from its foot up to the rail's underside over it.
	for k in posts.size():
		var p: Vector3 = posts[k]
		var t := clampf(Vector3(p.x - from.x, 0.0, p.z - from.z).dot(flat) / maxf(flat.length_squared(), 1e-6), 0.0, 1.0)
		var h := top_a.lerp(top_b, t).y - rail.y - p.y
		if h < 0.05:
			continue
		out.append(s.add_member("%s/baluster/%02d" % [id, k], &"baluster", wood, Vector3(bal, h, bal),
				Vector3(p.x, p.y + h * 0.5, p.z)))
	# The rail along the top, in spans: x along it, z across it, y up out of it.
	var along := top_b - top_a
	var length := along.length()
	var dir := along / maxf(length, 1e-6)
	var across := dir.cross(Vector3.UP).normalized()
	var up := across.cross(dir).normalized()
	var spans := maxi(1, ceili(length / float(spec.get("span", SPAN)) - 0.001))
	for i in spans:
		var lead := overhang if i == 0 else 0.0
		var tail := overhang if i == spans - 1 else 0.0
		var a := top_a + dir * (length * i / spans - lead)
		var b := top_a + dir * (length * (i + 1) / spans + tail)
		out.append(s.add_member("%s/rail/%02d" % [id, i], &"trim", wood, Vector3(a.distance_to(b), rail.y, rail.x),
				(a + b) * 0.5 - up * rail.y * 0.5, Basis(dir, up, across)))
	return out

extends RefCounted
## A bulkhead (#1174, the undertaker's): a cellar's outside door against a house wall, as the 19th
## century's hatchway was built (New England and the Midwest alike): a stone areaway dug beside the
## wall (two cheek walls and an end wall of the cellar's rubble, from the cellar's floor up to the
## yard), wooden steps down it to the cellar's floor, a passage through the foundation under a stone
## lintel (the builder leaves the gap: `SpecBuilding._foundation`), and over it a frame of two sloping
## cheek timbers on posts, high at the house wall, low at the yard, boarded at the sides, carrying a
## pair of plank doors hinged at the cheeks, which stand open (a man walks down) or lie shut.
##
##   Bulkhead.build(building, spec.bulkhead, wall, {"floor": cellar floor, "flags": its top})
##
## In the wall's frame: `s` along it (spec `z` [s0, s1], the passage), `d` out from its outer face
## (`out` the areaway's length), `y` up. `grade` the yard's ground at it, `risers` and `going` the
## steps', `cheek` the walls' thickness, `high` and `low` the doors' slope's ends, `open`, `wood`.
## Bands: the stone 0 (grounded under the cellar's floor), the frame 1, the steps and the doors 2:
## each rests on what it touches below. Ids `bulkhead/...`. Returns the Stair's dictionary (its ramp).

const Stair := preload("res://src/structures/stair.gd")
const PIECE := 1.2
const POST := 0.1
const RAFTER := Vector2(0.075, 0.15)  # a 3x6 cheek timber, on edge
const LEAF_T := 0.04


static func build(b: Structure, bk: Dictionary, wall: Dictionary, lv: Dictionary) -> Dictionary:
	var s0 := float(bk.z[0])
	var s1 := float(bk.z[1])
	var out := float(bk.out)
	var c := float(bk.get("cheek", 0.3))
	var grade := float(bk.grade)
	var floor := float(lv.floor)
	var flags := float(lv.flags)
	var high := float(bk.high)
	var low := float(bk.low)
	var wood := StringName(bk.get("wood", "framing"))
	var P := func(s: float, d: float, y: float) -> Vector3:
		return (wall.origin as Vector3) + (wall.along as Vector3) * s + (wall.out as Vector3) * d + Vector3.UP * y
	var along: Vector3 = (wall.along as Vector3).abs()
	var outv: Vector3 = wall.out
	var outa := outv.abs()
	var box := func(id: String, kind: StringName, wd: StringName, sa: float, sb: float, da: float, db: float, ya: float, yb: float) -> StructureMember:
		var size := along * (sb - sa) + outa * (db - da) + Vector3.UP * (yb - ya)
		return b.add_member(id, kind, wd, size, P.call((sa + sb) * 0.5, (da + db) * 0.5, (ya + yb) * 0.5))
	var made := {}
	# --- the areaway: its floor, the cheeks and the end wall (band 0) ---
	b.set(&"band", 0)
	var foot_d := float(bk.going) * 0.6
	var i := 0
	var d := 0.0
	while d < foot_d - 0.01:
		var d1 := minf(d + 1.0, foot_d)
		box.call("bulkhead/flag_%d" % i, &"sill", &"stone", s0, s1, d, d1, floor, flags)
		d = d1
		i += 1
	var top := grade + 0.1
	for side in 2:
		var sa := s0 - c if side == 0 else s1
		var n := maxi(1, ceili(out / PIECE))
		for k in n:
			box.call("bulkhead/cheek_%d/%d" % [side, k], &"sill", &"stone", sa, sa + c, out * k / n, out * (k + 1) / n, floor, top)
	box.call("bulkhead/end", &"sill", &"stone", s0, s1, out, out + c, floor, grade)
	# --- the frame on the cheeks (band 1): a post at the wall, the sloping cheek timber, boards ---
	b.set(&"band", 1)
	var rise := high - low
	var ang := atan2(rise, out)
	var slope := (-outv * cos(ang) + Vector3.UP * sin(ang)).normalized()  # up the slope, toward the wall
	var normal := along.cross(slope)
	if normal.y < 0.0:
		normal = -normal
	var lean := Basis(along, normal, along.cross(normal)).orthonormalized()
	var rlen := sqrt(rise * rise + out * out) + 0.1
	for side in 2:
		var sc := s0 - c * 0.5 if side == 0 else s1 + c * 0.5
		box.call("bulkhead/post_%d" % side, &"post", wood, sc - POST * 0.5, sc + POST * 0.5, 0.0, POST, top, high - RAFTER.y * 0.5)
		var mid: Vector3 = P.call(sc, out * 0.5, (high + low) * 0.5 - RAFTER.y * 0.5)
		# (x along the wall, y the timber's depth, z along the slope)
		var r := b.add_member("bulkhead/cheek_timber_%d" % side, &"rafter", wood, Vector3(RAFTER.x, RAFTER.y, rlen), mid, lean)
		made["rafter_%d" % side] = r
		# Boards closing the triangle under it: upright, cut to the slope in steps.
		var nb := maxi(2, floori(out / 0.3))
		for k in nb:
			var da := out * k / nb + 0.005
			var db := out * (k + 1) / nb - 0.005
			var yt := low + rise * (1.0 - (db / out)) - RAFTER.y - 0.01
			if yt > top + 0.05:
				var face := sc - c * 0.5 - 0.02 if side == 0 else sc + c * 0.5
				box.call("bulkhead/side_%d/%d" % [side, k], &"board", wood, face, face + 0.02, da, db, top, yt)
	box.call("bulkhead/header", &"beam", wood, s0 - c, s1 + c, 0.0, 0.1, high - 0.12, high)
	# --- the steps (band 2): the lab's Stair, from the yard at the end wall down to the flags ---
	b.set(&"band", 2)
	var risers := int(bk.risers)
	var rise_each := (grade - flags) / risers
	var head: Vector3 = P.call(s0 + 0.02, out, grade)
	var st := Stair.build(b, "bulkhead/stair", head, outv, along, s1 - s0 - 0.04, risers, rise_each, float(bk.going),
			{"rail": 0, "wood": wood})
	# --- the doors (band 2): two leaves hinged at the cheek timbers' tops ---
	var half := (s1 - s0) * 0.5 + c * 0.4
	for side in 2:
		var hinge_s := s0 - c * 0.5 if side == 0 else s1 + c * 0.5
		var toward := 1.0 if side == 0 else -1.0  # toward the middle, along the wall
		var hinge: Vector3 = P.call(hinge_s, out * 0.5, (high + low) * 0.5) + normal * 0.002
		var lx := along * toward  # across the leaf from its hinge
		var lb := Basis(lx, normal, lx.cross(normal)).orthonormalized()
		if bool(bk.get("open", true)):
			# Turned on its hinge past upright, leaning out over the cheek (95 degrees): the way that
			# lifts its free edge.
			var sg := 1.0 if (Basis(slope, PI * 0.5) * lx).dot(normal) > 0.0 else -1.0
			lb = (Basis(slope, deg_to_rad(95.0) * sg) * lb).orthonormalized()
		var cen := hinge + lb.x * (half * 0.5) + lb.y * (LEAF_T * 0.5)
		var leaf := b.add_member("bulkhead/door_%d" % side, &"door", wood, Vector3(half - 0.01, LEAF_T, rlen - 0.12), cen, lb)
		leaf.set_meta(&"use_role", 3.0)
		made["door_%d" % side] = leaf
	b.set(&"band", 0)
	st["made"] = made
	return st

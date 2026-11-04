class_name MasonryBlast
extends RefCounted
## What a charge does to a masonry wall: destruction-spec.md section 5 ("Big hits break joints"),
## as pure rules over a MasonryWall (no physics). Blast.detonate hands each masonry structure in
## reach to it (MasonryStructure.take_blast), which then breaks, frees and throws what this says.
##
## 1. The push. The face toward the charge takes the reflected pressure p (Blast's Kinney-Graham
##    side-on overpressure x the reflection coefficient) where it's nearest the charge in each
##    element's stretch of it; an element on that face is pushed with F = p x its face x
##    `blast_dynamic_factor`. An element behind it (the far leaf) is pushed by what's in front of it,
##    through their collar joints (in compression: those don't open).
## 2. Joints first. A bonded bed or head joint breaks when the difference in push across it beats
##    its bond: |F_a - F_b| > tension x area. (Sliding in the wall's plane, cohesion + friction x N,
##    is the in-plane rule; a charge's push is out of the plane, so tension governs here.)
## 3. Units crack only when pressed far harder: face pressure > 1.33 x unit tension x (deep/along)².
##    A cracked unit is freed and breaks in two as it goes.
## 4. What's freed flies. An element whose far side is free (the far leaf, a through-stone, or one
##    whose leaf behind has gone) and whose push beats its bonded joints' bond and the friction on
##    its beds (friction x the wall over it pressing them, S4's) loses them all and
##    takes off at v = I / m (the reflected impulse on its face, or what its front leaf passed
##    on). Again until nothing more is freed: the far leaf goes first, then the near one.
## 5. Then the solver (StructuralAnalysis's masonry check) decides what else falls.
##
## The pressure and impulse are Blast's (`overpressure_kpa`, `reflection`, `impulse`); everything
## else is materials.json's (`unit.tension`, the mortars' `tension`, `solver.blast_dynamic_factor`).

## Pressures under this (Pa) aren't worked through (nothing in masonry gives to them).
const FLOOR_PA := 2000.0


## The result: {"broke": joints broken (PackedInt32Array), "freed": element -> velocity (the file's
## space), "cracked": elements cracked (PackedInt32Array), "push": element -> N, "pressure":
## element -> Pa on its face}. `standing`: element -> true for those still in the wall (the rest
## are gone already). `at` in the file's space.
static func strike(wall: MasonryWall, at: Vector3, kg: float, standing: Dictionary, max_throw := 60.0) -> Dictionary:
	var dyn := MasonryMaterials.dial("blast_dynamic_factor", 1.0)
	var n := wall.count()
	var push := {}  # i -> N
	var imp := {}  # i -> N·s
	var pressure := {}
	var dir := {}  # i -> unit push direction (file space)
	var cracked := PackedInt32Array()
	var front := {}  # i -> true: on the face toward the charge
	var far_side := {}  # i -> true: nothing of its wall behind it
	# 1. The push on the face toward the charge.
	for i in n:
		if not standing.has(i) or wall.kinds[i] == &"footing":
			continue
		var k := wall.wall_of[i]
		var thick: float = wall.walls[k].thick
		var c := wall.to_wall(k, at)
		var lo := wall.lo[i]
		var hi := wall.hi[i]
		var outside := c.z < thick * 0.5  # the charge is on the outer face's side
		var face_z := 0.0 if outside else thick
		var on_face := lo.z <= 0.002 if outside else hi.z >= thick - 0.002
		var back_free := hi.z >= thick - 0.002 if outside else lo.z <= 0.002
		if back_free:
			far_side[i] = true
		if not on_face:
			continue
		front[i] = true
		var q := Vector3(clampf(c.x, lo.x, hi.x), clampf(c.y, lo.y, hi.y), face_z)
		var r := maxf(q.distance_to(c), 0.03)
		var side := Blast.overpressure_kpa(kg, r)
		# Pa: the reflected peak as an equivalent static push (`blast_dynamic_factor`: a pulse of a
		# millisecond or so on a stone held by its mortar; the masonry lab's step 2 tuned it).
		var p := side * Blast.reflection(side) * 1000.0 * dyn
		if p < FLOOR_PA:
			continue
		var face := (hi.x - lo.x) * (hi.y - lo.y)
		push[i] = p * face
		imp[i] = Blast.impulse(kg, r) * Blast.reflection(side) * face
		pressure[i] = p
		var d := (q - c).normalized()  # (from the charge through the face, either side)
		dir[i] = (wall.from_wall_dir(k, d) + Vector3.UP * 0.25).normalized()
		# 3. Units crack only under far more.
		var mat := MasonryMaterials.material(wall.materials[i])
		var t := float(mat.get("unit", {}).get("tension", INF))
		var deep := hi.z - lo.z
		var along := maxf(hi.x - lo.x, 0.01)
		if p > 1.33 * t * pow(deep / along, 2.0):
			cracked.append(i)
	# The far leaf pushed by the near one through their collar joints (shared by length).
	for i: int in push.keys():
		for j in wall.of[i]:
			if wall.jtype[j] != MasonryWall.Joint.COLLAR:
				continue
			var o := wall.other(j, i)
			if not standing.has(o) or front.has(o):
				continue
			var share: float = wall.jarea[j] / maxf((wall.hi[i].y - wall.lo[i].y) * (wall.hi[i].x - wall.lo[i].x), 1e-6)
			push[o] = float(push.get(o, 0.0)) + float(push[i]) * share
			imp[o] = float(imp.get(o, 0.0)) + float(imp[i]) * share
			dir[o] = dir[i]
	# 2. Joints first: bed and head joints by the difference in push across them.
	var broke := {}
	for i: int in push.keys():
		for j in wall.of[i]:
			if broke.has(j) or wall.bonded[j] == 0 or wall.jtype[j] == MasonryWall.Joint.COLLAR:
				continue
			var o := wall.other(j, i)
			var diff := absf(float(push[i]) - float(push.get(o, 0.0)) if standing.has(o) else 0.0)
			if diff > wall.jtension[j] * wall.jarea[j]:
				broke[j] = true
	# 4. What's freed flies: far side first, then what was behind it.
	var freed := {}
	var cracked_set := {}
	for i in cracked:
		cracked_set[i] = true
	var changed := true
	while changed:
		changed = false
		for i: int in push.keys():
			if freed.has(i):
				continue
			# Its collar joints with the leaf in front press on it (compression: they don't hold), and
			# those with a leaf behind it that has gone hold nothing. Free behind: the far leaf, or
			# every element behind it gone.
			var pressing := {}
			var behind := 0
			var gone_behind := 0
			for j in wall.of[i]:
				if wall.jtype[j] != MasonryWall.Joint.COLLAR:
					continue
				var o := wall.other(j, i)
				if front.has(o) and not front.has(i):
					pressing[j] = true
				elif front.has(i) and not front.has(o):
					behind += 1
					if freed.has(o) or not standing.has(o):
						gone_behind += 1
						pressing[j] = true
			var free_behind: bool = far_side.has(i) or (behind > 0 and gone_behind == behind)
			if not free_behind and not cracked_set.has(i):
				continue
			var skip := pressing.duplicate()
			for j: int in broke:
				skip[j] = true
			# Held by its bonded joints and by friction on its beds (the wall over it pressing down
			# on the top, that and its own weight on the bottom).
			var clamp := wall.friction[i] * (2.0 * wall.pressed[i] + wall.mass[i] * 9.81)
			if cracked_set.has(i) or float(push[i]) > wall.bond_of(i, skip) + clamp:
				freed[i] = true
				changed = true
				for j in wall.of[i]:
					broke[j] = true
	var out_freed := {}
	for i: int in freed:
		var v := float(imp.get(i, 0.0)) / maxf(wall.mass[i], 0.1)
		out_freed[i] = (dir.get(i, Vector3.UP) as Vector3) * minf(v, max_throw)
	var out_broke := PackedInt32Array()
	for j: int in broke:
		if wall.bonded[j] == 1:
			out_broke.append(j)
	out_broke.sort()
	return {"broke": out_broke, "freed": out_freed, "cracked": cracked, "push": push, "pressure": pressure}

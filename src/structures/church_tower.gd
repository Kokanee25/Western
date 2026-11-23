class_name ChurchTower
extends RefCounted
## The church's bell tower and what a plain frame building lacks for one (#1142, the building lab):
## a tower standing against the nave's gable front over its porch (the spec's `tower`), built as parts
## of the same Structure: its footing, sills and floor (`foundation`, `floor`); its three outer walls
## are ordinary spec walls (`walls`, a numeric `top`); then the belfry floor on joists, plates and
## corner posts, louvres, the bell beams, the pent skirt roof, the pyramidal spire of shingle courses on
## hip and common rafters with an iron finial (`belfry`); the windows' pointed heads are SashWindow's
## (`rise`). All of it members, so a ball breaks it and a lost post drops
## what it carried. SpecBuilding calls these two places in `build`; nothing else of it changed.
##
## The spec's `tower`: {x: [x0, x1], z: z of its front face, belfry_floor, belfry_top, spire: height,
## post, louvre: {from, to, slat, step, gap: [x0, x1, y0, y1] on the front}, finial, shingle: step}.
## Shingle courses stepped up a pyramid instead of a bent sheet: the Structure's members are boxes.

const PLATE := 0.1
const SKIN := 0.03
const STUD_D := 0.1

var b  # the SpecBuilding
var t: Dictionary
var x0: float
var x1: float
var z0: float


func _init(building: Node, tower: Dictionary) -> void:
	b = building
	t = tower
	x0 = float(t.x[0])
	x1 = float(t.x[1])
	z0 = float(t.z)


## Its footing and sills under the walls the spec gives it (its back is the nave's front wall).
func foundation() -> void:
	var f: Dictionary = b._fr.foundation
	var th := float(f.thick)
	var top := float(f.top)
	b.band = 0
	for run in [["front", Vector2(x0, z0), Vector2(x1, z0)], ["west", Vector2(x0, z0 + th), Vector2(x0, 0.0)],
			["east", Vector2(x1 - th, z0 + th), Vector2(x1 - th, 0.0)]]:
		b._stone_run("tower/foundation/%s" % run[0], run[1], run[2], th, top, [], float(f.bottom))
	var sill: Array = b._fr.sill.section
	var sw := float(sill[0])
	var sy := top + float(sill[1]) * 0.5
	var sec := Vector2(sill[1], sill[0])
	b._pieces("tower/sill/front", Vector3(x0, sy, z0 + sw * 0.5), Vector3.RIGHT, x1 - x0, sec, &"sill", &"framing")
	b._pieces("tower/sill/west", Vector3(x0 + sw * 0.5, sy, z0 + sw), Vector3.BACK, -z0 - sw, sec, &"sill", &"framing")
	b._pieces("tower/sill/east", Vector3(x1 - sw * 0.5, sy, z0 + sw), Vector3.BACK, -z0 - sw, sec, &"sill", &"framing")


## The porch floor: joists front to back, boards across (the lean-to's floor, a part).
func floor() -> void:
	b.band = 1
	b._floor({"id": "tower", "level": "ground", "rect": [x0 + STUD_D, z0 + 0.03, x1 - STUD_D, STUD_D], "joists": "z",
			"look": "wood:int_floor"}, [])


## The belfry, the louvres, the bell frame, the skirt roof, the spire and its finial.
func belfry() -> void:
	var fy := float(t.belfry_floor)
	var ty := float(t.belfry_top)
	var post := float(t.get("post", 0.15))
	var cx := (x0 + x1) * 0.5
	var cz := z0 + (-z0) * 0.5
	var w := x1 - x0
	# The plates on the walls' tops (a numeric `top` leaves the studs bare), carrying the floor.
	b.band = 1
	var walls_in_order: Array = []
	for id: String in ["tower_front", "tower_w", "tower_e"]:
		if b.walls.has(id):
			walls_in_order.append(b.walls[id].dict)
	for wd: Dictionary in walls_in_order:
		b._wall_member("%s/plate" % wd.name, &"plate", &"framing", wd, wd.x_start, wd.x_end, fy - PLATE, fy, -STUD_D, 0.0)
	# Joists across the tower between the east and west plates, boards over them, the hatch left open.
	b.band = 2
	var jh := 0.235
	var jzs: Array[float] = []
	var jn := ceili((-0.13 - (z0 + 0.13)) / 0.5)
	for i in jn + 1:
		jzs.append(lerpf(z0 + 0.13, -0.13, float(i) / float(jn)))
	# The ladder's hatch (x, z), between two joists by the nave's front wall (the second gap from it).
	var hatch := Rect2(cx + 0.62, jzs[jn - 2] + 0.04, 0.6, jzs[jn - 1] - jzs[jn - 2] - 0.08)
	var k := 0
	for z in jzs:
		b.add_member("tower/belfry/joist_%d" % k, &"joist", &"framing", Vector3(x1 - x0 - 0.06, jh, 0.05), Vector3(cx, fy + jh * 0.5, z))
		k += 1
	# Boards along z across the joists, the hatch left open.
	var bx := x0 + 0.1
	k = 0
	while bx < x1 - 0.1:
		var bw := minf(0.15, x1 - 0.1 - bx)
		if x1 - 0.1 - bx < 0.22:
			bw = x1 - 0.1 - bx  # the last board takes the remainder: no sliver
		var runs := [[z0 + 0.1, -0.1]]
		if bx + bw > hatch.position.x and bx < hatch.end.x:
			runs = [[z0 + 0.1, hatch.position.y], [hatch.end.y, -0.1]]
		var j := 0
		for rr: Array in runs:
			b.add_member("tower/belfry/board_%d_%d" % [k, j], &"floor_board", &"floor", Vector3(bw - 0.004, 0.032, float(rr[1]) - float(rr[0])),
					Vector3(bx + bw * 0.5, fy + jh + 0.016, (float(rr[0]) + float(rr[1])) * 0.5))
			j += 1
		bx += bw if bw > 0.15 else 0.15
		k += 1
	# Corner posts, and the ring of plates at their heads.
	b.band = 3
	var py := fy + jh + 0.025
	var ph := ty - py
	var px := [x0 + post * 0.5 + 0.02, x1 - post * 0.5 - 0.02]
	var pz := [z0 + post * 0.5 + 0.02, -post * 0.5 - 0.02]
	for ix in 2:
		for iz in 2:
			b.add_member("tower/belfry/post_%d%d" % [ix, iz], &"post", &"framing", Vector3(post, ph, post), Vector3(px[ix], py + ph * 0.5, pz[iz]))
	# The skirt roof where the clapboard stops: a board a side sloping out from the posts to over the walls.
	b.band = 4
	var sk_w := 0.5
	var sk_a := deg_to_rad(28.0)
	var sk_y := fy + jh + 0.04
	for i in 4:
		var n: Vector3 = [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][i]
		var along_x_ := absf(n.z) > 0.5
		var span := (x1 - x0 + 0.5) if along_x_ else (-z0 + 0.5)
		var c := Vector3(cx, sk_y + 0.14, cz) + n * ((w if along_x_ else -z0) * 0.5 - 0.02 + sk_w * 0.45)
		var sz := Vector3(span, 0.03, sk_w) if along_x_ else Vector3(sk_w, 0.03, span)
		# tilt about the wall's own axis so the outer edge is lower
		var ax := Vector3.RIGHT if along_x_ else Vector3.BACK
		var ang := sk_a * (1.0 if (n.z < -0.5 or n.x > 0.5) else -1.0)
		b.add_member("tower/belfry/skirt_%d" % i, &"roof_board", &"weathered_pine", sz, c, Basis(ax, ang))
	b.band = 3
	# A post at the middle of each face too, under the ring's mid-span (the spire's commons land there).
	for mp in [[cx, -post * 0.5 - 0.02], [x0 + post * 0.5 + 0.02, cz], [x1 - post * 0.5 - 0.02, cz]]:
		b.add_member("tower/belfry/mid_%d_%d" % [int(float(mp[0]) * 10), int(float(mp[1]) * -10)], &"post", &"framing", Vector3(post, ph, post), Vector3(float(mp[0]), py + ph * 0.5, float(mp[1])))
	b.band = 4
	var ring := Vector2(0.15, 0.25)  # (width, height)
	b.add_member("tower/belfry/ring_front", &"beam", &"framing", Vector3(w - 0.04, ring.y, ring.x), Vector3(cx, ty + ring.y * 0.5, z0 + 0.05 + 0.02))
	b.add_member("tower/belfry/ring_back", &"beam", &"framing", Vector3(w - 0.04, ring.y, ring.x), Vector3(cx, ty + ring.y * 0.5, -0.05 - 0.02))
	b.add_member("tower/belfry/ring_w", &"beam", &"framing", Vector3(ring.x, ring.y, -z0 - 0.04), Vector3(x1 - 0.05 - 0.02, ty + ring.y * 0.5, z0 + (-z0) * 0.5))
	b.add_member("tower/belfry/ring_e", &"beam", &"framing", Vector3(ring.x, ring.y, -z0 - 0.04), Vector3(x0 + 0.05 + 0.02, ty + ring.y * 0.5, z0 + (-z0) * 0.5))
	# Louvres: slats tilted 40 degrees between the posts, on all four faces, the front's left open
	# in the middle for the bell to be seen.
	var lv: Dictionary = t.get("louvre", {})
	var ly0 := float(lv.get("from", py + 0.6))
	var ly1 := float(lv.get("to", ty - 0.35))
	var step := float(lv.get("step", 0.13))
	var slat := Vector3(0.0, 0.12, 0.02)
	var tilt := deg_to_rad(40.0)
	var gap: Array = lv.get("gap", [])
	var faces := [["front", Vector3(0, 0, 1), z0 + post * 0.5 + 0.02, true], ["back", Vector3(0, 0, 1), -post * 0.5 - 0.02, false],
			["w", Vector3(1, 0, 0), x1 - post * 0.5 - 0.02, false], ["e", Vector3(1, 0, 0), x0 + post * 0.5 + 0.02, false]]
	for face: Array in faces:
		var along_x: bool = (face[1] as Vector3).z > 0.5
		var span0 := (x0 + post + 0.01) if along_x else (z0 + post + 0.01)
		var span1 := (x1 - post - 0.01) if along_x else (-post - 0.01)
		var y := ly0
		var n := 0
		while y < ly1:
			var runs: Array = [[span0, span1]]
			if face[3] and not gap.is_empty() and y + slat.y > float(gap[2]) and y < float(gap[3]):
				runs = [[span0, float(gap[0])], [float(gap[1]), span1]]
			var r := 0
			for rr: Array in runs:
				var len_ := float(rr[1]) - float(rr[0])
				if len_ < 0.1:
					continue
				var mid := (float(rr[0]) + float(rr[1])) * 0.5
				var size := Vector3(len_, slat.y, slat.z) if along_x else Vector3(slat.z, slat.y, len_)
				var c := Vector3(mid, y + slat.y * 0.5, float(face[2])) if along_x else Vector3(float(face[2]), y + slat.y * 0.5, mid)
				var axis := Vector3.RIGHT if along_x else Vector3.BACK
				b.add_member("tower/belfry/louvre_%s_%d_%d" % [face[0], n, r], &"board", &"framing", size, c, Basis(axis, -tilt if along_x else tilt))
				r += 1
			y += step
			n += 1
	_spire(ty + ring.y, cx, cz)


## The spire: shingle courses stepped up four faces, over four hip rafters and four common rafters
## from the belfry's ring plates, an iron cross on its apex.
func _spire(y0: float, cx: float, cz: float) -> void:
	var hs := float(t.spire)
	var eave := 0.16
	var half_x := (x1 - x0) * 0.5 - 0.06 + eave
	var half_z := -z0 * 0.5 - 0.06 + eave
	var s_ := maxf(half_x, half_z)  # a square spire over the tower's square plan: half a side
	var slope := atan2(hs, s_)
	var len_total := sqrt(s_ * s_ + hs * hs)
	var apex := Vector3(cx, y0 + hs, cz)
	# The seat: four beams laid on the ring, standing out past it by the eave, the hips' feet on them.
	b.band = 5
	for i in 4:
		var along_x := i < 2
		var sgn := 1.0 if i % 2 == 0 else -1.0
		var sz := Vector3(2.0 * s_ + 0.1, 0.1, 0.1) if along_x else Vector3(0.1, 0.1, 2.0 * s_ + 0.1)
		var cc := Vector3(cx, y0 + 0.03, cz + sgn * (s_ - 0.05)) if along_x else Vector3(cx + sgn * (s_ - 0.05), y0 + 0.03, cz)
		b.add_member("tower/spire/seat_%d" % i, &"beam", &"framing", sz, cc)
	for i in 4:
		var corner := Vector3(cx + (s_ if i % 2 == 0 else -s_), y0, cz + (s_ if i < 2 else -s_))
		var d := apex - corner
		var c := (corner + apex) * 0.5
		b.add_member("tower/spire/hip_%d" % i, &"rafter", &"framing", Vector3(0.1, 0.1, d.length()), c, Basis.looking_at(d.normalized(), Vector3.UP))
	for i in 4:
		var n: Vector3 = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][i]
		var base := Vector3(cx, y0, cz) + n * s_
		var d := (apex - base)
		b.add_member("tower/spire/common_%d" % i, &"rafter", &"framing", Vector3(0.08, 0.08, d.length()), (base + apex) * 0.5, Basis.looking_at(d.normalized(), Vector3.UP))
	b.band = 6
	var step := float(t.get("shingle", 0.22))
	var wood := StringName(b.spec.materials.get("roof", "weathered_pine"))
	for i in 4:
		var n: Vector3 = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][i]
		var tan_ := Vector3(n.z, 0, -n.x)
		var nrm := n * sin(slope) + Vector3.UP * cos(slope)
		var s0 := 0.0
		var k := 0
		while s0 < len_total - 0.05:
			var s1 := minf(s0 + step, len_total)
			var sm := (s0 + s1) * 0.5
			var width := 2.0 * s_ * (1.0 - sm * sin(slope) / hs) + 0.1
			var p := Vector3(cx, y0, cz) + n * (s_ - sm * cos(slope)) + Vector3.UP * (sm * sin(slope)) + nrm * 0.06
			var bas := Basis(tan_.abs() if false else tan_, nrm, tan_.cross(nrm))
			if absf(tan_.x) + absf(tan_.z) < 0.5:
				continue
			b.add_member("tower/spire/shingle_%d_%02d" % [i, k], &"roof_board", wood, Vector3(width, SKIN, (s1 - s0) + 0.03), p, bas.orthonormalized())
			s0 = s1
			k += 1
	# The iron finial: a post and a small cross on the apex.
	var fh := float(t.get("finial", 0.9))
	b.band = 6
	b.add_member("tower/spire/finial", &"post", &"iron", Vector3(0.05, fh, 0.05), apex + Vector3(0, fh * 0.5 - 0.1, 0))
	b.add_member("tower/spire/finial_arm", &"beam", &"iron", Vector3(0.3, 0.04, 0.04), apex + Vector3(0, fh * 0.6, 0))

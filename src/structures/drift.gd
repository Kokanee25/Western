class_name Drift
extends RefCounted
## A timbered drift (#1220, the hotel's cellar's secret B: the landlady's husband's keg road of 1881 under
## the saloon lane to saloon B's cellar): a passage as a mine's, of members of the building that owns it.
## Sets every `every` along x (a sill on the floor, two legs, a cap: the three-piece set of Colorado's
## drifts), lagging boards over the caps and behind the legs (resting on them), a walk of planks on the
## sills. In the building's space: it runs along +x from `x[0]` to `x[1]` between `z[0]` and `z[1]` (the
## timbers' outer faces), its floor the cellar's at `x[0]` rising `fall` to `x[1]`; `clear` the head room
## under the caps over the planks. In the valley the ground over it is dug and covered (CellarDig).
## Ids `drift/set_<k>/sill|leg_0|leg_1|cap`, `drift/roof_<k>/<i>`, `drift/side_<side>_<k>/<row>`,
## `drift/plank_<k>/<i>`.
##
##   Drift.build(building, spec.drift, cellar_floor)

const BOARD_W := 0.2
const SIDE_ROW := 0.25
const PLANK_W := 0.3


## The drift's floor (the sills' underside) at `x`, in the building's space.
static func floor_at(d: Dictionary, cellar_floor: float, x: float) -> float:
	var x0 := float(d.x[0])
	var x1 := float(d.x[1])
	return cellar_floor + float(d.get("fall", 0.0)) * clampf((x - x0) / (x1 - x0), 0.0, 1.0)


## The top of its roof's lagging at `x` (what the valley's cover lies on).
static func roof_at(d: Dictionary, cellar_floor: float, x: float) -> float:
	return floor_at(d, cellar_floor, x) + float(d.sill) + float(d.plank) + float(d.clear) + float(d.cap) + float(d.lagging)


static func build(b: Node3D, d: Dictionary, cellar_floor: float) -> int:
	var x0 := float(d.x[0])
	var x1 := float(d.x[1])
	var z0 := float(d.z[0])
	var z1 := float(d.z[1])
	var every := float(d.every)
	var leg := float(d.leg)
	var cap := float(d.cap)
	var sill := float(d.sill)
	var plank := float(d.plank)
	var lag := float(d.lagging)
	var clear := float(d.clear)
	var wood := StringName(d.get("wood", "rough"))
	var made := 0
	# The sets: the first a little in from the wall's face, the last at the far wall's.
	var n := maxi(2, ceili((x1 - x0 - 0.3) / every) + 1)
	var xs: Array[float] = []
	for k in n:
		xs.append(lerpf(x0 + 0.15, x1 - 0.15, float(k) / (n - 1)))
	var lz0 := z0 + lag + leg * 0.5          # the legs' middles
	var lz1 := z1 - lag - leg * 0.5
	for k in n:
		var x := xs[k]
		var f := floor_at(d, cellar_floor, x)
		var id := "drift/set_%02d" % k
		b.add_member(id + "/sill", &"sill", wood, Vector3(leg, sill, z1 - z0), Vector3(x, f + sill * 0.5, (z0 + z1) * 0.5))
		var lh := plank + clear
		for e in 2:
			b.add_member("%s/leg_%d" % [id, e], &"post", wood, Vector3(leg, lh, leg), Vector3(x, f + sill + lh * 0.5, lz0 if e == 0 else lz1))
		b.add_member(id + "/cap", &"beam", wood, Vector3(leg, cap, z1 - z0 - lag * 2.0), Vector3(x, f + sill + lh + cap * 0.5, (z0 + z1) * 0.5))
		made += 4
	# Between the sets: the roof's lagging on the caps, the sides' behind the legs, the walk on the sills.
	for k in n - 1:
		var a := xs[k]
		var e := xs[k + 1]
		var mid := (a + e) * 0.5
		var f := floor_at(d, cellar_floor, mid)
		var top := f + sill + plank + clear + cap
		# (each board a few mm into what it rests on: the support model joins members that meet)
		var cols := maxi(1, roundi((z1 - z0) / BOARD_W))
		for i in cols:
			var za := lerpf(z0, z1, float(i) / cols)
			var zb := lerpf(z0, z1, float(i + 1) / cols)
			b.add_member("drift/roof_%02d/%d" % [k, i], &"board", wood, Vector3(e - a - 0.004, lag, zb - za - 0.004), Vector3(mid, top + lag * 0.5 - 0.003, (za + zb) * 0.5))
			made += 1
		var rows := maxi(1, ceili((plank + clear + cap) / SIDE_ROW))
		for side in 2:
			var zc := z0 + lag * 0.5 + 0.003 if side == 0 else z1 - lag * 0.5 - 0.003
			for r in rows:
				var ya := f + sill + (plank + clear + cap) * r / rows
				var yb := f + sill + (plank + clear + cap) * (r + 1) / rows
				b.add_member("drift/side_%d_%02d/%d" % [side, k, r], &"board", wood, Vector3(e - a - leg + 0.01, yb - ya - 0.004, lag + 0.006), Vector3(mid, (ya + yb) * 0.5, zc))
				made += 1
		var pw := lz1 - lz0 - leg
		var pc := maxi(1, roundi(pw / PLANK_W))
		for i in pc:
			var za := lz0 + leg * 0.5 + pw * i / pc
			var zb := lz0 + leg * 0.5 + pw * (i + 1) / pc
			b.add_member("drift/plank_%02d/%d" % [k, i], &"floor_board", wood, Vector3(e - a - 0.004, plank, zb - za - 0.006), Vector3(mid, f + sill + plank * 0.5 - 0.002, (za + zb) * 0.5))
			made += 1
	return made

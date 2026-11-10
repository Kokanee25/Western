class_name PorchRoof
extends RefCounted
## A porch roof (an awning) over a walk, for any structure: posts out at the walk's street side,
## a beam on them, a ledger on the building's front, rafters from beam to ledger and roof boards
## across them, all members (they're shot, burn, and a man falling onto them breaks them: #736).
## In the structure's own space the front runs along +X from `x0` for `w`, the street is -Z and
## the front's face is z 0, as FalseFrontBuilding and Boardwalk have it.
##
##   PorchRoof.build(s, "porch", w, 2.2, 3.0)                       # FalseFrontBuilding's: two posts
##   PorchRoof.build(s, "awning", w, 2.2, 2.8, {"base": top, "post_every": 3.0})  # on a walk
##
## `height` is the beam's underside over `base` (the posts' feet: the ground, or a walk's planks).
## A spec may set `base` (0), `post_every` (0: a post at each end only, else about this far apart)
## `x0` (0) and `clear` (Vector2(from, to) along x each: no post stands there, a door's flight;
## one that would is moved just past the nearer end).

const POST := 0.14
const BOARD_T := 0.025


static func build(s: Structure, prefix: String, w: float, depth: float, height: float, spec := {}) -> Array[StructureMember]:
	var base: float = spec.get("base", 0.0)
	var x0: float = spec.get("x0", 0.0)
	var every: float = spec.get("post_every", 0.0)
	var out: Array[StructureMember] = []
	var beam_y0 := base + height
	var beam_y1 := beam_y0 + 0.18
	var ledger_y1 := beam_y0 + 0.37
	var zb := -depth
	var xs: Array[float] = [x0 + POST * 0.5 + 0.05, x0 + w - POST * 0.5 - 0.05]
	if every > 0.0:
		var n := maxi(1, roundi((xs[1] - xs[0]) / every))
		xs = []
		for k in n + 1:
			xs.append(lerpf(x0 + POST * 0.5 + 0.05, x0 + w - POST * 0.5 - 0.05, float(k) / n))
	for c: Vector2 in spec.get("clear", []):
		for k in xs.size():
			if xs[k] > c.x - POST and xs[k] < c.y + POST:
				xs[k] = c.x - POST if xs[k] - c.x < c.y - xs[k] else c.y + POST
	for i in xs.size():
		out.append(s.add_member("%s/post%d" % [prefix, i], &"post", &"framing", Vector3(POST, height, POST), Vector3(xs[i], base + height * 0.5, zb)))
	out.append(s.add_member("%s/beam" % prefix, &"beam", &"framing", Vector3(w + 0.2, beam_y1 - beam_y0, 0.16), Vector3(x0 + w * 0.5, (beam_y0 + beam_y1) * 0.5, zb)))
	out.append(s.add_member("%s/ledger" % prefix, &"ledger", &"framing", Vector3(w, 0.15, 0.05), Vector3(x0 + w * 0.5, ledger_y1 - 0.075, -0.025)))
	var a := atan2(ledger_y1 - beam_y1, -0.05 - zb)
	var basis := Basis(Vector3.RIGHT, -a)
	var up_slope := basis.z  # toward the building, rising
	var z_start := zb - 0.3
	var start := Vector3(0.0, beam_y1 - (zb - z_start) * tan(a), z_start)
	var length := (-0.05 - z_start) / cos(a)
	var i := 0
	var x := 0.2
	while x < w - 0.1:
		var c := start + up_slope * (length * 0.5) + basis.y * 0.06
		c.x = x0 + x
		out.append(s.add_member("%s/rafter/%02d" % [prefix, i], &"rafter", &"framing", Vector3(0.05, 0.12, length), c, basis))
		x += 0.75
		i += 1
	i = 0
	var sl := 0.0
	while sl < length - 0.02:
		var bw := minf(0.195, length - sl)
		var c := start + up_slope * (sl + bw * 0.5) + basis.y * (0.12 + BOARD_T * 0.5)
		c.x = x0 + w * 0.5
		out.append(s.add_member("%s/board/%02d" % [prefix, i], &"roof_board", &"weathered_pine", Vector3(w + 0.3, BOARD_T, bw), c, basis))
		sl += 0.2
		i += 1
	return out

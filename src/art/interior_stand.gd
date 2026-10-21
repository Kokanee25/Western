class_name InteriorStand
extends OakStair
## The saloon's interior woodwork on the material lab's bench (Sean 2026-10-21, his saloon picture
## docs/concept/targets/10_saloon_interior.png; brief docs/briefs/interior-woodwork.md;
## tools/material_lab.gd --material=interior): a corner of the saloon at the saloon sheet's sizes
## (the ground floor 3.7 m), every piece the room needs: a panelled wainscot with boards above on
## the back wall and a side wall, a door and a window cased, the bar and the back bar, chamfered
## posts with brackets under the gallery's beam, the gallery's joists and deck, its balustrade
## (newels, turned balusters, a moulded handrail). `profiled` off draws every piece square, as the
## game draws boards today (the A/B sheets' A). Drawn only, like the stand; indoors, so unweathered.
##
## Its space: the back wall along +X in the plane z = 0, the room toward -Z; the side wall along -Z
## in the plane x = 0, the room toward +X; the floor at y = 0.

const W := 5.0
const DEPTH := 4.5
const FLOOR_H := 3.7
const UPPER_H := 2.0
const GALLERY_D := 1.6
const POST_W := 0.2
const BEAM_WD := Vector2(0.2, 0.25)
const WAINSCOT := 0.9
const SKIRT := 0.18
const BAR := {"x0": 0.9, "x1": 3.4, "z": -1.25, "deep": 0.6, "h": 1.1}
const BACK_BAR := {"x0": 0.9, "x1": 3.4, "deep": 0.45, "h": 0.95, "top": 2.75}
## Openings, [from, to, bottom, top] along their wall: the back wall's door, the side wall's window.
const DOOR := [3.95, 4.85, 0.0, 2.15]
const WINDOW := [-3.4, -2.4, 1.0, 2.2]

const IPARTS := [&"int_floor", &"int_walls", &"int_wainscot", &"int_panels", &"int_caps", &"int_casings", &"int_posts",
	&"int_beams", &"int_brackets", &"int_bar", &"int_bar_top", &"int_back_bar", &"int_gallery", &"int_rail"]

## Profiles on (the kit, Profiles) or every piece a plain box.
var profiled := true
## The game's exterior woods instead of the interior ones (set before build: the A/B sheets).
static var game_woods := false


func _init() -> void:
	super()
	# The interior stain (Sean picked C, 2026-10-21): the game's interior woods
	# (tools/textures/promote_woods.py from the lab's studio_int).
	roles[&"int_floor"] = &"int_floor"
	roles[&"int_gallery"] = &"int_floor"
	roles[&"int_walls"] = &"int_boards"
	for p in [&"int_wainscot", &"int_panels", &"int_caps", &"int_casings", &"int_bar", &"int_bar_top", &"int_back_bar", &"int_rail",
			&"oak_newels", &"oak_balusters"]:
		roles[p] = &"int_oak"
	for p in [&"int_posts", &"int_beams", &"int_brackets"]:
		roles[p] = &"int_timber"
	# `game_woods`: the woods the game drew interiors in before (the A/B sheet's A and B).
	if game_woods:
		roles[&"int_floor"] = &"floor"
		roles[&"int_gallery"] = &"floor"
		roles[&"int_walls"] = &"dark_trim"
		for p in [&"int_wainscot", &"int_panels", &"int_caps", &"int_casings", &"int_bar", &"int_bar_top", &"int_back_bar", &"int_rail",
				&"oak_newels", &"oak_balusters"]:
			roles[p] = &"dark_oak"
		for p in [&"int_posts", &"int_beams", &"int_brackets"]:
			roles[p] = &"timber"


func focus_parts() -> Array:
	return IPARTS + [&"oak_newels", &"oak_balusters"]


## The lab's cameras on it ([eye, look at, fov], the stand's space), each with a man in it.
const VIEWS := {
	# The whole corner from the room: the bar, the gallery over it, the posts.
	"interior": [Vector3(3.3, 1.7, -7.6), Vector3(2.3, 2.3, 0.0), 62.0],
	# The bar's front and top, the back bar behind, the cowboy at it.
	"bar": [Vector3(3.2, 1.6, -4.2), Vector3(1.9, 1.15, -1.0), 46.0],
	# A post, its bracket and the beam, the rancher by it.
	"post": [Vector3(2.2, 1.75, -4.4), Vector3(0.4, 2.6, -1.5), 50.0],
	# The side wall's wainscot and window, the rancher in front.
	"wainscot": [Vector3(2.6, 1.5, -3.9), Vector3(0.0, 1.0, -2.6), 52.0],
	# Up on the gallery along its balustrade, the drifter at the rail.
	"gallery": [Vector3(0.7, 5.3, -0.55), Vector3(3.6, 4.5, -1.45), 55.0],
	# Up at the gallery from the floor, as the saloon picture sees it.
	"gallery_below": [Vector3(3.6, 1.6, -5.2), Vector3(2.0, 4.1, -1.4), 48.0],
}
## The men: the cowboy at the bar, the rancher by the side wall, the drifter on the gallery.
const MEN := [
	[&"bold_cowboy_s0", Vector3(2.25, 0.0, -2.05), Vector3(3.2, 1.5, -6.0)],
	[&"old_rancher_s1", Vector3(0.75, 0.0, -2.9), Vector3(2.5, 1.5, -6.0)],
	[&"young_drifter_s1", Vector3(3.0, FLOOR_H, -0.75), Vector3(2.5, 4.5, -6.0)],
]
## The lamps (the lab's four): a sconce on the side wall, one under the gallery on the back wall,
## a lamp hung in the room, one across the room.
## (Drawn as lamps, and casting shadows, on this stand: tools/material_lab.gd.)
const LAMPS := [Vector3(0.18, 2.2, -2.0), Vector3(3.7, 2.3, -0.25), Vector3(2.4, 2.4, -6.0), Vector3(2.4, 3.1, -3.0)]


func build() -> void:
	_rng.seed = seed_value
	solid_parts = []
	_floor()
	_wall_run(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), W, [DOOR])
	_wall_run(Vector3(0, 0, -DEPTH), Vector3(0, 0, 1), Vector3(1, 0, 0), DEPTH, [[WINDOW[0] + DEPTH, WINDOW[1] + DEPTH, WINDOW[2], WINDOW[3]]])
	_door()
	_window()
	_back_bar()
	_bar()
	_gallery()
	_ceiling()
	_flush()
	_flush_solid()


## The ceiling over the corner (the upper floor's top), boards on joists, so nothing shows the sky.
func _ceiling() -> void:
	var y := FLOOR_H + UPPER_H
	var x := 0.2
	while x < W:
		_board(&"int_beams", Vector3(x, y - 0.1, -DEPTH * 0.5), Vector3(0, 0, -1), Vector3.UP, DEPTH, 0.2, 0.05, Vector3(1, 0, 0))
		x += 0.6
	var z := -0.075
	while z > -DEPTH:
		_board(&"int_walls", Vector3(W * 0.5, y + 0.01, z), Vector3(1, 0, 0), Vector3.UP, W, 0.148, 0.02, Vector3(0, 0, 1))
		z -= 0.15


## A piece run along `along`, its section `runs` (x along `across`, y along `up`), or as a box the
## profile's size when `profiled` is off.
func _piece(part: StringName, centre: Vector3, along: Vector3, across: Vector3, up: Vector3, length: float, runs: Array) -> void:
	if profiled:
		_profiled(part, centre, along, across, up, length, runs)
	else:
		var sz := Profiles.size_of(runs)
		_board(part, centre, along, up, length, sz.x, sz.y, across)


func _floor() -> void:
	var x := 0.075
	while x < W:
		_board(&"int_floor", Vector3(x, -0.015, -DEPTH * 0.5 - 1.0), Vector3(0, 0, -1), Vector3(0, 1, 0), DEPTH + 2.0, 0.146, 0.03,
				Vector3(1, 0, 0))
		x += 0.15


## A wall from `origin` along `along` for `length`, its face toward `out`: beaded boards from the
## wainscot up through the gallery's height, the wainscot (skirting, stiles and rails, raised panels,
## a moulded cap) along its foot, a picture rail; `gaps` ([from, to, bottom, top] along it) left open.
func _wall_run(origin: Vector3, along: Vector3, out: Vector3, length: float, gaps: Array) -> void:
	var up := Vector3.UP
	var top := FLOOR_H + UPPER_H
	var s := 0.075
	while s < length:
		var spans := [[WAINSCOT, top]]
		for g in gaps:
			if s > g[0] - 0.07 and s < g[1] + 0.07:
				spans = [[maxf(WAINSCOT, 0.0), g[2]], [g[3], top]] if g[2] > WAINSCOT else [[g[3], top]]
		for sp in spans:
			if sp[1] - sp[0] > 0.02:
				_piece(&"int_walls", origin + along * s + up * ((sp[0] + sp[1]) * 0.5) + out * 0.01, up, along, out, sp[1] - sp[0],
						Profiles.beaded(0.148, 0.02, 0.006))
		s += 0.15
	# The picture rail, and the wainscot in the runs between openings that reach down to it.
	_piece(&"int_caps", origin + along * (length * 0.5) + up * 2.6 + out * 0.02, along, up, out, length, Profiles.ogee(0.04, 0.045))
	var runs := [[0.0, length]]
	for g in gaps:
		if g[2] < WAINSCOT:
			var nxt := []
			for r in runs:
				if g[0] > r[0]:
					nxt.append([r[0], minf(g[0] - 0.12, r[1])])
				if g[1] < r[1]:
					nxt.append([maxf(g[1] + 0.12, r[0]), r[1]])
			runs = nxt
	for r in runs:
		if r[1] - r[0] > 0.3:
			_wainscot(origin, along, out, r[0], r[1])


## The wainscot from s0 to s1 along a wall: a skirting with an eased top, stiles every ~0.6 m,
## top and bottom rails, a raised panel in each bay, a moulded cap on top.
func _wainscot(origin: Vector3, along: Vector3, out: Vector3, s0: float, s1: float) -> void:
	var up := Vector3.UP
	var len := s1 - s0
	var mid := origin + along * (s0 + len * 0.5)
	var t := 0.022
	_piece(&"int_wainscot", mid + up * (SKIRT * 0.5) + out * (t * 0.5 + 0.004), along, up, out, len, Profiles.rounded(SKIRT, t + 0.008, 0.008, [1]))
	var rail := 0.09
	var y0 := SKIRT
	var y1 := WAINSCOT - 0.03
	_piece(&"int_wainscot", mid + up * (y0 + rail * 0.5) + out * (t * 0.5), along, up, out, len, Profiles.chamfered(rail, t, 0.004))
	_piece(&"int_wainscot", mid + up * (y1 - rail * 0.5) + out * (t * 0.5), along, up, out, len, Profiles.chamfered(rail, t, 0.004))
	var bays := maxi(int(round(len / 0.6)), 1)
	var stile := 0.09
	var bay := (len - stile) / bays
	for b in bays + 1:
		var s := s0 + stile * 0.5 + b * bay
		_piece(&"int_wainscot", origin + along * s + up * ((y0 + rail + y1 - rail) * 0.5) + out * (t * 0.5), up, along, out,
				y1 - y0 - rail * 2.0, Profiles.chamfered(stile, t, 0.004))
		if b < bays:
			_panel(&"int_panels", origin + along * (s + bay * 0.5) + up * ((y0 + y1) * 0.5) + out * 0.002, along, up, out,
					bay - stile - 0.01, y1 - y0 - rail * 2.0 - 0.01, 0.018, 0.045)
	_piece(&"int_caps", mid + up * (WAINSCOT - 0.0225) + out * 0.03, along, out, up, len, Profiles.ogee(0.06, 0.045))


## A raised panel: its field standing `t` proud, bevelled down to its edges over `bevel` (a
## frustum), grain up the panel. Square (`profiled` off): a flat board.
func _panel(part: StringName, c: Vector3, right: Vector3, up: Vector3, out: Vector3, w: float, h: float, t: float, bevel: float) -> void:
	if not profiled:
		_board(part, c + out * (t * 0.5), up, out, h, w, t, right)
		return
	var took := _take(part, Vector3(h, w, t))
	var st: SurfaceTool = _tools[part][took[0]]
	var u0: float = took[1]
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	var e := t * 0.35
	var hw := w * 0.5
	var hh := h * 0.5
	var iw := hw - bevel
	var ih := hh - bevel
	var p := func(x: float, y: float, d: float) -> Vector3: return c + right * x + up * y + out * d
	var uv := func(x: float, y: float) -> Vector2: return Vector2(u0 + y + hh, x + hw)
	var size := Vector2(h, w)
	# The field.
	var fn := out
	var f := [p.call(-iw, -ih, t), p.call(iw, -ih, t), p.call(iw, ih, t), p.call(-iw, ih, t)]
	_tri(st, [f[0], f[1], f[2]], [fn, fn, fn], [uv.call(-iw, -ih), uv.call(iw, -ih), uv.call(iw, ih)], size, flag)
	_tri(st, [f[0], f[2], f[3]], [fn, fn, fn], [uv.call(-iw, -ih), uv.call(iw, ih), uv.call(-iw, ih)], size, flag)
	# The four bevels, from the field's edge down to the panel's.
	var o := [p.call(-hw, -hh, e), p.call(hw, -hh, e), p.call(hw, hh, e), p.call(-hw, hh, e)]
	var oxy := [Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)]
	var ixy := [Vector2(-iw, -ih), Vector2(iw, -ih), Vector2(iw, ih), Vector2(-iw, ih)]
	for k in 4:
		var k1 := (k + 1) % 4
		var n: Vector3 = ((o[k] - f[k]) as Vector3).cross(o[k1] - f[k]).normalized()
		if n.dot(out) < 0.0:
			n = -n
		_tri(st, [o[k], o[k1], f[k1]], [n, n, n], [uv.call(oxy[k].x, oxy[k].y), uv.call(oxy[k1].x, oxy[k1].y), uv.call(ixy[k1].x, ixy[k1].y)], size, flag)
		_tri(st, [o[k], f[k1], f[k]], [n, n, n], [uv.call(oxy[k].x, oxy[k].y), uv.call(ixy[k1].x, ixy[k1].y), uv.call(ixy[k].x, ixy[k].y)], size, flag)


## A board cut to an outline (a bracket, the back bar's crest): `outline` in its plane (x along
## `ax`, y along `ay`, from `origin`), `t` thick along `n`; its faces and cut edges long grain
## along `ax`. Square (`profiled` off): the outline's bounding board.
func _cut(part: StringName, origin: Vector3, ax: Vector3, ay: Vector3, n: Vector3, outline: PackedVector2Array, t: float) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in outline:
		lo = lo.min(q)
		hi = hi.max(q)
	if not profiled:
		var mid := (lo + hi) * 0.5
		_board(part, origin + ax * mid.x + ay * mid.y, ax, n, hi.x - lo.x, hi.y - lo.y, t, ay)
		return
	var took := _take(part, Vector3(hi.x - lo.x, hi.y - lo.y, t))
	var st: SurfaceTool = _tools[part][took[0]]
	var u0: float = took[1]
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	var size := hi - lo
	var at := func(q: Vector2, d: float) -> Vector3: return origin + ax * q.x + ay * q.y + n * d
	var uv := func(q: Vector2) -> Vector2: return Vector2(u0 + q.x - lo.x, q.y - lo.y)
	var idx := Geometry2D.triangulate_polygon(outline)
	for side in [[t * 0.5, n], [-t * 0.5, -n]]:
		for k in range(0, idx.size(), 3):
			var q := [outline[idx[k]], outline[idx[k + 1]], outline[idx[k + 2]]]
			_tri(st, [at.call(q[0], side[0]), at.call(q[1], side[0]), at.call(q[2], side[0])], [side[1], side[1], side[1]],
					[uv.call(q[0]), uv.call(q[1]), uv.call(q[2])], size, flag)
	var total := 0.0
	for i in outline.size():
		total += outline[i].distance_to(outline[(i + 1) % outline.size()])
	var v := 0.0
	var ccw := Geometry2D.is_polygon_clockwise(outline) == false
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var d := b - a
		var e2 := Vector2(d.y, -d.x).normalized() * (1.0 if ccw else -1.0)
		var en: Vector3 = (ax * e2.x + ay * e2.y).normalized()
		var v1 := v + d.length()
		_tri(st, [at.call(a, -t * 0.5), at.call(b, -t * 0.5), at.call(b, t * 0.5)], [en, en, en],
				[Vector2(u0 + v, 0), Vector2(u0 + v1, 0), Vector2(u0 + v1, t)], Vector2(total, t), flag)
		_tri(st, [at.call(a, -t * 0.5), at.call(b, t * 0.5), at.call(a, t * 0.5)], [en, en, en],
				[Vector2(u0 + v, 0), Vector2(u0 + v1, t), Vector2(u0 + v, t)], Vector2(total, t), flag)
		v = v1


## The back wall's door: beaded casings up each side, a head casing with a small cornice over it,
## a door of boards set back in the opening.
func _door() -> void:
	var x0: float = DOOR[0]
	var x1: float = DOOR[1]
	var h: float = DOOR[3]
	var cw := 0.11
	for x in [x0 - cw * 0.5, x1 + cw * 0.5]:
		_piece(&"int_casings", Vector3(x, h * 0.5, -0.011), Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, -1), h, Profiles.beaded(cw, 0.022, 0.006))
	_piece(&"int_casings", Vector3((x0 + x1) * 0.5, h + 0.08, -0.0125), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1), x1 - x0 + cw * 2.0 + 0.02,
			Profiles.rect(0.16, 0.025))
	_piece(&"int_caps", Vector3((x0 + x1) * 0.5, h + 0.185, -0.035), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, x1 - x0 + cw * 2.0 + 0.08,
			Profiles.ogee(0.07, 0.05))
	var bw := (x1 - x0) / 5.0
	for i in 5:
		_piece(&"int_back_bar", Vector3(x0 + bw * (i + 0.5), h * 0.5, 0.03), Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, -1), h,
				Profiles.beaded(bw - 0.002, 0.03, 0.006))


## The side wall's window: casings round it, a sill, the glass.
func _window() -> void:
	var z0: float = WINDOW[0]
	var z1: float = WINDOW[1]
	var y0: float = WINDOW[2]
	var y1: float = WINDOW[3]
	var cw := 0.11
	for z in [z0 - cw * 0.5, z1 + cw * 0.5]:
		_piece(&"int_casings", Vector3(0.011, (y0 + y1) * 0.5 + 0.04, z), Vector3.UP, Vector3(0, 0, -1), Vector3(1, 0, 0), y1 - y0 + 0.08,
				Profiles.beaded(cw, 0.022, 0.006))
	_piece(&"int_casings", Vector3(0.0125, y1 + 0.08 + 0.04, (z0 + z1) * 0.5), Vector3(0, 0, 1), Vector3.UP, Vector3(1, 0, 0), z1 - z0 + cw * 2.0 + 0.02,
			Profiles.rect(0.16, 0.025))
	_piece(&"int_caps", Vector3(0.035, y1 + 0.225, (z0 + z1) * 0.5), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3.UP, z1 - z0 + cw * 2.0 + 0.08,
			Profiles.ogee(0.07, 0.05))
	_piece(&"int_caps", Vector3(0.04, y0 - 0.02, (z0 + z1) * 0.5), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3.UP, z1 - z0 + cw * 2.0 + 0.04,
			Profiles.rounded(0.08, 0.035, 0.01, [0, 1]))
	var pane := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(z1 - z0, y1 - y0)
	pane.mesh = q
	pane.material_override = WoodMaterials.glass()
	_holder(&"int_casings").add_child(pane)
	pane.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.005, (y0 + y1) * 0.5, (z0 + z1) * 0.5))


## The back bar against the back wall: a panelled base, its counter, shelves on brackets, a
## framed mirror between two columns, a cornice and a crest across the top.
func _back_bar() -> void:
	var x0: float = BACK_BAR.x0
	var x1: float = BACK_BAR.x1
	var d: float = BACK_BAR.deep
	var h: float = BACK_BAR.h
	var len := x1 - x0
	var mid := (x0 + x1) * 0.5
	var front := -d
	# The base's front: rails, stiles, raised panels (as the wainscot, deeper and taller).
	_piece(&"int_back_bar", Vector3(mid, 0.06, front + 0.011), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1), len, Profiles.rounded(0.12, 0.03, 0.008, [1]))
	_piece(&"int_back_bar", Vector3(mid, h - 0.12, front + 0.011), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1), len, Profiles.chamfered(0.09, 0.022, 0.004))
	var bays := 4
	var stile := 0.09
	var bay := (len - stile) / bays
	for b in bays + 1:
		var x := x0 + stile * 0.5 + b * bay
		_piece(&"int_back_bar", Vector3(x, (0.12 + h - 0.165) * 0.5, front + 0.011), Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, -1), h - 0.285,
				Profiles.chamfered(stile, 0.022, 0.004))
		if b < bays:
			_panel(&"int_panels", Vector3(x + bay * 0.5, (0.12 + h - 0.165) * 0.5, front + 0.013), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1),
					bay - stile - 0.01, h - 0.3, 0.018, 0.05)
	# The counter, its front edge rounded.
	_piece(&"int_back_bar", Vector3(mid, h + 0.02, -d * 0.5 - 0.02), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, len + 0.06,
			Profiles.bar_top(d + 0.06, 0.04))
	# Columns at each end and the middle, up to the cornice.
	var top: float = BACK_BAR.top
	for x in [x0 + 0.06, mid, x1 - 0.06]:
		_piece(&"int_back_bar", Vector3(x, (h + 0.04 + top) * 0.5, -0.06), Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, -1), top - h - 0.04,
				Profiles.chamfered(0.1, 0.1, 0.012))
	# Two shelves each side of the middle column on brackets, and the mirror behind them.
	for side in [[x0 + 0.11, mid - 0.05], [mid + 0.05, x1 - 0.11]]:
		var a: float = side[0]
		var b: float = side[1]
		for y in [1.45, 1.95]:
			_piece(&"int_back_bar", Vector3((a + b) * 0.5, y, -0.12), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, b - a,
					Profiles.rounded(0.22, 0.025, 0.006, [0, 1]))
			for x in [a + 0.08, b - 0.08]:
				_cut(&"int_back_bar", Vector3(x - 0.01, y - 0.0125, 0.0), Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0),
						_bracket(0.18, 0.012), 0.02)
		var glass := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(b - a, top - h - 0.35)
		glass.mesh = q
		glass.material_override = _mirror()
		_holder(&"int_back_bar").add_child(glass)
		glass.transform = Transform3D(Basis(Vector3.UP, PI), Vector3((a + b) * 0.5, (h + top - 0.25) * 0.5 + 0.05, -0.012))
	# The cornice across the top and the crest over its middle.
	_piece(&"int_caps", Vector3(mid, top + 0.03, -0.09), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, len + 0.12, Profiles.ogee(0.16, 0.08))
	var crest := PackedVector2Array([Vector2(-len * 0.5, 0.0), Vector2(len * 0.5, 0.0), Vector2(len * 0.5, 0.09)])
	for i in range(1, 16):
		var s := float(i) / 16.0
		crest.append(Vector2(len * 0.5 - len * s, 0.09 + 0.17 * sin(PI * s)))
	crest.append(Vector2(-len * 0.5, 0.09))
	_cut(&"int_back_bar", Vector3(mid, top + 0.07, -0.05), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1), crest, 0.03)


## The bar: a raised-panel front between pilasters on a plinth, the top with its front edge a full
## bullnose (where arms rest), a brass foot rail on brackets.
func _bar() -> void:
	var x0: float = BAR.x0
	var x1: float = BAR.x1
	var z: float = BAR.z
	var d: float = BAR.deep
	var h: float = BAR.h
	var len := x1 - x0
	var mid := (x0 + x1) * 0.5
	var front := z - d * 0.5
	_piece(&"int_bar", Vector3(mid, 0.075, front + 0.015), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1), len, Profiles.rounded(0.15, 0.03, 0.01, [1]))
	_piece(&"int_bar", Vector3(mid, h - 0.1, front + 0.011), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1), len, Profiles.chamfered(0.1, 0.022, 0.004))
	var bays := 4
	var pil := 0.12
	var bay := (len - pil) / bays
	for b in bays + 1:
		var x := x0 + pil * 0.5 + b * bay
		_piece(&"int_bar", Vector3(x, (0.15 + h - 0.15) * 0.5, front + 0.0), Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, -1), h - 0.3,
				Profiles.chamfered(pil, 0.045, 0.01))
		if b < bays:
			_panel(&"int_panels", Vector3(x + bay * 0.5, (0.15 + h - 0.15) * 0.5, front + 0.015), Vector3(1, 0, 0), Vector3.UP, Vector3(0, 0, -1),
					bay - pil - 0.01, h - 0.32, 0.03, 0.07)
	# The ends: plain boards.
	for x in [x0, x1]:
		_board(&"int_bar", Vector3(x, h * 0.5, z), Vector3.UP, Vector3(1, 0, 0), h - 0.05, d, 0.03, Vector3(0, 0, 1))
	_piece(&"int_bar_top", Vector3(mid, h - 0.03, z - 0.09), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, len + 0.14, Profiles.bar_top(d + 0.2, 0.065))
	# The foot rail: brass, 50 mm, on brackets 0.15 up.
	var rail := PropModels.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.025, 0), Vector2(0.025, len), Vector2(0, len)]), 12, true)
	var brass := PixelArt.material(PixelArt.factory("prop_brass"), Color.WHITE, PixelArt.Mapping.UV, Vector3.ZERO, 0.45, 0.6, 0.6)
	var mi := MeshInstance3D.new()
	mi.mesh = rail
	mi.material_override = brass
	_holder(&"int_bar").add_child(mi)
	mi.transform = Transform3D(Basis(Vector3(0, 0, 1), -PI * 0.5), Vector3(x0, 0.15, front - 0.16))
	for x in [x0 + 0.2, mid, x1 - 0.2]:
		var arm := MeshInstance3D.new()
		arm.mesh = PropModels.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.012, 0), Vector2(0.012, 0.17), Vector2(0, 0.17)]), 8, true)
		arm.material_override = brass
		_holder(&"int_bar").add_child(arm)
		arm.transform = Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(x, 0.15, front))


## The gallery: two chamfered posts to the floor in front of the bar, a beam along its edge, a
## bracket each side of each post, joists back to the wall, the deck, and its balustrade (newels,
## a bottom rail, turned balusters, the moulded handrail at 1 m).
func _gallery() -> void:
	var zb := -GALLERY_D + POST_W * 0.5
	var beam_y := FLOOR_H - 0.03 - BEAM_WD.y * 0.5
	for x in [0.35, W - 0.35]:
		var ph := FLOOR_H - 0.03 - BEAM_WD.y
		_piece(&"int_posts", Vector3(x, ph * 0.5, zb), Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, -1), ph, Profiles.chamfered(POST_W, POST_W, 0.035))
		for side in [-1.0, 1.0]:
			if (x < 1.0 and side < 0.0) or (x > W - 1.0 and side > 0.0):
				continue
			_cut(&"int_brackets", Vector3(x + side * POST_W * 0.5, beam_y - BEAM_WD.y * 0.5, zb), Vector3(side, 0, 0), Vector3.UP,
					Vector3(0, 0, -1), _bracket(0.55, 0.035), 0.1)
	_piece(&"int_beams", Vector3(W * 0.5, beam_y, zb), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, W, Profiles.chamfered(BEAM_WD.x, BEAM_WD.y, 0.03))
	var x := 0.2
	var joist := GALLERY_D - POST_W - 0.005
	while x < W:
		# Back to the beam's back face (flush with its front they flickered through it as black ticks).
		_piece(&"int_beams", Vector3(x, FLOOR_H - 0.03 - 0.1, -joist * 0.5), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3.UP, joist,
				Profiles.chamfered(0.05, 0.2, 0.006))
		x += 0.4
	var z := -0.075
	while z > -GALLERY_D - 0.02:
		_board(&"int_gallery", Vector3(W * 0.5, FLOOR_H - 0.015, z), Vector3(1, 0, 0), Vector3.UP, W, 0.146, 0.03, Vector3(0, 0, 1))
		z -= 0.15
	# The balustrade on the deck's edge.
	var zr := -GALLERY_D + 0.07
	for nx in [0.2, W - 0.2]:
		_newel(Vector3(nx, FLOOR_H, zr), 1.15)
	var rail_y := FLOOR_H + 1.0
	_piece(&"int_rail", Vector3(W * 0.5, rail_y - 0.03, zr), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, W - 0.4, Profiles.handrail(0.075, 0.06))
	_piece(&"int_rail", Vector3(W * 0.5, FLOOR_H + 0.05, zr), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, W - 0.4, Profiles.chamfered(0.07, 0.05, 0.006))
	var bx := 0.38
	while bx < W - 0.3:
		_stout_baluster(Vector3(bx, FLOOR_H + 0.075, zr), rail_y - 0.06 - FLOOR_H - 0.075)
		bx += 0.12


## A stout turned baluster (the picture's gallery: square at its feet and neck, a full vase between),
## 64 mm at its square, h tall.
func _stout_baluster(at: Vector3, h: float) -> void:
	var sq := 0.032
	_board(&"oak_balusters", at + Vector3(0, 0.06, 0), Vector3.UP, Vector3(0, 0, 1), 0.12, sq * 2.0, sq * 2.0)
	_board(&"oak_balusters", at + Vector3(0, h - 0.06, 0), Vector3.UP, Vector3(0, 0, 1), 0.12, sq * 2.0, sq * 2.0)
	var t := h - 0.24
	var p := PackedVector2Array([Vector2(0, 0), Vector2(0.026, 0), Vector2(0.03, 0.02), Vector2(0.02, 0.05), Vector2(0.03, t * 0.25),
			Vector2(0.036, t * 0.42), Vector2(0.028, t * 0.6), Vector2(0.016, t * 0.78), Vector2(0.022, t * 0.88), Vector2(0.026, t * 0.95),
			Vector2(0.024, t), Vector2(0, t)])
	_turned(&"oak_balusters", PropModels.lathe(p, 12, true), Transform3D(Basis(), at + Vector3(0, 0.12, 0)), int(at.x * 53.0))


## A bracket's outline: `l` along the beam and down the post, its face a cove (the brace's curve)
## from one end to the other, `lip` square at each end.
func _bracket(l: float, lip: float) -> PackedVector2Array:
	var out := PackedVector2Array([Vector2(0, 0), Vector2(l, 0), Vector2(l, -lip)])
	var r := l - lip
	for i in range(1, 12):
		var a := PI * 0.5 + PI * 0.5 * float(i) / 12.0
		out.append(Vector2(l, -l) + Vector2(cos(a), sin(a)) * r)
	out.append(Vector2(lip, -l))
	out.append(Vector2(0, -l))
	return out


static var _mirror_mat: StandardMaterial3D


## The back bar's mirror: dark, glossy, faintly warm.
static func _mirror() -> StandardMaterial3D:
	if _mirror_mat == null:
		_mirror_mat = StandardMaterial3D.new()
		_mirror_mat.albedo_color = Color(0.16, 0.15, 0.13)
		_mirror_mat.metallic = 0.85
		_mirror_mat.roughness = 0.12
	return _mirror_mat

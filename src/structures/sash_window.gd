class_name SashWindow
extends RefCounted
## A double-hung sash window as members (#826, Sean's pick 4 on #821): the opening lined (jambs,
## head and sill boards from the siding's face to the inside finish's, so you never look into the
## wall), two sashes in it (the upper outside the lower, their meeting rails lapped at the middle),
## each of stiles, rails and glazing bars, and a pane of glass a light, each its own glass member:
## a ball through one breaks that one (StructureMember.shatter), the rest stand. The panes are
## kind `glass`, so Sight holds them on `Layers.SIGHT_GLASS` (sight.gd KIND_GLASS: seen through,
## shot through, not walked through) as it held the old single pane.
##
## Any FalseFrontBuilding (the building lab's builder, the town's) calls `build` for an opening;
## it is a part (docs/PARTS.md), not the builder's. It works behind bars (`_bars`, at d -0.04 to
## -0.018): the sashes sit inward of them.
##
## Sizes from period joinery (Hodgson, "Practical Carpentry" 1883 and the sash-maker's tables in
## Bell's "Carpentry Made Easy" 1858): sashes 1 3/8 in thick, stiles ~2 in, top rails ~2 1/4 in,
## bottom rails ~3 in, meeting rails 1 1/4 in, glazing bars ~7/8 in; jamb linings 7/8 in.
##
## A pointed head (#1142, the church: opts `rise`): the opening is cut to the apex, the double-hung
## sashes stand under a transom at the springing, and over it a fixed head sash with straight sides
## meeting at a point (a carpenter-Gothic lancet: the plain pointed head of Upjohn's "Rural
## Architecture" 1852 and the pattern books after it, sawn straight, not struck to a curve). Its
## reveal is lined with two slanted boards, the wall's corners each side of the point are filled with
## short boards of the siding and the inside finish stepped up to the slant (as a carpenter cuts each
## course to a head casing), and a slanted casing covers the joint outside. Every piece a member.

const LINING_T := 0.022
const SILL_T := 0.03
const SASH_T := 0.032
const STILE_W := 0.05
const TOP_RAIL := 0.055
const BOTTOM_RAIL := 0.075
const MEET_RAIL := 0.032
const BAR_W := 0.022
const PANE_T := 0.003
## The sashes' depths (along the wall's `out`, metres from the studs' outer face; the inside is
## negative): the upper sash outside, the lower inside, a parting bead's width between.
const UPPER_D := -0.042
const LOWER_D := -0.078
## A pointed head's slanted lining (in the wall's plane) and how high each step of its fill is (about).
const ARCH_W := 0.06
const FILL_STEP := 0.07

static var _pane_mat: ShaderMaterial


## Build the window in `o` (the opening in the wall's own frame: x along it, y up) of `wall` (a
## FalseFrontBuilding wall dict). `lights` is the pane count of the whole window (two sashes of
## lights / 2; 1 is a single fixed light). `opts`: `wood` (the sash's, default dark_trim), `outer`
## and `inner` (the lining's faces, default the siding's face and the inside boards'), `id` (the
## members' prefix); for a pointed head (the rectangle `o` then runs to its apex) `rise` (the head's
## height over the springing), `face_wood` (the siding's), `level` (the inside finish's ids) and
## `casing` (false: no casing outside). Returns what it made, panes last.
static func build(b: FalseFrontBuilding, wall: Dictionary, o: Rect2, lights: int, opts := {}) -> Array[StructureMember]:
	var rise := float(opts.get("rise", 0.0))
	if rise > 0.0:
		var sq := Rect2(o.position, Vector2(o.size.x, o.size.y - rise))
		var rest := opts.duplicate()
		rest.erase("rise")
		var below := build(b, wall, sq, lights, rest)
		var head := pointed_head(b, wall, o, rise, opts)
		var all: Array[StructureMember] = []
		for m in below + head:
			if m.kind != &"glass":
				all.append(m)
		for m in below + head:
			if m.kind == &"glass":
				all.append(m)
		return all
	var made: Array[StructureMember] = []
	var wood := StringName(opts.get("wood", &"dark_trim"))
	var outer := float(opts.get("outer", FalseFrontBuilding.BOARD_T))
	var inner := float(opts.get("inner", -FalseFrontBuilding.STUD_D - 0.02))
	var id: String = opts.get("id", "%s/window_%d_%d" % [wall.name, int(o.position.x * 100.0), int(o.position.y * 100.0)])
	# The lining: the sill board across the bottom, the jambs on it, the head across their tops.
	# Lined in framing's tier (as the boards' nailers are): the sashes rest on it as trim on a stud.
	var x0 := o.position.x
	var x1 := o.end.x
	var y0 := o.position.y
	var y1 := o.end.y
	made.append(b._wall_member(id + "/lining_sill", &"cripple", wood, wall, x0, x1, y0, y0 + SILL_T, inner, outer))
	made.append(b._wall_member(id + "/lining_jamb0", &"cripple", wood, wall, x0, x0 + LINING_T, y0 + SILL_T, y1 - LINING_T, inner, outer))
	made.append(b._wall_member(id + "/lining_jamb1", &"cripple", wood, wall, x1 - LINING_T, x1, y0 + SILL_T, y1 - LINING_T, inner, outer))
	made.append(b._wall_member(id + "/lining_head", &"cripple", wood, wall, x0, x1, y1 - LINING_T, y1, inner, outer))
	var cx0 := x0 + LINING_T
	var cx1 := x1 - LINING_T
	var cy0 := y0 + SILL_T
	var cy1 := y1 - LINING_T
	var panes: Array[StructureMember] = []
	if lights <= 1:
		_sash(b, wall, id + "/sash", Rect2(cx0, cy0, cx1 - cx0, cy1 - cy0), 1, BOTTOM_RAIL, TOP_RAIL,
				(UPPER_D + LOWER_D) * 0.5, wood, made, panes)
	else:
		var mid := (cy0 + cy1) * 0.5
		var each := maxi(lights / 2, 1)
		# The upper sash from the head down past the middle by half a meeting rail, the lower up to it.
		_sash(b, wall, id + "/upper", Rect2(cx0, mid - MEET_RAIL * 0.5, cx1 - cx0, cy1 - mid + MEET_RAIL * 0.5), each,
				MEET_RAIL, TOP_RAIL, UPPER_D, wood, made, panes)
		_sash(b, wall, id + "/lower", Rect2(cx0, cy0, cx1 - cx0, mid + MEET_RAIL * 0.5 - cy0), lights - each,
				BOTTOM_RAIL, MEET_RAIL, LOWER_D, wood, made, panes)
	made.append_array(panes)
	return made


## The pointed head over a sash window: `o` the whole opening (to the apex), `rise` the head's height
## over the springing (where the square sashes' head lining lies, the transom). See the top.
static func pointed_head(b: FalseFrontBuilding, wall: Dictionary, o: Rect2, rise: float, opts := {}) -> Array[StructureMember]:
	var made: Array[StructureMember] = []
	var wood := StringName(opts.get("wood", &"dark_trim"))
	var face_wood := StringName(opts.get("face_wood", wood))
	var outer := float(opts.get("outer", FalseFrontBuilding.BOARD_T))
	var inner := float(opts.get("inner", -FalseFrontBuilding.STUD_D - 0.02))
	var x0 := o.position.x
	var x1 := o.end.x
	var ye := o.end.y
	var ys := ye - rise
	var cx := (x0 + x1) * 0.5
	var hw := (x1 - x0) * 0.5
	var sin_t := rise / sqrt(hw * hw + rise * rise)
	var cos_t := hw / sqrt(hw * hw + rise * rise)
	var id: String = opts.get("id", "%s/window_%d_%d" % [wall.name, int(x0 * 100.0), int(o.position.y * 100.0)])
	var tag := "gothic_%d_%d" % [int(x0 * 100.0), int(o.position.y * 100.0)]
	# The left slant's x at height y, `p` in from it (perpendicular to it, toward the opening).
	var slant_x := func(y: float, p: float) -> float: return x0 + (y - ys) / rise * hw + p / sin_t
	# The reveal's two slanted linings, the springing to the apex, through the wall.
	for side in 2:
		var a := Vector2(x0 if side == 0 else x1, ys)
		var top := Vector2(cx, ye) + (Vector2(cx, ye) - a).normalized() * 0.03
		made.append(_slant(b, wall, "%s/arch_%s" % [id, "lr"[side]], &"cripple", wood, a, top, ARCH_W, inner, outer))
	# The wall's corners beside the point: boards of the siding outside and the finish inside, each
	# cut to the slant at its middle height (the lining covers the steps).
	var n := maxi(3, roundi(rise / FILL_STEP))
	var dy := rise / n
	var lvl := String(opts.get("level", "ground"))
	for i in n:
		var ya := ys + i * dy
		var ym := ya + dy * 0.5
		var lx: float = slant_x.call(ym, 0.0)
		if lx - x0 < 0.01:
			continue
		for side in 2:
			var a0 := x0 if side == 0 else x1 - (lx - x0)
			var a1 := lx if side == 0 else x1
			var sfx := "%s%d" % ["lr"[side], i]
			made.append(b._wall_member("%s/siding/%s/%s" % [wall.name, tag, sfx], &"board", face_wood, wall, a0, a1, ya, ya + dy, 0.0, outer))
			made.append(b._wall_member("%s/in_%s/%s/%s" % [wall.name, lvl, tag, sfx], &"board", &"framing", wall, a0, a1, ya, ya + dy,
					inner, -FalseFrontBuilding.STUD_D))
	# Over the apex, the rest of the lap course the opening cut (#1170: it showed as a dark strip of header): one
	# board across the opening from the point to that course's top (the courses from 0.05 up, LAP_BOARD_H each).
	var lap := FalseFrontBuilding.LAP_BOARD_H
	var course_top := 0.05 + (floorf((ye - 0.05) / lap) + 1.0) * lap - 0.005
	if course_top - ye > 0.008 and opts.get("lap_fill", true):
		made.append(b._wall_member("%s/siding/%s/over" % [wall.name, tag], &"board", face_wood, wall, x0, x1, ye, course_top, 0.0, outer))
	# The fixed head sash: its slanted sides, a bar up the middle, a pane each side of it a step.
	var d1 := (UPPER_D + LOWER_D) * 0.5
	var d0 := d1 - SASH_T
	var off := ARCH_W * 0.5 + STILE_W * 0.5
	var ytop := ye - off / cos_t
	for side in 2:
		var bx: float = slant_x.call(ys, off)
		var a := Vector2(bx if side == 0 else x1 - (bx - x0), ys)
		made.append(_slant(b, wall, "%s/head/stile_%s" % [id, "lr"[side]], &"trim", wood, a, Vector2(cx, ytop), STILE_W, d0, d1))
	made.append(b._wall_member(id + "/head/bar", &"trim", wood, wall, cx - BAR_W * 0.5, cx + BAR_W * 0.5, ys, ytop, d0 + 0.006, d1))
	var pd := d1 - 0.01
	var pn := maxi(3, roundi((ytop - ys) / FILL_STEP))
	var ph := (ytop - ys) / pn
	var panes: Array[StructureMember] = []
	for i in pn:
		var ya := ys + i * ph
		var px: float = slant_x.call(ya + ph * 0.5, off)
		if cx - BAR_W * 0.5 - px < 0.015:
			continue
		for side in 2:
			var a0 := px if side == 0 else cx + BAR_W * 0.5
			var a1 := cx - BAR_W * 0.5 if side == 0 else x1 - (px - x0)
			var p := b._wall_member("%s/head/pane_%s%d" % [id, "lr"[side], i], &"glass", &"glass", wall, a0, a1, ya, ya + ph, pd - PANE_T, pd)
			dress_pane(p)
			panes.append(p)
	# The casing outside: two slanted boards over the joint, from the jambs' casings to a point.
	if opts.get("casing", true):
		var tw: float = b.trim_w
		var tid := "%s/trim_%d_%d" % [wall.name, int(x0 * 100.0), int(o.position.y * 100.0)]
		for side in 2:
			var bx: float = slant_x.call(ys, -tw * 0.5)
			var a := Vector2(bx if side == 0 else x1 - (bx - x0), ys)
			var apex := Vector2(cx, ye + tw * 0.5 / cos_t)
			apex += (apex - a).normalized() * tw * 0.5 * cos_t / sin_t
			made.append(_slant(b, wall, "%s/arch_%s" % [tid, "lr"[side]], &"trim", wood, a, apex, tw,
					outer, outer + FalseFrontBuilding.TRIM_T))
			if opts.get("hood", 0.0) > 0.0:
				# a drip cap along the casing's outer edge, standing proud of it (#1170: "a hood on the arch")
				var hd := float(opts.hood)
				var dir := (apex - a).normalized()
				var p0 := a + dir.rotated(PI * 0.5 if side == 0 else -PI * 0.5) * (tw * 0.5 + hd * 0.5 - 0.01)
				# to the middle line, and on by half its width's mitre, so the two meet at the point
				var p1 := p0 + dir * ((cx - p0.x) / dir.x) + dir * (hd * 0.5 * cos_t / sin_t)
				made.append(_slant(b, wall, "%s/hood_%s" % [tid, "lr"[side]], &"trim", wood, p0, p1, hd,
						outer - 0.002, outer + FalseFrontBuilding.TRIM_T + 0.03))  # (back on the siding: it rests on the boards, not the casing)
	made.append_array(panes)
	return made


## A member from `p0` to `p1` (the wall's own frame: x along it, y up), `w` wide in the wall's plane,
## from `d0` to `d1` through it.
static func _slant(b: FalseFrontBuilding, wall: Dictionary, id: String, kind: StringName, wood: StringName,
		p0: Vector2, p1: Vector2, w: float, d0: float, d1: float) -> StructureMember:
	var along: Vector3 = wall.along
	var out: Vector3 = wall.out
	var mid := (p0 + p1) * 0.5
	var c: Vector3 = wall.origin + along * mid.x + Vector3.UP * mid.y + out * ((d0 + d1) * 0.5)
	var dir := (along * (p1.x - p0.x) + Vector3.UP * (p1.y - p0.y)).normalized()
	var bas := Basis(dir, out.cross(dir), out).orthonormalized()
	return b.add_member(id, kind, wood, Vector3(p0.distance_to(p1), w, d1 - d0), c, bas)


## One sash in `r`: its bottom and top rails (`lo`, `hi` high) run through between the linings,
## the stiles between them, glazing bars making `n` lights in a grid of the most nearly upright
## panes (cols x rows = n), a pane in each. Each piece rests on the one under it (the support
## graph's trim on trim) or on the lining beside it, so the sash stands as its joints hold it, and
## a pane rests on the rail or bar under it.
static func _sash(b: FalseFrontBuilding, wall: Dictionary, id: String, r: Rect2, n: int, lo: float, hi: float, d: float,
		wood: StringName, made: Array[StructureMember], panes: Array[StructureMember]) -> void:
	var d0 := d - SASH_T
	var d1 := d
	var gy0 := r.position.y + lo
	var gy1 := r.end.y - hi
	made.append(b._wall_member(id + "/rail_lo", &"trim", wood, wall, r.position.x, r.end.x, r.position.y, gy0, d0, d1))
	made.append(b._wall_member(id + "/rail_hi", &"trim", wood, wall, r.position.x, r.end.x, gy1, r.end.y, d0, d1))
	made.append(b._wall_member(id + "/stile0", &"trim", wood, wall, r.position.x, r.position.x + STILE_W, gy0, gy1, d0, d1))
	made.append(b._wall_member(id + "/stile1", &"trim", wood, wall, r.end.x - STILE_W, r.end.x, gy0, gy1, d0, d1))
	var gx0 := r.position.x + STILE_W
	var gx1 := r.end.x - STILE_W
	var grid := grid_for(n, gx1 - gx0, gy1 - gy0)
	var cols: int = grid.x
	var rows: int = grid.y
	# The glazing bars: the crossbars across between the stiles, the uprights cut between them;
	# the glass between, in the bars' outer half.
	var pw := (gx1 - gx0 - BAR_W * (cols - 1)) / cols
	var ph := (gy1 - gy0 - BAR_W * (rows - 1)) / rows
	for k in range(1, rows):
		var by := gy0 + k * ph + (k - 1) * BAR_W
		made.append(b._wall_member("%s/bar_h%d" % [id, k], &"trim", wood, wall, gx0, gx1, by, by + BAR_W, d0 + 0.006, d1))
	for c in cols:
		var px := gx0 + c * (pw + BAR_W)
		for k in rows:
			var py := gy0 + k * (ph + BAR_W)
			if c > 0:
				made.append(b._wall_member("%s/bar_v%d_%d" % [id, c, k], &"trim", wood, wall, px - BAR_W, px, py, py + ph, d0 + 0.006, d1))
			var pd := d1 - 0.01
			var p := b._wall_member("%s/pane%d_%d" % [id, c, k], &"glass", &"glass", wall, px, px + pw, py, py + ph, pd - PANE_T, pd)
			dress_pane(p)
			panes.append(p)


## The lights of one sash as columns and rows: of the ways to make `n`, the one whose panes stand
## most nearly as period panes do (about 3 wide to 4 high), always with an upright bar when it has
## more than one (a sash is divided across first; its crossbars then rest on the uprights' pieces).
## Vector2i(cols, rows).
static func grid_for(n: int, w: float, h: float) -> Vector2i:
	var best := Vector2i(n, 1)
	var err := INF
	for cols in range(1 if n == 1 else 2, n + 1):
		if n % cols != 0:
			continue
		var rows := n / cols
		var e := absf(log((w / cols) / (h / rows)) - log(0.75))
		if e < err - 0.0001:
			err = e
			best = Vector2i(cols, rows)
	return best


## A pane drawn as old window glass: a faint green film, dust gathered in its corners and along its
## bottom (window_glass.gdshader), no shadow of its own (as the single pane was).
static func dress_pane(p: StructureMember) -> void:
	var mi := p.get_child(0) as MeshInstance3D
	if mi == null:
		return
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = pane_material()
	mi.set_instance_shader_parameter(&"half_size", p.size * 0.5)


static func pane_material() -> ShaderMaterial:
	if _pane_mat == null:
		_pane_mat = ShaderMaterial.new()
		_pane_mat.shader = load("res://src/structures/window_glass.gdshader")
	return _pane_mat

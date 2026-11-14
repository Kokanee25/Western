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

static var _pane_mat: ShaderMaterial


## Build the window in `o` (the opening in the wall's own frame: x along it, y up) of `wall` (a
## FalseFrontBuilding wall dict). `lights` is the pane count of the whole window (two sashes of
## lights / 2; 1 is a single fixed light). `opts`: `wood` (the sash's, default dark_trim), `outer`
## and `inner` (the lining's faces, default the siding's face and the inside boards'), `id` (the
## members' prefix). Returns what it made, panes last.
static func build(b: FalseFrontBuilding, wall: Dictionary, o: Rect2, lights: int, opts := {}) -> Array[StructureMember]:
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

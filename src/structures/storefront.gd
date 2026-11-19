class_name Storefront
extends RefCounted
## A period storefront as members (#1053): show windows and a recessed entry, a part any spec
## building takes from its front wall's openings (docs/PARTS.md "A storefront").
##
## - A **show window** (a wall opening of `"type": "window", "show": true`): the opening lined as a
##   sash window's is, a frame of plate glass in it (`cols` lights side by side, a mullion between),
##   a transom bar `transom` metres under its head and a row of `transom_lights` over it, and the
##   wall under it (its `sill`) faced as a panelled bulkhead.
## - A **recessed entry** (`"type": "recess"`): the front wall open from the floor to `height`
##   over `width`, its header and kings framing the mouth; the door set back `depth` metres in a
##   short wall of its own (`door`: width, height; a glazed leaf, shut, a transom light over it), the
##   show windows angling in from the mouth's corners to the door's jambs (glass over a `bulkhead`,
##   the same transom line), a boarded ceiling over the recess at the head, a threshold across the
##   mouth. The recess's floor is the shop's own.
##
## Built from NPS Preservation Brief 11, "Rehabilitating Historic Storefronts" (display windows on
## a low bulkhead, a recessed entry, transoms, "the display window area expanded to the maximum
## extent possible", 1850-1900). Sizes from period joinery as SashWindow's (Hodgson 1883, Bell
## 1858): plate-glass stiles and rails heavier than a sash's (a 2 1/2 in stile, a 3 in bottom rail).
##
## Everything is a member: a pane is kind `glass` (breaks alone, seen and shot through), the frame
## `trim`, the recess's posts and heads framing (`stud`, `header`), its bulkheads and ceiling
## `board`. Ids: a show window's under `<wall>/window_show_<x>`, the recess's under `<wall>/recess/`.

const STILE := 0.065
const RAIL_LO := 0.08
const RAIL_HI := 0.065
const BAR := 0.05
const TRANSOM_BAR := 0.06
const GLASS_D := -0.05  # the panes' plane, metres out from the studs' outer face (inside negative)
const POST := 0.1       # the recess's corner posts and door jambs
const HEAD := 0.1       # the recess's head over its walls


## A frame for members off an axis (the recess's angled sides): `origin` the line's start at the
## floor's height 0, `along` it, `out` (the side the street is on), its basis (x along, y up).
static func frame(origin: Vector3, along: Vector3, out: Vector3, length: float) -> Dictionary:
	along = along.normalized()
	return {"origin": origin, "along": along, "out": out.normalized(), "length": length,
			"basis": Basis(along, Vector3.UP, along.cross(Vector3.UP))}


## A member on a frame: `s0..s1` along it, `y0..y1`, `d0..d1` out from its line.
static func member(b: FalseFrontBuilding, f: Dictionary, id: String, kind: StringName, wood: StringName,
		s0: float, s1: float, y0: float, y1: float, d0: float, d1: float) -> StructureMember:
	var c: Vector3 = (f.origin as Vector3) + (f.along as Vector3) * ((s0 + s1) * 0.5) + Vector3.UP * ((y0 + y1) * 0.5) \
			+ (f.out as Vector3) * ((d0 + d1) * 0.5)
	return b.add_member(id, kind, wood, Vector3(s1 - s0, y1 - y0, absf(d1 - d0)), c, f.basis)


## A wall dict (FalseFrontBuilding._wall) as a frame.
static func of_wall(wall: Dictionary) -> Dictionary:
	return frame(wall.origin, wall.along, wall.out, float(wall.length))


## Plate glass in `r` on frame `f`: rails, stiles, `cols` lights with mullions between, a transom bar
## `transom` under the head and `tcols` transom lights over it. Returns the panes.
static func lights(b: FalseFrontBuilding, f: Dictionary, id: String, r: Rect2, cols: int, transom: float, tcols: int,
		wood: StringName, d := GLASS_D) -> Array[StructureMember]:
	var panes: Array[StructureMember] = []
	var d0 := d - 0.03
	var d1 := d + 0.02
	var x0 := r.position.x
	var x1 := r.end.x
	var y0 := r.position.y
	var y1 := r.end.y
	member(b, f, id + "/rail_lo", &"trim", wood, x0, x1, y0, y0 + RAIL_LO, d0, d1)
	member(b, f, id + "/rail_hi", &"trim", wood, x0, x1, y1 - RAIL_HI, y1, d0, d1)
	member(b, f, id + "/stile0", &"trim", wood, x0, x0 + STILE, y0 + RAIL_LO, y1 - RAIL_HI, d0, d1)
	member(b, f, id + "/stile1", &"trim", wood, x1 - STILE, x1, y0 + RAIL_LO, y1 - RAIL_HI, d0, d1)
	var gx0 := x0 + STILE
	var gx1 := x1 - STILE
	var gy0 := y0 + RAIL_LO
	var top := y1 - RAIL_HI
	var ty := top
	if transom > 0.1:
		ty = top - transom
		member(b, f, id + "/transom_bar", &"trim", wood, gx0, gx1, ty, ty + TRANSOM_BAR, d0, d1)
		_row(b, f, id + "/t", gx0, gx1, ty + TRANSOM_BAR, top, maxi(tcols, 1), d, d0, d1, wood, panes)
	_row(b, f, id + "/l", gx0, gx1, gy0, ty, maxi(cols, 1), d, d0, d1, wood, panes)
	return panes


## A row of `n` panes between x0 and x1, a bar between each.
static func _row(b: FalseFrontBuilding, f: Dictionary, id: String, x0: float, x1: float, y0: float, y1: float, n: int,
		d: float, d0: float, d1: float, wood: StringName, panes: Array[StructureMember]) -> void:
	var pw := (x1 - x0 - BAR * (n - 1)) / n
	for k in n:
		var px := x0 + k * (pw + BAR)
		if k > 0:
			member(b, f, "%s/bar%d" % [id, k], &"trim", wood, px - BAR, px, y0, y1, d0, d1)
		var p := member(b, f, "%s/pane%d" % [id, k], &"glass", &"glass", px, px + pw, y0, y1, d - 0.004, d)
		SashWindow.dress_pane(p)
		panes.append(p)


## A show window in opening `o` (the wall's frame) of `wall`: lined, its plate glass and transom, and
## the bulkhead under it faced in panels. `so` the opening's spec.
static func show_window(b: FalseFrontBuilding, wall: Dictionary, o: Rect2, so: Dictionary, wood: StringName) -> Array[StructureMember]:
	var id := "%s/window_show_%d" % [wall.name, int(o.position.x * 100.0)]
	var f := of_wall(wall)
	var outer := FalseFrontBuilding.BOARD_T
	var inner := -FalseFrontBuilding.STUD_D - 0.02
	var lt := SashWindow.LINING_T
	member(b, f, id + "/lining_sill", &"cripple", wood, o.position.x, o.end.x, o.position.y, o.position.y + SashWindow.SILL_T, inner, outer)
	member(b, f, id + "/lining_jamb0", &"cripple", wood, o.position.x, o.position.x + lt, o.position.y + SashWindow.SILL_T, o.end.y - lt, inner, outer)
	member(b, f, id + "/lining_jamb1", &"cripple", wood, o.end.x - lt, o.end.x, o.position.y + SashWindow.SILL_T, o.end.y - lt, inner, outer)
	member(b, f, id + "/lining_head", &"cripple", wood, o.position.x, o.end.x, o.end.y - lt, o.end.y, inner, outer)
	var r := Rect2(o.position.x + lt, o.position.y + SashWindow.SILL_T, o.size.x - lt * 2.0, o.size.y - SashWindow.SILL_T - lt)
	var cols := int(so.get("cols", maxi(roundi(r.size.x / 1.8), 1)))
	var tcols := int(so.get("transom_lights", maxi(roundi(r.size.x / 0.85), 1)))
	var panes := lights(b, f, id, r, cols, float(so.get("transom", 0.0)), tcols, wood)
	if so.has("gilt"):
		gilt(f, panes, r, so.gilt)
	# The bulkhead: a panel a light under the sill, stiles and rails round them, on the siding.
	var bottom := float(so.get("bulkhead_from", o.position.y - float(so.get("sill", 0.5)) + 0.08))
	_panels(b, f, id + "/bulkhead", o.position.x - FalseFrontBuilding.TRIM_W, o.end.x + FalseFrontBuilding.TRIM_W,
			bottom, o.position.y - 0.04, cols, outer, wood)
	return panes


## A sign-writer's gold leaf on a show window's glass (#1074, the store's "A. P. HOLLIS"): the
## factory's `gilt_<id>` (tools/textures/gold_leaf.py: gold, outlined and shaded) laid on the inside
## face of the lights it crosses, each pane carrying its own piece, so a broken pane takes its letters
## with it. `g`: {id, y (the lettering's middle over the opening's foot), width (metres, else as
## made)}. Seen from the shop it reads backwards, as gilding on glass does. `r` the glass's rect.
static func gilt(f: Dictionary, panes: Array[StructureMember], r: Rect2, g: Dictionary) -> void:
	var path := "res://assets/textures/gilt_%s.png" % String(g.get("id", ""))
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	var w := float(g.get("width", tex.get_width() / float(GILT_TEXELS)))
	var h := w * tex.get_height() / float(tex.get_width())
	var sc := r.get_center().x
	var yc := r.position.y - SashWindow.SILL_T + float(g.get("y", 1.3))
	var along: Vector3 = f.along
	var out: Vector3 = f.out
	# Seen from the street (looking in, along -out) the letters run to the viewer's right.
	var right := Vector3.UP.cross(out).normalized()
	var k := signf(along.dot(right))
	var basis := Basis(right, Vector3.UP, out)
	for p: StructureMember in panes:
		# The pane in the frame's coordinates (along its line, up): its centre and size.
		var pc: Vector3 = p.position - (f.origin as Vector3)
		var ps := pc.dot(along)
		var py := pc.y
		var x0 := maxf(ps - p.size.x * 0.5, sc - w * 0.5)
		var x1 := minf(ps + p.size.x * 0.5, sc + w * 0.5)
		var y0 := maxf(py - p.size.y * 0.5, yc - h * 0.5)
		var y1 := minf(py + p.size.y * 0.5, yc + h * 0.5)
		if x1 - x0 < 0.01 or y1 - y0 < 0.01:
			continue
		# Corners in the lettering's own (right, up) from its middle, and their UVs.
		var a := (x0 - sc) * k
		var c := (x1 - sc) * k
		var r0 := minf(a, c)
		var r1 := maxf(a, c)
		var uv := func(rx: float, uy: float) -> Vector2: return Vector2(rx / w + 0.5, 0.5 - uy / h)
		var q0 := y0 - yc
		var q1 := y1 - yc
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(Vector3.BACK)
		for v: Vector2 in [Vector2(r0, q0), Vector2(r1, q0), Vector2(r1, q1), Vector2(r0, q0), Vector2(r1, q1), Vector2(r0, q1)]:
			st.set_uv(uv.call(v.x, v.y))
			st.add_vertex(Vector3(v.x, v.y, 0.0))
		var mi := MeshInstance3D.new()
		mi.name = "Gilt"
		mi.mesh = st.commit()
		mi.material_override = gilt_material(tex)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# On the glass's inside face (the pane runs from GLASS_D - 0.004 to GLASS_D out of the studs).
		var at := (f.origin as Vector3) + along * sc + Vector3.UP * yc + out * (pc.dot(out) - p.size.z * 0.5 - 0.0015)
		mi.transform = p.transform.affine_inverse() * Transform3D(basis, at)
		p.add_child(mi)


const GILT_TEXELS := 256
static var _gilt_mats := {}


## Leaf over a black outline: a little metal where it's gold (the outline's black stays black), burnished,
## both faces drawn (from the shop it's the leaf's back, read backwards).
static func gilt_material(tex: Texture2D) -> StandardMaterial3D:
	if _gilt_mats.has(tex):
		return _gilt_mats[tex]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# (Mostly its own colour: at 0.85 metal it showed only what it reflects, and under the porch's roof
	# with no probe outside that's next to nothing: the leaf went grey, #1074's first render.)
	m.metallic = 0.3
	m.metallic_specular = 0.8
	m.roughness = 0.35
	_gilt_mats[tex] = m
	return m


## A panelled face from x0 to x1, y0 to y1, `n` panels, on a wall's outside at depth `d`: stiles
## and rails proud of the panels.
static func _panels(b: FalseFrontBuilding, f: Dictionary, id: String, x0: float, x1: float, y0: float, y1: float, n: int,
		d: float, wood: StringName) -> void:
	if y1 - y0 < 0.2:
		return
	var st := 0.09
	member(b, f, id + "/panel", &"trim", wood, x0, x1, y0, y1, d, d + 0.015)
	# (its stiles and rails a band up: they rest on the panel, nailed through it)
	var band0 := int(b.get(&"band"))
	b.set(&"band", band0 + 1)
	member(b, f, id + "/rail_lo", &"trim", wood, x0, x1, y0, y0 + st, d + 0.015, d + 0.035)
	member(b, f, id + "/rail_hi", &"trim", wood, x0, x1, y1 - st, y1, d + 0.015, d + 0.035)
	for k in n + 1:
		var sx := lerpf(x0, x1 - st, float(k) / n)
		member(b, f, "%s/stile%d" % [id, k], &"trim", wood, sx, sx + st, y0 + st, y1 - st, d + 0.015, d + 0.035)
	b.set(&"band", band0)


## The recessed entry in opening `o` of `wall` (its mouth): its spec `so` {depth, door {width,
## height}, bulkhead, transom}. `wood` the frame's paint, `ceiling` the ceiling boards' wood.
static func recess(b: FalseFrontBuilding, wall: Dictionary, o: Rect2, so: Dictionary, wood: StringName) -> void:
	var g := geometry(wall, o, so)
	var id := "%s/recess" % wall.name
	var y0 := o.position.y
	var h := o.size.y
	var bk := float(so.get("bulkhead", 0.5))
	var tr := float(so.get("transom", 0.0))
	var dr: Dictionary = so.get("door", {})
	var dh := float(dr.get("height", 2.13))
	var band0 := int(b.get(&"band"))
	# The two angled sides: a post at each end, a head over them, a bulkhead between them on the
	# floor, plate glass over it.
	for side in 2:
		var f: Dictionary = g.sides[side]
		var L := float(f.length)
		var sid := "%s/side%d" % [id, side]
		member(b, f, sid + "/post0", &"stud", &"framing", 0.0, POST, y0, y0 + h - HEAD, -POST, 0.0)
		member(b, f, sid + "/post1", &"stud", &"framing", L - POST, L, y0, y0 + h - HEAD, -POST, 0.0)
		member(b, f, sid + "/head", &"header", &"framing", 0.0, L, y0 + h - HEAD, y0 + h, -POST, 0.0)
		member(b, f, sid + "/bulkhead", &"board", wood, POST, L - POST, y0, y0 + bk, -0.07, -0.02)
		_panels(b, f, sid + "/bulkhead_face", POST, L - POST, y0 + 0.08, y0 + bk, 1, -0.02, wood)
		lights(b, f, sid + "/glass", Rect2(POST, y0 + bk, L - POST * 2.0, h - HEAD - bk), maxi(roundi((L - POST * 2.0) / 1.8), 1),
				tr, maxi(roundi((L - POST * 2.0) / 0.85), 1), wood)
	# The door's wall at the recess's back: jambs, a head, the door's header, a transom light over it.
	var dw: Dictionary = g.door_wall
	var L := float(dw.length)
	member(b, dw, id + "/entry/jamb0", &"stud", &"framing", 0.0, POST, y0, y0 + h - HEAD, -POST, 0.0)
	member(b, dw, id + "/entry/jamb1", &"stud", &"framing", L - POST, L, y0, y0 + h - HEAD, -POST, 0.0)
	member(b, dw, id + "/entry/head", &"header", &"framing", 0.0, L, y0 + h - HEAD, y0 + h, -POST, 0.0)
	member(b, dw, id + "/entry/lintel", &"header", &"framing", POST, L - POST, y0 + dh, y0 + dh + HEAD, -POST, 0.0)
	lights(b, dw, id + "/entry/transom", Rect2(POST, y0 + dh + HEAD, L - POST * 2.0, h - HEAD * 2.0 - dh), 1, 0.0, 1, wood)
	# The leaf, shut: a panel under its glass, stiles, its rails a band up on them (all kind `door`), its
	# glass a band over the rails.
	var lx0 := POST + 0.005
	var lx1 := L - POST - 0.005
	var ly0 := y0 + 0.01
	var ly1 := y0 + dh - 0.005
	var panel := 0.9
	var st := 0.11
	var ld0 := -0.07
	var ld1 := -0.025
	var leaf := member(b, dw, id + "/entry_leaf/panel", &"door", wood, lx0, lx1, ly0, ly0 + panel, ld0, ld1)
	leaf.set_meta(&"use_role", 3.0)
	leaf.set_meta(&"latch", -(dw.out as Vector3))
	member(b, dw, id + "/entry_leaf/stile0", &"door", wood, lx0, lx0 + st, ly0 + panel, ly1, ld0, ld1)
	member(b, dw, id + "/entry_leaf/stile1", &"door", wood, lx1 - st, lx1, ly0 + panel, ly1, ld0, ld1)
	b.set(&"band", band0 + 1)
	member(b, dw, id + "/entry_leaf/rail_hi", &"door", wood, lx0 + st, lx1 - st, ly1 - st, ly1, ld0, ld1)
	member(b, dw, id + "/entry_leaf/rail_lo", &"door", wood, lx0 + st, lx1 - st, ly0 + panel, ly0 + panel + 0.05, ld0, ld1)
	b.set(&"band", band0 + 2)
	var pane := member(b, dw, id + "/entry_leaf/pane", &"glass", &"glass", lx0 + st, lx1 - st, ly0 + panel + 0.05, ly1 - st, -0.05, -0.046)
	SashWindow.dress_pane(pane)
	b.set(&"band", band0)
	# The ceiling: boards across the recess at its head, from the front wall's studs to the door's wall.
	var D := float(so.get("depth", 1.2))
	var bw := 0.1
	var z := FalseFrontBuilding.STUD_D
	var k := 0
	var cf := of_wall(wall)
	var ceil_wood := StringName(so.get("ceiling_wood", wood))
	while z < D - 0.005:
		var z1 := minf(z + bw, D)
		var zm := (z + z1) * 0.5
		var s0 := lerpf(o.position.x, float(g.jamb0), zm / D) - POST
		var s1 := lerpf(o.end.x, float(g.jamb1), zm / D) + POST
		member(b, cf, "%s/ceiling/%02d" % [id, k], &"board", ceil_wood, s0, s1, y0 + h, y0 + h + 0.022, -z1 + 0.002, -z)
		z = z1
		k += 1
	# The threshold across the mouth: a block from the sill's top to the floor's (the shop's floor
	# boards start inside the wall).
	var sill_top := float(so.get("sill_top", y0 - 0.275))
	var tb := int(b.get(&"band"))
	b.set(&"band", 0)
	member(b, cf, id + "/threshold", &"joist", &"framing", o.position.x, o.end.x, sill_top, y0, -FalseFrontBuilding.STUD_D - 0.02, 0.02)
	b.set(&"band", tb)


## Where the recess's pieces stand: its two sides' frames (from the mouth's corners on the wall's
## outer face to the door's jambs), the door's wall's frame, and the jambs' places along the wall.
static func geometry(wall: Dictionary, o: Rect2, so: Dictionary) -> Dictionary:
	var D := float(so.get("depth", 1.2))
	var dr: Dictionary = so.get("door", {})
	var dwid := float(dr.get("width", 1.07))
	var sc := o.get_center().x
	var jamb0 := sc - dwid * 0.5 - POST
	var jamb1 := sc + dwid * 0.5 + POST
	var origin: Vector3 = wall.origin
	var along: Vector3 = wall.along
	var out: Vector3 = wall.out
	var at := func(s: float, depth: float) -> Vector3: return origin + along * s - out * depth
	var sides := []
	for side in 2:
		var a: Vector3 = at.call(o.position.x if side == 0 else o.end.x, 0.0)
		var e: Vector3 = at.call(jamb0 if side == 0 else jamb1, D)
		var dir := (e - a).normalized()
		var n := Vector3(dir.z, 0.0, -dir.x)
		var mid: Vector3 = at.call(sc, D * 0.5)
		if n.dot(mid - a) < 0.0:
			n = -n
		sides.append(frame(a, dir, n, a.distance_to(e)))
	return {"sides": sides, "door_wall": frame(at.call(jamb0, D), along, out, jamb1 - jamb0), "jamb0": jamb0, "jamb1": jamb1,
			"door": Rect2(jamb0 + POST, o.position.y, dwid, float(dr.get("height", 2.13))), "depth": D}


## What lets daylight in, for RoomLight (spec_building's light_openings): each side's glass and the
## door with its transom, each in its own frame.
static func light_openings(wall: Dictionary, o: Rect2, so: Dictionary) -> Array:
	var g := geometry(wall, o, so)
	var out := []
	var bk := float(so.get("bulkhead", 0.5))
	for f: Dictionary in g.sides:
		out.append({"rect": Rect2(POST, o.position.y + bk, float(f.length) - POST * 2.0, o.size.y - HEAD - bk), "kind": "window",
				"frame": {"origin": f.origin, "along": f.along, "inward": -(f.out as Vector3)}})
	var dw: Dictionary = g.door_wall
	out.append({"rect": Rect2(POST, o.position.y, float(dw.length) - POST * 2.0, o.size.y - HEAD), "kind": "door",
			"frame": {"origin": dw.origin, "along": dw.along, "inward": -(dw.out as Vector3)}})
	return out

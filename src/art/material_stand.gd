class_name MaterialStand
extends Node3D
## The material lab's test stand (roadmap 1.4a, Sean 2026-10-21; docs/briefs/building-pipeline.md
## "Material lab"): a wall, a post and beam, a deck and steps, every piece a board of its real size
## with its cut ends drawn in end grain, for judging one material at a time beside the men.
##
## Built here, not from the game's structure classes: the stand shows a material as production
## should draw it (end grain on every cut end, each board its own strip and its own place along it,
## no two neighbours alike), which today's MemberMesh doesn't yet (what production needs is listed
## in the brief). Drawn only, unless `solid` (a box on Layers.WORLD for each board, so a body can
## land on it: the ragdoll lab's stairs); no members, no load paths.
##
## The stand's space: the wall along +X in the plane z = 0, its face toward -Z; the deck in front of
## it (z from 0 to -DECK_DEPTH), the steps at the deck's front, the post and beam at its front edge,
## the ground at y = 0. Each board's mesh carries the flags texel_grid reads (COLOR r 1 g 0: a cut
## end; r 0 g 0 b: a long face starting b x 2 m along its strip) and its face size in UV2.

## Each part's wood (PixelArt's keys). `material` puts the one under test on its part; the rest
## stay the game's.
const ROLES := {
	&"siding": &"saloon_red",
	&"siding_low": &"saloon_red_low",
	&"studs": &"framing",
	&"trim": &"dark_trim",
	&"deck": &"floor",
	&"joists": &"framing",
	&"rim": &"fascia",
	&"frame": &"timber",
	&"treads": &"floor",
	&"stringers": &"weathered_pine",
}
## Which parts a material is judged on (the parts it goes on in the town).
const PART_OF := {
	&"saloon_red": [&"siding", &"siding_low"],
	&"store_boards": [&"siding", &"siding_low"],
	&"weathered_pine": [&"siding", &"siding_low", &"stringers"],
	&"floor": [&"deck", &"treads"],
	&"timber": [&"frame"],
	&"fascia": [&"rim"],
	&"framing": [&"studs", &"joists"],
	&"dark_trim": [&"trim"],
}

## Sizes in metres (USDA Wood Handbook's dressed sizes; period practice as the timber pass used,
## docs/briefs/material-lab-timber.md): lap siding 150 x 20 at the butt, 125 to the weather; deck
## planks 150 x 45 with 8 mm gaps, 30 mm past the rim; joists and rim 45 x 190; posts 150 square;
## the beam 150 x 200; studs 45 x 95 at 400; treads two 140 x 45 boards with a 35 mm nosing.
const WALL_W := 3.2
const WALL_H := 2.6
const SIDING_W := 0.15
const SIDING_T := 0.02
const SIDING_EXPOSE := 0.125
const LOW_H := 1.0
const STUD := Vector2(0.045, 0.095)
const STUD_GAP := 0.4
const DECK_DEPTH := 1.8
const DECK_TOP := 0.42
const PLANK := Vector2(0.15, 0.045)
const PLANK_GAP := 0.008
const OVERHANG := 0.03
const JOIST := Vector2(0.045, 0.19)
const POST := 0.15
const BEAM := Vector2(0.15, 0.2)
const FRAME_TOP := 2.75
const POST_X := [0.25, 2.95]
const STEP_X := Vector2(1.0, 2.2)
const TREAD := Vector2(0.14, 0.045)
const NOSING := 0.035
const RISE := 0.14

## Where each part weathers (round 3's weathering layer, texel_grid's `weathered`; Sean
## 2026-10-21): [ground y (mud and grime rise from it), drip line y (rain streaks hang from it),
## amount], in the stand's space, which is the structure's. The wall's ground is the deck it stands
## on and its drip line its top; the post's the deck and the beam's underside; the frame under the
## deck (rim, joists, stringers, risers) splashes from the real ground and streaks from the planks'
## street edge; studs behind the siding are sheltered.
const WEATHER := {
	&"siding": [DECK_TOP, WALL_H, 1.0], &"siding_low": [DECK_TOP, WALL_H, 1.0], &"trim": [DECK_TOP, WALL_H, 1.0],
	&"studs": [DECK_TOP, WALL_H, 0.3], &"deck": [0.0, DECK_TOP, 1.0], &"treads": [0.0, DECK_TOP, 1.0],
	&"joists": [0.0, DECK_TOP - PLANK.y, 0.8], &"rim": [0.0, DECK_TOP - PLANK.y, 1.0],
	&"stringers": [0.0, DECK_TOP - RISE, 1.0], &"frame": [DECK_TOP, FRAME_TOP - BEAM.y, 1.0],
}
## The siding's nails (one through each lap at each stud, 20 mm above the butt): [pitch along the
## wall, the first, the rows' pitch, the first row's height]; rust streaks hang under some.
const NAILS := [STUD_GAP, STUD.x * 0.5, SIDING_EXPOSE, DECK_TOP]

## The wood under test (one of PART_OF's keys), &"" for the game's stand as it is.
var material: StringName = &""
## Each part's wood (ROLES, and a subclass's own parts).
var roles := ROLES.duplicate()
var seed_value := 1
## Lay the weathering layer's frame on every board (CUSTOM0/1; drawn only where the set has a
## stain sheet). Off: the boards carry none, as production's members don't yet.
var weathered := true
## Collision: a box for each board of the parts `solid_parts` names (all when empty), on one
## StaticBody3D on Layers.WORLD. Off: drawn only (the lab).
var solid := false
var solid_parts: Array = []
var _shapes: Array = []
## What was built: wood -> [{"name", "size", "part"}] (the lab's numbers: thickness, counts).
var boards := {}
## The members' meshes by part (the lab hides and masks them by part).
var part_nodes := {}

var _rng := RandomNumberGenerator.new()
## Per part, the strips its boards took, in order (no neighbour repeats).
var _last := {}
## wood -> {strip -> SurfaceTool}: boards sharing a strip share a mesh (one draw each).
var _tools := {}
## The board being laid's weathering frame and nails (CUSTOM0, CUSTOM1).
var _frame_of := Color(0, 0, 0, 0)
var _nails_of := Color(0, 0, 0, 0)


func wood_for(part: StringName) -> StringName:
	if material != &"" and PART_OF.get(material, []).has(part):
		if part == &"siding_low":
			return StringName(String(material) + "_low") if WoodMaterials.strip_count(StringName(String(material) + "_low")) > 0 else material
		return material
	return roles[part]


## The parts the material under test is on (all of them for the plain stand).
func focus_parts() -> Array:
	return PART_OF.get(material, ROLES.keys())


func build() -> void:
	_rng.seed = seed_value
	_wall()
	_deck()
	_steps()
	_frame()
	_flush()
	_flush_solid()


func _wall() -> void:
	# Studs and plates behind the siding (seen past its open end).
	var xs := []
	var x := STUD.x * 0.5
	while x < WALL_W - STUD.x:
		xs.append(x)
		x += STUD_GAP
	xs.append(WALL_W - STUD.x * 0.5)
	for sx in xs:
		_board(&"studs", Vector3(sx, WALL_H * 0.5, SIDING_T + STUD.y * 0.5), Vector3(0, 1, 0), Vector3(1, 0, 0), WALL_H, STUD.x, STUD.y)
	for y in [STUD.x * 0.5, WALL_H - STUD.x * 0.5]:
		_board(&"studs", Vector3(WALL_W * 0.5, y, SIDING_T + STUD.y * 0.5), Vector3(1, 0, 0), Vector3(0, 0, 1), WALL_W, STUD.y, STUD.x)
	# Lap siding from the deck up, each board tilted out at its foot by the one below; the left end
	# left open (its cut ends), the right under a corner board.
	var tilt := atan2(SIDING_T * 0.5, SIDING_W)
	var y := DECK_TOP - 0.02
	while y + SIDING_W <= WALL_H + 0.01:
		var part := &"siding_low" if y < LOW_H else &"siding"
		var across := Vector3(0, cos(tilt), sin(tilt))
		var thick := Vector3(0, -sin(tilt), cos(tilt))
		var c := Vector3(WALL_W * 0.5, y + SIDING_W * 0.5, -SIDING_T * 0.5)
		_board(part, c, Vector3(1, 0, 0), thick, WALL_W, SIDING_W, SIDING_T, across)
		y += SIDING_EXPOSE
	_board(&"trim", Vector3(WALL_W + 0.05, (WALL_H + DECK_TOP) * 0.5, -SIDING_T - 0.011), Vector3(0, 1, 0), Vector3(0, 0, 1), WALL_H - DECK_TOP, 0.12, 0.022)


func _deck() -> void:
	# Joists along the wall on pads, the rim joist under the planks' street ends.
	var jy := DECK_TOP - PLANK.y - JOIST.y * 0.5
	for z in [-0.15, -0.95, -DECK_DEPTH + JOIST.x * 0.5]:
		_board(&"rim" if z < -1.0 else &"joists", Vector3(WALL_W * 0.5, jy, z), Vector3(1, 0, 0), Vector3(0, 0, 1), WALL_W, JOIST.y, JOIST.x)
		for px in [0.3, WALL_W * 0.5, WALL_W - 0.3]:
			_board(&"joists", Vector3(px, (jy - JOIST.y * 0.5) * 0.5, z + (0.07 if z < -1.0 else 0.0)), Vector3(0, 1, 0), Vector3(1, 0, 0),
					jy - JOIST.y * 0.5, 0.14, 0.14)
	# Planks across the walk, wall to street, their street ends 30 mm past the rim (each a few mm
	# off, as a hand cuts them).
	var x := PLANK.x * 0.5
	while x < WALL_W:
		var len := DECK_DEPTH + OVERHANG + _rng.randf_range(-0.008, 0.008)
		_board(&"deck", Vector3(x, DECK_TOP - PLANK.y * 0.5, -len * 0.5), Vector3(0, 0, -1), Vector3(0, 1, 0), len, PLANK.x, PLANK.y,
				Vector3(1, 0, 0))
		x += PLANK.x + PLANK_GAP


func _steps() -> void:
	# Two steps down from the deck's front: treads of two boards with a nosing, a riser set back
	# under each tread's front, a gap at the ground, three stringers.
	var front := -DECK_DEPTH
	var depth := TREAD.x * 2 + 0.005
	var w := STEP_X.y - STEP_X.x
	var mid := (STEP_X.x + STEP_X.y) * 0.5
	for s in 2:
		var top := DECK_TOP - RISE * (s + 1)
		var back := front - (depth - NOSING) * s
		for b in 2:
			var z := back - TREAD.x * (b + 0.5) - 0.005 * b
			_board(&"treads", Vector3(mid, top - TREAD.y * 0.5, z), Vector3(1, 0, 0), Vector3(0, 1, 0), w, TREAD.x, TREAD.y, Vector3(0, 0, 1))
		var riser_top := top - TREAD.y
		var riser_foot := maxf(top - RISE, 0.03)
		_board(&"stringers", Vector3(mid, (riser_top + riser_foot) * 0.5, back - depth + NOSING + 0.011), Vector3(1, 0, 0), Vector3(0, 0, 1),
				w - 0.05, riser_top - riser_foot, 0.022)
	var foot := front - (depth - NOSING) * 2 - NOSING
	for sx in [STEP_X.x + 0.03, mid, STEP_X.y - 0.03]:
		# A stringer on the slope from the ground at the foot to the rim, under the treads.
		var a := Vector3(sx, 0.0, foot + 0.05)
		var b := Vector3(sx, DECK_TOP - PLANK.y - 0.02, front + 0.02)
		var along := (b - a).normalized()
		var up := along.cross(Vector3(1, 0, 0)).normalized()
		_board(&"stringers", (a + b) * 0.5 - up * 0.1, along, Vector3(1, 0, 0), a.distance_to(b), 0.18, 0.04, up)


func _frame() -> void:
	var z := -DECK_DEPTH + 0.15
	for px in POST_X:
		var h := FRAME_TOP - BEAM.y - DECK_TOP
		_board(&"frame", Vector3(px, DECK_TOP + h * 0.5, z), Vector3(0, 1, 0), Vector3(0, 0, 1), h, POST, POST)
	# The beam over the posts, past them at each end (its ends cut square, end grain out).
	_board(&"frame", Vector3(WALL_W * 0.5, FRAME_TOP - BEAM.y * 0.5, z), Vector3(1, 0, 0), Vector3(0, 0, 1), WALL_W + 0.5, BEAM.y, BEAM.x)


## A board: centre, length axis, thickness axis (`across`, if given, is the width axis; else
## length x thickness), its length, width and thickness. Picks a strip that its last neighbour
## in the part didn't take, and its own place along the strip.
func _board(part: StringName, centre: Vector3, along: Vector3, thick: Vector3, length: float, width: float, thickness: float,
		across := Vector3.ZERO) -> void:
	var wood := wood_for(part)
	along = along.normalized()
	thick = thick.normalized()
	if across == Vector3.ZERO:
		across = thick.cross(along).normalized()
	var strips := maxi(WoodMaterials.strip_count(wood), 1)
	var prev: Array = _last.get(part, [])
	var pick := _rng.randi_range(0, strips - 1)
	if strips > 2:
		# Neither of the last two boards in this part (the one beside and the one beyond it on
		# siding, whose boards' laps alternate).
		while prev.slice(-2).has(pick):
			pick = _rng.randi_range(0, strips - 1)
	elif strips == 2 and not prev.is_empty():
		pick = 1 - int(prev[-1])
	prev.append(pick)
	_last[part] = prev
	var u0 := _rng.randf_range(0.0, 1.99)
	if not boards.has(wood):
		boards[wood] = []
	boards[wood].append({"part": part, "size": Vector3(length, width, thickness), "strip": pick})
	if not _tools.has(part):
		_tools[part] = {}
	var tools: Dictionary = _tools[part]
	if not tools.has(pick):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if weathered:
			st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
			st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)
		tools[pick] = st
	_frame_of = Color(0, 0, 0, 0)
	_nails_of = Color(0, 0, 0, 0)
	if weathered:
		var w: Array = WEATHER.get(part, [0.0, 0.0, 0.0])
		_frame_of = Color(w[0], w[1], w[2], 0.0)
		if part == &"siding" or part == &"siding_low":
			_nails_of = Color(NAILS[0], NAILS[1], NAILS[2], NAILS[3])
	_box(tools[pick], centre, along * length, across * width, thick * thickness, u0)
	_solid_box(part, centre, along, across, thick, Vector3(length, width, thickness))


## A collision box for a board (when `solid` and its part is one of `solid_parts`): axes along,
## across and thick, sized length, width and thickness.
func _solid_box(part: StringName, centre: Vector3, along: Vector3, across: Vector3, thick: Vector3, size: Vector3) -> void:
	if not solid or (not solid_parts.is_empty() and not solid_parts.has(part)):
		return
	var b := Basis(along.normalized(), across.normalized(), thick.normalized())
	if b.determinant() < 0.0:
		b.z = -b.z
	_shapes.append([Transform3D(b.orthonormalized(), centre), size])


## The collected boxes as one body (call after the meshes are built).
func _flush_solid() -> void:
	if _shapes.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "Collision"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	add_child(body)
	for sh in _shapes:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = sh[1]
		cs.shape = box
		cs.transform = sh[0]
		body.add_child(cs)
	_shapes.clear()


## The six faces of a board: four long faces (u along the grain from u0, v across), two ends.
func _box(st: SurfaceTool, c: Vector3, l: Vector3, w: Vector3, t: Vector3, u0: float) -> void:
	var ll := l.length()
	var wl := w.length()
	var tl := t.length()
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	var endf := Color(1.0, 0.0, 0.0, 1.0)
	# Long faces: +t (the face), -t (the back), +w and -w (the edges).
	_quad(st, c + t * 0.5, l, w, t.normalized(), Vector2(ll, wl), u0, flag)
	_quad(st, c - t * 0.5, l, -w, -t.normalized(), Vector2(ll, wl), u0, flag)
	_quad(st, c + w * 0.5, l, -t, w.normalized(), Vector2(ll, tl), u0, flag)
	_quad(st, c - w * 0.5, l, t, -w.normalized(), Vector2(ll, tl), u0, flag)
	# Cut ends.
	_quad(st, c + l * 0.5, w, -t, l.normalized(), Vector2(wl, tl), 0.0, endf)
	_quad(st, c - l * 0.5, w, t, -l.normalized(), Vector2(wl, tl), 0.0, endf)


## One face centred at `c`, spanning `a` (u) and `b` (v), facing `n`. UV in metres (u from u0),
## UV2 the face's size.
func _quad(st: SurfaceTool, c: Vector3, a: Vector3, b: Vector3, n: Vector3, size: Vector2, u0: float, col: Color) -> void:
	var corners := [c - a * 0.5 - b * 0.5, c + a * 0.5 - b * 0.5, c + a * 0.5 + b * 0.5, c - a * 0.5 + b * 0.5]
	var uvs := [Vector2(u0, 0), Vector2(u0 + size.x, 0), Vector2(u0 + size.x, size.y), Vector2(u0, size.y)]
	# Wind each triangle so it faces n.
	var order := [0, 1, 2, 0, 2, 3]
	if (corners[1] - corners[0]).cross(corners[2] - corners[0]).dot(n) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for i in order:
		st.set_color(col)
		if weathered:
			st.set_custom(0, _frame_of)
			st.set_custom(1, _nails_of)
		st.set_normal(n)
		st.set_uv(uvs[i])
		st.set_uv2(size)
		st.add_vertex(corners[i])


## A part's node (made the first time).
func _holder(part: StringName) -> Node3D:
	if not part_nodes.has(part):
		var holder := Node3D.new()
		holder.name = String(part)
		add_child(holder)
		part_nodes[part] = holder
	return part_nodes[part]


## One mesh per part and strip, drawn in that strip's material.
func _flush() -> void:
	for part in _tools:
		var holder := _holder(part)
		var wood := wood_for(part)
		for pick in _tools[part]:
			var mi := MeshInstance3D.new()
			mi.name = "%s_%d" % [wood, pick]
			mi.mesh = (_tools[part][pick] as SurfaceTool).commit()
			mi.material_override = WoodMaterials.get_material(wood, pick)
			holder.add_child(mi)
	_tools.clear()


## What the stand draws: meshes, triangles, materials, textures and their memory (with mipmaps).
func numbers() -> Dictionary:
	var meshes := 0
	var tris := 0
	var mats := {}
	var texs := {}
	for mi in find_children("*", "MeshInstance3D", true, false):
		meshes += 1
		tris += (mi as MeshInstance3D).mesh.get_faces().size() / 3
		var m := (mi as MeshInstance3D).material_override as ShaderMaterial
		mats[m] = true
		if m:
			for p in [&"albedo_tex", &"end_tex", &"wear_tex"]:
				var t = m.get_shader_parameter(p)
				if t is Texture2D:
					texs[(t as Texture2D).resource_path] = t
	var mem := 0
	for path in texs:
		var t: Texture2D = texs[path]
		# RGBA8 in memory (the import's lossless/VRAM choice aside), a third more with mipmaps.
		mem += int(t.get_width() * t.get_height() * 4 * 4.0 / 3.0)
	return {"meshes": meshes, "triangles": tris, "materials": mats.size(), "textures": texs.size(), "texture_bytes": mem}

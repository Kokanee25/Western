class_name TrackLine
extends Node3D
## A railroad track laid along a curve (docs/briefs/train.md, step 1). The line is given as plan
## and profile, as a surveyor lays it out:
##   - plan: `segments`, each {length, k0, k1}: the curvature (1/radius, + to the left) going
##     linearly from k0 to k1 over its length: a straight is 0 to 0, an arc k to k, an easement
##     spiral 0 to k (so a car's swing comes on gradually, not with a jerk);
##   - profile: `grades`, [[s, grade], ...] the grade from each distance on (+ rises toward the
##     line's end), each change eased over `vertical_curve` metres.
## From those it makes a `Curve3D` (the top of the rail, the line's centre) every metre, and from
## that the rails, ties, ballast and the fill under them, in chunks. Plain and unbreakable in step 1.
##
## The 1D train asks `grade_at(s)`, `curvature_at(s)`, `length`; the cars ask `transform_at(s)`.
## `s` is the distance along the curve as Godot bakes it, so where a car is drawn and where the
## simulation says it is are the same number.

## Plan and profile (see above). Set before `build()`.
var segments: Array = []
var grades: Array = [[0.0, 0.0]]
var vertical_curve := 60.0
var tuning: TrainTuning
## The ground under the line in this node's space (x, z) -> y; the fill reaches down to it.
var ground_y: Callable = func(_x: float, _z: float) -> float: return 0.0
## Where the rail top starts above the ground at s = 0, m.
var start_height := 1.0
## Named distances along the line (stop marks): name -> s. Drawn as white boards.
var marks: Dictionary = {}
## The route's sections along the curve (TrainRoute.sections): [{id, from_s, to_s}]. Damage and
## the wreck are kept by section id and distance along it (`key_of`, `s_of`), so a re-laid route
## keeps them where its same section is. A line with none is one section, "line".
var sections: Array = []
## The track as members (step 5, #616): ties and rails a TrackChunk each CHUNK-ish metres (a whole
## number of rails), breakable as any building's members, at rest till something touches them.
## Off: step 1's drawn ties and rails (a MultiMesh and swept rails), unbreakable.
var track_members := members_default
## `-- --track-drawn`: every line drawn as step 1's (the before, for the idle cost).
static var members_default := not "--track-drawn" in OS.get_cmdline_user_args()
var chunks: Array[TrackChunk] = []
## Bridges on the line (TrainRoute.crossings: {id, kind, from_s, to_s}; the trestle lab, #623): each
## built as a Trestle (a TrackChunk of its own, the bents under its ties) with no ballast or fill
## under it. Only with `track_members`.
var crossings: Array = []
## The Trestles built for them.
var trestles: Array[Trestle] = []
## Their dials (config/trestle.tres unless set).
var trestle_tuning: TrestleTuning
## What's wrong with the line (TrackState): broken, bent and blocked stretches.
var state: TrackState
## The railroad's repair crew for this line (TrackRepair): sent for when it's damaged.
var repair: TrackRepair
## Chunks of the drawn track, m.
const CHUNK := 100.0
const STEP := 1.0  # the alignment's sampling, m

var curve := Curve3D.new()
var length := 0.0
## The line's lowest rail top (its own space): anything well under it isn't on the line (asked
## before the curve's nearest point, which is ~1-2 ms on a long line).
var lowest := 0.0
var _grade := PackedFloat32Array()  # by metre
var _curv := PackedFloat32Array()
var _scale := 1.0  # baked length / the alignment's own length


## Lay out the curve (no drawing; works out of the tree, for the headless runs).
func lay_out() -> void:
	var pts := PackedVector3Array()
	var tans := PackedVector3Array()
	var total := 0.0
	for seg: Dictionary in segments:
		total += float(seg.length)
	var heading := 0.0  # radians, 0 = -Z (north), + to the left (toward -X)
	var pos := Vector3(0.0, start_height, 0.0)
	_grade.resize(int(total / STEP) + 2)
	_curv.resize(_grade.size())
	var at := 0.0
	var i := 0
	var seg_i := 0
	var seg_from := 0.0
	while true:
		# Curvature and grade here.
		while seg_i < segments.size() - 1 and at > seg_from + float(segments[seg_i].length):
			seg_from += float(segments[seg_i].length)
			seg_i += 1
		var seg: Dictionary = segments[seg_i]
		var f := clampf((at - seg_from) / maxf(float(seg.length), 0.001), 0.0, 1.0)
		var k := lerpf(float(seg.k0), float(seg.k1), f)
		var g := grade_profile(at)
		_grade[i] = g
		_curv[i] = k
		var dir := Vector3(-sin(heading), 0.0, -cos(heading))
		pts.append(pos)
		tans.append((dir + Vector3.UP * g).normalized())
		if at >= total:
			break
		var ds := minf(STEP, total - at)
		# Midpoint step: heading and grade at the half step.
		var k_mid := lerpf(float(seg.k0), float(seg.k1), clampf((at + ds * 0.5 - seg_from) / maxf(float(seg.length), 0.001), 0.0, 1.0))
		var h_mid := heading + k_mid * ds * 0.5
		var g_mid := grade_profile(at + ds * 0.5)
		pos += Vector3(-sin(h_mid), 0.0, -cos(h_mid)) * ds + Vector3.UP * g_mid * ds
		heading += k_mid * ds
		at += ds
		i += 1
	_grade.resize(i + 1)
	_curv.resize(i + 1)
	curve = Curve3D.new()
	curve.bake_interval = 0.25
	var every := 5  # a control point every 5 m, its handles along the tangent (a smooth cubic)
	for j in range(0, pts.size(), every):
		_add_point(pts, tans, j, every)
	if (pts.size() - 1) % every != 0:
		_add_point(pts, tans, pts.size() - 1, (pts.size() - 1) % every)
	length = curve.get_baked_length()
	_scale = length / maxf(total, 0.001)
	lowest = INF
	for p in pts:
		lowest = minf(lowest, p.y)


func _add_point(pts: PackedVector3Array, tans: PackedVector3Array, j: int, gap: int) -> void:
	var h := tans[j] * (float(gap) * STEP / 3.0)
	curve.add_point(pts[j], -h, h)


## The grade at a distance along the alignment (eased through each change).
func grade_profile(at: float) -> float:
	var g := float(grades[0][1])
	for n in range(1, grades.size()):
		var change_at := float(grades[n][0])
		var to := float(grades[n][1])
		var f := clampf((at - (change_at - vertical_curve * 0.5)) / maxf(vertical_curve, 0.001), 0.0, 1.0)
		g = lerpf(g, to, f) if f > 0.0 else g
		if f < 1.0:
			break
	return g


## A distance along the line as laid (the plan's metres, as a route file gives them) as a distance
## along the drawn curve (what `s` is everywhere else).
func along(laid: float) -> float:
	return laid * _scale


## Where `s` is on the route: {section: id, at: m along that section}.
func key_of(s: float) -> Dictionary:
	if sections.is_empty():
		return {"section": "line", "at": s}
	for sec: Dictionary in sections:
		if s < float(sec.to_s) or sec == sections.back():
			return {"section": String(sec.id), "at": s - float(sec.from_s)}
	return {"section": "line", "at": s}


## The distance along the curve of a place on the route (`key_of`'s), or NAN if this route has no
## such section. Past the section's end it's clamped to it.
func s_of(key: Dictionary) -> float:
	var id := String(key.get("section", "line"))
	var at := float(key.get("at", 0.0))
	if sections.is_empty():
		return at if id == "line" else NAN
	for sec: Dictionary in sections:
		if String(sec.id) == id:
			return clampf(float(sec.from_s) + at, float(sec.from_s), float(sec.to_s))
	return NAN


## A named mark's distance along the curve (`marks`), or NAN if there's no such mark.
func mark_s(mark_name: String) -> float:
	return float(marks[mark_name]) if marks.has(mark_name) else NAN


func _index(s: float) -> float:
	return clampf(s / _scale / STEP, 0.0, float(_grade.size() - 1))


## The grade (rise over run, + uphill toward the line's end) at distance s.
func grade_at(s: float) -> float:
	var x := _index(s)
	var i := int(x)
	return lerpf(_grade[i], _grade[mini(i + 1, _grade.size() - 1)], x - i)


## The curvature (1/radius, + to the left going toward the line's end) at s.
func curvature_at(s: float) -> float:
	var x := _index(s)
	var i := int(x)
	return lerpf(_curv[i], _curv[mini(i + 1, _curv.size() - 1)], x - i)


## Where the rail top's middle is at s, in this node's space.
func point_at(s: float) -> Vector3:
	return curve.sample_baked(clampf(s, 0.0, length), true)


## A frame at s: origin on the rail top's middle, -Z along the line toward its end, +Y up.
func transform_at(s: float) -> Transform3D:
	# (Its direction from a metre of the curve inside the line: past either end both points were the
	# end's, and no direction: the lookout's scan ahead of a train at the valley line's end, G3.)
	var c := clampf(s, 0.5, maxf(length - 0.5, 0.5))
	var a := point_at(c - 0.5)
	var b := point_at(c + 0.5)
	var fwd := (b - a).normalized()
	return Transform3D(Basis.looking_at(fwd, Vector3.UP), point_at(s))


# --- Drawing --------------------------------------------------------------------------------

var _mats := {}


func _mat(kind: String, colour: Color, rough := 0.95, metal := 0.0) -> StandardMaterial3D:
	if not _mats.has(kind):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = rough
		m.metallic = metal
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[kind] = m
	return _mats[kind]


## Lay the line out and draw it: ballast, fill, the marks, and the ties and rails (as members,
## TrackChunk, or drawn: `track_members`). Fill and ballast collide.
func build() -> void:
	if curve.point_count == 0:
		lay_out()
	for c in get_children():
		c.free()
	var t := tuning if tuning else TrainTuning.new()
	var n_drawn := int(ceil(length / CHUNK))
	for n in n_drawn:
		_build_chunk(n * CHUNK, minf((n + 1) * CHUNK, length), t, n)
	for mark_name in marks:
		_build_mark(String(mark_name), float(marks[mark_name]))
	chunks.clear()
	trestles.clear()
	if track_members:
		# A whole number of rails a chunk (the joints at its ends), about CHUNK long; a crossing is a
		# chunk of its own (a Trestle), the chunk before it ending where it starts.
		var per := maxf(1.0, roundf(CHUNK / t.rail_length)) * t.rail_length
		var cross := _crossings_sorted()
		var ci := 0
		var n := 0
		var a := 0.0
		while a < length - 0.01:
			if ci < cross.size() and a >= float(cross[ci].from_s) - 0.01:
				var tr := Trestle.new()
				if trestle_tuning == null:
					trestle_tuning = load("res://config/trestle.tres")
				tr.setup_crossing(self, t, trestle_tuning, n, a, minf(float(cross[ci].to_s), length), str(cross[ci].id))
				add_child(tr)
				chunks.append(tr)
				trestles.append(tr)
				a = minf(float(cross[ci].to_s), length)
				ci += 1
				n += 1
				continue
			var b := minf(a + per, length)
			if ci < cross.size():
				b = minf(b, float(cross[ci].from_s))
			var c := TrackChunk.new()
			c.setup(self, t, n, a, b)
			add_child(c)
			chunks.append(c)
			a = b
			n += 1
	if state == null:
		state = TrackState.new(self)
	state.line_built()
	if track_members:
		repair = TrackRepair.new()
		repair.setup(self)
		add_child(repair)


func _crossings_sorted() -> Array:
	var out := crossings.duplicate()
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.from_s) < float(y.from_s))
	return out


## Is s on a crossing (a bridge: no ballast or fill under it)?
func on_crossing(s: float) -> bool:
	if not track_members:
		return false
	for c: Dictionary in crossings:
		if s > float(c.from_s) and s < float(c.to_s):
			return true
	return false


## The Trestle over s, or null.
func trestle_at(s: float) -> Trestle:
	for tr in trestles:
		if s >= tr.from_s and s <= tr.to_s:
			return tr
	return null


## The TrackChunk holding distance s, or null.
func chunk_at(s: float) -> TrackChunk:
	for c in chunks:
		if s >= c.from_s and s < c.to_s + 0.001:
			return c
	return null


func _build_chunk(a: float, b: float, t: TrainTuning, n: int) -> void:
	var chunk := Node3D.new()
	chunk.name = "Chunk%02d" % n
	add_child(chunk)
	var step := 2.0
	var rail_h := t.rail_size.y
	var tie_top := -rail_h
	var bal_top := tie_top - t.tie_size.y * 0.5  # ties half sunk in the ballast
	var bal_bot := bal_top - t.ballast_depth
	var half_top := t.ballast_top * 0.5
	var half_bot := half_top + t.ballast_depth * 1.5
	# Ballast and fill: profiles (x across, y) swept along the chunk.
	var bal := [Vector2(-half_bot, bal_bot), Vector2(-half_top, bal_top), Vector2(half_top, bal_top), Vector2(half_bot, bal_bot)]
	var rails := []
	for side in [-1.0, 1.0]:
		var x0: float = side * (t.gauge * 0.5 + t.rail_size.x * 0.5)
		var hw := t.rail_size.x * 0.5
		rails.append([Vector2(x0 - hw, tie_top), Vector2(x0 - hw, 0.0), Vector2(x0 + hw, 0.0), Vector2(x0 + hw, tie_top)])
	var st_fill := SurfaceTool.new()
	st_fill.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_bal := SurfaceTool.new()
	st_bal.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_rail := SurfaceTool.new()
	st_rail.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := a
	var frames: Array[Transform3D] = []
	while true:
		frames.append(transform_at(s))
		if s >= b:
			break
		s = minf(s + step, b)
	var swept := 0
	var filled := 0
	for j in frames.size() - 1:
		var f0 := frames[j]
		var f1 := frames[j + 1]
		if on_crossing(minf(a + (j + 0.5) * step, b)):
			continue  # a bridge: nothing under the ties but the bridge
		swept += 1
		_sweep(st_bal, bal, f0, f1)
		if not track_members:
			for r in rails:
				_sweep(st_rail, r, f0, f1)
		# The fill: from the ballast's foot down to the ground, sides at 1.5:1.
		var fill0 := _fill_profile(f0, half_bot, bal_bot)
		var fill1 := _fill_profile(f1, half_bot, bal_bot)
		# In a cut the ground's over the ballast's foot: no fill there (its quads would have no area,
		# and a shape of nothing but those is refused: the valley's cuttings, G3).
		for side in [[0, 1], [2, 3]]:
			var a0: Vector3 = fill0[side[0]]
			var b0: Vector3 = fill0[side[1]]
			var a1: Vector3 = fill1[side[0]]
			var b1: Vector3 = fill1[side[1]]
			if a0.distance_squared_to(b0) + a1.distance_squared_to(b1) > 1e-4:
				_quad(st_fill, a0, b0, b1, a1)
				filled += 1
	var body := StaticBody3D.new()
	body.name = "Bed"
	body.collision_layer = Layers.WORLD
	chunk.add_child(body)
	for pair in [[st_fill, _mat("fill", Color(0.42, 0.33, 0.23))], [st_bal, _mat("ballast", Color(0.36, 0.34, 0.31))]]:
		if swept == 0:
			break  # all of it on a bridge
		if pair[0] == st_fill and filled == 0:
			continue  # all of it in a cut
		var st: SurfaceTool = pair[0]
		st.generate_normals()
		var mesh := st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = pair[1]
		chunk.add_child(mi)
		var cs := CollisionShape3D.new()
		var tri := mesh.create_trimesh_shape()
		# Two-sided: a kit prop finds its footing with a thin box mostly below the surface it stands
		# on, which a one-sided bed doesn't count (a crate set on the ballast went loose at once).
		tri.backface_collision = true
		cs.shape = tri
		body.add_child(cs)
	if track_members:
		return  # the ties and rails are members (TrackChunk)
	st_rail.generate_normals()
	var rail_mi := MeshInstance3D.new()
	rail_mi.name = "Rails"
	rail_mi.mesh = st_rail.commit()
	rail_mi.material_override = _mat("rail", Color(0.30, 0.27, 0.25), 0.55, 0.6)
	chunk.add_child(rail_mi)
	# Ties: one MultiMesh a chunk.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(t.tie_size.x, t.tie_size.y, t.tie_size.z)
	mm.mesh = box
	var first := ceilf(a / t.tie_spacing) * t.tie_spacing
	var count := maxi(0, int(floor((b - first) / t.tie_spacing - 0.0001)) + 1)
	mm.instance_count = count
	for k in count:
		var f := transform_at(first + k * t.tie_spacing)
		f.origin += f.basis.y * (tie_top - t.tie_size.y * 0.5)
		mm.set_instance_transform(k, f)
	var ties := MultiMeshInstance3D.new()
	ties.name = "Ties"
	ties.multimesh = mm
	ties.material_override = _mat("tie", Color(0.42, 0.34, 0.26))
	chunk.add_child(ties)


func _fill_profile(f: Transform3D, half_bot: float, bal_bot: float) -> Array:
	var out := []
	for side in [-1.0, 1.0]:
		var top := f * Vector3(side * half_bot, bal_bot, 0.0)
		var drop := maxf(0.0, top.y - float(ground_y.call(top.x, top.z)) + 0.3)
		var foot := f * Vector3(side * (half_bot + drop * 1.5), bal_bot - drop, 0.0)
		out.append(top)
		out.append(foot)
	# [left top, left foot, right top, right foot] -> faces outward
	return [out[1], out[0], out[2], out[3]]


func _sweep(st: SurfaceTool, profile: Array, f0: Transform3D, f1: Transform3D) -> void:
	for k in profile.size() - 1:
		var p0: Vector2 = profile[k]
		var p1: Vector2 = profile[k + 1]
		_quad(st, f0 * Vector3(p0.x, p0.y, 0.0), f0 * Vector3(p1.x, p1.y, 0.0),
			f1 * Vector3(p1.x, p1.y, 0.0), f1 * Vector3(p0.x, p0.y, 0.0))


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# a-b along the profile at the near end, c-d at the far end; wound so the face looks outward.
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)
	st.add_vertex(a)
	st.add_vertex(d)
	st.add_vertex(c)


func _build_mark(mark_name: String, s: float) -> void:
	var f := transform_at(s)
	var post := MeshInstance3D.new()
	post.name = "Mark_" + mark_name
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 2.2, 0.12)
	post.mesh = box
	post.material_override = _mat("mark", Color(0.92, 0.9, 0.85))
	post.transform = f
	post.position += f.basis.x * 2.6 + f.basis.y * 0.8
	add_child(post)
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 0.5, 0.05)
	board.mesh = bm
	board.material_override = post.material_override
	board.transform = f
	board.position += f.basis.x * 2.6 + f.basis.y * 1.8
	add_child(board)

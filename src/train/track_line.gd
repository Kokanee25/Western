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
## Chunks of the drawn track, m.
const CHUNK := 100.0
const STEP := 1.0  # the alignment's sampling, m

var curve := Curve3D.new()
var length := 0.0
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
	var a := point_at(s - 0.5)
	var b := point_at(s + 0.5)
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


## Lay the line out and draw it: rails, ties, ballast, fill, the marks. Fill and ballast collide.
func build() -> void:
	if curve.point_count == 0:
		lay_out()
	for c in get_children():
		c.free()
	var t := tuning if tuning else TrainTuning.new()
	var chunks := int(ceil(length / CHUNK))
	for n in chunks:
		_build_chunk(n * CHUNK, minf((n + 1) * CHUNK, length), t, n)
	for mark_name in marks:
		_build_mark(String(mark_name), float(marks[mark_name]))


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
	for j in frames.size() - 1:
		var f0 := frames[j]
		var f1 := frames[j + 1]
		_sweep(st_bal, bal, f0, f1)
		for r in rails:
			_sweep(st_rail, r, f0, f1)
		# The fill: from the ballast's foot down to the ground, sides at 1.5:1.
		var fill0 := _fill_profile(f0, half_bot, bal_bot)
		var fill1 := _fill_profile(f1, half_bot, bal_bot)
		_quad(st_fill, fill0[0], fill0[1], fill1[1], fill1[0])
		_quad(st_fill, fill0[2], fill0[3], fill1[3], fill1[2])
	var body := StaticBody3D.new()
	body.name = "Bed"
	body.collision_layer = Layers.WORLD
	chunk.add_child(body)
	for pair in [[st_fill, _mat("fill", Color(0.42, 0.33, 0.23))], [st_bal, _mat("ballast", Color(0.36, 0.34, 0.31))]]:
		var st: SurfaceTool = pair[0]
		st.generate_normals()
		var mesh := st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = pair[1]
		chunk.add_child(mi)
		var cs := CollisionShape3D.new()
		cs.shape = mesh.create_trimesh_shape()
		body.add_child(cs)
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

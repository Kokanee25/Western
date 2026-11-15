extends BridgeLab
## Issue #973 (our own cloth, step 1): the core's film beside Jolt's, in the running game's real look
## (`--game-args=--real`). In a row, each dropped from a metre at once: our sheet, the Jolt rag (a
## ClothProp of the same size, points and mass), the glove's own mesh (WornGarment from his skin) as
## our cloth, the same glove as Jolt's GarmentCloth; behind them our sheet hung by two corners. Lab
## only; README.md beside it has the runs.
##
##   cc_set X Y Z [MODEL]   the row there (the glove made from MODEL's skin, sean_s3_talking by default)
##   cc_cam NAME           front | low | top: the free camera, in the row's frame
##   cc_film DIR [SECONDS=6]   drop them all and draw every frame to DIR; the measures back
##   cc_clear              all of it gone
##   cc_cost X Y Z [FRAMES=180] [MODEL]   each dropped alone: the physics frame (ms) against nothing
##                         dropped (Performance's physics time: our script's tick and Jolt's step), and
##                         ours' own solver time

const HELP := {
	"cc_set": "cc_set X Y Z [MODEL] -> our sheet, the Jolt rag, our glove, Jolt's glove in a row there, and our hung sheet (#973)",
	"cc_cam": "cc_cam front|low|top -> the free camera in the row's frame",
	"cc_film": "cc_film DIR [SECONDS=6] -> drop them, each frame to DIR/0000.png...; measures back",
	"cc_clear": "cc_clear -> the row gone",
	"cc_dump": "cc_dump PATH [MODEL] -> the glove's points and triangles as JSON (for the plugin's own probes)",
	"cc_cost": "cc_cost X Y Z [FRAMES=180] [MODEL] -> each cloth dropped alone there: the physics frame's ms against none, ours' own ms",
}
## Cameras in the row's frame (the row along +X from the origin, 0.8 m apart): [at, looking at, fov].
const CAMS := {
	"front": [Vector3(1.2, 1.25, 2.6), Vector3(1.2, 0.35, 0.0), 50.0],
	"low": [Vector3(1.2, 0.45, 1.6), Vector3(1.2, 0.15, 0.0), 55.0],
	"top": [Vector3(1.2, 2.6, 1.0), Vector3(1.2, 0.0, -0.1), 50.0],
}
const SPACING := 0.8
const DROP := 1.0
const TILT := 0.6   # rad the sheets are tilted, so they fold as they land
const SHEET := 0.5
const SHEET_PTS := 16
const SHEET_KG := 0.05

var origin := Vector3.ZERO
var items: Array[Node3D] = []
var ours: Array[SolverCloth] = []
var jolt: Array[Node3D] = []
var hanger: Node3D


func commands() -> Dictionary:
	return HELP


func _cmd_cc_set(a: Array) -> Dictionary:
	if a.size() < 3:
		return {"ok": false, "error": "cc_set X Y Z [MODEL]"}
	if not SolverCloth.available():
		return {"ok": false, "error": "ClothCore isn't loaded (the native plugin)"}
	_cmd_cc_clear([])
	await physics_frames(2)
	origin = vec(a, 0)
	origin.y = _ground_y(origin)
	var model := StringName(a[3]) if a.size() >= 4 else &"sean_s3_talking"
	var glove: Array = await _glove_points(model)
	if glove.is_empty():
		return {"ok": false, "error": "no glove from %s" % model}
	var floor_y := origin.y
	# 1. our sheet, 2. the Jolt rag
	var s := _sheet(origin + Vector3(0, DROP, 0))
	var mine := SolverCloth.make(s[0], s[1], s[2], _look(Color(0.62, 0.55, 0.42)), SHEET_KG / (SHEET * SHEET),
			{"floor_y": floor_y, "bend_mode": SolverCloth.FLAT, "bend_stiffness": 2e-5})
	_add(mine)
	ours.append(mine)
	var rag := ClothProp.new()
	rag.kit_id = &"cc_rag"
	rag.definition = {"size": [SHEET, SHEET], "points": [SHEET_PTS, SHEET_PTS], "mass": SHEET_KG,
			"stiffness": 1.0, "precision": 12, "damping": 0.06, "grip_radius": 0.03,
			"catch_seconds": 2.0, "burn_seconds": 30.0, "holds_ml": 60.0, "soaks": 0.5}
	_add(rag)
	rag.global_transform = Transform3D(Basis(Vector3.RIGHT, TILT), origin + Vector3(SPACING, DROP, 0))
	jolt.append(rag)
	# 3. our glove, 4. Jolt's glove (the same points, mass 35 g as the handoff's)
	var g_pts: PackedVector3Array = glove[0]
	var tris: PackedInt32Array = glove[1]
	var uv: PackedVector2Array = glove[2]
	var area := _area(g_pts, tris)
	var leather := _look(Color(0.30, 0.20, 0.12))
	var ours_glove := SolverCloth.make(_moved(g_pts, origin + Vector3(2 * SPACING, DROP, 0)), tris, uv, leather,
			0.035 / maxf(area, 1e-4), {"floor_y": floor_y, "bend_mode": SolverCloth.SHAPED, "bend_stiffness": 0.5,
			"max_strain": 1.05, "substeps": 20})
	_add(ours_glove)
	ours.append(ours_glove)
	var jg := GarmentCloth.make(_moved(g_pts, origin + Vector3(3 * SPACING, DROP, 0)), tris, uv, leather, 0.035, 12)
	_add(jg)
	jg.global_transform = Transform3D.IDENTITY
	jolt.append(jg)
	# Behind: our sheet hung by two corners from a rail (a node), held throughout.
	var hs := _sheet(origin + Vector3(1.2, 1.4, -0.9), 0.0)
	var hung := SolverCloth.make(hs[0], hs[1], hs[2], _look(Color(0.55, 0.18, 0.15)), SHEET_KG / (SHEET * SHEET),
			{"floor_y": floor_y, "bend_stiffness": 2e-5})
	_add(hung)
	ours.append(hung)
	hanger = Node3D.new()
	street.add_child(hanger)
	items.append(hanger)
	var corners: Array[int] = [0, SHEET_PTS - 1]
	hung.pin_to(corners, hanger)
	# Everything held still until the film drops it.
	for c in ours:
		if c != hung:
			var all: Array[int] = []
			for i in c.point_count():
				all.append(i)
			c.hold_on(all)
	await physics_frames(1)   # (a ClothProp's soft body is made in its _ready)
	for j in jolt:
		_pin_soft(j, true)
	return {"at": arr(origin), "glove_points": g_pts.size(), "glove_triangles": tris.size() / 3,
			"glove_area_m2": snappedf(area, 0.0001), "sheet_points": SHEET_PTS * SHEET_PTS}


func _cmd_cc_cam(a: Array) -> Dictionary:
	var c: Array = CAMS.get(a[0] if a.size() > 0 else "front", CAMS.front)
	var at: Vector3 = origin + (c[0] as Vector3)
	var to: Vector3 = origin + (c[1] as Vector3)
	return await bridge._cmd_camera([str(at.x), str(at.y), str(at.z), str(to.x), str(to.y), str(to.z), str(c[2])])


func _cmd_cc_film(a: Array) -> Dictionary:
	if ours.is_empty():
		return {"ok": false, "error": "cc_set first"}
	var draw := DisplayServer.get_name() != "headless"
	var dir: String = a[0] if a.size() > 0 else "build/cc_film"
	var frames := int(float(a[1]) * 60.0) if a.size() > 1 else 360
	if draw:
		DirAccess.make_dir_recursive_absolute(dir)
	var hidden := _hide_overlays()
	for i in 2:   # (the hung one stays held)
		ours[i].let_go()
	for j in jolt:
		_pin_soft(j, false)
	var ms := [0.0, 0.0, 0.0]
	var n := 0
	var lowest := INF
	var strain := 0.0
	for f in frames:
		if draw:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%04d.png" % [dir, f])
		else:
			await physics_frames(1)
		for k in 3:
			ms[k] += ours[k].last_millis
		n += 1
		for k in 2:
			for p in ours[k].points_now():
				lowest = minf(lowest, p.y - origin.y)
			strain = maxf(strain, ours[k].core.max_strain())
	for c: CanvasLayer in hidden:
		if is_instance_valid(c):
			c.visible = true
	return {"dir": dir, "frames": n, "ms_tick_sheet": snappedf(ms[0] / n, 0.001),
			"ms_tick_glove": snappedf(ms[1] / n, 0.001), "ms_tick_hung": snappedf(ms[2] / n, 0.001),
			"lowest_above_floor_m": snappedf(lowest, 0.0001), "max_strain": snappedf(strain, 0.0001),
			"resting": [ours[0].resting, ours[1].resting], "jolt_glove_resting": (jolt[1] as GarmentCloth).resting}


func _cmd_cc_clear(_a: Array) -> Dictionary:
	for n in items:
		if is_instance_valid(n):
			n.queue_free()
	items.clear()
	ours.clear()
	jolt.clear()
	hanger = null
	return {"cleared": true}


func _cmd_cc_dump(a: Array) -> Dictionary:
	var g: Array = await _glove_points(StringName(a[1]) if a.size() >= 2 else &"sean_s3_talking")
	if g.is_empty():
		return {"ok": false, "error": "no glove"}
	var pts := []
	for p: Vector3 in g[0]:
		pts.append([p.x, p.y, p.z])
	var f := FileAccess.open(a[0] if a.size() > 0 else "build/glove.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"points": pts, "triangles": Array(g[1])}))
	return {"points": pts.size(), "triangles": (g[1] as PackedInt32Array).size() / 3}


func _cmd_cc_cost(a: Array) -> Dictionary:
	if a.size() < 3:
		return {"ok": false, "error": "cc_cost X Y Z [FRAMES] [MODEL]"}
	_cmd_cc_clear([])
	origin = vec(a, 0)
	origin.y = _ground_y(origin)
	var frames := int(a[3]) if a.size() >= 4 else 180
	var glove: Array = await _glove_points(StringName(a[4]) if a.size() >= 5 else &"sean_s3_talking")
	var at := origin + Vector3(0, DROP, 0)
	var out := {}
	for kind in ["none", "jolt_rag", "our_sheet", "jolt_glove", "our_glove", "none_again"]:
		var c: Node3D = null
		var s := _sheet(at)
		match kind:
			"jolt_rag":
				var r := ClothProp.new()
				r.kit_id = &"cc_rag"
				c = r
				r.definition = {"size": [SHEET, SHEET], "points": [SHEET_PTS, SHEET_PTS], "mass": SHEET_KG,
						"stiffness": 1.0, "precision": 12, "damping": 0.06, "grip_radius": 0.03,
						"catch_seconds": 2.0, "burn_seconds": 30.0, "holds_ml": 60.0, "soaks": 0.5}
			"our_sheet":
				c = SolverCloth.make(s[0], s[1], s[2], null, SHEET_KG / (SHEET * SHEET),
						{"floor_y": origin.y, "bend_stiffness": 2e-5})
			"jolt_glove":
				c = GarmentCloth.make(_moved(glove[0], at), glove[1], glove[2], null, 0.035, 12)
			"our_glove":
				c = SolverCloth.make(_moved(glove[0], at), glove[1], glove[2], null,
						0.035 / maxf(_area(glove[0], glove[1]), 1e-4),
						{"floor_y": origin.y, "bend_mode": SolverCloth.SHAPED, "bend_stiffness": 0.5, "max_strain": 1.05, "substeps": 20})
		if c:
			_add(c)
			if c is ClothProp:
				c.global_transform = Transform3D(Basis(Vector3.RIGHT, TILT), at) if kind == "jolt_rag" else Transform3D.IDENTITY
		await physics_frames(10)
		var sum := 0.0
		var own := 0.0
		for f in frames:
			await physics_frames(1)
			sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			if c is SolverCloth:
				own += (c as SolverCloth).last_millis
		out[kind] = {"physics_ms": snappedf(sum / frames, 0.001)}
		if c is SolverCloth:
			out[kind]["own_ms"] = snappedf(own / frames, 0.001)
		_cmd_cc_clear([])
		await physics_frames(3)
	var base := (float(out.none.physics_ms) + float(out.none_again.physics_ms)) * 0.5
	for k: String in out:
		out[k]["over_none_ms"] = snappedf(float(out[k].physics_ms) - base, 0.001)
	out["frames"] = frames
	return out


## Every point of a Jolt cloth (a ClothProp) pinned where it is, or let go.
func _pin_soft(c: Node3D, on: bool) -> void:
	var cp := c as ClothProp
	for i in cp.point_count():
		cp.soft.set_point_pinned(i, on)


func _add(n: Node3D) -> void:
	street.add_child(n)
	items.append(n)


## The ground's height under `at` (a ray down).
func _ground_y(at: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 20.0, at + Vector3.DOWN * 20.0, Layers.WORLD)
	var hit: Dictionary = street.get_world_3d().direct_space_state.intersect_ray(q)
	return (hit.position as Vector3).y if hit else at.y


## A sheet SHEET m square, SHEET_PTS a side, its middle at `at`, tilted by `tilt` about X: [points, tris, uvs].
func _sheet(at: Vector3, tilt := TILT) -> Array:
	var b := Basis(Vector3.RIGHT, tilt)
	var pts := PackedVector3Array()
	var uv := PackedVector2Array()
	var n := SHEET_PTS
	for r in n:
		for c in n:
			var local := Vector3(SHEET * (float(c) / (n - 1) - 0.5), 0.0, SHEET * (float(r) / (n - 1) - 0.5))
			pts.append(at + b * local)
			uv.append(Vector2(local.x, local.z))
	var tris := PackedInt32Array()
	for r in n - 1:
		for c in n - 1:
			var i := r * n + c
			if (r + c) % 2 == 0:
				tris.append_array([i, i + 1, i + n, i + 1, i + n + 1, i + n])
			else:
				tris.append_array([i, i + n + 1, i + n, i, i + 1, i + n + 1])
	return [pts, tris, uv]


## The long glove's points as worn on `model`'s left arm (world), its triangles and UVs; the man gone.
func _glove_points(model: StringName) -> Array:
	var man := HumanBody.new()
	man.person_id = &"cc_man"
	man.has_gun = false
	man.body_model = model
	man.enter(street, origin + Vector3(0, 0, -30), 0.0)
	await physics_frames(20)
	var g := WornGarment.glove(man, "l")
	var out := []
	if g:
		out = [g.posed(), g.indices, g.uvs]
	man.queue_free()
	await physics_frames(2)
	return out


## `pts` moved so their middle is at `to`.
func _moved(pts: PackedVector3Array, to: Vector3) -> PackedVector3Array:
	var mid := Vector3.ZERO
	for p in pts:
		mid += p
	mid /= maxf(pts.size(), 1)
	var out := PackedVector3Array()
	for p in pts:
		out.append(p - mid + to)
	return out


func _area(pts: PackedVector3Array, tris: PackedInt32Array) -> float:
	var s := 0.0
	for t in range(0, tris.size(), 3):
		s += 0.5 * (pts[tris[t + 1]] - pts[tris[t]]).cross(pts[tris[t + 2]] - pts[tris[t]]).length()
	return s


func _look(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _hide_overlays() -> Array[CanvasLayer]:
	var out: Array[CanvasLayer] = []
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var c := n as CanvasLayer
		if c.visible and c.find_children("*", "SubViewportContainer", true, false).is_empty() \
				and c.find_children("*", "SubViewport", true, false).is_empty():
			c.visible = false
			out.append(c)
	return out

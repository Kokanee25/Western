extends BridgeLab
## Issue #895 (the garment handoff): the film, in the running game's real look (`--game-args=--real`).
## MetaHuman Sean (his Studio build, copied into assets/people/ for the run, never committed) on the
## street with a kit chair by him; the long glove worn; drawn off, tossed onto the chair. Lab only;
## README.md beside it has the runs.
##
##   gh_man X Y Z [YAW] [MODEL]   him there, no brain (a MetaHuman: his GLB's own materials); a chair at his right front
##   gh_dress               the glove on him (the game's GarmentHandoff, #917)
##   gh_cam NAME            hands | wide | chair | side: the free camera, set in his frame
##   gh_film DIR [SECONDS=11]   the handoff from its cue, every frame drawn to DIR; its measures back
##   gh_clear               him, the chair, the glove gone

var MODEL := &"barkeep_s2_talking"  # (the lab's was sean_metahuman_s3, never committed; gh_man's 5th word)
const HELP := {
	"gh_man": "gh_man X Y Z [YAW] [MODEL] -> MetaHuman Sean there (no brain, his own materials), a chair by him (#895)",
	"gh_dress": "gh_dress -> the long glove on his left arm, worn (the game's GarmentHandoff)",
	"gh_cam": "gh_cam hands|wide|chair|side -> the free camera in his frame",
	"gh_film": "gh_film DIR [SECONDS=11] -> the handoff from its cue, each frame to DIR/0000.png...",
	"gh_clear": "gh_clear -> him, the chair and the glove gone",
}
## Cameras in his frame (he at the origin facing -Z, his right +X): [at, looking at, fov].
const CAMS := {
	"hands": [Vector3(-0.2, 1.75, -1.25), Vector3(0.15, 1.05, -0.45), 42.0],
	"wide": [Vector3(-1.7, 1.55, -2.7), Vector3(0.35, 0.9, -0.45), 45.0],
	"chair": [Vector3(1.75, 1.45, -1.9), Vector3(0.75, 0.6, -0.55), 44.0],
	"side": [Vector3(-1.5, 1.3, -0.3), Vector3(0.1, 1.0, -0.4), 42.0],
}

var man: HumanBody
var chair: Node3D
var handoff: Node3D


func commands() -> Dictionary:
	return HELP


func _cmd_gh_man(a: Array) -> Dictionary:
	if a.size() < 3:
		return {"ok": false, "error": "gh_man X Y Z [YAW]"}
	_cmd_gh_clear([])
	await physics_frames(2)
	var at := vec(a, 0)
	var yaw := deg_to_rad(-float(a[3])) if a.size() >= 4 else 0.0
	if a.size() >= 5:
		MODEL = StringName(a[4])
	man = HumanBody.new()
	man.person_id = &"gh_man"
	man.name = "GhMan"
	man.has_gun = false
	man.body_model = MODEL
	man.enter(street, at, yaw)
	await physics_frames(30)
	var own := _own_materials() if String(MODEL).contains("metahuman") else 0
	chair = PropKit.spawn(&"chair")
	street.add_child(chair)
	chair.global_position = man.global_transform * Vector3(0.95, 0.0, -0.75)
	chair.global_rotation.y = man.global_rotation.y + deg_to_rad(200.0)
	return {"person": "gh_man", "at": arr(man.global_position), "own_materials": own,
			"chair": arr(chair.global_position)}


func _cmd_gh_dress(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "gh_man first"}
	if handoff:
		return {"ok": false, "error": "dressed already (gh_man again for a fresh one)"}
	handoff = load("res://experiments/garment_handoff/handoff.gd").new()
	handoff.name = "GloveHandoff"
	handoff.measure_skin = false  # (the bench counts it; here it would slow the film)
	street.add_child(handoff)
	return handoff.dress(man, chair)


func _cmd_gh_cam(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "gh_man first"}
	var c: Array = CAMS.get(a[0] if a.size() > 0 else "hands", CAMS.hands)
	var xf := man.global_transform
	var at: Vector3 = xf * (c[0] as Vector3)
	var to: Vector3 = xf * (c[1] as Vector3)
	return await bridge._cmd_camera([str(at.x), str(at.y), str(at.z), str(to.x), str(to.y), str(to.z), str(c[2])])


func _cmd_gh_film(a: Array) -> Dictionary:
	if handoff == null:
		return {"ok": false, "error": "gh_man and gh_dress first"}
	if DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "headless: nothing is drawn"}
	var dir: String = a[0] if a.size() > 0 else "build/gh_film"
	var frames := int(float(a[1]) * 60.0) if a.size() > 1 else 660
	DirAccess.make_dir_recursive_absolute(dir)
	var hidden := _hide_overlays()
	handoff.begin()
	for f in frames:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%04d.png" % [dir, f])
		if handoff.done:
			break
	for c: CanvasLayer in hidden:
		if is_instance_valid(c):
			c.visible = true
	var r: Dictionary = handoff.rec.duplicate()
	r.erase("through")
	return {"dir": dir, "phase_at": r.phase_at, "rest_at": r.rest_at, "where": r.where, "pop_mm": r.pop_mm,
			"stretch_max": r.get("stretch_max", 1.0), "flung": r.flung, "below_floor": r.below_floor}


func _cmd_gh_clear(_a: Array) -> Dictionary:
	for n in [handoff, chair, man]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	for n in street.get_children():
		if n is GarmentHandoff:
			n.queue_free()
	handoff = null
	chair = null
	man = null
	return {"cleared": true}


## His GLB's own materials on his skin's meshes (as the Studio's test scene and the skeleton lab
## draw a MetaHuman: the game's people shaders expect the painted men's textures).
func _own_materials() -> int:
	var scene := load(PeopleBodies.PATH % man.body_model) as PackedScene
	var root := scene.instantiate()
	var mats := {}
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var shape := String(mi.name).to_lower().trim_prefix("body_").trim_prefix("cloth_")
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			mats[shape] = mi.mesh.surface_get_material(0)
	root.free()
	var n := 0
	for c in man.skeleton.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		for shape: String in mats:
			if String(mi.name).begins_with(shape.to_pascal_case() + "_"):
				mi.material_override = mats[shape]
				n += 1
				break
	return n


## The screen's words off while filming: every CanvasLayer but the game picture's.
func _hide_overlays() -> Array[CanvasLayer]:
	var out: Array[CanvasLayer] = []
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var c := n as CanvasLayer
		if c.visible and c.find_children("*", "SubViewportContainer", true, false).is_empty() \
				and c.find_children("*", "SubViewport", true, false).is_empty():
			c.visible = false
			out.append(c)
	return out

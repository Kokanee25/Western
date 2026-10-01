extends RefCounted
## The character lab's set, shared by tools/character_lab.gd and tools/paint_bake.gd: an empty world
## in a SubViewport with ShotMatch's table and man, the painting's camera, and light tuned to the
## painting's (not the saloon's). Loaded by path (tool scripts run before autoloads compile).

## The light on him, relative to the table's centre on the floor (ShotMatch's space: +X your left,
## +Z away from you). Tuned against the painting's face and coat brightness (2026-09-29): a warm key
## over the lamp side, a warm-grey fill so his shadow side is brown, not black (the painting's room
## is full of lamps), a rim from behind him on your left (its sconces).
const KEY := {"at": Vector3(0.3, 1.45, -0.25), "color": Color(1.0, 0.74, 0.48), "energy": 0.3, "range": 3.0}
const RIM := {"at": Vector3(1.5, 1.8, 0.5), "color": Color(1.0, 0.78, 0.55), "energy": 0.8, "range": 3.0}
const FILL := {"color": Color(0.58, 0.46, 0.38), "energy": 1.0}
## The table lamp (ShotMatch's): 40 cm from his face it would burn his cheek out.
const TABLE_LAMP := 0.8
## Views round him besides the painting's: degrees from straight in front (to his left positive),
## height over his chest, distance (m).
const VIEWS := {"front": [0.0, 0.1], "three_quarter": [-40.0, 0.15], "side": [-90.0, 0.1],
		"side_left": [90.0, 0.1], "back": [180.0, 0.2]}
const VIEW_DISTANCE := 1.8
const VIEW_FOV := 40.0
## Close views of his head (face, hair, hat, collar): degrees round from straight in front as
## VIEWS, at HEAD_DISTANCE; "head_shot" looks from your seat at the table (the painting's side).
const HEAD_VIEWS := {"head_front": 0.0, "head_three_quarter": -40.0, "head_side": -90.0,
		"head_side_left": 90.0, "head_back": 180.0, "head_shot": INF}
const HEAD_DISTANCE := 0.75


static func default_energy() -> Dictionary:
	return {"key": KEY.energy, "rim": RIM.energy, "fill": FILL.energy, "lamp": TABLE_LAMP}


## Build the set in `vp` (its own world). Returns {world, man, camera, env, lights}. `outlines`: the
## game's line work on the camera (the paint bake's guides and depth maps go without).
static func build(vp: SubViewport, energy: Dictionary, outlines := false) -> Dictionary:
	var sm = load("res://src/art/shot_match.gd")
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var w := Node3D.new()
	w.name = "Lab"
	vp.add_child(w)
	var env := _environment(w, energy.fill)
	_ground(w, sm.TABLE)
	var man = sm.stage(w)
	w.find_child("TableLamp", true, false).energy = energy.lamp
	var lights := []
	for l in [[KEY, energy.key], [RIM, energy.rim]]:
		var o := OmniLight3D.new()
		o.light_color = l[0].color
		o.light_energy = l[1]
		o.omni_range = l[0].range
		o.shadow_enabled = true
		w.add_child(o)
		o.global_position = sm.rig(w) * (l[0].at as Vector3)
		lights.append(o)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.current = true
	if outlines:
		load("res://src/render/outline.gd").attach(cam)
	cam.global_transform = sm.camera_transform(w)
	cam.fov = sm.FOV
	return {"world": w, "man": man, "camera": cam, "env": env, "lights": lights}


## Put the camera on one of the VIEWS round him (or back on the painting's for "shot").
static func aim(set: Dictionary, view: String) -> void:
	var sm = load("res://src/art/shot_match.gd")
	var cam: Camera3D = set.camera
	if view == "shot":
		cam.global_transform = sm.camera_transform(set.world)
		cam.fov = sm.FOV
		return
	var man = set.man
	if HEAD_VIEWS.has(view):
		var head: Vector3 = (man.parts[&"head"] as Node3D).global_position + Vector3.DOWN * 0.03
		var deg: float = HEAD_VIEWS[view]
		var to: Vector3
		if deg != INF:
			to = (-man.global_basis.z as Vector3).rotated(Vector3.UP, deg_to_rad(deg))
		else:
			to = ((sm.camera_transform(set.world) as Transform3D).origin - head).normalized()
		cam.fov = VIEW_FOV
		cam.global_transform = Transform3D(Basis.looking_at(-to, Vector3.UP), head + to * HEAD_DISTANCE)
		return
	var chest: Vector3 = (man.parts[&"chest"] as Node3D).global_position
	var v: Array = VIEWS[view]
	var dir := (-man.global_basis.z as Vector3).rotated(Vector3.UP, deg_to_rad(v[0]))
	cam.fov = VIEW_FOV
	cam.global_transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), chest + dir * VIEW_DISTANCE + Vector3.UP * float(v[1]))


static func grab(tree: SceneTree, vp: SubViewport) -> Image:
	for i in 8:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Black round him (so nothing of ours but him gets pasted), and the game's grade: ACES, a little
## glow, the same contrast as the saloon's environment.
static func _environment(w: Node3D, fill: float) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = FILL.color
	env.ambient_light_energy = fill
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.2
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	w.add_child(we)
	return env


## A floor for the chair and table to stand on (ShotMatch finds it by a ray).
static func _ground(w: Node3D, at: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 1, 12)
	cs.shape = box
	sb.add_child(cs)
	w.add_child(sb)
	sb.global_position = Vector3(at.x, -0.5, at.z)

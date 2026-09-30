extends SceneTree
## The painting's man on his own, framed and lit as the painting has him, and pasted into the
## painting over its own man, so he can be judged by himself (not with our saloon round him):
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/character_lab.gd -- --out=DIR
##   [--key= --rim= --fill= --lamp=] (light strengths, to try others)
## Writes lab.png (the frame, 640x360: him, his table and cup on black), in_painting.png (his pixels
## over the painting at the same size) and _x3 versions of both.
## His pixels are found by rendering twice: once as he is, once with him casting shadows but not
## drawn. What differs is him, where he can be seen: the table in front of him, and his own shadow,
## are the same in both, so they stay the painting's.

const PAINTING := "res://docs/concept/saloon-night.png"
const SIZE := Vector2i(640, 360)

## The light on him, relative to the table's centre on the floor (ShotMatch's space: +X your left,
## +Z away from you). Tuned against the painting's face and coat brightness (2026-09-29). The
## painting's, not the saloon's: a warm key from the lamp side and above,
## so the brim shades his brow; a low warm fill so his shadow side is brown, not black (the
## painting's room is full of lamps); a rim from behind him on your left (its sconces).
const KEY := {"at": Vector3(0.3, 1.45, -0.25), "color": Color(1.0, 0.74, 0.48), "energy": 0.3, "range": 3.0}
const RIM := {"at": Vector3(1.5, 1.8, 0.5), "color": Color(1.0, 0.78, 0.55), "energy": 0.8, "range": 3.0}
const FILL := {"color": Color(0.58, 0.46, 0.38), "energy": 1.0}
## The table lamp (ShotMatch's): 40 cm from his face it would burn his cheek out; the painting's
## lamp lights the table more than him.
const TABLE_LAMP := 0.8
## A pixel is his if it differs by more than this (0..1, any channel) between the two renders.
const DIFF := 0.03


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/character_lab"
	var energy := {"key": KEY.energy, "rim": RIM.energy, "fill": FILL.energy, "lamp": TABLE_LAMP}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		for k in energy:
			if a.begins_with("--%s=" % k):
				energy[k] = float(a.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out)
	root.get_node(^"Settings").autosave = false
	var sm = load("res://src/art/shot_match.gd")
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	w.name = "Lab"
	vp.add_child(w)
	_environment(w, energy.fill)
	_ground(w, sm.TABLE)
	var man = sm.stage(w)
	w.find_child("TableLamp", true, false).energy = energy.lamp
	for l in [[KEY, energy.key], [RIM, energy.rim]]:
		var o := OmniLight3D.new()
		o.light_color = l[0].color
		o.light_energy = l[1]
		o.omni_range = l[0].range
		o.shadow_enabled = true
		w.add_child(o)
		o.global_position = sm.TABLE + (l[0].at as Vector3)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.current = true
	cam.global_transform = sm.camera_transform(w)
	cam.fov = sm.FOV
	for i in 90:
		await physics_frame
	var with_him := await _grab(vp)
	for mi: MeshInstance3D in man.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var without := await _grab(vp)
	with_him.save_png("%s/lab.png" % out)
	var painting := Image.load_from_file(ProjectSettings.globalize_path(PAINTING))
	painting.convert(Image.FORMAT_RGBA8)
	painting.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var pasted := painting.duplicate() as Image
	var his := 0
	for y in SIZE.y:
		for x in SIZE.x:
			var a := with_him.get_pixel(x, y)
			var b := without.get_pixel(x, y)
			if maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) > DIFF:
				pasted.set_pixel(x, y, a)
				his += 1
	pasted.save_png("%s/in_painting.png" % out)
	for pair in [[with_him, "lab"], [pasted, "in_painting"]]:
		var big := (pair[0] as Image).duplicate() as Image
		big.resize(SIZE.x * 3, SIZE.y * 3, Image.INTERPOLATE_NEAREST)
		big.save_png("%s/%s_x3.png" % [out, pair[1]])
	print("character lab: %d of his pixels pasted, saved to %s" % [his, out])
	quit()


func _grab(vp: SubViewport) -> Image:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Black round him (so nothing of ours but him gets pasted), and the game's grade: ACES, a little
## glow, the same contrast as the saloon's environment.
func _environment(w: Node3D, fill: float) -> void:
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


## A floor for the chair and table to stand on (ShotMatch finds it by a ray).
func _ground(w: Node3D, at: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 1, 12)
	cs.shape = box
	sb.add_child(cs)
	w.add_child(sb)
	sb.global_position = Vector3(at.x, -0.5, at.z)

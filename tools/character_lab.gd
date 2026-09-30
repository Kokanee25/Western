extends SceneTree
## The painting's man on his own, framed and lit as the painting has him, and pasted into the
## painting over its own man, so he can be judged by himself (not with our saloon round him):
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/character_lab.gd -- --out=DIR
##   [--key= --rim= --fill= --lamp=] (light strengths, to try others)
##   [--self_lit= --paint_gain= --paint_wrap= --paint_limit=] (how his painted textures show: HumanBody.paint_look)
##   [--size=WxH] (the frame; 640x360 by default, the game's)
##   [--view=shot|front|three_quarter|side|side_left|back] (shot, the painting's view, is the
##   default; the others orbit him at 1.8 m, looking at his chest, and write only lab.png)
## Writes lab.png (the frame, 640x360: him, his table and cup on black), in_painting.png (his pixels
## over the painting at the same size) and _x3 versions of both. The set is tools/lab_stage.gd.
## His pixels are found by rendering twice: once as he is, once with him casting shadows but not
## drawn. What differs is him, where he can be seen: the table in front of him, and his own shadow,
## are the same in both, so they stay the painting's.

const PAINTING := "res://docs/concept/saloon-night.png"
## The frame's size (--size=WxH to try others: at the painting's own 1672x941, each painted square
## on him gets several screen pixels, as the painting's do).
var SIZE := Vector2i(640, 360)
## A pixel is his if it differs by more than this (0..1, any channel) between the two renders.
const DIFF := 0.03


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var stage = load("res://tools/lab_stage.gd")
	var out := "/tmp/character_lab"
	var energy: Dictionary = stage.default_energy()
	var view := "shot"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--size="):
			SIZE = Vector2i(int(a.substr(7).get_slice("x", 0)), int(a.substr(7).get_slice("x", 1)))
		elif a.begins_with("--view="):
			view = a.substr(7)
		for k in energy:
			if a.begins_with("--%s=" % k):
				energy[k] = float(a.get_slice("=", 1))
		# How his painted textures are shown (HumanBody.paint_look): --self_lit= --paint_gain= --paint_wrap=
		var hb = load("res://src/bodies/human_body.gd")
		for k: StringName in hb.paint_look:
			if a.begins_with("--%s=" % k):
				hb.paint_look[k] = float(a.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out)
	root.get_node(^"Settings").autosave = false
	var vp := SubViewport.new()
	vp.size = SIZE
	root.add_child(vp)
	var set: Dictionary = stage.build(vp, energy)
	var man = set.man
	for i in 90:
		await physics_frame
	stage.aim(set, view)
	if view != "shot":
		var img: Image = await stage.grab(self, vp)
		img.save_png("%s/lab.png" % out)
		img.resize(SIZE.x * 2, SIZE.y * 2, Image.INTERPOLATE_NEAREST)
		img.save_png("%s/lab_x2.png" % out)
		print("character lab: %s view saved to %s" % [view, out])
		quit()
		return
	var with_him: Image = await stage.grab(self, vp)
	for mi: MeshInstance3D in man.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var without: Image = await stage.grab(self, vp)
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

extends "res://tools/screenshots.gd"
## The game's own fixed views (tools/screenshots.gd, every option it has) under a lab look, and
## with the paint probe over the whole frame: the render lab's way into the real saloon and street
## without touching the game's files (experiments/render_lab/README.md).
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/render_lab/shots.gd -- \
##       --out=DIR --fresh --only=shot_match_saloon,shot_match_street [--lab-look=paint] [--world-probe]
##
## --lab-look=: a look from lab_looks.gd put on every material as it enters the tree (base: none).
## --world-probe: after each view, with everything held still, <view>_w.png (the frame) and
## <view>_w__paint.png (the paint probe) for analyse.py light. It stands in for --face-probe, so
## pass both (--face-probe is what calls it).

const LabLooks := preload("res://experiments/render_lab/lab_looks.gd")

var _world_probe := false


func _initialize() -> void:
	var lab_look := "base"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lab-look="):
			lab_look = a.substr(11)
		elif a == "--world-probe":
			_world_probe = true
	LabLooks.install(self, lab_look)
	super._initialize()


func _save_face_probe(viewport: SubViewport, player, base: String) -> void:
	if not _world_probe:
		await super._save_face_probe(viewport, player, base)
		return
	var cam: Camera3D = player.camera
	var env: Environment = cam.environment
	if env == null:
		var we := viewport.find_child("WorldEnvironment", true, false) as WorldEnvironment
		env = we.environment if we else null
	var scene := viewport.get_child(0)
	var mode := scene.process_mode
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(base + "_w.png")
	LabLooks.probe(viewport, env, true)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(base + "_w__paint.png")
	LabLooks.probe(viewport, env, false)
	scene.process_mode = mode
	print("saved ", base.get_file(), "_w and its paint probe")

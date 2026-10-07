extends SceneTree
## The saloon's front against the street painting's (docs/concept/street-golden-hour.png): the street
## at the painting's hour, a camera placed in the saloon's own space (so it follows the building
## wherever the town's layout puts it), the render beside the painting's crop of its saloon.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/facade_lab.gd -- --out=DIR [--blocks] [--building=Jail]
##
## Writes DIR/facade_<view>.png for each view and DIR/facade_sheet.png (the painting's saloon over
## the renders). Views, in the saloon's space (front-left corner the origin, the front facing -Z):
## `painting` stands in the street off the saloon's right-hand end and looks back along its front
## as the painting does; `square` is the front three-quarters on, closer.

const HOUR := 17.6
## [name, eye, look at, vertical fov] in the saloon's space; x is scaled by its width over 9.6.
const VIEWS := [
	["painting", Vector3(12.0, 1.75, -11.0), Vector3(3.6, 3.6, -0.6), 50.0],
	["square", Vector3(8.6, 1.7, -9.0), Vector3(4.2, 3.9, 0.0), 58.0],
	["door", Vector3(3.9, 1.65, -3.2), Vector3(3.6, 1.7, 0.0), 58.0],
]
## The painting's saloon (pixels of the 1672-wide painting).
const CROP := Rect2i(0, 0, 900, 640)
## Other buildings (`--building=Jail`): their views in their own space (front-left corner the
## origin, x along the front, -Z out to the street), not scaled, and the painting's crop of them.
## The painting stands in the street east of the jail, its front raking away to the west and its
## east side wall (the building's left, x 0) toward you.
const OTHER := {
	"Jail": {"views": [["painting", Vector3(-6.5, 1.75, -9.0), Vector3(3.6, 3.0, 0.0), 50.0],
			["square", Vector3(3.2, 1.7, -8.5), Vector3(3.2, 3.2, 0.0), 58.0],
			["door", Vector3(1.4, 1.65, -3.6), Vector3(1.6, 1.8, 0.0), 58.0]],
		"crop": Rect2i(1150, 300, 400, 300)},
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://facade_lab"
	var outline := false
	var shade := 1.0
	var building := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg == "--outline":
			outline = true
		elif arg.begins_with("--shade="):
			shade = float(arg.substr(8))
		elif arg.begins_with("--building="):
			building = arg.substr(11)
	DirAccess.make_dir_recursive_absolute(out)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var viewport: SubViewport = main.get_node(^"GameViewport")
	load("res://src/art/street_match.gd").stage(street)
	var clock = street.get_node(^"DayCycle")
	clock.set_physics_process(false)
	clock.set_time(HOUR)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	for w in player.weapons:
		w.visible = false
	var saloon := _saloon(street) if building.is_empty() else street.find_child(building, true, false) as Node3D
	if saloon == null:
		push_error("facade_lab: no saloon on the street")
		quit(1)
		return
	var cam := Camera3D.new()
	cam.name = "FacadeCamera"
	street.add_child(cam)
	cam.current = true
	var mosaic: Script = load("res://src/render/depth_mosaic.gd")
	mosaic.apply(cam, settings.mosaic_active(), settings.MOSAIC_K, settings.MOSAIC_STEPS)
	# Trials of crispness: the outline pass's dark lines on edges and creases (`--outline`), and the
	# sky's fill in the shadows scaled (`--shade=0.5`: deeper darks, SSAO stronger to match).
	if outline:
		var o = load("res://src/render/outline.gd").attach(cam)
		await process_frame
		var m := o.material_override as ShaderMaterial
		m.set_shader_parameter(&"thickness", 1.0)
		m.set_shader_parameter(&"fade_from", 25.0)
		m.set_shader_parameter(&"fade_to", 60.0)
	if shade != 1.0:
		var env := (street.find_child("WorldEnvironment", true, false) as WorldEnvironment).environment
		env.ambient_light_energy *= shade
		env.ssao_intensity *= 1.0 / shade
	var k: float = saloon.width / 9.6 if building.is_empty() else 1.0
	var views: Array = VIEWS if building.is_empty() else OTHER[building].views if OTHER.has(building) \
			else [["square", Vector3(saloon.width * 0.5, 1.7, -9.5), Vector3(saloon.width * 0.5, 3.2, 0.0), 58.0]]
	var shots: Array[Image] = []
	for v in views:
		var eye: Vector3 = v[1]
		var at: Vector3 = v[2]
		eye.x *= k
		at.x *= k
		var t: Transform3D = saloon.global_transform
		cam.global_position = t * eye
		cam.look_at(t * at, Vector3.UP)
		cam.fov = v[3]
		for i in 30:
			await process_frame
		var img := viewport.get_texture().get_image()
		img.save_png("%s/facade_%s.png" % [out, v[0]])
		shots.append(img)
	_sheet(out, shots, CROP if building.is_empty() else OTHER[building].crop if OTHER.has(building) else Rect2i(560, 100, 400, 300))
	quit()


## The saloon on the street: StreetDressing's façade saloon where there is one (before the town
## went to Sean's map), else the saloon itself (config/town.json's `Saloon`).
func _saloon(street: Node) -> Node3D:
	for name in ["StreetSaloon", "Saloon"]:
		var n := street.find_child(name, true, false)
		if n != null and "porch" in n:
			return n
	return null


func _sheet(out: String, shots: Array[Image], region: Rect2i) -> void:
	var painting := Image.load_from_file(ProjectSettings.globalize_path("res://docs/concept/street-golden-hour.png"))
	var crop := painting.get_region(region)
	var w := 1280
	crop.resize(w, int(crop.get_height() * float(w) / crop.get_width()), Image.INTERPOLATE_LANCZOS)
	var h := crop.get_height()
	for s in shots:
		h += 8 + int(s.get_height() * float(w) / s.get_width())
	var sheet := Image.create(w, h, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.08, 0.08))
	crop.convert(Image.FORMAT_RGB8)
	sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i.ZERO)
	var y := crop.get_height() + 8
	for s in shots:
		var c := s.duplicate() as Image
		c.convert(Image.FORMAT_RGB8)
		c.resize(w, int(c.get_height() * float(w) / c.get_width()), Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(0, y))
		y += c.get_height() + 8
	sheet.save_png("%s/facade_sheet.png" % out)

extends TestCase
## The probe mosaic trial (src/render/probe_mosaic.gd): its blocks are cut from an origin snapped
## to a grid, which stays put while the camera is within half a cell of it, waits while a
## cross-fade is under way, and crosses as fast as cells go by; switched on, it takes the screen
## mosaic's place on the camera, and off it leaves.

var cam: Camera3D


func before_each() -> void:
	cam = Camera3D.new()
	add_child(cam)
	await process_frames(1)


func after_each() -> void:
	cam.queue_free()
	await process_frames(1)


func test_the_origin_is_the_nearest_grid_point() -> void:
	check_eq(ProbeMosaic.snap(Vector3(0.24, 1.26, -0.74), 0.5), Vector3(0.0, 1.5, -0.5), "nearest point of a 0.5 m grid")
	check_eq(ProbeMosaic.snap(Vector3(3.9, 0.1, 2.6), 1.0), Vector3(4.0, 0.0, 3.0), "of a 1 m grid")


func test_turning_and_small_steps_keep_the_origin() -> void:
	var m := ProbeMosaic.new()
	m.cell = 0.5
	m.step(Vector3(1.1, 1.6, 2.1), 1.0 / 30.0)
	var o := m.origin()
	check_eq(o, Vector3(1.0, 1.5, 2.0), "first origin")
	for i in 10:
		m.step(Vector3(1.1 + 0.012 * i, 1.6, 2.1), 1.0 / 30.0)
	check_eq(m.origin(), o, "inside the cell it stays put")
	check_near(m.fading(), 1.0, 0.0001, "no cross-fade")
	m.free()


func test_crossing_a_cell_fades_to_the_new_origin_and_waits_for_it() -> void:
	var m := ProbeMosaic.new()
	m.cell = 0.5
	m.step(Vector3(1.0, 1.5, 2.0), 1.0 / 30.0)
	# Walking slowly (0.6 m/s) over the boundary at x = 1.25.
	var x := 1.0
	var crossed_at := -1
	for i in 30:
		x += 0.02
		m.step(Vector3(x, 1.5, 2.0), 1.0 / 30.0)
		if crossed_at < 0 and m.fading() < 1.0:
			crossed_at = i
			check_eq(m.origin(), Vector3(1.5, 1.5, 2.0), "the new origin")
	check(crossed_at >= 0, "the origin moved on")
	check_near(m.fading(), 1.0, 0.0001, "the fade is done within a second")
	# A fade takes about FADE_SECONDS at walking pace: 10 frames at 30 fps.
	var m2 := ProbeMosaic.new()
	m2.cell = 0.5
	m2.step(Vector3(1.24, 1.5, 2.0), 1.0 / 30.0)
	m2.step(Vector3(1.26, 1.5, 2.0), 1.0 / 30.0)
	check(m2.fading() < 0.05, "a fade starts at the boundary")
	var frames := 0
	while m2.fading() < 1.0 and frames < 60:
		m2.step(Vector3(1.26, 1.5, 2.0), 1.0 / 30.0)
		frames += 1
	check(frames >= 8 and frames <= 12, "it takes about a third of a second standing still (%d frames)" % frames)
	# While it fades the origin waits, even if you go on into the next cell.
	var m3 := ProbeMosaic.new()
	m3.cell = 0.5
	m3.step(Vector3(1.24, 1.5, 2.0), 1.0 / 30.0)
	m3.step(Vector3(1.26, 1.5, 2.0), 1.0 / 30.0)
	m3.step(Vector3(1.80, 1.5, 2.0), 1.0 / 30.0)
	check_eq(m3.origin(), Vector3(1.5, 1.5, 2.0), "the origin waits for its fade")
	m.free()
	m2.free()
	m3.free()


func test_running_fades_as_fast_as_cells_go_by() -> void:
	var m := ProbeMosaic.new()
	m.cell = 0.5
	var x := 0.0
	m.step(Vector3(x, 1.5, 0.0), 1.0 / 30.0)
	var fades := 0
	var was := 1.0
	for i in 60:
		x += 6.0 / 30.0  # 6 m/s for two seconds: 24 cells
		m.step(Vector3(x, 1.5, 0.0), 1.0 / 30.0)
		if m.fading() < 1.0 and was >= 1.0:
			fades += 1
		was = m.fading()
	check(fades >= 15, "it keeps up with a running man (%d fades for 24 cells)" % fades)
	check(m.origin().distance_to(ProbeMosaic.snap(Vector3(x, 1.5, 0.0), 0.5)) <= 1.0, "and isn't left behind")
	m.free()


func test_switched_on_it_replaces_the_screen_mosaic_and_off_it_leaves() -> void:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return
	DepthMosaic.attach(cam, 5.0)
	ProbeMosaic.apply(cam, true, 384.0, 0.5, 14.0)
	await process_frames(2)
	check(cam.get_node_or_null(^"DepthMosaic") == null, "the screen mosaic is gone")
	var m := cam.get_node_or_null(^"ProbeMosaic") as ProbeMosaic
	check(m != null, "the probe mosaic is on the camera")
	if m:
		var mat := m.material_override as ShaderMaterial
		check_near(float(mat.get_shader_parameter(&"texels")), 384.0, 0.01, "its texels")
		check_near(float(mat.get_shader_parameter(&"bands")), 14.0, 0.01, "its bands")
		check(mat.get_shader_parameter(&"probe_origin") != null, "it follows the camera")
	ProbeMosaic.apply(cam, false, 384.0, 0.5, 14.0)
	await process_frames(2)
	check(cam.get_node_or_null(^"ProbeMosaic") == null, "off, it leaves")

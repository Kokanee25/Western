extends SceneTree
## Film of the fire both ways, for comparing (the art session's; docs/briefs/fire-look.md, the
## flipbooks): the livery burning at dusk from the fire painting's view (livery_fire_dusk, staged
## as tools/screenshots.gd stages it) and the saloon burning inside at night (saloon_fire_inside),
## each filmed with the drawn fire sheets and then with the simulated flipbooks, the same fire, the
## same slow turn. Frames go to DIR/<view>_<mode>_NNN.png; tools/fire_ab.py makes the video.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 24 -s res://tools/fire_ab.gd -- --out=DIR [--frames=72] [--pan=6] [--views=livery_fire_dusk,saloon_fire_inside]
##
## With --fixed-fps 24 the shaders' time steps a 24th of a second a frame however slow the render,
## so the frames play back at 24 fps as they'd look. Untyped where it touches the game's classes:
## -s scripts compile before the autoloads exist.

var out := "user://fire_ab"
var frames := 72
var pan := 6.0
var views := ["livery_fire_dusk", "saloon_fire_inside"]


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--frames="):
			frames = int(a.substr(9))
		elif a.begins_with("--pan="):
			pan = float(a.substr(6))
		elif a.begins_with("--views="):
			views = Array(a.substr(8).split(","))
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	settings.internal_resolution = Vector2i(1280, 720)
	var ffx: Variant = load("res://src/fire/fire_fx.gd")
	var shots: Variant = load("res://tools/screenshots.gd")
	var all: Array = shots.VIEWS
	for name in views:
		var view: Array = []
		for s in all:
			if s[0] == name:
				view = s
		# A fresh street for each view, so one's fire isn't in the other's.
		var main: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
		var viewport: SubViewport = main.get_node(^"GameViewport")
		var street: Node3D = main.get_node(^"GameViewport/TestStreet")
		var clock = street.get_node(^"DayCycle")
		var player = street.get_node(^"Player")
		var town = main.find_child("TownLife", true, false)
		if town:
			town.gang_arrives = 1e9
		clock.set_physics_process(false)
		clock.set_time(view[1])
		# Where tools/screenshots.gd puts the view (its _view_move: the buildings have moved since
		# some views were written).
		var move: Transform3D = shots._view_move(name)
		var yaw0: float = view[3] + rad_to_deg(move.basis.get_euler().y)
		player.global_position = move * (view[2] as Vector3)
		player.velocity = Vector3.ZERO
		player.rotation = Vector3(0.0, deg_to_rad(yaw0), 0.0)
		player.input_enabled = true
		player.add_look(Vector2(0.0, view[4] - player.get_pitch_degrees()))
		player.input_enabled = false
		for w in player.weapons:
			w.selected = false
			w.drawn = false
			w.visible = false
		_stage(main, String(view[5]), player)
		var fire = main.find_child("FireSystem", true, false)
		# The fire held where it is while it's filmed, so both films show the same fire.
		fire.set_physics_process(false)
		for mode in ["sheets", "flipbooks"]:
			ffx.flipbooks = mode == "flipbooks"
			player.rotation = Vector3(0.0, deg_to_rad(yaw0 + pan * 0.5), 0.0)
			# FireFX swaps a share of the members' sheets a frame (FireSystem._refresh_fx).
			for i in 30:
				fire._refresh_fx(1)
				await process_frame
			for f in frames:
				player.rotation = Vector3(0.0, deg_to_rad(yaw0 + pan * (0.5 - float(f) / frames)), 0.0)
				await process_frame
				viewport.get_texture().get_image().save_png(out.path_join("%s_%s_%03d.png" % [name, mode, f]))
		print("fire_ab: %s, %d frames each way" % [name, frames])
		main.queue_free()
		await process_frame
		await process_frame
	quit()


## The view's fire, as tools/screenshots.gd stages it (its livery_fire and saloon_fire).
func _stage(main: Node, setup: String, player: Node3D) -> void:
	var fire = main.find_child("FireSystem", true, false)
	if setup == "livery_fire":
		var livery = main.find_child("Livery", true, false)
		var lit := 0
		for m in livery.get_members():
			if lit < 30 and String(m.member_id).contains("front") and m.global_position.y < 2.4 and m.wood != &"glass":
				fire.ignite(m)
				lit += 1
		for i in 480:
			fire.step(0.5)
	elif setup == "saloon_fire":
		var saloon = main.find_child("Saloon", true, false)
		var eye := player.global_position
		var ahead := -player.global_basis.z
		var lit := 0
		for m in saloon.get_members():
			if lit < 24 and _in_view(m.global_position, eye, ahead) and m.global_position.y < 2.2 and m.size.y > 0.25 and m.wood != &"glass":
				fire.ignite(m)
				lit += 1
		# The player lifted out of reach while it burns (it would scorch him), then back.
		var here := player.global_position
		player.global_position = here + Vector3.UP * 40.0
		for i in 60:
			fire.step(0.5)
		player.global_position = here
		# Nor does the fire scorch him while he looks (it reaches what's by him in half a minute):
		# this FireSystem's own copy of the tuning, config/fire.tres untouched.
		fire.tuning = fire.tuning.duplicate()
		fire.tuning.scorch_rate = 0.0
		fire.tuning.scorch_reach = 0.0
	# Which members show flames (FireSystem does it every half second), and their looks.
	fire._update_fx()
	fire._refresh_fx(1)


## Within 30 degrees of `ahead` from `eye`, 4 to 10 m off (the saloon fire's staging).
func _in_view(p: Vector3, eye: Vector3, ahead: Vector3) -> bool:
	var d := Vector3(p.x - eye.x, 0.0, p.z - eye.z)
	return d.length() > 4.0 and d.length() < 10.0 and d.normalized().dot(ahead) > cos(deg_to_rad(30.0))

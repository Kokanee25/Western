extends TestCase
## The painting's shot (ShotMatch): a man sat at the card table, leaning on it, the lamp lit.

func test_the_man_sits_at_the_table() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	var man := ShotMatch.stage(street)
	await physics_frames(60)
	var floor_y := man.global_position.y
	var pelvis := (man.parts[&"pelvis"] as Node3D).global_position.y - floor_y
	check(pelvis > 0.4 and pelvis < 0.65, "sat on the chair, not standing (pelvis %.2f m up)" % pelvis)
	var top := ShotMatch.TABLE_HEIGHT
	# The painting's pose: his right forearm along the table's edge, the cup in that hand.
	for sid: StringName in [&"hand_r", &"forearm_r"]:
		var h := (man.parts[sid] as Node3D).global_position.y - floor_y
		check(h > top - 0.02 and h < top + 0.25, "%s on the table (%.2f m, top %.2f)" % [sid, h, top])
	var cup := man.find_child("HeldCup", true, false) as Node3D
	check(cup != null and man.parts[&"hand_r"].is_ancestor_of(cup), "the cup's in his right hand")
	var lamp := street.find_child("TableLamp", true, false) as OilLamp
	check(lamp != null and lamp.lit, "the lamp's lit")
	var cam := ShotMatch.camera_transform(street)
	var to_man := (man.parts[&"head"] as Node3D).global_position - cam.origin
	check(rad_to_deg((-cam.basis.z).angle_to(to_man)) < 25.0, "and he's in the middle of the shot")
	street.queue_free()


func test_the_shot_keeps_its_lens_and_aim() -> void:
	# The gun in your hands drives the camera (kick, aim zoom); framed for the painting, it mustn't
	# pull the lens back to the game's 75° or level the view (every shot-match round before
	# 2026-09-29 was rendered at 75° this way).
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await physics_frames(5)
	var street := main.find_child("TestStreet", true, false) as Node3D
	var player := main.find_child("Player", true, false) as Player
	ShotMatch.stage(street)
	player.set_physics_process(false)
	await physics_frames(10)
	ShotMatch.frame_camera(player, street)
	var want := ShotMatch.camera_transform(street)
	await process_frames(60)
	check_near(player.camera.fov, ShotMatch.FOV, 0.01, "the painting's lens")
	var off := rad_to_deg((-player.camera.global_basis.z).angle_to(-want.basis.z))
	check(off < 0.1, "still looking where it was put (%.2f° off)" % off)
	main.queue_free()
	await process_frames(2)


func test_the_street_shot_looks_west_into_the_sun_with_the_gun_out() -> void:
	# The street painting's shot (StreetMatch): down the street toward the low sun, the near false
	# front on your left, the revolver in hand, the painting's lens held against the gun's pull.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await physics_frames(5)
	var street := main.find_child("TestStreet", true, false) as Node3D
	var player := main.find_child("Player", true, false) as Player
	var clock := street.find_child("DayCycle", true, false) as DayCycle
	clock.set_physics_process(false)
	clock.set_time(StreetMatch.HOUR)
	StreetMatch.stage(street)
	var gun := player.get_node(^"Head/Camera3D/Gun") as WeaponViewmodel
	gun.needs_captured_mouse = false
	gun.take_out()
	StreetMatch.frame_camera(player)
	await process_frames(60)
	check_near(player.camera.fov, StreetMatch.FOV, 0.01, "the painting's lens")
	var fwd := -player.camera.global_basis.z
	var sun := clock.get_sun_direction()
	check(sun.y > 0.05 and sun.y < 0.3, "the sun is low, about where the painting has it (%.2f up)" % sun.y)
	var to_sun := rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(Vector2(sun.x, sun.z)))
	check(absf(to_sun) < 25.0, "looking toward the sun (%.0f° off)" % to_sun)
	var store := street.find_child("Store", true, false) as Node3D
	var right := player.camera.global_basis.x
	check(right.dot(store.global_position + Vector3(3, 0, 0) - player.camera.global_position) < 0.0, "the store's on your left")
	check(gun.drawn and gun.visible, "the revolver's out")
	main.queue_free()
	await process_frames(2)

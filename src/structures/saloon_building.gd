class_name SaloonBuilding
extends FalseFrontBuilding
## The saloon: the same member-built false front as the store, bigger, with a bar, a back bar and
## a room full of props from assets/props/ (Meshy models, or placeholder boxes until they exist).
## This is the art test room: compare it with docs/concept/saloon-night.png.


func _init() -> void:
	width = 10.0
	depth = 12.0
	wall_height = 4.2
	front_height = 7.0
	sign_text = "SALOON"
	# A tall doorway and no porch roof over it, as the painting's: from the back of the room you
	# see the moonlit street and the moon through it (art).
	door_size = Vector2(1.5, 3.2)
	porch = false
	night_ambient = 0.035
	room_haze = 0.012


func _build_furniture() -> void:
	var f := floor_top
	# The bar along the right-hand wall.
	var bx0 := 7.55
	var bx1 := 8.25
	var bz0 := 3.0
	var bz1 := 9.5
	var bar_h := 1.08
	add_member("bar/front", &"furniture_frame", &"dark_trim", Vector3(0.04, bar_h, bz1 - bz0), Vector3(bx0 + 0.02, f + bar_h * 0.5, (bz0 + bz1) * 0.5))
	add_member("bar/end0", &"furniture_frame", &"dark_trim", Vector3(bx1 - bx0, bar_h, 0.04), Vector3((bx0 + bx1) * 0.5, f + bar_h * 0.5, bz0 + 0.02))
	add_member("bar/end1", &"furniture_frame", &"dark_trim", Vector3(bx1 - bx0, bar_h, 0.04), Vector3((bx0 + bx1) * 0.5, f + bar_h * 0.5, bz1 - 0.02))
	add_member("bar/top", &"furniture_top", &"dark_trim", Vector3(bx1 - bx0 + 0.14, 0.05, bz1 - bz0 + 0.1),
			Vector3((bx0 + bx1) * 0.5 - 0.05, f + bar_h + 0.025, (bz0 + bz1) * 0.5))
	add_member("bar/foot_rail", &"trim", &"dark_trim", Vector3(0.05, 0.05, bz1 - bz0 - 0.2), Vector3(bx0 - 0.025, f + 0.18, (bz0 + bz1) * 0.5))
	# Back bar: shelves against the right-hand wall, full of bottles.
	var sx0 := width - STUD_D - 0.4
	var sx1 := width - STUD_D
	for i in 3:
		add_member("backbar/upright%d" % i, &"furniture_frame", &"framing", Vector3(sx1 - sx0, 2.2, 0.04),
				Vector3((sx0 + sx1) * 0.5, f + 1.1, 3.6 + i * 2.6))
	var shelf_heights := [0.9, 1.45, 2.0]
	for i in shelf_heights.size():
		add_member("backbar/shelf%d" % i, &"furniture_top", &"floor", Vector3(sx1 - sx0, 0.03, 5.3),
				Vector3((sx0 + sx1) * 0.5, f + shelf_heights[i], 6.2))

	var props := get_node_or_null(^"Props")
	if props:
		props.free()
	props = Node3D.new()
	props.name = "Props"
	add_child(props)

	for i in 5:
		_place(props, &"bar_stool", Vector3(bx0 - 0.45, f, 3.8 + i * 1.3), 0.0)
	for i in shelf_heights.size():
		for j in 7:
			_place(props, &"whiskey_bottle", Vector3((sx0 + sx1) * 0.5, f + shelf_heights[i] + 0.015, 4.0 + j * 0.7 + i * 0.2), -90.0)
	_place(props, &"whiskey_bottle", Vector3(bx0 + 0.2, f + bar_h + 0.05, 5.1), 0.0)
	_place(props, &"tin_cup", Vector3(bx0 + 0.25, f + bar_h + 0.05, 5.5), 0.0)
	_place(props, &"oil_lamp", Vector3(bx0 + 0.3, f + bar_h + 0.05, 7.4), 0.0)
	_place(props, &"spittoon", Vector3(bx0 - 0.9, f, 5.8), 0.0)
	_place(props, &"spittoon", Vector3(bx0 - 0.9, f, 8.6), 0.0)

	# Two card tables with chairs, a lamp, a bottle and cups.
	for t: Vector3 in [Vector3(2.6, f, 4.2), Vector3(3.2, f, 8.2)]:
		_place(props, &"card_table", t, 15.0)
		for k in 4:
			var a := deg_to_rad(15.0 + 90.0 * k)
			var offset := Vector3(sin(a), 0.0, cos(a)) * 0.85
			_place(props, &"chair", t + offset, rad_to_deg(a) + 180.0)
		var top := t + Vector3(0.0, 0.76, 0.0)
		_place(props, &"oil_lamp", top + Vector3(0.1, 0.0, -0.1), 0.0)
		_place(props, &"whiskey_bottle", top + Vector3(-0.3, 0.0, 0.2), 0.0)
		_place(props, &"tin_cup", top + Vector3(0.35, 0.0, 0.25), 0.0)
		_place(props, &"tin_cup", top + Vector3(-0.2, 0.0, -0.35), 0.0)

	# Piano against the left wall, facing into the room; barrels in the back corner.
	_place(props, &"upright_piano", Vector3(STUD_D + 0.33, f, 10.4), 90.0)
	_place(props, &"barrel", Vector3(width - 0.9, f, depth - 0.9), 0.0)
	_place(props, &"barrel", Vector3(width - 1.6, f, depth - 0.8), 20.0)
	_place(props, &"barrel", Vector3(width - 0.95, f + 0.9, depth - 0.9), 45.0)

	# On the walls: the stag over the back wall, a painting, and lamps in sconces.
	_place(props, &"deer_head", Vector3(width * 0.5, f + 2.7, depth - STUD_D), 180.0)
	_place(props, &"framed_painting", Vector3(STUD_D, f + 2.2, 6.2), 90.0)
	for z: float in [2.4, 7.2]:
		_place(props, &"wall_sconce", Vector3(STUD_D, f + 1.9, z), 90.0)
	_place(props, &"wall_sconce", Vector3(width * 0.5 - 2.0, f + 1.9, depth - STUD_D), 180.0)
	_place(props, &"wall_sconce", Vector3(width * 0.5 + 2.0, f + 1.9, depth - STUD_D), 180.0)
	# Dressed as the painting has it (art: plank walls, stair and balcony, mirrors, piano by the door...).
	SaloonDressing.build(self)


## Put a prop at `pos` (building space) turned `yaw_degrees` about Y. Lamp props also get a light.
func _place(parent: Node3D, id: StringName, pos: Vector3, yaw_degrees: float) -> Node3D:
	var prop := PropLibrary.spawn(id)
	prop.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)), pos)
	parent.add_child(prop)
	var def := PropLibrary.definition(id)
	if def.has("light_height"):
		var lamp := OilLamp.new()
		lamp.name = "Light"
		lamp.show_mesh = false
		lamp.lit_from_hour = 17
		lamp.lit_until_hour = 4
		lamp.energy = 1.1
		lamp.light_range = 6.0
		var forward := 0.12 if def.get("anchor", "floor") == "wall" else 0.0
		lamp.position = Vector3(0.0, float(def["light_height"]) - 0.16, forward)
		prop.add_child(lamp)
	return prop

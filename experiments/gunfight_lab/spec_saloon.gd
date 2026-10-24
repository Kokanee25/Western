extends RefCounted
## The building lab's saloon (experiments/building_lab/, F5's eighth stop) as the gunfight lab's
## arena: built out in the desert west of town if it isn't yet, and its ways in and about joined
## into the town's places (Waypoints), so the gang can walk it: in at the door, round the bar,
## through to the kitchen and the back room, up the hall stair to the galleries, the rooms and out
## onto the street balcony. Without them a man can only walk where he can see (Waypoints: "straight
## to the nearest point he can reach, then along the links"), and the stair and the back rooms are
## out of his reach. The saloon itself is the building lab's, as built: nothing here changes it.
##
##   var SpecSaloon := preload("res://experiments/gunfight_lab/spec_saloon.gd")
##   var b: Node3D = SpecSaloon.ensure(street, town.places)   # the building (built the first time)
##   SpecSaloon.at(Vector3(7.62, 0.78, 2.0))                    # its own space -> the world's

const Play := preload("res://experiments/building_lab/play.gd")


## Its own space (x along the front from its west corner, z back from the front, y up from the
## ground; FORMAT.md) to the world's: it stands square to the street at Play.ORIGIN.
static func at(local: Vector3) -> Vector3:
	return Play.ORIGIN + local


## The building (built and its places added the first time; F5's stop builds the same one).
static func ensure(street: Node3D, places: Waypoints) -> Node3D:
	var b := street.get_node_or_null(^"SpecSaloon") as Node3D
	if b == null:
		b = Play.build(street)
	if places != null and not places.has(&"spec_door"):
		add_places(places)
	return b


## Its places (the building's own space; the floor 0.78, the upper floor 4.44; from the spec's
## rooms, doors, stairs and walking paths, saloon.json), joined to each other as a man walks between
## them and to the town's road out west.
static func add_places(w: Waypoints) -> void:
	var g := 0.78  # the ground floor's top
	var u := 4.44  # the upper floor's
	var p := func(x: float, y: float, z: float) -> Vector3: return at(Vector3(x, y, z))
	# Out front: the desert, the boardwalk's steps (at x 7.62), its walk, the door.
	w.add(&"spec_front", p.call(7.62, 0.0, -6.5), [&"west_edge"] if w.has(&"west_edge") else [])
	w.add(&"spec_front_w", p.call(2.0, 0.0, -6.0), [&"spec_front"])
	w.add(&"spec_front_e", p.call(13.5, 0.0, -6.0), [&"spec_front"])
	w.add(&"spec_steps", p.call(7.62, 0.0, -3.7), [&"spec_front"])
	w.add(&"spec_landing", p.call(7.62, g, -1.2), [&"spec_steps"])
	w.add(&"spec_walk_w", p.call(2.0, g, -1.2), [&"spec_landing"])
	w.add(&"spec_walk_e", p.call(13.5, g, -1.2), [&"spec_landing"])
	w.add(&"spec_door", p.call(7.62, g, 0.55), [&"spec_landing"])
	# The hall: in from the door, along the bar's front (the bar on the west, x 1.75), round the
	# tables, to the stair's foot.
	w.add(&"spec_hall", p.call(7.62, g, 2.4), [&"spec_door"])
	w.add(&"spec_bar_front_s", p.call(3.4, g, 3.4), [&"spec_hall"])
	w.add(&"spec_bar_front", p.call(3.3, g, 6.8), [&"spec_bar_front_s"])
	w.add(&"spec_bar_front_n", p.call(3.3, g, 10.4), [&"spec_bar_front"])
	w.add(&"spec_tables", p.call(9.8, g, 5.4), [&"spec_hall", &"spec_bar_front"])  # between the three tables
	w.add(&"spec_tables_back", p.call(9.6, g, 10.0), [&"spec_tables", &"spec_bar_front_n"])
	w.add(&"spec_hall_e", p.call(13.4, g, 2.2), [&"spec_hall"])  # past the near table's chairs
	w.add(&"spec_stair_foot", p.call(14.57, g, 5.3), [&"spec_hall_e"])
	# Round the bar's near end to behind it, and along behind it to the kitchen door.
	w.add(&"spec_bar_end", p.call(2.4, g, 1.6), [&"spec_hall", &"spec_bar_front_s"])
	w.add(&"spec_behind_bar_s", p.call(1.0, g, 2.2), [&"spec_bar_end"])
	w.add(&"spec_behind_bar", p.call(1.0, g, 6.8), [&"spec_behind_bar_s"])
	w.add(&"spec_behind_bar_n", p.call(1.0, g, 11.2), [&"spec_behind_bar"])
	# The kitchen (west, behind the bar) and the back room (east), each through its door in the
	# hall's back wall (z 12.19); the door between them; the back door to the yard. The cellar's
	# trap (x 2.24..3.24, z 12.29..14.53) stands open: the way goes round its far end.
	w.add(&"spec_kitchen_door", p.call(0.95, g, 12.2), [&"spec_behind_bar_n"])
	w.add(&"spec_kitchen", p.call(1.4, g, 15.4), [&"spec_kitchen_door"])
	w.add(&"spec_back_door", p.call(4.24, g, 16.7), [&"spec_kitchen"])
	w.add(&"spec_yard", p.call(4.24, 0.0, 19.2), [&"spec_back_door"])
	# Its door's leaf stands open into the hall on its west side (x 10.78), a gallery post just
	# south-west of it: the way in comes from the east, up the room past the stair.
	w.add(&"spec_hall_ne", p.call(13.2, g, 7.0), [&"spec_hall_e"])
	w.add(&"spec_back_room_hall", p.call(12.6, g, 11.5), [&"spec_hall_ne"])
	w.add(&"spec_back_room_front", p.call(11.24, g, 11.6), [&"spec_back_room_hall"])  # square to its door
	w.add(&"spec_back_room_door", p.call(11.24, g, 12.2), [&"spec_back_room_front"])
	w.add(&"spec_back_room", p.call(12.4, g, 14.6), [&"spec_back_room_door"])
	w.add(&"spec_kitchen_east", p.call(6.6, g, 14.64), [&"spec_kitchen"])
	w.add(&"spec_back_room_west", p.call(8.6, g, 14.64), [&"spec_back_room", &"spec_kitchen_east"])
	# Up the hall stair (x 14.06..15.08, climbing north from z 6.0 to its head on the back gallery at
	# z 10.57) to the galleries round the well: back (z 10.57..12.19), west (x 3.66..5.49), front
	# (z 0.1..1.93).
	w.add(&"spec_stair_head", p.call(14.57, u, 11.1), [&"spec_stair_foot"])
	w.add(&"spec_gallery_back_e", p.call(12.6, u, 11.4), [&"spec_stair_head"])
	w.add(&"spec_gallery_back", p.call(8.0, u, 11.4), [&"spec_gallery_back_e"])
	w.add(&"spec_gallery_back_w", p.call(4.6, u, 11.3), [&"spec_gallery_back"])
	w.add(&"spec_gallery_west", p.call(4.6, u, 6.2), [&"spec_gallery_back_w"])
	w.add(&"spec_gallery_front_w", p.call(4.7, u, 1.1), [&"spec_gallery_west"])
	w.add(&"spec_gallery_front", p.call(9.7, u, 1.1), [&"spec_gallery_front_w"])
	w.add(&"spec_gallery_front_e", p.call(14.5, u, 1.1), [&"spec_gallery_front"])
	# The rooms off the galleries: 1 to 3 over the back rooms (doors at x 12.6, 7.52, 4.24 in z 12.19),
	# 4 and 5 over the bar (doors at z 4.23 and 7.93 in x 3.66).
	w.add(&"spec_room_1", p.call(12.6, u, 13.6), [&"spec_gallery_back_e"])
	w.add(&"spec_room_2", p.call(7.52, u, 13.6), [&"spec_gallery_back"])
	w.add(&"spec_room_3", p.call(4.24, u, 13.6), [&"spec_gallery_back_w"])
	w.add(&"spec_room_4", p.call(2.4, u, 4.23), [&"spec_gallery_west"])
	w.add(&"spec_room_5", p.call(2.4, u, 7.93), [&"spec_gallery_west"])
	# Out onto the street balcony by its door at x 4.88.
	w.add(&"spec_balcony_door", p.call(4.88, u, 0.0), [&"spec_gallery_front_w"])
	w.add(&"spec_balcony", p.call(4.88, u, -1.3), [&"spec_balcony_door"])
	w.add(&"spec_balcony_w", p.call(1.2, u, -1.3), [&"spec_balcony"])
	w.add(&"spec_balcony_e", p.call(12.0, u, -1.3), [&"spec_balcony"])

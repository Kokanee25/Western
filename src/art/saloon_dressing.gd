class_name SaloonDressing
## The saloon dressed as the painting has it (docs/concept/saloon-night.png): plank walls stained
## dark by lamp smoke, a stair up the front wall to a balcony in the corner over the bar's end,
## mirrors behind the back bar, more bottles on its shelves, a piano by the door, the stag over the
## door with pictures beside it, and lamps in sconces round the walls. Called by SaloonBuilding at
## the end of its furnishing. Lit like the painting's room: two dozen lamps in sconces round the
## walls, on the back bar and hanging over the bar, a back bar packed with bottles in front of a tall
## mirror (a reflection probe gives it the room to show). Everything structural is a member (it burns, breaks, falls and is
## saved like the rest of the building); loose things are PropLibrary props in its Props node.
##
## Saloon space (FalseFrontBuilding): the front wall's inside face is z = STUD_D, the side walls'
## x = STUD_D and width - STUD_D; the floor's top is floor_top. The door (door_rect) is in the middle
## of the front, the bar runs along the right-hand wall (x ~ 7.5-8.3, z 3-9.5), the back bar behind it.
## The stair and balcony keep clear of the walk from the door to the bar's end and behind it.

## The balcony: its floor's top above the room's floor, and its corner (x from BALCONY_X to the
## right-hand wall, z from the front wall to BALCONY_Z).
## The wall sconces' light: each throws a bright pool on the wall round itself and little further
## (the painting's room: a dozen lamps, each lighting its own patch of planks), so a steep
## falloff (2, the inverse square) at more energy than a lamp that lights a room
## (the blind critic's first point, 2026-10-05: "a dozen lamps each lighting its own patch of
## wall"; ours were wide and dim, a brown wash with flames floating in it).
const SCONCE_ENERGY := 1.0
const SCONCE_FALLOFF := 2.0
const SCONCE_REACH := 4.0
const BALCONY_HEIGHT := 2.3
const BALCONY_X := 8.4
const BALCONY_Z := 1.9
## The stair: 12 risers up the front wall from the door side to the balcony's edge.
const RISERS := 12
const TREAD := 0.22
const STAIR_WIDTH := 0.9
## Plank walls: boards this wide, up to the wall plates.
const PANEL_WIDTH := 0.3


static func build(s: FalseFrontBuilding) -> void:
	var f := s.floor_top
	_panelling(s, f)
	_balcony(s, f)
	_stair(s, f)
	_mirrors(s, f)
	_bottle_wall(s, f)
	var props := s.get_node_or_null(^"Props") as Node3D
	if props:
		_props(s, props, f)
		_lamps(s, props, _fresh(s, "Lamps"), f)
	_reflections(s, f)


## A new empty node under the saloon by this name (an old one from an earlier build gone).
static func _fresh(s: FalseFrontBuilding, name: String) -> Node3D:
	var old := s.get_node_or_null(NodePath(name))
	if old:
		old.free()
	var n := Node3D.new()
	n.name = name
	s.add_child(n)
	return n


# --- plank walls -------------------------------------------------------------------------------

## Vertical boards on the inside of every wall (the saloon_wall texture: rough pine stained dark),
## stopping at doors and windows.
static func _panelling(s: FalseFrontBuilding, f: float) -> void:
	var w := s.width
	var d := s.depth
	var sd := FalseFrontBuilding.STUD_D
	var top := s.wall_height - FalseFrontBuilding.PLATE_H
	var t := 0.02
	var door := s.door_rect
	# [name, from, along, inward normal, length, openings (along, y rects)]
	var walls := [
		["front", Vector3(0, 0, sd), Vector3.RIGHT, Vector3.BACK, w,
				[door, Rect2(0.55, 1.05, 1.1, 1.35), Rect2(w - 1.65, 1.05, 1.1, 1.35)]],
		["left", Vector3(sd, 0, 0), Vector3.BACK, Vector3.RIGHT, d, []],
		["right", Vector3(w - sd, 0, 0), Vector3.BACK, Vector3.LEFT, d, [Rect2(d * 0.55 - 0.5, 1.2, 1.0, 1.0)]],
		["back", Vector3(0, 0, d - sd), Vector3.RIGHT, Vector3.FORWARD, w, [Rect2(w * 0.5 - 0.4, 1.3, 0.8, 0.8)]],
	]
	for wall in walls:
		var name: String = wall[0]
		var origin: Vector3 = wall[1]
		var along: Vector3 = wall[2]
		var inward: Vector3 = wall[3]
		var length: float = wall[4]
		var openings: Array = wall[5]
		var x := sd
		var i := 0
		while x < length - sd - 0.01:
			var x1 := minf(x + PANEL_WIDTH, length - sd)
			var spans := [[f, top]]
			for o: Rect2 in openings:
				if x1 > o.position.x and x < o.end.x:
					var cut := []
					for sp in spans:
						if o.position.y > sp[0]:
							cut.append([sp[0], minf(sp[1], o.position.y)])
						if o.end.y < sp[1]:
							cut.append([maxf(sp[0], o.end.y), sp[1]])
					spans = cut
			for sp in spans:
				if sp[1] - sp[0] < 0.05:
					continue
				var c: Vector3 = origin + along * ((x + x1) * 0.5) + Vector3.UP * ((sp[0] + sp[1]) * 0.5) + inward * (t * 0.5)
				var size: Vector3 = along.abs() * (x1 - x - 0.004) + Vector3(0, sp[1] - sp[0], 0) + inward.abs() * t
				s.add_member("panel/%s/%02d_%d" % [name, i, int(sp[0] * 10)], &"board", &"saloon_wall", size, c)
			x = x1
			i += 1


# --- the balcony and stair ---------------------------------------------------------------------

static func _balcony(s: FalseFrontBuilding, f: float) -> void:
	var w := s.width
	var sd := FalseFrontBuilding.STUD_D
	var y := f + BALCONY_HEIGHT
	var x0 := BALCONY_X
	var x1 := w - sd
	var z0 := sd
	var z1 := BALCONY_Z
	# Posts at the beam's ends (the open corner and against the wall), down through the floor to
	# the ground like the porch posts; the beam on them; a ledger nailed along the front wall's
	# studs; the joists from the ledger to the beam.
	for p in [[x0 + 0.06, "corner"], [x1 - 0.06, "wall"]]:
		s.add_member("balcony/post_%s" % p[1], &"post", &"dark_trim", Vector3(0.12, y - 0.33, 0.12), Vector3(p[0], (y - 0.33) * 0.5, z1 - 0.06))
	s.add_member("balcony/beam", &"beam", &"dark_trim", Vector3(x1 - x0, 0.15, 0.12), Vector3((x0 + x1) * 0.5, y - 0.255, z1 - 0.06))
	# (reaching back past the corner, so it's nailed to at least three studs)
	s.add_member("balcony/ledger", &"ledger", &"framing", Vector3(x1 - x0 + 0.6, 0.15, 0.05), Vector3((x0 + x1) * 0.5 - 0.3, y - 0.255, z0 + 0.025))
	var jx := x0 + 0.04
	var j := 0
	while jx < x1 - 0.02:
		s.add_member("balcony/joist/%02d" % j, &"rafter", &"framing", Vector3(0.05, 0.15, z1 - z0), Vector3(jx, y - 0.105, (z0 + z1) * 0.5))
		jx += 0.4
		j += 1
	s.add_member("balcony/joist/%02d" % j, &"rafter", &"framing", Vector3(0.05, 0.15, z1 - z0), Vector3(x1 - 0.025, y - 0.105, (z0 + z1) * 0.5))
	# Floor boards across the joists (along x).
	var bz := z0
	var b := 0
	while bz < z1 - 0.01:
		var bw := minf(0.15, z1 - bz)
		s.add_member("balcony/board/%02d" % b, &"furniture_top", &"floor", Vector3(x1 - x0, 0.03, bw - 0.004), Vector3((x0 + x1) * 0.5, y - 0.015, bz + bw * 0.5))
		bz += bw
		b += 1
	# The rail: balusters on the floor's edge along both open sides, a cap rail on them.
	_rail(s, "balcony/rail_x", Vector3(x0 + 0.03, y, STAIR_WIDTH + sd + 0.04), Vector3(x0 + 0.03, y, z1 - 0.03))
	_rail(s, "balcony/rail_z", Vector3(x0 + 0.03, y, z1 - 0.03), Vector3(x1 - 0.04, y, z1 - 0.03))


## Balusters every 0.15 m from a to b (on a floor at a.y), and a cap rail on top of them.
static func _rail(s: FalseFrontBuilding, id: String, a: Vector3, b: Vector3) -> void:
	var height := 0.95
	var n := maxi(1, int(a.distance_to(b) / 0.15))
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		s.add_member("%s/baluster/%02d" % [id, k], &"trim", &"dark_trim", Vector3(0.035, height - 0.05, 0.035), p + Vector3.UP * ((height - 0.05) * 0.5))
	var mid := (a + b) * 0.5 + Vector3.UP * (height - 0.025)
	var along := (b - a)
	var size := Vector3(absf(along.x) + 0.08, 0.05, absf(along.z) + 0.08)
	s.add_member("%s/cap" % id, &"trim", &"dark_trim", size, mid)


static func _stair(s: FalseFrontBuilding, f: float) -> void:
	var sd := FalseFrontBuilding.STUD_D
	var rise := BALCONY_HEIGHT / RISERS
	var x_top := BALCONY_X
	var x_bottom := x_top - (RISERS - 1) * TREAD
	var z_in := sd - 0.01  # the inner stringer in against the studs (it's nailed to them)
	var z_out := sd + STAIR_WIDTH
	# Stringers from the floor at the bottom to the balcony's edge at the top.
	var a := Vector3(x_bottom - TREAD, f, 0)
	var b := Vector3(x_top, f + BALCONY_HEIGHT, 0)
	var length := Vector2(b.x - a.x, b.y - a.y).length()
	var angle := atan2(b.y - a.y, b.x - a.x)
	var basis := Basis(Vector3.BACK, angle)
	for side in [[z_in + 0.025, "in"], [z_out - 0.025, "out"]]:
		var c := (a + b) * 0.5 + Vector3(0.0, -0.06, side[0])
		s.add_member("stair/stringer_%s" % side[1], &"rafter", &"dark_trim", Vector3(length, 0.26, 0.05), c, basis)
	# Treads.
	for i in RISERS - 1:
		var x := x_bottom + (i - 0.5) * TREAD
		var top := f + (i + 1) * rise
		s.add_member("stair/tread/%02d" % i, &"furniture_top", &"floor", Vector3(TREAD + 0.02, 0.035, STAIR_WIDTH - 0.02),
				Vector3(x + TREAD * 0.5, top - 0.0175, (z_in + z_out) * 0.5))
	# A newel post at the foot and balusters up the open side, a hand rail along them.
	s.add_member("stair/newel", &"furniture_frame", &"dark_trim", Vector3(0.09, 1.05, 0.09), Vector3(x_bottom - TREAD + 0.05, f + 0.525, z_out + 0.045))
	for i in RISERS - 1:
		var x := x_bottom + (i - 0.5) * TREAD + TREAD * 0.5
		var top := f + (i + 1) * rise
		s.add_member("stair/baluster/%02d" % i, &"trim", &"dark_trim", Vector3(0.03, 0.9, 0.03), Vector3(x, top + 0.45, z_out - 0.03))
	var ra := Vector3(x_bottom - TREAD + 0.05, f + 1.05, z_out - 0.03)
	var rb := Vector3(x_top, f + BALCONY_HEIGHT + 0.95, z_out - 0.03)
	var rl := Vector2(rb.x - ra.x, rb.y - ra.y).length()
	s.add_member("stair/hand_rail", &"trim", &"dark_trim", Vector3(rl, 0.05, 0.06), (ra + rb) * 0.5,
			Basis(Vector3.BACK, atan2(rb.y - ra.y, rb.x - ra.x)))
	# Something to walk up: a ramp under the treads (the player's controller doesn't climb steps).
	var ramp := StaticBody3D.new()
	ramp.name = "StairRamp"
	ramp.collision_layer = Layers.WORLD
	ramp.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.05, STAIR_WIDTH)
	shape.shape = box
	ramp.add_child(shape)
	s.add_child(ramp)
	ramp.transform = Transform3D(basis, (a + b) * 0.5 + Vector3(0, 0.0, (z_in + z_out) * 0.5))


# --- the back bar's mirrors --------------------------------------------------------------------

## Two mirrors on the right-hand wall behind the back bar's shelves, either side of its window,
## in dark frames: glass members (a shot breaks them) with a mirror's finish. Tall, as the
## painting's: the bottles stand in front of their lower half, the room shows in the top.
const MIRROR_TOP := 2.95
static func _mirrors(s: FalseFrontBuilding, f: float) -> void:
	var w := s.width
	var x := w - FalseFrontBuilding.STUD_D - 0.025
	var y0 := f + 1.0
	var y1 := f + MIRROR_TOP
	for m in [[3.8, 5.95, "a"], [7.25, 8.7, "b"]]:
		var z0: float = m[0]
		var z1: float = m[1]
		var glass := s.add_member("backbar/mirror_%s" % m[2], &"glass", &"glass", Vector3(0.01, y1 - y0, z1 - z0), Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5))
		(glass.get_child(0) as MeshInstance3D).material_override = mirror_material()
		for e in [[z0 - 0.04, z0], [z1, z1 + 0.04]]:
			s.add_member("backbar/mirror_%s/side_%d" % [m[2], int(e[0] * 10)], &"trim", &"dark_trim", Vector3(0.03, y1 - y0 + 0.08, 0.04), Vector3(x - 0.005, (y0 + y1) * 0.5, (e[0] + e[1]) * 0.5))
		s.add_member("backbar/mirror_%s/top" % m[2], &"trim", &"dark_trim", Vector3(0.04, 0.08, z1 - z0 + 0.12), Vector3(x - 0.01, y1 + 0.04, (z0 + z1) * 0.5))


static func mirror_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.42, 0.3)
	m.metallic = 1.0
	m.roughness = 0.18
	return m


## The room as the mirrors (and brass, glass and tin) see it: one probe the size of the room,
## taken once (the lamps are lit by the time it's drawn at night; by day it shows the day).
static func _reflections(s: FalseFrontBuilding, f: float) -> void:
	var old := s.get_node_or_null(^"RoomReflections")
	if old:
		old.free()
	var probe := ReflectionProbe.new()
	probe.name = "RoomReflections"
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.interior = true
	probe.box_projection = true
	probe.size = Vector3(s.width - 0.2, s.wall_height - 0.1, s.depth - 0.2)
	probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	probe.intensity = 1.0
	probe.max_distance = 20.0
	s.add_child(probe)
	probe.position = Vector3(s.width * 0.5, f + (s.wall_height - 0.1) * 0.5, s.depth * 0.5)


# --- the back bar's bottles --------------------------------------------------------------------

## The back bar packed with bottles, as the painting's: two staggered rows on every shelf, the
## glass, heights and labels mixed. Scenery, drawn as one mesh per kind of glass (a few hundred
## bottles as props would be a few hundred bodies); the bar's own PropLibrary bottles stay the
## ones a bullet can hit.
static func _bottle_wall(s: FalseFrontBuilding, f: float) -> void:
	var w := s.width
	var sd := FalseFrontBuilding.STUD_D
	var rng := RandomNumberGenerator.new()
	rng.seed = 1882
	var tools := {}
	var root := _fresh(s, "BottleWall")
	for shelf in [0.9, 1.45, 2.0]:
		for row in 2:
			# In front of and behind the PropLibrary bottles (x 9.7).
			var x: float = w - sd - 0.35 + row * 0.25
			var z := 3.66 + row * 0.04
			while z < 8.78:
				var v := rng.randi_range(0, 2)
				var squat := rng.randf() < 0.2
				var sy := rng.randf_range(0.7, 0.8) if squat else rng.randf_range(0.88, 1.12)
				var sxz := rng.randf_range(1.05, 1.2) if squat else rng.randf_range(0.85, 1.0)
				var xf := Transform3D(Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3(sxz, sy, sxz)),
						Vector3(x + rng.randf_range(-0.012, 0.012), f + shelf + 0.015, z))
				_add_bottle(tools, v, xf)
				z += 0.09 * sxz + rng.randf_range(0.0, 0.02)
				# Now and then a gap.
				if rng.randf() < 0.05:
					z += 0.1
	for key: String in tools:
		var st: SurfaceTool = tools[key][0]
		var mi := MeshInstance3D.new()
		mi.name = key
		mi.mesh = st.commit()
		mi.material_override = tools[key][1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)


## One bottle's pieces (PropModels.bottle) added into the merged meshes, by material.
static func _add_bottle(tools: Dictionary, variant: int, xf: Transform3D) -> void:
	var model := Node3D.new()
	PropModels.bottle(model, variant)
	for mi: MeshInstance3D in model.get_children():
		var mat := mi.material_override
		var key := "%s_%s" % [mi.name, mat.resource_name if mat.resource_name != "" else str(mat.get_instance_id())]
		if not tools.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = [st, mat]
		(tools[key][0] as SurfaceTool).append_from(mi.mesh, 0, xf * mi.transform)
	model.free()


# --- loose things ------------------------------------------------------------------------------

static func _props(s: FalseFrontBuilding, props: Node3D, f: float) -> void:
	var w := s.width
	var d := s.depth
	var sd := FalseFrontBuilding.STUD_D
	# More bottles on the back bar, between the ones already there.
	var shelf_heights := [0.9, 1.45, 2.0]
	for i in shelf_heights.size():
		for j in 7:
			_place(s, props, &"whiskey_bottle", Vector3(w - sd - 0.2, f + shelf_heights[i] + 0.015, 4.35 + j * 0.7 + i * 0.2), -90.0)
	# The piano against the front wall between its left window and the door, a stool before it,
	# a lamp on top.
	var piano_at := Vector3(2.95, f, sd + 0.4)
	_place(s, props, &"upright_piano", piano_at, 0.0)
	_place(s, props, &"bar_stool", piano_at + Vector3(0.0, 0.0, 0.75), 0.0)
	_place(s, props, &"oil_lamp", piano_at + Vector3(-0.55, 1.3, -0.05), 0.0)
	# The stag on the front wall over the stair, pictures beside the door and on the left-hand
	# wall, and lamps in sconces round the walls.
	_place(s, props, &"deer_head", Vector3(6.7, f + 3.05, sd + 0.02), 0.0)
	_place(s, props, &"framed_painting", Vector3(w * 0.5 - 1.9, f + 2.6, sd + 0.02), 0.0)
	_place(s, props, &"framed_painting", Vector3(sd + 0.02, f + 2.3, 3.5), 90.0)
	for p in [[Vector3(w * 0.5 - 0.95, f + 2.0, sd + 0.02), 0.0], [Vector3(2.0, f + 2.1, sd + 0.02), 0.0],
			[Vector3(w - sd - 0.02, f + 2.55, 3.3), -90.0], [Vector3(w - sd - 0.02, f + 2.55, 9.0), -90.0],
			[Vector3(w - 0.8, f + BALCONY_HEIGHT + 1.5, sd + 0.02), 0.0], [Vector3(sd + 0.02, f + 1.9, d - 2.4), 90.0]]:
		var sconce := _place(s, props, &"wall_sconce", p[0], p[1])
		var light := sconce.get_node_or_null(^"Light") as OilLamp if sconce else null
		if light:
			light.energy = SCONCE_ENERGY
			light.attenuation = SCONCE_FALLOFF
			light.set_meta(&"lamp_group", &"sconce")



## The painting's room glows with lamps: sconces round every wall (two flanking the tall mirror,
## one over the back bar's window), lamps standing on the back bar's top shelf, lamps hung over the
## bar and the room. Each dimmer than one lamp on its own, with its halo in the smoke, no shadows
## (two dozen shadowed lights would be slow, and the room's few big ones already cast them). The
## sconces are props (Props); the lamps on the back bar and the hung ones go in `lamps`.
static func _lamps(s: FalseFrontBuilding, props: Node3D, lamps: Node3D, f: float) -> void:
	var w := s.width
	var d := s.depth
	var sd := FalseFrontBuilding.STUD_D
	var rx := w - sd - 0.02
	var sconces := [
		# The right-hand wall: by the balcony, either side of the mirror, over the window, by the far mirror.
		[Vector3(rx, f + 2.85, 2.55), -90.0], [Vector3(rx, f + 2.6, 3.45), -90.0], [Vector3(rx, f + 2.6, 6.3), -90.0],
		[Vector3(rx, f + 2.6, 6.95), -90.0], [Vector3(rx, f + 2.6, 9.4), -90.0], [Vector3(rx, f + BALCONY_HEIGHT + 1.35, 1.2), -90.0],
		# The front wall right of the door, over the stair.
		[Vector3(s.door_rect.end.x + 0.45, f + 2.2, sd + 0.02), 0.0],
		# The left-hand wall and the back.
		[Vector3(sd + 0.02, f + 2.1, 2.2), 90.0], [Vector3(sd + 0.02, f + 2.1, 5.6), 90.0], [Vector3(sd + 0.02, f + 2.1, 7.9), 90.0],
		[Vector3(2.4, f + 2.1, d - sd - 0.02), 180.0], [Vector3(6.8, f + 2.1, d - sd - 0.02), 180.0],
	]
	for p in sconces:
		var sconce := _lit_prop(s, props, &"wall_sconce", p[0], p[1], SCONCE_ENERGY, SCONCE_REACH)
		(sconce.get_node(^"Light") as OilLamp).attenuation = SCONCE_FALLOFF
	# On the back bar's top shelf, among the bottles.
	for z in [4.45, 5.55, 7.95]:
		var lamp := OilLamp.new()
		lamp.name = "BackBarLamp"
		lamp.set_meta(&"lamp_group", &"back_bar")
		lamp.lit_from_hour = 17
		lamp.lit_until_hour = 4
		lamp.energy = 0.45
		lamp.light_range = 3.5
		lamp.haze = 1.2
		lamp.casts_shadows = false
		lamps.add_child(lamp)
		lamp.position = Vector3(w - sd - 0.2, f + 2.0 + 0.015, z)
	# Hung from the rafters on rods: over the bar, over the room.
	for p in [Vector3(8.1, f + 2.55, 4.4), Vector3(8.1, f + 2.55, 7.6), Vector3(4.6, f + 2.75, 5.2), Vector3(3.6, f + 2.75, 9.0)]:
		_hanging_lamp(s, lamps, p)


## A prop with its lamp's light (PropLibrary's "light_height"), the light set up before it's lit.
static func _lit_prop(s: FalseFrontBuilding, props: Node3D, id: StringName, pos: Vector3, yaw: float, energy: float, reach: float) -> Node3D:
	var prop := PropLibrary.spawn(id)
	prop.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), pos)
	var def := PropLibrary.definition(id)
	var lamp := OilLamp.new()
	lamp.name = "Light"
	lamp.set_meta(&"lamp_group", &"sconce")
	lamp.show_mesh = false
	lamp.lit_from_hour = 17
	lamp.lit_until_hour = 4
	lamp.energy = energy
	lamp.light_range = reach
	lamp.haze = 1.2
	lamp.casts_shadows = false
	var forward := 0.12 if def.get("anchor", "floor") == "wall" else 0.0
	lamp.position = Vector3(0.0, float(def.get("light_height", 0.2)) - 0.16, forward)
	prop.add_child(lamp)
	props.add_child(prop)
	# The prop's own chimney glows with the lamp (the light's own lamp model is hidden).
	var chimney := prop.find_child("Chimney", true, false) as MeshInstance3D
	if chimney:
		lamp._chimney = chimney
		lamp.set_lit(lamp.lit)
	return prop


## A lamp hung on a rod from the roof: its font in a brass ring, a tin shade over the chimney.
static func _hanging_lamp(s: FalseFrontBuilding, parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "HangingLamp"
	parent.add_child(root)
	root.position = at
	var lamp := OilLamp.new()
	lamp.name = "Light"
	lamp.set_meta(&"lamp_group", &"hung")
	lamp.lit_from_hour = 17
	lamp.lit_until_hour = 4
	lamp.energy = 0.6
	lamp.light_range = 5.0
	lamp.haze = 1.2
	lamp.casts_shadows = false
	root.add_child(lamp)
	var brass := PropModels.lamp_brass()
	PropModels._add(root, "Ring", PropModels.lathe(PropModels._profile([[0.085, 0.07], [0.09, 0.08], [0.085, 0.09]]), 12), brass)
	for k in 3:
		var a := TAU * k / 3.0
		PropModels._stick(root, Vector3(cos(a) * 0.085, 0.08, sin(a) * 0.085), Vector3(0, 0.5, 0), 0.008, brass)
	PropModels._add(root, "Shade", PropModels.lathe(PropModels._profile([[0.2, 0.42], [0.12, 0.47], [0.05, 0.5], [0.03, 0.5]]), 14), PropModels.tin())
	PropModels._add(root, "ShadeUnder", PropModels.lathe(PropModels._profile([[0.2, 0.42], [0.12, 0.47], [0.05, 0.5]]), 14, false, true), PropModels.tin())
	var top := s.wall_height - 0.05
	PropModels._box(root, "Rod", Vector3(0.012, top - at.y - 0.5, 0.012), Vector3(0, 0.5 + (top - at.y - 0.5) * 0.5, 0), brass)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _place(s: FalseFrontBuilding, props: Node3D, id: StringName, pos: Vector3, yaw: float) -> Node3D:
	return s.call(&"_place", props, id, pos, yaw) if s.has_method(&"_place") else null

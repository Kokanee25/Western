class_name TrainView
extends Node3D
## The train drawn as boxes on trucks, and the same boxes as moving solids (docs/briefs/train.md,
## steps 1 and 2; the models are step 3). Each car's two trucks stand on the track at their own
## distance, so the car's body is the chord between them and swings through a bend as a real one
## does; the trucks turn under it.
##
## The drawn cars (`bodies`) are placed every frame between ticks (`place(frac)`), so they move
## smoothly at any frame rate; the solids (`solids`, an AnimatableBody3D a car on the world's layer)
## are placed on the physics tick (`place_solids()`), so they shove crates and men, carry whoever
## stands on them (the player rides, crosses car to car, jumps off) and stop bullets. The shapes of
## both come from one list (TrainCars), so what you see is what you stand on.
## A child of the TrackLine (its space).

var sim: TrainSim
var track: TrackLine
var bodies: Array[Node3D] = []
var solids: Array[AnimatableBody3D] = []
var trucks: Array[Node3D] = []  # two a car
## Make the solids (off for the headless scenario tests that only draw).
var with_solids := true

var _mats := {}


func _mat(colour: Color) -> StandardMaterial3D:
	var key := colour.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = 0.85
		m.cull_mode = BaseMaterial3D.CULL_DISABLED  # the pilot's hull is wound by hand
		_mats[key] = m
	return _mats[key]


func setup(on_track: TrackLine, train_sim: TrainSim) -> void:
	track = on_track
	sim = train_sim
	for c in get_children():
		c.free()
	bodies.clear()
	solids.clear()
	trucks.clear()
	var t := sim.tuning
	for i in sim.cars.size():
		var car: Dictionary = sim.cars[i]
		var body := Node3D.new()
		body.name = String(car.name).capitalize().replace(" ", "")
		add_child(body)
		bodies.append(body)
		var solid: AnimatableBody3D = null
		if with_solids:
			solid = AnimatableBody3D.new()
			solid.name = body.name + "Solid"
			solid.sync_to_physics = true
			solid.collision_layer = Layers.WORLD
			solid.collision_mask = 0
			solid.set_meta(&"train_car", i)
			solid.set_meta(&"surface", &"metal" if car.kind in [&"engine", &"tender"] else &"wood")
			add_child(solid)
			solids.append(solid)
		for sh: Dictionary in TrainCars.shapes(car, t):
			if sh.get("drawn", true):
				_draw_shape(body, sh)
			if solid and sh.solid:
				_solid_shape(solid, sh)
		for w in 2:
			var truck := Node3D.new()
			truck.name = "%sTruck%d" % [body.name, w]
			add_child(truck)
			_draw_shape(truck, TrainCars.truck_shape(t))
			trucks.append(truck)


func _draw_shape(parent: Node3D, sh: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	if sh.has("hull"):
		mi.mesh = _hull_mesh(sh.hull)
	elif sh.has("cylinder"):
		var cyl := CylinderMesh.new()
		cyl.top_radius = sh.radius
		cyl.bottom_radius = sh.radius
		cyl.height = sh.height
		mi.mesh = cyl
		mi.rotation_degrees = Vector3(90, 0, 0)
	else:
		var b := BoxMesh.new()
		b.size = sh.size
		mi.mesh = b
	mi.material_override = _mat(sh.colour)
	if not sh.has("hull"):
		mi.position = sh.at
	parent.add_child(mi)


func _solid_shape(solid: AnimatableBody3D, sh: Dictionary) -> void:
	var cs := CollisionShape3D.new()
	if sh.has("hull"):
		var cp := ConvexPolygonShape3D.new()
		cp.points = sh.hull
		cs.shape = cp
	elif sh.has("cylinder"):
		var c := CylinderShape3D.new()
		c.radius = sh.radius
		c.height = sh.height
		cs.shape = c
		cs.rotation_degrees = Vector3(90, 0, 0)
		cs.position = sh.at
	else:
		var b := BoxShape3D.new()
		b.size = sh.size
		cs.shape = b
		if sh.has("basis"):
			cs.basis = sh.basis
		cs.position = sh.at
	solid.add_child(cs)


## A convex hull of eight points (a box's corners in the order TrainCars gives them) as a mesh.
func _hull_mesh(p: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Corners: 0..3 the front face (-x low, +x low, -x high, +x high), 4..7 the back face.
	for q in [[0, 1, 3, 2], [5, 4, 6, 7], [4, 0, 2, 6], [1, 5, 7, 3], [2, 3, 7, 6], [4, 5, 1, 0]]:
		st.add_vertex(p[q[0]])
		st.add_vertex(p[q[1]])
		st.add_vertex(p[q[2]])
		st.add_vertex(p[q[0]])
		st.add_vertex(p[q[2]])
		st.add_vertex(p[q[3]])
	st.generate_normals()
	return st.commit()


## Where car i's body stands (between its trucks) with the train `frac` of the way through the tick.
func car_transform(i: int, frac := 1.0) -> Transform3D:
	var f0 := track.transform_at(sim.truck_s(i, 0, frac))
	var f1 := track.transform_at(sim.truck_s(i, 1, frac))
	var fwd := (f0.origin - f1.origin).normalized()
	var up := (f0.basis.y + f1.basis.y).normalized()
	return Transform3D(Basis.looking_at(fwd, up), (f0.origin + f1.origin) * 0.5)


## Stand every drawn car on the track, `frac` of the way from a tick ago to now.
func place(frac := 1.0) -> void:
	for i in sim.cars.size():
		trucks[i * 2].transform = track.transform_at(sim.truck_s(i, 0, frac))
		trucks[i * 2 + 1].transform = track.transform_at(sim.truck_s(i, 1, frac))
		bodies[i].transform = car_transform(i, frac)


## The solids where the cars are now (on the physics tick).
func place_solids() -> void:
	for i in solids.size():
		solids[i].transform = car_transform(i, 1.0)

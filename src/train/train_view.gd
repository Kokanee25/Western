class_name TrainView
extends Node3D
## The train drawn as boxes on trucks (docs/briefs/train.md, step 1; the models are step 3). Each
## car's two trucks stand on the track at their own distance, so the car's body is the chord
## between them and swings through a bend as a real one does; the trucks turn under it.
## A child of the TrackLine (its space). `place(s)` with the train's front at s.

var sim: TrainSim
var track: TrackLine
var bodies: Array[Node3D] = []
var trucks: Array[Node3D] = []  # two a car

var _mats := {}


func _mat(colour: Color) -> StandardMaterial3D:
	var key := colour.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = 0.85
		_mats[key] = m
	return _mats[key]


func setup(on_track: TrackLine, train_sim: TrainSim) -> void:
	track = on_track
	sim = train_sim
	for c in get_children():
		c.free()
	bodies.clear()
	trucks.clear()
	var t := sim.tuning
	for i in sim.cars.size():
		var car: Dictionary = sim.cars[i]
		var body := Node3D.new()
		body.name = String(car.name).capitalize().replace(" ", "")
		add_child(body)
		bodies.append(body)
		# The body's middle sits this far behind its trucks' middle.
		var tr: Vector2 = car.trucks
		var back: float = float(car.length) * 0.5 - (tr.x + tr.y) * 0.5
		match car.name:
			&"engine":
				_box(body, Vector3(1.9, 0.5, car.length), Vector3(0, 0.75, back), Color(0.13, 0.12, 0.12))  # frame
				var boiler := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.62
				cyl.bottom_radius = 0.62
				cyl.height = car.length * 0.62
				boiler.mesh = cyl
				boiler.material_override = _mat(Color(0.12, 0.12, 0.13))
				boiler.rotation_degrees = Vector3(90, 0, 0)
				boiler.position = Vector3(0, 1.75, back - car.length * 0.17)
				body.add_child(boiler)
				_box(body, Vector3(0.5, 1.1, 0.5), Vector3(0, 2.75, back - car.length * 0.4), Color(0.1, 0.1, 0.1))  # stack
				_box(body, Vector3(2.2, 2.0, 2.4), Vector3(0, 2.1, back + car.length * 0.5 - 1.3), Color(0.32, 0.12, 0.08))  # cab
			&"tender":
				_box(body, Vector3(2.1, 1.6, car.length), Vector3(0, 1.55, back), Color(0.14, 0.13, 0.13))
			_:
				_box(body, Vector3(t.car_width, t.car_height - 0.9, car.length), Vector3(0, 0.9 + (t.car_height - 0.9) * 0.5, back), Color(0.45, 0.17, 0.10))
		for w in 2:
			var truck := Node3D.new()
			truck.name = "%sTruck%d" % [body.name, w]
			add_child(truck)
			_box(truck, Vector3(t.gauge + 0.35, 0.45, 1.6), Vector3(0, 0.3, 0), Color(0.08, 0.08, 0.08))
			trucks.append(truck)


func _box(parent: Node3D, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _mat(colour)
	mi.position = at
	parent.add_child(mi)
	return mi


## Stand every car on the track with the train's front at s.
func place(s: float) -> void:
	for i in sim.cars.size():
		var s0 := sim.truck_s(i, 0, s)
		var s1 := sim.truck_s(i, 1, s)
		var f0 := track.transform_at(s0)
		var f1 := track.transform_at(s1)
		trucks[i * 2].transform = f0
		trucks[i * 2 + 1].transform = f1
		var fwd := (f0.origin - f1.origin).normalized()
		var up := (f0.basis.y + f1.basis.y).normalized()
		bodies[i].transform = Transform3D(Basis.looking_at(fwd, up), (f0.origin + f1.origin) * 0.5)

extends TestCase
## The train's models (train step 3, docs/briefs/train.md, #542): the engine's wheels and rods
## move exactly with the distance travelled (the drivers turn s / r; each main rod's two ends stay
## its length apart, its crosshead on the slide; each side rod rides its pins); the exhaust beats
## four a wheel turn; the cars' trucks turn their wheels by distance; every car has its model and
## its walk path's solids; the boxcar is gone over by its ladders (Ladder); the coach has its seats.

const LINE := preload("res://experiments/train_lab/test_line.gd")

var tuning: TrainTuning


func before_each() -> void:
	tuning = load("res://config/train.tres")


func _engine() -> EngineModel:
	var e := EngineModel.new()
	add_child(e)
	return e


func test_drivers_turn_with_distance() -> void:
	var e := _engine()
	var r: float = e.rig.driver_r
	for s in [0.0, 1.0, 2.7, -3.3]:
		e.roll(s)
		check_near(e.drivers[0].rotation.x, -s / r, 1e-5, "the drivers turn s / r (s %.1f)" % s)
		check_near(e.drivers[3].rotation.x, e.drivers[0].rotation.x, 1e-6, "all four pairs together")
	e.free()


func test_rods_hold_their_pins() -> void:
	var e := _engine()
	var r: float = e.rig.driver_r
	var crank: float = e.rig.crank
	var main_z: float = e.rig.drivers_z[int(e.rig.main)]
	var worst_len := 0.0
	var worst_side := 0.0
	var travel := Vector2(INF, -INF)
	for k in 64:
		var s := TAU * r * k / 64.0
		e.roll(s)
		for side in ["R", "L"]:
			var theta := -s / r
			var phase: float = e.rig.pins[side]
			var pin := Vector3(0.0, r + crank * cos(theta + phase), main_z + crank * sin(theta + phase))
			var ch: Node3D = e.crossheads[side]
			var mr: Node3D = e.main_rods[side]
			# The main rod's pin end is on the crank pin, its far end at the crosshead's wrist pin.
			var far := mr.position + mr.basis * Vector3(0.0, 0.0, -float(e.rig.main_len))
			worst_len = maxf(worst_len, Vector2(far.y - ch.position.y, far.z - ch.position.z).length())
			worst_len = maxf(worst_len, Vector2(mr.position.y - pin.y, mr.position.z - pin.z).length())
			check_near(ch.position.y, float(e.rig.slide_y), 1e-5, "the crosshead stays on its slide")
			# The side rod's offset from rest is the pin's.
			var rod: Node3D = e.side_rods[side]
			var rest_pin := Vector2(crank * cos(phase), crank * sin(phase))
			var now := Vector2(crank * cos(theta + phase), crank * sin(theta + phase))
			worst_side = maxf(worst_side, absf(rod.position.y - (e._rest[rod].y + now.x - rest_pin.x)))
			if side == "R":
				travel = Vector2(minf(travel.x, ch.position.z), maxf(travel.y, ch.position.z))
	check(worst_len < 0.002, "the main rods' ends on the pin and the crosshead (worst %.4f m)" % worst_len)
	check(worst_side < 1e-4, "the side rods ride the pins (worst %.5f m)" % worst_side)
	check_near(travel.y - travel.x, 2.0 * crank, 0.01, "the crosshead's travel is the stroke (%.3f m)" % (travel.y - travel.x))
	e.free()


func test_four_beats_a_turn() -> void:
	var e := _engine()
	e.steam = 0.5
	var r: float = e.rig.driver_r
	var n0 := e.beats
	var steps := 200
	for k in steps + 1:
		e.roll(TAU * r * 3.0 * k / steps)  # three turns
	check_eq(e.beats - n0, 12, "four beats a wheel turn, three turns")
	e.free()


func test_every_car_has_a_model_and_trucks_turn() -> void:
	var line := LINE.make(tuning)
	var sim := TrainSim.new(tuning, line)
	sim.place(300.0)
	var view := TrainView.new()
	line.add_child(view)
	view.setup(line, sim)
	view.place()
	check_eq(view.models_by_car.size(), sim.cars.size(), "a model a car")
	check(view.models_by_car[0] is EngineModel, "the engine is the Blender model")
	for i in range(1, sim.cars.size()):
		var meshes := view.models_by_car[i].find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() >= 1, "car %d drawn (%d meshes)" % [i, meshes.size()])
	# The cars' trucks turn by distance (the engine's are its own).
	var truck := view.trucks[2 * 2]
	var model: Node3D = truck.get_child(0)
	var wheels: Array = model.get_meta(&"wheels")
	sim.place(301.0)
	view.place()
	check_near((wheels[0] as Node3D).rotation.x, -sim.truck_s(2, 0) / TrainModels.WHEEL_R, 1e-4, "a truck's wheels turn s / r")
	line.free()


func test_boxcar_has_ladders_and_the_coach_seats() -> void:
	var line := LINE.make(tuning)
	var sim := TrainSim.new(tuning, line)
	var view := TrainView.new()
	line.add_child(view)
	view.setup(line, sim)
	var box := -1
	var coach := -1
	for i in sim.cars.size():
		if sim.cars[i].kind == &"box":
			box = i
		if sim.cars[i].kind == &"coach":
			coach = i
	var ladders := view.solids[box].get_children().filter(func(n: Node) -> bool: return n is Ladder)
	check_eq(ladders.size(), 2, "a ladder up each end of the boxcar")
	for l: Ladder in ladders:
		check_near(l.height, 2.0, 0.01, "to its roof walk")
	var seats := TrainModels.seats(sim.cars[coach], tuning)
	check(seats.size() >= 40, "the coach seats twenty and more (%d)" % seats.size())
	for s: Transform3D in seats:
		check(absf(s.origin.x) > TrainModels.AISLE, "a seat clear of the aisle")
	line.free()

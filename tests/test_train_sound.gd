extends TestCase
## The train heard (train step 4, issue #571; TrainSound, TrainSynth): four chuffs a wheel turn, a
## clack an axle a rail joint, every coupler's bang heard, each one-shot on its own moment however
## the ticks fall into drawn frames (none doubled or dropped at a low frame rate), the Doppler shift
## the right way round, the loops seamless and the one-shots led by silence, every train sound heard
## and clean; and with no ears nothing at all.

const LINE := preload("res://experiments/train_lab/test_line.gd")
const SOUNDS := preload("res://tests/test_sounds.gd")
const DT := 1.0 / 60.0

var world: Node3D
var ears: Camera3D
var tuning: TrainTuning
var line: TrackLine
var train: Train


func before_each() -> void:
	tuning = load("res://config/train.tres")
	world = Node3D.new()
	add_child(world)
	ears = Camera3D.new()
	world.add_child(ears)
	ears.make_current()
	line = LINE.make(tuning)
	world.add_child(line)
	train = Train.new()
	train.view = TrainView.new()
	train.view.models = false
	train.view.with_solids = false
	train.add_child(train.view)
	line.add_child(train)
	train.setup(line, tuning)
	train.set_physics_process(false)  # stepped here, by hand
	train.set_process(false)
	train.sound.set_process(false)
	SynthSounds.warm(TrainSynth.IDS)
	SynthSounds.finish_warm()


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## `secs` of the train's ticks, a drawn frame every `per_frame` ticks (2: 30 fps).
func _run(secs: float, per_frame := 1) -> void:
	for i in int(secs * 60.0):
		train.sim.step(DT)
		train.view.place(1.0)
		train.sound.tick(DT, train.sim.take_events())
		if (i + 1) % per_frame == 0:
			train.sound._process(DT * per_frame)


func _ears_beside(s: float, off: float) -> void:
	var f := line.global_transform * line.transform_at(s)
	ears.global_position = f * Vector3(-off, 1.7, 0.0)


func test_four_chuffs_a_wheel_turn() -> void:
	train.place(150.0)
	_ears_beside(160.0, 8.0)
	train.sim.throttle = 1.0
	var s0 := train.sim.truck_s(0, 0)
	_run(20.0)
	var turns := (train.sim.truck_s(0, 0) - s0) / (TAU * float(train.sound.rig.driver_r))
	var beats := int(train.sound.counts.get("beats", 0))
	check(absf(beats - turns * 4.0) <= 1.0, "%d beats over %.1f wheel turns (four a turn)" % [beats, turns])
	check(int(train.sound.counts.get("started", 0)) > beats, "every beat with steam heard, and the cocks at the start (%s)" % [train.sound.counts])


func test_each_sound_on_its_moment_at_any_frame_rate() -> void:
	var heard := []
	for per_frame in [1, 2]:
		_ears_beside(200.0, 10.0)
		train.place(150.0)
		train.sim.time = 0.0
		train.sim.set_speed(30.0 / 3.6)
		train.sim.throttle = 0.6
		train.sound.counts = {}
		train.sound.started.clear()
		train.sound.log_started = true
		_run(6.0, per_frame)
		var onsets := []
		var ok := true
		for st: Dictionary in train.sound.started:
			var late: float = st.now - st.on
			if late < -0.0001 or late > DT * per_frame + 0.0001:
				ok = false
			# Started `late` after its moment and skipped that far into its lead: heard at on + LEAD.
			onsets.append(snappedf(float(st.now) - float(st.from) / float(st.pitch), 0.0001))
		check(ok, "at %d tick(s) a frame every one-shot starts within the frame after it was due" % per_frame)
		heard.append({"onsets": onsets, "counts": train.sound.counts.duplicate()})
	check_eq(heard[0].counts.get("clacks"), heard[1].counts.get("clacks"), "the same clacks at 60 and 30 frames a second")
	check_eq(heard[0].counts.get("beats"), heard[1].counts.get("beats"), "the same beats")
	var a: Array = heard[0].onsets
	var b: Array = heard[1].onsets
	a.sort()
	b.sort()
	var worst := 0.0
	for i in mini(a.size(), b.size()):
		worst = maxf(worst, absf(float(a[i]) - float(b[i])))
	check(a.size() == b.size() and worst < 0.002, "every one-shot heard at the same moment either way (worst %.4f s of %d)" % [worst, a.size()])


func test_a_clack_an_axle_a_joint() -> void:
	_ears_beside(200.0, 10.0)
	train.place(150.0)
	train.sim.set_speed(10.0)
	var axles := train.sound._axles.size()
	var s0 := train.sim.s
	_run(5.0)
	var joints := (train.sim.s - s0) / tuning.rail_length
	var clacks := int(train.sound.counts.get("clacks", 0))
	check(absf(clacks - axles * joints) <= axles, "%d clacks: %d axles over %.1f joints" % [clacks, axles, joints])
	check(axles == 5 + 4 * (train.sim.cars.size() - 1), "the engine's pony and four drivers, two axles a truck under the rest (%d)" % axles)


func test_every_coupler_heard_on_a_start() -> void:
	_ears_beside(130.0, 6.0)
	train.place(150.0)
	train.sim.throttle = 1.0
	var events := 0
	for i in 60 * 12:
		train.sim.step(DT)
		var ev := train.sim.take_events()
		events += ev.size()
		train.sound.tick(DT, ev)
		train.sound._process(DT)
	check(events >= train.sim.cars.size() - 1, "the slack ran out down the train (%d events)" % events)
	check_eq(int(train.sound.counts.get("couplers", 0)), events, "each one heard")


func test_doppler_the_right_way() -> void:
	var up := TrainSound.doppler(Vector3.ZERO, Vector3(20, 0, 0), Vector3(100, 0, 0), Vector3.ZERO)
	var away := TrainSound.doppler(Vector3.ZERO, Vector3(-20, 0, 0), Vector3(100, 0, 0), Vector3.ZERO)
	check_near(up, 343.0 / 323.0, 0.0001, "coming at 20 m/s it's %.3f higher" % up)
	check_near(away, 343.0 / 363.0, 0.0001, "going away %.3f lower" % away)
	check_near(TrainSound.doppler(Vector3.ZERO, Vector3(0, 0, 20), Vector3(100, 0, 0), Vector3.ZERO), 1.0, 0.0001,
		"crossing square on, no shift")


func test_nothing_without_ears() -> void:
	ears.queue_free()
	await physics_frames(1)
	train.place(150.0)
	train.sim.throttle = 1.0
	_run(3.0)
	check(train.sound.counts.is_empty() and train.sound.queue.is_empty(), "no ears, nothing counted or queued")


func test_loops_seamless_and_shots_led_by_silence() -> void:
	for id: StringName in TrainSynth.IDS:
		var s := _samples(id)
		if TrainSynth.is_loop(id):
			var steps := PackedFloat32Array()
			for i in range(0, s.size() - 1, 7):
				steps.append(absf(s[i + 1] - s[i]))
			steps.sort()
			var usual := steps[int(steps.size() * 0.999)]
			var seam := absf(s[0] - s[s.size() - 1])
			check(seam <= usual, "%s loops without a step (%.4f, a usual sample's step up to %.4f)" % [id, seam, usual])
		else:
			var lead := int(TrainSynth.RATE * TrainSynth.LEAD)
			var quiet := true
			for i in lead:
				if s[i] != 0.0:
					quiet = false
			check(quiet and absf(s[lead + 200]) + absf(s[lead + 400]) > 0.0, "%s: %d ms of silence, then the sound" % [id, int(TrainSynth.LEAD * 1000.0)])


func test_every_train_sound_heard_clean() -> void:
	for id: StringName in TrainSynth.IDS:
		check(id in TrainSynth.WARM, "%s is made ahead when a train is first heard" % id)
	for id: StringName in TrainSynth.IDS:
		var s := _samples(id)
		var clipped := 0
		var loudest := 0.0
		var win := int(TrainSynth.RATE * 0.05)
		var i := 0
		for v in s:
			if absf(v) * 32767.0 >= SOUNDS.CLIP:
				clipped += 1
		while i + win <= s.size():
			var acc := 0.0
			for j in win:
				acc += s[i + j] * s[i + j]
			loudest = maxf(loudest, sqrt(acc / win))
			i += win
		check_eq(clipped, 0, "%s never reaches full scale" % id)
		check(loudest >= SOUNDS.HEARD, "%s is heard (%.3f)" % [id, loudest])
		# The sub-bass check on its first second (the DFT is slow in GDScript).
		var share := SOUNDS.energy_below(s.slice(0, mini(s.size(), TrainSynth.RATE)), TrainSynth.RATE, 40.0)
		check(share <= SOUNDS.SUB_BASS_SHARE, "%s: %.1f%% of its energy under 40 Hz" % [id, share * 100.0])


func _samples(id: StringName) -> PackedFloat32Array:
	var bytes := SynthSounds.get_sound(id).data
	var out := PackedFloat32Array()
	out.resize(bytes.size() / 2)
	for i in out.size():
		out[i] = bytes.decode_s16(i * 2) / 32767.0
	return out


## Its own cars aren't a wall (they're solids the world's rays meet): beside the train in the open,
## it's heard plain, not muffled.
func test_not_muffled_by_its_own_cars() -> void:
	world.queue_free()
	await physics_frames(2)
	world = Node3D.new()
	add_child(world)
	ears = Camera3D.new()
	world.add_child(ears)
	ears.make_current()
	line = LINE.make(tuning)
	world.add_child(line)
	train = Train.new()
	train.view = TrainView.new()
	train.view.models = false
	train.add_child(train.view)
	line.add_child(train)
	train.setup(line, tuning)
	train.place(150.0)
	_ears_beside(150.0 - 4.0, 8.0)  # beside the engine, looking through it at nothing
	await physics_frames(30)
	check_eq(train.sound._bus, &"Master", "heard in the open, not through its own engine")

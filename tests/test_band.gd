extends TestCase
## The band (#799; Band, config/band.json, assets/audio/band/): the parts from one tune's note data
## played together on one clock, each placed at its player; a shot stops them dead and they start
## again at the top of the phrase they stopped in; a killing ends their night; in the valley, the
## fiddler and the pianist play their parts at the yard set with their hands on the note data.

const TUNE := "payday_night"
const PARTS := ["fiddle", "banjo", "piano", "harmonica", "bones", "tambourine"]

var holder: Node3D
var band: Band


func after_each() -> void:
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
	holder = null
	band = null
	await physics_frames(2)


## A band of every part at points round (0, 1, -6), heard from a camera at the origin.
func _band(extra := {}) -> Band:
	holder = Node3D.new()
	holder.name = "BandTest"
	add_child(holder)
	var cam := Camera3D.new()
	holder.add_child(cam)
	cam.make_current()
	var players := []
	for i in PARTS.size():
		players.append({"id": PARTS[i], "pos": [-2.5 + i, 1.2, -6.0]})
	var d := {"tunes": [TUNE], "between_s": [1.0, 1.0], "stop_s": 0.25, "start_s": 0.06,
			"hush": {"shot_m": 80.0, "blast_m": 200.0, "death_m": 30.0, "quiet_s": 2.0},
			"sound": {"unit_size": 2.0, "volume_db": 0.0, "max_db": 3.0}, "players": players}
	d.merge(extra, true)
	band = Band.new()
	band.data = d
	band.always = true
	holder.add_child(band)
	return band


func test_the_note_data_s_phrases_and_parts() -> void:
	var n := Band.load_notes(TUNE)
	check(not n.is_empty(), "notes.json is there")
	var bars: Array = n.get("bars", [])
	var phrases: Array = n.get("phrases", [])
	check_eq(bars.size(), 64, "Payday Night: 64 bars (AABB twice through)")
	check_eq(phrases.size(), 16, "a phrase every four bars")
	for i in phrases.size():
		check_near(float(phrases[i]), float(bars[i * 4]), 1e-4, "phrase %d starts on bar %d" % [i, i * 4])
		if i > 0:
			check(float(phrases[i]) > float(phrases[i - 1]), "the phrases in order")
	check(float(n.length_s) >= float(n.end_s), "the parts run past the last note (it rings out)")
	var b := _band()
	await physics_frames(1)
	for p: String in PARTS:
		var s: AudioStream = band.players[StringName(p)].sound.stream
		check(s != null, "%s's part loads" % p)
		if s:
			check_near(s.get_length(), float(n.length_s), 0.05, "%s's part the tune's length (one clock)" % p)
	check(not b.bow_plan.is_empty() and not (b.strikes[0] as Array).is_empty(), "the bow and the keys planned from the note data")
	var prev := -1.0
	for st: Array in b.bow_plan:
		check(float(st[0]) >= prev, "the strokes in order")
		prev = float(st[0])
		check(float(st[3]) >= 0.1 and float(st[3]) <= 0.62, "the bow stays on the hair")


func test_they_play_together_each_at_his_place() -> void:
	_band()
	await physics_frames(10)
	check_eq(band.state, &"playing", "in hours with someone to play: they play")
	for i in PARTS.size():
		var pl: Dictionary = band.players[StringName(PARTS[i])]
		var p: AudioStreamPlayer3D = pl.sound
		check(p.playing, "%s playing" % PARTS[i])
		check_near(float(pl.gain), 1.0, 1e-3, "%s at full" % PARTS[i])
		check(p.global_position.distance_to(Vector3(-2.5 + i, 1.2, -6.0)) < 1e-3, "%s's sound where he is" % PARTS[i])
		check_eq(p.bus, &"Master", "%s outdoors, nothing between: no room, no wall" % PARTS[i])
	check(band.clock > 0.0 and band.clock < 0.2, "the tune's clock running from its start")


func test_a_shot_stops_them_dead_and_they_start_at_the_phrase() -> void:
	_band()
	await physics_frames(int(6.2 * 60))
	var at := band.clock
	var top := band.phrase_start(at)
	check(top > 0.0 and top < at, "six seconds in: inside a phrase that isn't the first")
	Events.shot_fired.emit(Vector3(0, 1.5, -10), Vector3.FORWARD, null)
	check_eq(band.state, &"hushed", "a shot 4 m off: stopped")
	check_eq(band.why, &"shot", "for the shot")
	check_near(band.resume_at, top, 1e-4, "to start again at the top of the phrase they stopped in")
	await physics_frames(int(0.25 * 60) + 2)
	for p: String in PARTS:
		check(float(band.players[StringName(p)].gain) <= 0.0, "%s quiet in the bow's lift (0.25 s)" % p)
		check(not (band.players[StringName(p)].sound as AudioStreamPlayer3D).playing, "%s stopped" % p)
	await physics_frames(60)
	Events.shot_fired.emit(Vector3(0, 1.5, -10), Vector3.FORWARD, null)
	await physics_frames(90)
	check_eq(band.state, &"hushed", "another shot: the quiet counts from it")
	await physics_frames(40)
	check_eq(band.state, &"playing", "quiet a while: they play again")
	check(band.clock >= top and band.clock < top + 0.3, "from the top of that phrase")


func test_a_shot_far_off_they_play_on() -> void:
	_band()
	await physics_frames(30)
	Events.shot_fired.emit(Vector3(0, 1.5, -300), Vector3.FORWARD, null)
	await physics_frames(2)
	check_eq(band.state, &"playing", "a shot 300 m off: they play on")


func test_a_killing_ends_their_night() -> void:
	_band()
	await physics_frames(30)
	var dead := Node3D.new()
	holder.add_child(dead)
	dead.global_position = Vector3(1, 0, -8)
	Events.person_died.emit(dead, &"shot")
	await physics_frames(int(60 * 3.0))
	check_eq(band.state, &"done", "a man killed by them: done for the night")
	check(not (band.players[&"fiddle"].sound as AudioStreamPlayer3D).playing, "and quiet")


func test_a_part_joins_at_the_top_of_a_phrase() -> void:
	_band({"hush": {"shot_m": 0.0, "blast_m": 0.0, "death_m": 0.0, "quiet_s": 2.0}})  # nothing else stops them
	await physics_frames(int(2.0 * 60))
	var pl: Dictionary = band.players[&"banjo"]
	pl.gain = 0.0
	pl.joining = false
	var next := band.next_phrase(band.clock)
	await physics_frames(int((next - band.clock - 0.1) * 60))
	check(float(pl.gain) <= 0.0, "out: not in before the phrase's top (%s)" % [band.log])
	await physics_frames(12)
	check(float(pl.gain) > 0.5, "in at the top of the next phrase")


func test_through_a_wall_it_s_muffled() -> void:
	_band()
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 6, 0.3)
	shape.shape = box
	wall.add_child(shape)
	wall.collision_layer = Layers.WORLD
	holder.add_child(wall)
	wall.global_position = Vector3(0, 1.5, -3)
	await physics_frames(30)
	for p: String in PARTS:
		check_eq((band.players[StringName(p)].sound as AudioStreamPlayer3D).bus, &"Muffled", "%s heard through the wall" % p)


func test_the_valley_s_fiddler_and_pianist_play_their_parts() -> void:
	ValleyFolk.murder_auto = false
	holder = Node3D.new()
	holder.name = "Main"
	add_child(holder)
	var valley: ValleyWorld = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var folk: ValleyFolk = valley.folk
	band = folk.band
	check(band != null, "the valley's folk have a band (config/band.json on the set's lot)")
	check(folk.props.has("piano") and folk.props.has("chair_piano"), "the set has its piano and the pianist's chair")
	if band == null:
		ValleyFolk.murder_auto = true
		return
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.set_time(21.0)
	await physics_frames(1)
	folk._look = 0.0
	var fiddler_in := await wait_until(func() -> bool:
		return band.can_play(&"fiddle") and band.can_play(&"piano"), 60 * 20)
	check(fiddler_in, "at nine the fiddler's at his post and the pianist at the piano, ready")
	var on := await wait_until(func() -> bool:
		return float(band.players[&"fiddle"].gain) > 0.9 and float(band.players[&"piano"].gain) > 0.9, 60 * 8)
	check(on, "their parts sound (in at a phrase's top)")
	var fiddler: HumanBody = folk.people.get(&"fiddler")
	var fiddle := fiddler.find_child("HeldFiddle", false, false) as MeshInstance3D if fiddler else null
	check(fiddle != null and fiddle.visible, "the fiddle in his hands")
	if fiddler:
		var d := band.spot_of(&"fiddle").distance_to(fiddler.global_position + Vector3.UP * 1.4)
		check(d < 0.6, "the fiddle's sound at him, at his chin (%.2f m)" % d)
		var palms: Array[Vector3] = []
		for i in 8:
			palms.append(fiddler.palm("r"))
			await physics_frames(10)
		var most := 0.0
		for p: Vector3 in palms:
			most = maxf(most, p.distance_to(palms[0]))
		check(most > 0.08, "his bow hand moves with the strokes (%.2f m)" % most)
	var pianist: HumanBody = folk.people.get(&"pianist")
	if pianist:
		check(pianist.palm("l").distance_to(band.spot_of(&"piano")) < 1.0, "the pianist's hand at the keys")
	Events.shot_fired.emit(band.centre() + Vector3(3, 0.5, 0), Vector3.FORWARD, null)
	await physics_frames(30)
	check_eq(band.state, &"hushed", "a shot in the yard: the band stops dead")
	check(float(band.players[&"fiddle"].gain) <= 0.0, "the fiddle quiet")
	ValleyFolk.murder_auto = true

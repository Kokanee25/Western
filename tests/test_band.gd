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


# --- #938: Payday Night on saloon B's stage, a second tune, faster through a fight ---------------

func test_a_second_tune_and_each_tune_s_hurried_render() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Band.DATA))
	var tunes: Array = d.get("tunes", [])
	check(tunes.size() >= 2, "two tunes in the set (%s)" % [tunes])
	for t: String in tunes:
		var n := Band.load_notes(t)
		check(not n.is_empty(), "%s's note data" % t)
		check(Band.has_fast(t), "%s has its hurried render" % t)
		var f := Band.load_notes(t + "_fast")
		var k := float(f.get("faster", 1.0))
		check(k > 1.1 and k < 1.2, "%s's hurried render ~1.15x (%.2f)" % [t, k])
		check_eq((f.get("phrases", []) as Array).size(), (n.get("phrases", []) as Array).size(), "%s: the same phrases hurried" % t)
		check_near(float(f.get("length_s", 0.0)) * k, float(n.get("length_s", 0.0)), 1.5, "%s: the same tune, shorter by its tempo" % t)
		for p: String in PARTS:
			check(ResourceLoader.exists("res://assets/audio/band/%s_fast/%s.ogg" % [t, p]), "%s's hurried %s" % [t, p])


func test_a_fist_fight_near_and_they_play_on_faster() -> void:
	_band({"fight": {"kinds": ["shove", "kick"], "fight_m": 25.0, "fight_s": 3.0, "draws": ["draw"], "draw_m": 25.0},
			"hush": {"shot_m": 80.0, "blast_m": 200.0, "death_m": 0.0, "quiet_s": 2.0}})
	await physics_frames(int(2.0 * 60))
	check(not band.fast, "steady to start")
	var next := band.next_phrase(band.clock)
	var i := (band.notes.phrases as Array).find(next)
	Events.deed.emit(null, &"shove", null, Vector3(1, 0, -7))
	await physics_frames(3)
	check_eq(band.state, &"playing", "a shove by them: they play on")
	check(not band.fast, "not hurried till the phrase's top")
	await physics_frames(int((next - band.clock) * 60) + 4)
	check(band.fast, "hurried from the top of the next phrase (%s)" % [band.log])
	check_eq(band.render_id(), TUNE + "_fast", "the hurried render's parts")
	var ph: Array = band.notes.phrases
	check(band.clock >= float(ph[i]) - 1e-3 and band.clock < float(ph[i]) + 0.2, "at the same phrase in it (%d: %.2f, clock %.2f)" % [i, float(ph[i]), band.clock])
	for p: String in PARTS:
		var s: AudioStreamPlayer3D = band.players[StringName(p)].sound
		check(s.playing and float(band.players[StringName(p)].gain) > 0.5, "%s plays on, hurried" % p)
	var hurried_at := band.clock
	# Three seconds since the last blow: back to the tune's own at a phrase's top.
	var back := await wait_until(func() -> bool: return not band.fast, 60 * 20)
	check(back and band.clock > 0.0, "the fight over, back to the tune's own tempo (%s)" % [band.log])
	check(band.phrase_start(band.clock) <= band.clock and band.clock - band.phrase_start(band.clock) < 0.2, "at a phrase's top")
	check(hurried_at > 0.0, "(hurried a while)")
	Events.deed.emit(null, &"shove", null, Vector3(0, 0, -200))
	await physics_frames(5)
	check(band._fight_left <= 0.0, "a fight 200 m off: nothing to them")
	Events.deed.emit(null, &"draw", null, Vector3(1, 0, -8))
	check_eq(band.state, &"hushed", "a gun drawn by them: stopped dead")
	check_eq(band.why, &"gun", "for the gun")


func test_ordinary_nights_the_fiddle_and_piano_only() -> void:
	_band({"nights": {"ordinary": {"players": {"fiddle": {}, "piano": {}}}}})
	await physics_frames(10)
	check(band.can_play(&"fiddle") and band.can_play(&"piano"), "the fiddle and the piano play an ordinary night")
	check(not band.can_play(&"banjo") and float(band.players[&"banjo"].gain) <= 0.0, "the banjo doesn't")
	band.night_override = &"payday"
	band.data["nights"]["payday"] = {"players": {"banjo": {}}}
	band._pick_night()
	check(band.can_play(&"banjo") and not band.can_play(&"fiddle"), "a night's players are its band")


## Payday Night (day 13): the fiddler and the piano player walk to saloon B's stage (#902) and play
## there, the stage's own upright; the other parts placed on the stage; the curtain drawn open; heard
## from the bar room under it through the floor, and from the street.
func test_payday_night_the_band_on_saloon_b_s_stage() -> void:
	ValleyFolk.murder_auto = false
	holder = Node3D.new()
	holder.name = "Main"
	add_child(holder)
	var valley: ValleyWorld = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var folk: ValleyFolk = valley.folk
	band = folk.band
	var hall: Node3D = valley.buildings.get("saloon")
	check(band != null and hall != null, "the valley's band and saloon B")
	if band == null or hall == null:
		ValleyFolk.murder_auto = true
		return
	check(folk.props.has("stage_piano") and folk.props.has("chair_stage_piano"), "the stage's upright and its chair")
	var sp: Vector3 = hall.to_local(folk.props.stage_piano.global_position)
	check(sp.x > 2.5 and sp.x < 7.4 and sp.z > 10.9 and sp.z < 13.4 and absf(sp.y - 5.67) < 0.05, "the upright on the stage (%s)" % sp)
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 13
	clock.set_time(21.0)
	await physics_frames(1)
	folk._look = 0.0
	var in_ := await wait_until(func() -> bool: return band.can_play(&"fiddle") and band.can_play(&"piano"), 60 * 20)
	check(in_, "Payday Night: the fiddler and the pianist on the stage, ready (%s)" % [band.report()])
	check_eq(band.night, &"payday", "the town's payday")
	for id: String in PARTS:
		var at: Vector3 = hall.to_local(band.spot_of(StringName(id)))
		check(at.x > 2.4 and at.x < 7.5 and at.z > 10.9 and at.z < 13.4 and at.y > 5.67, "%s's sound on the stage (%s)" % [id, at.snappedf(0.01)])
		check(band.can_play(StringName(id)), "%s plays Payday Night" % id)
	var fiddler: HumanBody = folk.people.get(&"fiddler")
	if fiddler:
		var u: Vector3 = hall.to_local(fiddler.global_position)
		check(Vector2(u.x, u.z).distance_to(Vector2(4.3, 12.6)) < 0.4 and absf(u.y - 5.67) < 0.15, "the fiddler at the stage's use point (%s)" % u.snappedf(0.01))
	var pianist: HumanBody = folk.people.get(&"pianist")
	if pianist:
		check(pianist.palm("l").distance_to(band.spot_of(&"piano")) < 1.0, "the pianist's hand at the stage's keys")
	var c: DrawCurtain = hall.get(&"curtain")
	check(c != null and c.is_open(), "the curtain drawn open for them")
	var on := await wait_until(func() -> bool: return float(band.players[&"fiddle"].gain) > 0.9, 60 * 8)
	check(on, "the fiddle sounds")
	# Heard from below (the bar room under the stage) and from the street.
	var cam := Camera3D.new()
	holder.add_child(cam)
	cam.make_current()
	cam.global_position = hall.to_global(Vector3(5.0, 1.7, 11.5))
	await physics_frames(30)
	var below := String((band.players[&"fiddle"].sound as AudioStreamPlayer3D).bus)
	check(below != "Master", "from the bar room under the stage, through its floor: not heard in the open (%s)" % below)
	cam.global_position = hall.to_global(Vector3(8.0, 1.7, -6.0))
	await physics_frames(30)
	var street := String((band.players[&"fiddle"].sound as AudioStreamPlayer3D).bus)
	check(street in ["Muffled", "RoomMuffled"], "from Main Street, through the saloon's walls: muffled (%s)" % street)
	print("  band buses: below %s, street %s" % [below, street])
	clock.day = 1
	ValleyFolk.murder_auto = true


## Payday Night, the clock running into it: the fiddler comes out of the saloon and walks to the
## stage by the folk's ways (the yard, the outside stair, the upper hall, the wing, its steps).
func test_payday_night_the_fiddler_walks_up_to_the_stage() -> void:
	ValleyFolk.murder_auto = false
	holder = Node3D.new()
	holder.name = "Main"
	add_child(holder)
	var valley: ValleyWorld = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var folk: ValleyFolk = valley.folk
	band = folk.band
	var hall: Node3D = valley.buildings.get("saloon")
	check(folk.places.has(&"saloonb_stage") and folk.places.is_stair(&"saloonb_stair_foot", &"saloonb_landing"), "saloon B's ways to the stage, up its outside stair")
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 13
	clock.set_time(18.95)
	await physics_frames(1)
	folk._look = 0.0
	await physics_frames(2)
	clock.set_time(19.02)
	await physics_frames(1)
	folk._look = 0.0
	var out := await wait_until(func() -> bool: return folk.people.has(&"fiddler"), 60 * 5)
	check_eq(String(folk.state.get(&"fiddler", "")), "coming", "walking in")
	check(out, "he comes out to go to the stage (%s)" % folk.report().get("fiddler"))
	var fiddler: HumanBody = folk.people.get(&"fiddler")
	var route: Array = (fiddler.get_node(^"Brain") as CivilianBrain).places.route(fiddler.get_world_3d().direct_space_state, fiddler.global_position, &"saloonb_stage") if fiddler else []
	check(not route.is_empty(), "a way from the saloon's door to the stage (%d points)" % route.size())
	var up := await wait_until(func() -> bool: return band.can_play(&"fiddle") and band.can_play(&"piano"), 60 * 240)
	var at: Vector3 = hall.to_local(fiddler.global_position) if is_instance_valid(fiddler) else Vector3.ZERO
	check(up, "he's walked up to the stage and plays, the pianist at the stage's upright (%s, at %s; %s)" % [folk.report().get("fiddler"), at.snappedf(0.01), folk.report().get("pianist")])
	clock.day = 1
	ValleyFolk.murder_auto = true

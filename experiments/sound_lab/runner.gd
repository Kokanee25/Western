extends Node
## One sound lab scenario in the running street (README.md beside this file): the town quietened,
## the shooter and the ears placed, the event made through the game's own code (the player's gun,
## a ball flown by Ballistics, a stick lit, timber set alight), and everything the player hears
## taken off the end of the Master bus (after the limiter) into a WAV, with every sound that
## started, how it was placed, the voices playing and the frame's time.
##
## Run under Movie Maker (`--write-movie`, run.py does), the mix is done once a frame on game time,
## so the WAV lines up with the game's clock and two runs of one seed sound the same.

const SCENARIOS := "res://experiments/sound_lab/scenarios.json"
const PLAYER_AWAY := Vector3(60.0, 0.0, -30.0)  # out of the way when he isn't the ears

var lab: BridgeLab
var scenario := ""
var seed_value := 1
var out_dir := ""
var picture := false  # draw every frame (slow); otherwise one frame of the view, then none

var _data := {}
var _spec := {}
var _street: Node3D
var _capture: AudioEffectCapture
var _capture_bus_slot := -1
var _frames := PackedVector2Array()
var _recording := false
var _t0_usec := 0
var _t0_tick := 0
var _marks: Array = []
var _started: Array = []  # every sound that began: what, where, how placed, how far from the ears
var _players: Array[Node] = []
var _was_playing := {}
var _last_pos := {}
var _voice_rows: Array = []  # per frame: t, voices, frame ms
var _last_usec := 0
var _hits: Array = []
var _setup := {}
var _listener_node: Node3D
var _lab_shooter: Node3D
var _view_from: Array = []  # [from, at] for the still when the ears aren't a camera


static func data() -> Dictionary:
	var f := FileAccess.open(SCENARIOS, FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f else {}


## Every scenario's name: the guns made from `guns`, then the rest.
static func names(d := data()) -> Array:
	var out := []
	var g: Dictionary = d.get("guns", {})
	for w: String in g.get("weapons", []):
		for place: String in g.get("places", {}):
			for l: String in g.places[place].listeners:
				out.append("%s_%s_%s" % [w, place, l])
	out.append_array((d.get("scenarios", {}) as Dictionary).keys())
	return out


static func spec_of(name: String, d: Dictionary) -> Dictionary:
	if (d.get("scenarios", {}) as Dictionary).has(name):
		return (d.scenarios[name] as Dictionary).duplicate(true)
	var parts := name.split("_")
	if parts.size() == 3 and (d.guns.places as Dictionary).has(parts[1]):
		var p: Dictionary = d.guns.places[parts[1]]
		if (p.listeners as Dictionary).has(parts[2]) and parts[0] in d.guns.weapons:
			return {"kind": "gun", "weapon": parts[0], "place": parts[1], "shooter": p.shooter, "aim": p.aim,
					"listener": p.listeners[parts[2]], "label": parts[2]}
	return {}


func run() -> Dictionary:
	_data = data()
	_spec = spec_of(scenario, _data)
	if _spec.is_empty():
		return {"ok": false, "error": "no scenario %s (sound_list)" % scenario}
	_street = lab.street as Node3D
	DirAccess.make_dir_recursive_absolute(out_dir)
	_quiet_town()
	await lab.seconds(0.5)
	var ok: Dictionary
	match String(_spec.kind):
		"gun": ok = await _setup_gun()
		"pass": ok = _setup_pass()
		"impact": ok = await _setup_impact()
		"ricochet": ok = _setup_ricochet()
		"dynamite": ok = _setup_dynamite()
		"fire": ok = await _setup_fire()
		"steps": ok = _setup_steps()
		"fight": ok = await _setup_fight()
		"cost": ok = _setup_cost()
		_: ok = {"ok": false, "error": "no kind %s" % _spec.kind}
	if not ok.get("ok", true):
		_unhook()
		return ok
	await lab.seconds(1.0)
	await _view_shot()
	_hook()
	_start_recording()
	await lab.seconds(0.5)  # the noise floor
	match String(_spec.kind):
		"gun": await _event_gun()
		"pass": _event_pass()
		"impact": _event_impact()
		"ricochet": _event_ricochet()
		"dynamite": _event_dynamite()
		"fire": await _event_fire()
		"steps": await _event_steps()
		"fight": await _event_fight()
		"cost": await _event_cost()
	await lab.seconds(float(_spec.get("tail", _data.get("tail", 4.0))))
	_stop_recording()
	_unhook()
	return _write()


# --- Setup ---------------------------------------------------------------------------------------

## Everyone out of the street, the clock stopped, Ballistics seeded; the player put away.
func _quiet_town() -> void:
	var gone := 0
	if _spec.kind != "fight":
		for tl in get_tree().get_nodes_in_group(&"town_life"):
			(tl as Node).process_mode = Node.PROCESS_MODE_DISABLED
		for spawner in _street.find_children("*", "OutlawSpawner", true, false):
			(spawner as Node).process_mode = Node.PROCESS_MODE_DISABLED
		for p in get_tree().get_nodes_in_group(&"people"):
			if p is HumanBody:
				(p as Node).queue_free()
				gone += 1
	_put_player(PLAYER_AWAY)
	var clock := _street.find_child("DayCycle", true, false) as DayCycle
	if clock:
		clock.set_time(float(_spec.get("hour", _data.get("hour", 15.0))))
		clock.set_time_scale(0.0)
	var ballistics := _ballistics()
	if ballistics:
		ballistics._rng.seed = 1873 + seed_value
	_setup = {"people_removed": gone, "hour": _spec.get("hour", _data.get("hour", 15.0)), "seed": seed_value,
			"mix_rate": AudioServer.get_mix_rate(), "speaker_mode": AudioServer.get_speaker_mode(),
			"movie_maker": OS.has_feature("movie") or Engine.get_write_movie_path() != ""}


func _setup_gun() -> Dictionary:
	var feet := _floor(_v(_spec.shooter))
	_put_player(feet)
	lab.bridge._face(_v(_spec.aim))
	var w: Dictionary = await lab.bridge._cmd_weapon([_spec.weapon])
	if not w.get("ok", false):
		return {"ok": false, "error": "couldn't draw the %s: %s" % [_spec.weapon, w]}
	lab.bridge._face(_v(_spec.aim))
	if _spec.listener is String:
		_listener_node = lab.player.camera
	else:
		# The ears on their own (an AudioListener3D), not a free camera: the gun aims down the
		# current camera's line, so the player's camera stays current.
		var at := _v(_spec.listener)
		var eye := lab.player.camera.global_position
		var ears := AudioListener3D.new()
		ears.name = "LabEars"
		_street.add_child(ears)
		ears.global_position = at
		ears.look_at(eye)
		ears.make_current()
		_listener_node = ears
		_view_from = [at, eye]
	_setup["shooter"] = _arr(lab.player.camera.global_position)
	_setup["listener"] = _arr(_listener_node.global_position)
	_setup["distance_m"] = snappedf(_listener_node.global_position.distance_to(lab.player.camera.global_position), 0.01)
	return {"ok": true}


func _setup_pass() -> Dictionary:
	_put_player(_floor(_v(_spec.player)))
	lab.bridge._face(_v(_spec.shooter))
	_listener_node = lab.player.camera
	_lab_shooter = _make_lab_shooter(_v(_spec.shooter))
	return {"ok": true}


func _setup_impact() -> Dictionary:
	if _spec.material == "flesh":
		var man := HumanBody.new()
		man.rng_seed = 700 + seed_value
		man.person_id = &"lab_man"
		man.name = "LabMan"
		man.has_gun = false
		var cb := CivilianBrain.new()
		cb.name = "Brain"
		man.add_child(cb)
		man.enter(_street, _floor(_v(_spec.man)), PI)
		cb.post = man.global_position
		await lab.physics_frames(3)
		var chest := man.parts.get(&"chest") as Node3D
		_spec["to"] = _arr(chest.global_position if chest else man.global_position + Vector3.UP * 1.3)
	elif _spec.material == "glass":
		var best: StructureMember
		var best_d := 4.0
		for n in _street.find_children("*", "StructureMember", true, false):
			var m := n as StructureMember
			if m.kind == &"glass" and not m.broken:
				var d := m.world_aabb().get_center().distance_to(_v(_spec.glass_near))
				if d < best_d:
					best_d = d
					best = m
		if best == null:
			return {"ok": false, "error": "no pane near %s" % [_spec.glass_near]}
		_spec["to"] = _arr(best.world_aabb().get_center())
		_setup["pane"] = String(best.member_id)
	_put_player(_floor(_v(_spec.player)))
	lab.bridge._face(_v(_spec.to))
	_listener_node = lab.player.camera
	_setup["distance_m"] = snappedf(_listener_node.global_position.distance_to(_v(_spec.to)), 0.01)
	return {"ok": true}


func _setup_ricochet() -> Dictionary:
	var strike: Vector3
	var n: Vector3
	var along: Vector3
	if _spec.surface == "ground":
		strike = _floor(_v(_spec.strike))
		n = Vector3.UP
		along = _v(_spec.come_from) * -1.0
	else:
		var q := PhysicsRayQueryParameters3D.create(_v(_spec.probe_from), _v(_spec.probe_to))
		q.collide_with_areas = false
		var hit := _street.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			return {"ok": false, "error": "nothing to glance off on %s -> %s" % [_spec.probe_from, _spec.probe_to]}
		strike = hit.position
		n = (hit.normal as Vector3).normalized()
		if _spec.has("centre"):  # a curved face (the well): the normal is the radius
			n = Vector3(strike.x - _spec.centre[0], 0.0, strike.z - _spec.centre[2]).normalized()
		along = n.cross(Vector3.UP).normalized()
		if _spec.has("along"):
			along = (_v(_spec.along) - n * _v(_spec.along).dot(n)).normalized()
		_setup["surface_of_hit"] = String(Ballistics.surface_of(hit.collider, n))
		_setup["hit"] = String((hit.collider as Node).name)
	var g := deg_to_rad(float(_spec.graze))
	var dir := (along * cos(g) - n * sin(g)).normalized()
	_spec["origin"] = _arr(strike - dir * float(_spec.get("run", 10.0)))
	_spec["dir"] = _arr(dir)
	_setup["strike"] = _arr(strike)
	var p: Vector3 = _v(_spec.player) if _spec.has("player") else strike + n * float(_spec.player_off)
	_put_player(_floor(p))
	lab.bridge._face(strike)
	_listener_node = lab.player.camera
	_setup["distance_m"] = snappedf(_listener_node.global_position.distance_to(strike), 0.01)
	return {"ok": true}


func _setup_dynamite() -> Dictionary:
	var at := _v(_spec.sticks[0])
	_put_player(_floor(_v(_spec.player)))
	lab.bridge._face(at)
	_listener_node = lab.player.camera
	_setup["distance_m"] = snappedf(_listener_node.global_position.distance_to(at), 0.01)
	return {"ok": true}


func _setup_fire() -> Dictionary:
	var fire := FireSystem.find(get_tree())
	if fire == null:
		return {"ok": false, "error": "no FireSystem"}
	_put_player(_floor(_v(_spec.wait_at)))
	var lit := 0
	for p: Array in _spec.ignite:
		var r: Dictionary = await lab.bridge._cmd_ignite([p[0], p[1], p[2]])
		lit += 1 if r.get("ok", true) else 0
	await lab.seconds(float(_spec.grow))
	_setup["ignited"] = lit
	_setup["burning_members"] = _burning()
	_listener_node = lab.player.camera
	var first: Dictionary = _spec.listen[0]
	_put_player(_floor(_v(first.player)))
	lab.bridge._face(_v(_spec.ignite[0]))
	return {"ok": true}


func _setup_steps() -> Dictionary:
	var w: Dictionary = _spec.walks[0]
	_put_player(_floor(_v(w.from)))
	_listener_node = lab.player.camera
	return {"ok": true}


func _setup_fight() -> Dictionary:
	_put_player(_floor(_v(_spec.player)))
	await lab.bridge._cmd_weapon(["revolver"])
	_listener_node = lab.player.camera
	return {"ok": true}


func _setup_cost() -> Dictionary:
	_put_player(_floor(_v(_spec.player)))
	_listener_node = lab.player.camera
	return {"ok": true}


# --- Events --------------------------------------------------------------------------------------

func _event_gun() -> void:
	_mark("shot")
	var r: Dictionary = await lab.bridge._cmd_shoot([1])
	_setup["shoot"] = r


func _event_pass() -> void:
	var head := lab.player.global_position + Vector3.UP * 1.5
	var side := (head - _lab_shooter.global_position).cross(Vector3.UP).normalized()
	var aim := head + side * float(_spec.miss)
	if bool(_spec.get("report", false)):
		(_lab_shooter.get_child(0) as AudioStreamPlayer3D).play()
	_mark("fired", _lab_shooter.global_position)
	var b := _fire_ball(_lab_shooter.global_position, aim - _lab_shooter.global_position)
	b.tumbling = bool(_spec.get("tumbling", false))
	_setup["miss_m"] = _spec.miss
	_setup["distance_m"] = snappedf(head.distance_to(_lab_shooter.global_position), 0.01)


func _event_impact() -> void:
	var from := _v(_spec.from)
	_mark("fired", _v(_spec.to))
	_fire_ball(from, _v(_spec.to) - from)


func _event_ricochet() -> void:
	_mark("fired", _v(_spec.origin))
	_fire_ball(_v(_spec.origin), _v(_spec.dir))


func _event_dynamite() -> void:
	var sticks: Array[DynamiteStick] = []
	for p: Array in _spec.sticks:
		var s := DynamiteStick.make(_street, Vector3(p[0], p[1], p[2]), Vector3.ZERO, 0.0)
		s.fuse_left = 0.5
		s.light()
		sticks.append(s)
	_mark("lit")


func _event_fire() -> void:
	for i in (_spec.listen as Array).size():
		var l: Dictionary = _spec.listen[i]
		if i > 0:
			_put_player(_floor(_v(l.player)))
			lab.bridge._face(_v(_spec.ignite[0]))
			await lab.physics_frames(2)
		_mark(l.name, _v(_spec.ignite[0]))
		_marks[-1]["burning_members"] = _burning()
		await lab.seconds(float(l.seconds))


func _event_steps() -> void:
	for w: Dictionary in _spec.walks:
		_put_player(_floor(_v(w.from)))
		await lab.physics_frames(10)
		_mark(w.name, lab.player.global_position)
		var args := [str(w.to[0]), str(w.to[1])]
		if w.run:
			args.append("run")
		_marks[-1]["walk"] = await lab.bridge._cmd_walk(args)
		await lab.seconds(1.0)


func _event_fight() -> void:
	await lab.bridge._cmd_gang([])
	await lab.bridge._cmd_fight([])
	_mark("fight")
	var end := _now() + float(_spec.seconds)
	var next_shot := _now() + float(_spec.player_shoots_every)
	while _now() < end:
		if _now() >= next_shot and not lab.bridge._knocked_out():
			for id in ["brody", "lyle", "kid"]:
				var p := lab.person(id)
				if p and p.physiology.is_conscious():
					lab.bridge._face(lab.bridge._chest(p))
					await lab.bridge._cmd_shoot([1])
					break
			next_shot = _now() + float(_spec.player_shoots_every)
		await get_tree().physics_frame


## Many looping 3D sounds at once round the ears: the frame's time against the number playing (with
## Movie Maker the mix runs on the main thread, inside the frame).
func _event_cost() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 + seed_value
	var results := []
	for count: int in _spec.voices:
		var made: Array[AudioStreamPlayer3D] = []
		for i in count:
			var p := AudioStreamPlayer3D.new()
			p.stream = SynthSounds.get_sound(&"fire")
			p.unit_size = 6.0
			_street.add_child(p)
			p.global_position = lab.player.global_position + Vector3(rng.randf_range(-20, 20), 1.0, rng.randf_range(-20, 20))
			p.play()
			made.append(p)
		await lab.seconds(0.5)
		_mark("voices_%d" % count)
		var from := _voice_rows.size()
		await lab.seconds(float(_spec.seconds))
		var ms := PackedFloat32Array()
		for row: Array in _voice_rows.slice(from):
			ms.append(row[2])
		results.append({"voices": count, "frame_ms_mean": snappedf(_mean(ms), 0.001), "frame_ms_median": snappedf(_median(ms), 0.001)})
		for p in made:
			p.queue_free()
		await lab.physics_frames(2)
	_setup["cost"] = results


# --- What's heard --------------------------------------------------------------------------------

## The end of the Master bus, after the limiter: what comes out of the speakers.
func _start_recording() -> void:
	var master := AudioServer.get_bus_index(&"Master")
	_capture = AudioEffectCapture.new()
	_capture.buffer_length = 2.0
	AudioServer.add_bus_effect(master, _capture)
	_capture_bus_slot = AudioServer.get_bus_effect_count(master) - 1
	_frames.clear()
	_recording = true
	_t0_usec = Time.get_ticks_usec()
	_t0_tick = Engine.get_physics_frames()
	_last_usec = _t0_usec
	_drain()
	_frames.clear()


func _stop_recording() -> void:
	_drain()
	_recording = false
	var master := AudioServer.get_bus_index(&"Master")
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) == _capture:
			AudioServer.remove_bus_effect(master, i)
			break


func _drain() -> void:
	if _capture and _capture.get_frames_available() > 0:
		_frames.append_array(_capture.get_buffer(_capture.get_frames_available()))


## Game seconds since the recording began (the WAV's own clock, on a fixed step).
func _now() -> float:
	return float(Engine.get_physics_frames() - _t0_tick) / float(Engine.physics_ticks_per_second)


func _mark(name: String, at := Vector3.INF) -> void:
	var m := {"name": name, "t": snappedf(_now(), 0.001)}
	if at != Vector3.INF:
		m["at"] = _arr(at)
		if _listener_node:
			m["distance_m"] = snappedf(_listener_node.global_position.distance_to(at), 0.01)
	_marks.append(m)


func _process(_delta: float) -> void:
	if not _recording:
		return
	_drain()
	var now := Time.get_ticks_usec()
	var voices := 0
	for p in _players:
		if not is_instance_valid(p):
			continue
		var playing: bool = p.playing
		var pos: float = p.get_playback_position() if playing else 0.0
		var key := p.get_instance_id()
		if playing and (not _was_playing.get(key, false) or pos + 0.05 < float(_last_pos.get(key, 0.0))):
			_started.append(_describe_start(p))
		_was_playing[key] = playing
		_last_pos[key] = pos
		voices += 1 if playing else 0
	_voice_rows.append([snappedf(_now(), 0.001), voices, snappedf((now - _last_usec) / 1000.0, 0.001)])
	_last_usec = now


func _hook() -> void:
	for n in get_tree().root.find_children("*", "", true, false):
		_on_node_added(n)
	get_tree().node_added.connect(_on_node_added)
	Events.bullet_hit.connect(_on_bullet_hit)
	Events.shot_fired.connect(_on_shot_fired)
	Events.exploded.connect(_on_exploded)


func _unhook() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	if Events.bullet_hit.is_connected(_on_bullet_hit):
		Events.bullet_hit.disconnect(_on_bullet_hit)
	if Events.shot_fired.is_connected(_on_shot_fired):
		Events.shot_fired.disconnect(_on_shot_fired)
		Events.exploded.disconnect(_on_exploded)


func _on_node_added(n: Node) -> void:
	if n is AudioStreamPlayer or n is AudioStreamPlayer3D or n is AudioStreamPlayer2D:
		_players.append(n)


## Every gun going off (the player's, the gang's) and every charge, marked where it happened.
func _on_shot_fired(origin: Vector3, _dir: Vector3, who: Node) -> void:
	_mark("shot_fired", origin)
	_marks[-1]["who"] = "player" if who == lab.player else (String(who.get(&"person_id")) if who else "")


func _on_exploded(at: Vector3, kg: float) -> void:
	_mark("exploded", at)
	_marks[-1]["kg"] = kg


func _on_bullet_hit(info: Dictionary) -> void:
	_hits.append({"t": snappedf(_now(), 0.001), "at": _arr(info.position), "ricochet": info.get("ricochet", false),
			"surface": String(info.get("surface", &"")), "person": info.has("person"),
			"what": String((info.collider as Node).name) if info.get("collider") is Node else ""})


## What a sound that just began is, who plays it and how it's placed, and what Godot's distance
## model makes of it at the ears (inverse distance: unit_size / distance, capped at max_db; the
## low-pass `attenuation_filter_db` deep as the gain falls under 1).
func _describe_start(p: Node) -> Dictionary:
	var stream: AudioStream = p.stream
	var d := {"t": snappedf(_now(), 0.001), "sound": _sound_id(stream), "node": String(_street.get_path_to(p)) if _street.is_ancestor_of(p) else String(p.get_path()),
			"owner": _owner_script(p), "bus": String(p.bus), "volume_db": p.volume_db,
			"length_s": snappedf(stream.get_length(), 0.01) if stream else 0.0,
			"inside": p.get_meta(&"inside") if p.has_meta(&"inside") else null,
			"walled": p.get_meta(&"walled") if p.has_meta(&"walled") else null}
	if p is AudioStreamPlayer3D:
		var p3 := p as AudioStreamPlayer3D
		var dist := p3.global_position.distance_to(_listener_node.global_position) if _listener_node else -1.0
		var gain := 1.0 / maxf(dist / p3.unit_size, 0.0001) if p3.attenuation_model == AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE else -1.0
		var att_db := minf(linear_to_db(gain) + p3.volume_db, p3.max_db)
		d.merge({"at": _arr(p3.global_position), "distance_m": snappedf(dist, 0.01), "unit_size": p3.unit_size,
				"max_db": p3.max_db, "max_distance": p3.max_distance, "model": p3.attenuation_model,
				"filter_hz": p3.attenuation_filter_cutoff_hz, "filter_db": p3.attenuation_filter_db,
				"doppler": p3.doppler_tracking, "area_mask": p3.area_mask, "panning": p3.panning_strength,
				"godot_db_at_ears": snappedf(att_db, 0.1),
				"godot_filter_db": snappedf((1.0 - minf(1.0, db_to_linear(att_db))) * p3.attenuation_filter_db, 0.1)})
	return d


func _sound_id(s: AudioStream) -> String:
	for k: StringName in SynthSounds._cache:
		if SynthSounds._cache[k] == s:
			return String(k)
	return s.resource_path if s else "?"


func _owner_script(p: Node) -> String:
	var n := p
	while n:
		var sc := n.get_script() as Script
		if sc and n != p:
			return sc.resource_path.get_file()
		n = n.get_parent()
	return ""


# --- Out -----------------------------------------------------------------------------------------

func _write() -> Dictionary:
	var rate := int(AudioServer.get_mix_rate())
	var bytes := PackedByteArray()
	bytes.resize(_frames.size() * 4)
	for i in _frames.size():
		bytes.encode_s16(i * 4, int(clampf(_frames[i].x, -1.0, 1.0) * 32767.0))
		bytes.encode_s16(i * 4 + 2, int(clampf(_frames[i].y, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = bytes
	wav.save_to_wav(out_dir.path_join("heard.wav"))
	var csv := FileAccess.open(out_dir.path_join("voices.csv"), FileAccess.WRITE)
	csv.store_line("t,voices,frame_ms")
	for row: Array in _voice_rows:
		csv.store_line("%s,%d,%s" % row)
	csv.close()
	var most := 0
	for row: Array in _voice_rows:
		most = maxi(most, row[1])
	var out := {"scenario": scenario, "spec": _spec, "setup": _setup, "marks": _marks, "started": _started,
			"hits": _hits, "seconds": snappedf(_frames.size() / float(rate), 0.001), "mix_rate": rate,
			"voices_max": most, "listener": _arr(_listener_node.global_position) if _listener_node else []}
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	return out


## The view from the ears, once, before the sound (a still for the clip); then nothing is drawn
## (the mix doesn't need it) unless `picture`.
func _view_shot() -> void:
	if DisplayServer.get_name() == "headless":
		return  # nothing is drawn, and frame_post_draw never comes
	RenderingServer.render_loop_enabled = true
	if not _view_from.is_empty():
		var a: Vector3 = _view_from[0]
		var b: Vector3 = _view_from[1]
		await lab.bridge._cmd_camera([a.x, a.y, a.z, b.x, b.y, b.z])
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(out_dir.path_join("view.png"))
	if not _view_from.is_empty():
		await lab.bridge._cmd_camera(["player"])
		(_listener_node as AudioListener3D).make_current()
	RenderingServer.render_loop_enabled = picture


# --- Helpers -------------------------------------------------------------------------------------

func _ballistics() -> Ballistics:
	return get_tree().get_first_node_in_group(&"ballistics") as Ballistics


## A revolver ball (config/revolver.tres) flown by Ballistics from `from` along `dir`, nobody's.
func _fire_ball(from: Vector3, dir: Vector3) -> Ballistics.Bullet:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var none: Array[RID] = []
	var b := _ballistics().fire(from, dir.normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, none)
	b.form = t.form_factor
	return b


## A gun going off where no one stands: an AudioStreamPlayer3D set as OutlawBrain sets his
## (src/bodies/outlaw_brain.gd: the gunshot, unit_size 25, max_db 6), so a lab ball comes with the
## report an outlaw's would.
func _make_lab_shooter(at: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "LabShooter"
	_street.add_child(n)
	n.global_position = at
	var p := AudioStreamPlayer3D.new()
	p.stream = SynthSounds.get_sound(&"gunshot")
	p.unit_size = 25.0
	p.max_db = 6.0
	n.add_child(p)
	return n


func _put_player(feet: Vector3) -> void:
	if lab.player:
		lab.player.global_position = feet
		lab.player.velocity = Vector3.ZERO


## The floor under a point (its y kept if nothing's there).
func _floor(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.5, p + Vector3.DOWN * 3.0, Layers.WORLD | Layers.WALK)
	if lab.player:
		q.exclude = [lab.player.get_rid()]
	var hit := _street.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else p


func _burning() -> int:
	var n := 0
	for m in _street.find_children("*", "StructureMember", true, false):
		n += 1 if (m as StructureMember).burning else 0
	return n


func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func _mean(a: PackedFloat32Array) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(a.size(), 1)


static func _median(a: PackedFloat32Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]


func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

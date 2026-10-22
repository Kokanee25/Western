class_name GameAudio
## Where a sound is heard from (the sound lab, docs/briefs/sound-lab.md): a sound is played where it
## happened and reaches the ears as it would. It arrives late by the distance over the speed of
## sound; the air takes its highs the further it goes; inside a building it rings in the room (the
## Room bus); a wall between muffles it (Muffled); outdoors it slaps back off the nearest fronts. All
## worked out once, when the sound starts, from where the ears are then (the current
## AudioListener3D, else the camera).
##
## `--old-sound` puts the gunshots back as they were before the lab (one sample, placed only by
## distance): the lab's "before", from the same build.

const SPEED_OF_SOUND := 343.0  ## m/s at 20 °C
## Inside: a roof within this overhead and a wall every way within ROOM_REACH.
const ROOF_REACH := 9.0
const ROOM_REACH := 22.0
## Reflections: the fronts within this of the source.
const SLAP_REACH := 35.0
## The ears are this much nearer than the source before a wall between counts (the shooter's own
## gun is never behind his hat brim).
const WALL_MARGIN := 0.4

static var _tuning: SoundTuning
static var _on := true
static var _checked := false
static var _buses_made := false


static func enabled() -> bool:
	if not _checked:
		_checked = true
		_on = not ("--old-sound" in OS.get_cmdline_user_args())
	return _on


## The dials (config/sound.tres).
static func t() -> SoundTuning:
	if _tuning == null:
		_tuning = load("res://config/sound.tres")
	return _tuning


## A gun going off at `at`: the report (its blast, close), the roll of it (the boom that carries,
## and the hills sending it back), and outdoors the slap off the fronts. `big` for the coach gun.
static func gunshot(host: Node, at: Vector3, big := false) -> void:
	var near := &"report_big" if big else &"report"
	var far := &"rolling_big" if big else &"rolling"
	var k := t()
	var heard := play(host, near, at, {"unit_size": k.report_unit_size, "volume_db": k.report_db, "max_db": k.report_db})
	play(host, far, at, {"unit_size": k.roll_unit_size, "volume_db": k.roll_db, "max_db": k.roll_max_db, "panning": 0.5})
	if heard and not heard.get_meta(&"inside", false):
		for s: Dictionary in slaps(host, at):
			play(host, near, s.at, {"unit_size": k.report_unit_size, "volume_db": k.report_db + k.slap_db,
					"max_db": k.report_db + k.slap_db, "walls": false})


## A charge of `kg` going off at `at`: the blast (full within a few metres, more for a bigger
## charge), its roll off the hills, outdoors the slap off the fronts, and what it threw coming down
## round it over the next seconds (clods and splinters, each placed and late by its own distance).
static func blast(host: Node, at: Vector3, kg: float) -> void:
	var k := t()
	var size := pow(maxf(kg, 0.01) / 0.2, 1.0 / 3.0)
	var heard := play(host, &"blast", at, {"unit_size": k.blast_unit_size * size, "volume_db": 6.0, "max_db": 6.0})
	play(host, &"blast_roll", at, {"unit_size": k.blast_roll_unit_size * size, "volume_db": k.blast_roll_db,
			"max_db": k.blast_roll_max_db, "panning": 0.4})
	if heard and not heard.get_meta(&"inside", false):
		for s: Dictionary in slaps(host, at):
			play(host, &"blast", s.at, {"unit_size": k.blast_unit_size * size, "volume_db": 6.0 + k.slap_db,
					"max_db": 6.0 + k.slap_db, "walls": false})
	var holder := _holder(host)
	if holder == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(at.round()))
	for i in int(round(k.debris_count * size)):
		var a := rng.randf() * TAU
		var r := rng.randf_range(1.5, 9.0) * size
		var where := at + Vector3(cos(a) * r, 0.0, sin(a) * r)
		var id := &"impact_wood" if i % 3 == 2 else &"impact_dirt"
		var db := rng.randf_range(-16.0, -6.0)
		holder.get_tree().create_timer(rng.randf_range(0.5, 2.8), false, true).timeout.connect(func() -> void:
				if is_instance_valid(holder) and holder.is_inside_tree():
					play(holder, id, where, {"volume_db": db, "normal": Vector3.UP}))


## Play `id` at `at` as heard from the ears. `o`: unit_size (6), volume_db (0), max_db (3),
## panning (1), delay (true: distance / the speed of sound; an image source is already the reflected
## path's length away), walls (true: the room and the walls by where it is), normal (the face a sound
## made on a surface came off).
static func play(host: Node, id: StringName, at: Vector3, o := {}) -> AudioStreamPlayer3D:
	if host == null or not host.is_inside_tree():
		return null
	var holder := _holder(host)
	if holder == null:
		return null
	_make_buses()
	var ears := ears_of(host)
	var d := ears.global_position.distance_to(at) if ears else 0.0
	var p := AudioStreamPlayer3D.new()
	p.stream = SynthSounds.get_sound(id)
	p.unit_size = float(o.get("unit_size", 6.0))
	p.volume_db = float(o.get("volume_db", 0.0))
	p.max_db = float(o.get("max_db", 3.0))
	p.panning_strength = float(o.get("panning", 1.0))
	p.attenuation_filter_cutoff_hz = air_cutoff(d)
	if bool(o.get("walls", true)) and ears:
		var inside := inside(holder, at)
		# A sound made on a surface (a ball striking it) is judged from a hand's breadth off it, or
		# the surface itself would be the wall.
		var heard_from: Vector3 = at + (o.get("normal", Vector3.ZERO) as Vector3) * 0.25
		var blocked := walled(holder, ears.global_position, heard_from)
		p.set_meta(&"inside", inside)
		p.set_meta(&"walled", blocked)
		p.bus = (&"RoomMuffled" if blocked else &"Room") if inside else (&"Muffled" if blocked else &"Master")
	holder.add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
	var delay := d / SPEED_OF_SOUND if bool(o.get("delay", true)) else 0.0
	if delay < 0.5 / Engine.physics_ticks_per_second:
		p.play()
	else:
		holder.get_tree().create_timer(delay, false, true).timeout.connect(func() -> void:
				if is_instance_valid(p) and p.is_inside_tree():
					p.play())
	return p


## The ears: the current AudioListener3D of the host's viewport, else its camera.
static func ears_of(host: Node) -> Node3D:
	var vp := host.get_viewport()
	if vp == null:
		return null
	var l := vp.get_audio_listener_3d()
	return l if l else vp.get_camera_3d()


## The corner of the air's high shelf for a sound `d` metres off.
## (ISO 9613-1's absorption climbs steeply above ~2 kHz.)
static func air_cutoff(d: float) -> float:
	return clampf(20000.0 / (1.0 + d / t().air_metres), 1500.0, 20000.0)


## Under a roof with walls round: a roof overhead and a wall every way (a porch's roof with the
## street open in front isn't a room).
static func inside(world: Node3D, at: Vector3) -> bool:
	var space := world.get_world_3d().direct_space_state
	var from := at + Vector3.UP * 0.1
	if _ray(space, from, from + Vector3.UP * ROOF_REACH).is_empty():
		return false
	for dir: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		if _ray(space, from, from + dir * ROOM_REACH).is_empty():
			return false
	return true


## Something solid between the ears and the sound (more than a hand's breadth short of it).
static func walled(world: Node3D, ears: Vector3, at: Vector3) -> bool:
	if ears.distance_to(at) < WALL_MARGIN * 2.0:
		return false
	var hit := _ray(world.get_world_3d().direct_space_state, ears, at)
	return not hit.is_empty() and (hit.position as Vector3).distance_to(at) > WALL_MARGIN


## The two strongest reflections of a sound at `at` off the fronts round it, as image sources (the
## source mirrored in each wall's plane: heard from there, it comes the reflected path's length
## late and from the wall's side). A wall is something that's still there a metre higher (not a
## post or a rail).
static func slaps(host: Node, at: Vector3) -> Array:
	var holder := _holder(host)
	var ears := ears_of(host)
	if holder == null or ears == null:
		return []
	var space := holder.get_world_3d().direct_space_state
	var direct := ears.global_position.distance_to(at)
	var found := []
	for i in 8:
		var a := TAU * i / 8.0
		var dir := Vector3(sin(a), 0.0, cos(a))
		var hit := _wall(space, at, dir)
		if hit.is_empty():
			continue
		var n := Vector3((hit.normal as Vector3).x, 0.0, (hit.normal as Vector3).z).normalized()
		if n == Vector3.ZERO:
			continue
		var image := at - 2.0 * (at - (hit.position as Vector3)).dot(n) * n
		var path := image.distance_to(ears.global_position)
		if path < direct + 3.0:
			continue  # it'd come with the sound itself
		if found.any(func(f: Dictionary) -> bool: return (f.at as Vector3).distance_to(image) < 2.0):
			continue
		found.append({"at": image, "path": path})
	found.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.path < y.path)
	return found.slice(0, 2)


## A wall `dir` of `at`: of three rays a metre apart in height, the nearest that another agrees with
## to within a stride (so not a post or a rail, and not the back of a room through an open door).
static func _wall(space: PhysicsDirectSpaceState3D, at: Vector3, dir: Vector3) -> Dictionary:
	var hits := []
	for h: float in [0.0, 1.0, 2.0]:
		var from := at + Vector3.UP * h
		var hit := _ray(space, from, from + dir * SLAP_REACH)
		if not hit.is_empty():
			hit["d"] = from.distance_to(hit.position)
			hit.position = (hit.position as Vector3) - Vector3.UP * h
			hits.append(hit)
	hits.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.d < y.d)
	for i in hits.size() - 1:
		if float(hits[i + 1].d) - float(hits[i].d) < 1.5:
			return hits[i]
	return {}


## The first solid thing on the line: buildings, the ground, fixed props; not people (the player's
## capsule is on WORLD) or loose things, which are looked past.
static func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	for i in 4:
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit.collider is StaticBody3D:
			return hit
		q.exclude = q.exclude + [hit.rid]
	return {}


## Where the sounds go: a node in the host's 3D world (made once).
static func _holder(host: Node) -> Node3D:
	var vp := host.get_viewport()
	if vp == null:
		return null
	var h := vp.get_node_or_null(^"GameAudio") as Node3D
	if h == null:
		h = Node3D.new()
		h.name = "GameAudio"
		vp.add_child(h)
	return h


## The buses, made once beside Master (which keeps the ears' filter and the speakers' guard):
## Room (a small timber room: a short, damped reverb), Muffled (through a wall: the highs gone and
## a little quieter) and RoomMuffled (a room heard through its wall).
static func _make_buses() -> void:
	if _buses_made:
		return
	_buses_made = true
	if AudioServer.get_bus_index(&"Room") >= 0:
		return
	for name: StringName in [&"Room", &"Muffled", &"RoomMuffled"]:
		var i := AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, name)
		AudioServer.set_bus_send(i, &"Master")
		if name != &"Muffled":
			AudioServer.add_bus_effect(i, _room())
		if name != &"Room":
			var wall := AudioEffectLowPassFilter.new()
			wall.cutoff_hz = t().wall_cutoff_hz
			wall.resonance = 0.5
			AudioServer.add_bus_effect(i, wall)
			var quieter := AudioEffectAmplify.new()
			quieter.volume_db = t().wall_db
			AudioServer.add_bus_effect(i, quieter)


static func _room() -> AudioEffectReverb:
	var room := AudioEffectReverb.new()
	room.room_size = t().room_size
	room.damping = t().room_damping
	room.spread = 0.7
	room.hipass = 0.1
	room.predelay_msec = 12.0
	room.predelay_feedback = 0.2
	room.dry = 1.0
	room.wet = t().room_wet
	return room

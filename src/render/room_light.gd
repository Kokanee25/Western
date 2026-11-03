class_name RoomLight
extends Node
## Indoor light that knows the building (issue #608 part 1; Settings.room_light, off by default,
## `-- --room-light=on`, LookPreset `settings.room_light`). Godot's own GI doesn't suit a saloon
## built at run time and broken in play (baked light can't follow it; SDFGI is coarse and leaks
## indoors), so this uses what the game knows: every room, wall, opening and broken board.
##
## - **Bounce.** Each lit OilLamp in a building sends three rays (down, up, the nearest wall in
##   the building's own axes) and a soft shadowless spot sits where each lands, facing into the
##   room: the light that floor, ceiling and wall give back (the idea is instant radiosity's
##   "virtual point lights", Keller 1997). Its energy is the lamp's, by the engine's own omni
##   falloff to that surface, times the surface's lightness (its wood's texture, averaged once);
##   its colour the lamp's times the wood's. A spot's half angle is under 90 degrees, so it never
##   lights the surface it comes off, which already has the lamp's direct light. Near bounces of
##   different lamps are merged, a room keeps its strongest few, and they follow the flicker.
##   Lamps are looked at every refresh_seconds: a lamp carried, knocked over, put out or smashed
##   re-casts its rays (a few lamps a physics tick); the rest is cached.
## - **Each room's own fill.** The building's interior probe (FalseFrontBuilding.InteriorAmbient)
##   at night goes dark amber and down to ambient_scale of what it was (the bounces do the rest of
##   its work), scaled again by the share of the room's lamps still lit (DayCycle reads the meta
##   `room_light_scale`).
## - **Openings.** The front door and windows (as MoonWindows has them) and every hole a break
##   makes in a wall let the sky in: a soft spot just inside, sized to the opening, moonlight by
##   night (the round-2 MoonWindows' numbers, which it then stands in for) and skylight by day
##   (the sun comes through on its own, shadowed). A hole is found from the structure's own
##   data: Events.member_broken names the member, its box says which wall and where, and a grid
##   of rays through that patch of wall says how much of it is open now. Only that patch is
##   probed, on a ray budget; nothing is rebuilt.
## - **Haze.** The room's own fog volume (FalseFrontBuilding.RoomHaze) thickens with every shot
##   fired and every blast inside, and clears over a minute or two: gunsmoke hanging in the
##   lamps' pools (GunSmoke's own clouds are the first seconds).
##
## Off, it takes everything it made away and puts back what it changed: the old look exactly.

const TUNING := "res://config/room_light.tres"
const GROUP := &"room_light"
## A front window's area (MoonWindows' openings): an opening this size lets in what its spot did.
const WINDOW_AREA := 1.1 * 1.35
## The rays: the flame's own hitbox and prop aside, from just off the flame.
const RAY_START := 0.04
## The share of a lamp's light one ray's patch stands for, as a diffuse surface gives it back:
## (4 pi / 6) / pi.
const PATCH_SHARE := 2.0 / 3.0

static var tuning: RoomLightTuning
## On now (MoonWindows stands its spots down while it is).
static var active := false

## Every building with a room: building -> Room.
var _rooms := {}
## Every lamp seen: lamp -> Lamp.
var _lamps := {}
var _since := 0.0
## Mean colour of each wood's texture (look or wood -> Color).
static var _albedo := {}


class Lamp:
	var pos := Vector3.INF
	var shines := false
	var energy := 0.0
	var range_ := 0.0
	var falloff := 0.0
	var room: FalseFrontBuilding
	## [{pos, normal, gain (per unit of the lamp's light energy), colour}]
	var hits: Array = []
	var dirty := true


class Room:
	var building: FalseFrontBuilding
	var spots: Array[SpotLight3D] = []
	## Per spot: [[lamp, gain], ...]
	var feeds: Array = []
	var merge_due := true
	## The openings: {wall, rect (along, up), kind (door/window/hole), spot}
	var openings: Array = []
	## Walls waiting to be probed for holes: {wall, rect, wait}
	var pending: Array = []
	## Being probed: {wall, rect, cell, cells: PackedVector2Array, open: PackedVector2Array, next}
	var probing: Array = []
	var haze_extra := 0.0
	var haze_base := -1.0
	var haze_written := -1.0
	var colour_was := Color()
	var probe: ReflectionProbe
	var haze: FogVolume


static func tune() -> RoomLightTuning:
	if tuning == null:
		tuning = load(TUNING) as RoomLightTuning if ResourceLoader.exists(TUNING) else RoomLightTuning.new()
	return tuning


static func find(tree: SceneTree) -> RoomLight:
	return tree.get_first_node_in_group(GROUP) as RoomLight if tree else null


## On now (MoonWindows asks: it can't name this class, the -s tools compile it).
func running() -> bool:
	return active


func _ready() -> void:
	add_to_group(GROUP)
	tune()
	Events.member_broken.connect(_on_member_broken)
	Events.shot_fired.connect(func(origin: Vector3, _d: Vector3, _s: Node) -> void: _add_haze(origin, tune().haze_per_shot))
	Events.exploded.connect(func(at: Vector3, kg: float) -> void: _add_haze(at, tune().haze_per_blast_kg * kg))


func _exit_tree() -> void:
	if active:
		_stop()


func _process(delta: float) -> void:
	var on: bool = Settings.room_light
	if on != active:
		if on:
			_start()
		else:
			_stop()
	if not active:
		return
	var t := Prof.start()
	_since += delta
	if _since >= tune().refresh_seconds:
		_since = 0.0
		_refresh()
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	for b: FalseFrontBuilding in _rooms.keys():
		if not is_instance_valid(b):
			_rooms.erase(b)
			continue
		var r: Room = _rooms[b]
		if r.merge_due and _lamps_ready(r):
			_merge(r)
		_flicker(r)
		_fill(r)
		_openings_light(r, clock)
		_haze(r, delta)
	Prof.stop(&"room_light", t)


func _physics_process(delta: float) -> void:
	if not active:
		return
	var t := Prof.start()
	var budget := tune().lamps_per_tick
	for lamp: OilLamp in _lamps.keys():
		if budget <= 0:
			break
		var l: Lamp = _lamps[lamp]
		if l.dirty and is_instance_valid(lamp):
			_cast(lamp, l)
			budget -= 1
	var rays := tune().hole_rays_per_tick
	for r: Room in _rooms.values():
		if not is_instance_valid(r.building):
			continue
		for p: Dictionary in r.pending.duplicate():
			p.wait -= delta
			if p.wait <= 0.0:
				r.pending.erase(p)
				_begin_probe(r, p.wall, p.rect)
				if p.get("again", false):
					# Once more when the rubble's down (a board still leaning in the hole hides it).
					r.pending.append({"wall": p.wall, "rect": p.rect, "wait": tune().hole_settle, "again": false})
		while rays > 0 and not r.probing.is_empty():
			rays = _probe_step(r, r.probing[0], rays)
			if r.probing[0].next >= (r.probing[0].cells as PackedVector2Array).size():
				_end_probe(r, r.probing.pop_front())
	Prof.stop(&"room_light", t)


# --- on and off ----------------------------------------------------------------------------------

func _start() -> void:
	active = true
	_since = tune().refresh_seconds
	for s in get_tree().get_nodes_in_group(&"structures"):
		if s is FalseFrontBuilding:
			_room_for(s as FalseFrontBuilding)


func _stop() -> void:
	active = false
	for r: Room in _rooms.values():
		if not is_instance_valid(r.building):
			continue
		for s in r.spots:
			s.queue_free()
		for o: Dictionary in r.openings:
			if is_instance_valid(o.spot):
				(o.spot as Node).queue_free()
		if is_instance_valid(r.probe):
			r.probe.remove_meta(&"room_light_scale")
			r.probe.ambient_color = r.colour_was
		if is_instance_valid(r.haze) and r.haze_base >= 0.0 and r.haze.material is FogMaterial:
			# Put back what it was, unless something else set it since.
			var fm := r.haze.material as FogMaterial
			if is_equal_approx(fm.density, r.haze_written):
				fm.density = r.haze_base
	_rooms.clear()
	_lamps.clear()


func _room_for(b: FalseFrontBuilding) -> Room:
	if _rooms.has(b):
		return _rooms[b]
	var r := Room.new()
	r.building = b
	r.probe = b.get_node_or_null(^"InteriorAmbient") as ReflectionProbe
	if r.probe:
		r.colour_was = r.probe.ambient_color
		r.probe.ambient_color = tune().ambient_colour
	r.haze = b.get_node_or_null(^"RoomHaze") as FogVolume
	_rooms[b] = r
	# The building's own openings: the door and, if it has them, the front windows (MoonWindows').
	var rects: Array[Rect2] = [b.door_rect]
	if b.front_windows:
		var f := b.floor_top
		rects.append_array([Rect2(0.55, f + 0.67, 1.1, 1.35), Rect2(b.width - 1.65, f + 0.67, 1.1, 1.35)])
	for i in rects.size():
		_add_opening(r, &"front", rects[i], &"door" if i == 0 else &"window")
	return r


# --- the lamps' bounce -----------------------------------------------------------------------------

## Every lamp looked at: new ones, moved ones, lit or put out, their light's reach changed.
func _refresh() -> void:
	var seen := {}
	for n in get_tree().get_nodes_in_group(&"oil_lamps"):
		var lamp := n as OilLamp
		if lamp == null or not lamp.is_inside_tree() or lamp._light == null:
			continue
		seen[lamp] = true
		var l: Lamp = _lamps.get(lamp)
		if l == null:
			l = Lamp.new()
			_lamps[lamp] = l
		var pos := lamp.light_position()
		var shines := lamp.shines() and lamp._light.visible
		var moved := pos.distance_to(l.pos) > tune().lamp_moved
		var light := lamp._light
		var changed := shines != l.shines or not is_equal_approx(light.omni_range, l.range_) \
				or not is_equal_approx(light.omni_attenuation, l.falloff) or not is_equal_approx(lamp.energy, l.energy)
		if moved or changed:
			var was := l.room
			l.room = _building_at(pos) if moved else l.room
			l.pos = pos
			l.shines = shines
			l.energy = lamp.energy
			l.range_ = light.omni_range
			l.falloff = light.omni_attenuation
			l.dirty = shines and l.room != null
			if not l.dirty:
				l.hits.clear()
			for b in [was, l.room]:
				if b != null and _rooms.has(b):
					(_rooms[b] as Room).merge_due = true
	for lamp in _lamps.keys():
		if not seen.has(lamp):
			var l: Lamp = _lamps[lamp]
			if l.room and _rooms.has(l.room):
				(_rooms[l.room] as Room).merge_due = true
			_lamps.erase(lamp)


## The building whose room holds `at` (inside its walls, floor to ridge), or null.
func _building_at(at: Vector3) -> FalseFrontBuilding:
	for b: FalseFrontBuilding in _rooms.keys():
		if not is_instance_valid(b):
			continue
		var local := b.global_transform.affine_inverse() * at
		var ridge := b.wall_height + b.width * 0.5 * tan(deg_to_rad(b.roof_pitch_degrees))
		if local.x > 0.0 and local.x < b.width and local.z > 0.0 and local.z < b.depth and local.y > -0.5 and local.y < ridge:
			return b
	return null


func _lamps_ready(r: Room) -> bool:
	for lamp: OilLamp in _lamps.keys():
		var l: Lamp = _lamps[lamp]
		if l.room == r.building and l.dirty:
			return false
	return true


## A lamp's three rays (physics frame): the floor under it, what's over it, the nearest wall.
func _cast(lamp: OilLamp, l: Lamp) -> void:
	l.dirty = false
	l.hits.clear()
	var b := l.room
	if b == null or not is_instance_valid(b):
		return
	var space := World.space(b)
	if space == null:
		return
	var from := lamp.light_position()
	var reach := l.range_
	var exclude: Array[RID] = []
	var own := lamp.hitbox_rid()
	if own.is_valid():
		exclude.append(own)
	var holder := lamp.get_parent()
	for i in 3:  # a lamp prop's own body (a sconce's bracket, a lamp's foot)
		if holder is CollisionObject3D and not holder is StructureMember:
			exclude.append((holder as CollisionObject3D).get_rid())
		holder = holder.get_parent() if holder else null
	var axes := b.global_transform.basis
	var ups: Array[Vector3] = [Vector3.DOWN, Vector3.UP]
	for dir in ups:
		var hit := _ray(space, from, dir, reach, exclude)
		if not hit.is_empty():
			l.hits.append(_bounce(lamp, l, from, hit))
	var wall := {}
	for dir: Vector3 in [axes.x, -axes.x, axes.z, -axes.z]:
		var hit := _ray(space, from, dir.normalized(), reach, exclude)
		if not hit.is_empty() and (wall.is_empty() or from.distance_to(hit.position) < from.distance_to(wall.position)):
			wall = hit
	if not wall.is_empty():
		l.hits.append(_bounce(lamp, l, from, wall))


static func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, dir: Vector3, reach: float, exclude: Array[RID]) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from + dir * RAY_START, from + dir * reach, Layers.WORLD)
	q.exclude = exclude
	return space.intersect_ray(q)


## What one ray's surface gives back, per unit of its lamp's light energy.
func _bounce(lamp: OilLamp, l: Lamp, from: Vector3, hit: Dictionary) -> Dictionary:
	var tn := tune()
	var d := from.distance_to(hit.position)
	var albedo := surface_colour(hit.collider)
	# How much it gives back: its lightness as it looks (sRGB), the painted look's, not linear's.
	var lightness := albedo.linear_to_srgb().get_luminance()
	var hue := albedo / maxf(maxf(albedo.r, albedo.g), maxf(albedo.b, 0.001))
	var colour := Color.WHITE.lerp(Color(hue.r, hue.g, hue.b), tn.tint) * lamp._light.light_color
	# A ray stands for a sixth of the lamp's light (4 pi / 6 sr): what falls on that patch, as
	# a diffuse surface gives it back (over pi), the same near or far (a far patch is bigger and
	# dimmer) but inside the lamp's range (the engine's window).
	return {"pos": hit.position, "normal": hit.normal, "colour": colour,
			"gain": tn.bounce_gain * lightness * PATCH_SHARE * omni_window(d, l.range_)}


## The window the engine puts on an omni light's reach: (1 - (d/range)^4)^2.
static func omni_window(d: float, reach: float) -> float:
	var w := maxf(1.0 - pow(d / maxf(reach, 0.001), 4.0), 0.0)
	return w * w


## The engine's own omni falloff: Godot's (1 - (d/range)^4)^2 window over d^-attenuation.
static func omni_falloff(d: float, reach: float, attenuation: float) -> float:
	var nd := pow(d / maxf(reach, 0.001), 4.0)
	var w := maxf(1.0 - nd, 0.0)
	return w * w * pow(maxf(d, 0.0001), -attenuation)


## A surface's colour: its wood's texture averaged (a member's look or wood), else the default.
static func surface_colour(collider: Object) -> Color:
	var m := collider as StructureMember
	if m == null:
		return tune().default_albedo
	var wood := m.look if m.look != &"" else m.wood
	if _albedo.has(wood):
		return _albedo[wood]
	var c := tune().default_albedo
	var tex := WoodMaterials.texture_for(wood)
	var img: Image = tex.get_image() if tex else null
	if img and not img.is_empty():
		img = img.duplicate()
		if img.is_compressed():
			img.decompress()
		img.resize(4, 4, Image.INTERPOLATE_BILINEAR)
		var sum := Color(0, 0, 0, 0)
		for y in 4:
			for x in 4:
				sum += img.get_pixel(x, y).srgb_to_linear()
		c = Color(sum.r / 16.0, sum.g / 16.0, sum.b / 16.0)
	_albedo[wood] = c
	return c


## The room's bounces merged into its spots: near ones facing the same way are one light, the
## strongest max_bounces_per_room kept.
func _merge(r: Room) -> void:
	r.merge_due = false
	var tn := tune()
	var clusters: Array = []  # {pos, normal, weight, colour, feeds}
	for lamp: OilLamp in _lamps.keys():
		var l: Lamp = _lamps[lamp]
		if l.room != r.building or not l.shines:
			continue
		for h: Dictionary in l.hits:
			var w: float = h.gain * lamp.energy
			if w <= 0.0:
				continue
			var into: Dictionary = {}
			for c: Dictionary in clusters:
				if (c.pos as Vector3).distance_to(h.pos) < tn.bounce_merge and (c.normal as Vector3).dot(h.normal) > 0.7:
					into = c
					break
			if into.is_empty():
				clusters.append({"pos": h.pos, "normal": h.normal, "weight": w, "colour": h.colour * w, "feeds": [[lamp, h.gain]]})
			else:
				var total: float = into.weight + w
				into.pos = (into.pos * into.weight + h.pos * w) / total
				into.normal = ((into.normal as Vector3) * into.weight + (h.normal as Vector3) * w).normalized()
				into.weight = total
				into.colour = (into.colour as Color) + h.colour * w
				(into.feeds as Array).append([lamp, h.gain])
	clusters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.weight > b.weight)
	clusters = clusters.filter(func(c: Dictionary) -> bool: return c.weight >= tn.min_bounce_energy)
	clusters.resize(mini(clusters.size(), tn.max_bounces_per_room))
	while r.spots.size() > clusters.size():
		r.spots.pop_back().queue_free()
	while r.spots.size() < clusters.size():
		var s := SpotLight3D.new()
		s.name = "Bounce%d" % r.spots.size()
		s.shadow_enabled = false
		s.light_specular = 0.0
		s.add_to_group(&"room_light_bounce")
		r.building.add_child(s)
		r.spots.append(s)
	r.feeds.clear()
	for i in clusters.size():
		var c: Dictionary = clusters[i]
		var s := r.spots[i]
		var n: Vector3 = c.normal
		var up := Vector3.UP if absf(n.y) < 0.9 else Vector3.FORWARD
		s.global_transform = Transform3D(Basis.looking_at(n, up), (c.pos as Vector3) + n * tn.bounce_offset)
		var col: Color = c.colour / maxf(c.weight, 0.0001)
		s.light_color = col
		s.spot_angle = tn.bounce_spread
		s.spot_range = maxf(tn.bounce_reach_min, tn.bounce_reach * _reach_of(c.feeds))
		s.spot_attenuation = tn.bounce_attenuation
		s.spot_angle_attenuation = tn.bounce_angle_attenuation
		s.light_volumetric_fog_energy = tn.bounce_haze
		s.light_energy = 0.0
		r.feeds.append(c.feeds)
	_flicker(r, true)


func _reach_of(feeds: Array) -> float:
	var most := 0.0
	for f: Array in feeds:
		var lamp: OilLamp = f[0]
		if is_instance_valid(lamp) and _lamps.has(lamp):
			most = maxf(most, (_lamps[lamp] as Lamp).range_)
	return most


## Each spot's energy from its lamps' light now (their flicker; a lamp gone out gives none till
## the next refresh merges it away).
func _flicker(r: Room, force := false) -> void:
	for i in r.spots.size():
		var e := 0.0
		for f: Array in r.feeds[i]:
			var lamp: OilLamp = f[0]
			if is_instance_valid(lamp) and lamp._light and lamp._light.visible and not lamp.broken:
				e += float(f[1]) * lamp._light.light_energy
		var s := r.spots[i]
		if force or absf(s.light_energy - e) > 0.005 * maxf(e, 0.01):
			s.light_energy = e
		if s.visible != (e > 0.0):
			s.visible = e > 0.0


# --- the room's own fill -------------------------------------------------------------------------

func _fill(r: Room) -> void:
	if not is_instance_valid(r.probe):
		return
	var share := 1.0
	if tune().ambient_follows_lamps:
		var all := 0.0
		var lit := 0.0
		for lamp: OilLamp in _lamps.keys():
			var l: Lamp = _lamps[lamp]
			if l.room == r.building:
				all += lamp.energy
				if l.shines and l.room == r.building:
					lit += lamp.energy
		share = lit / all if all > 0.0 else 1.0
	r.probe.set_meta(&"room_light_scale", tune().ambient_scale * share)
	if r.probe.ambient_color != tune().ambient_colour:
		r.probe.ambient_color = tune().ambient_colour


# --- openings ------------------------------------------------------------------------------------

func _add_opening(r: Room, wall: StringName, rect: Rect2, kind: StringName) -> Dictionary:
	var s := SpotLight3D.new()
	s.name = "Opening%d" % r.openings.size()
	s.shadow_enabled = false
	s.light_specular = 0.2
	s.light_volumetric_fog_energy = 0.6  # a shaft in the room's haze (MoonWindows')
	s.light_energy = 0.0
	s.visible = false
	s.add_to_group(&"room_light_opening")
	r.building.add_child(s)
	var b := r.building
	var w := _wall_frame(b, wall)
	var top := Vector2(rect.get_center().x, rect.end.y - 0.1)
	var inward: Vector3 = w.inward
	var at: Vector3 = (w.origin as Vector3) + (w.along as Vector3) * top.x + Vector3.UP * top.y + inward * (FalseFrontBuilding.STUD_D + 0.05)
	var dir := (inward * cos(deg_to_rad(38.0)) + Vector3.DOWN * sin(deg_to_rad(38.0))).normalized()
	s.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), at)
	var o := {"wall": wall, "rect": rect, "kind": kind, "spot": s}
	r.openings.append(o)
	return o


## A wall in the building's own space: where along it starts, which way along, which way in.
static func _wall_frame(b: FalseFrontBuilding, wall: StringName) -> Dictionary:
	match wall:
		&"back":
			return {"origin": Vector3(0, 0, b.depth), "along": Vector3.RIGHT, "inward": Vector3.FORWARD}
		&"left":
			return {"origin": Vector3.ZERO, "along": Vector3.BACK, "inward": Vector3.RIGHT}
		&"right":
			return {"origin": Vector3(b.width, 0, 0), "along": Vector3.BACK, "inward": Vector3.LEFT}
	return {"origin": Vector3.ZERO, "along": Vector3.RIGHT, "inward": Vector3.BACK}


## Every opening's spot to the sky now: the moon's by night, the day's sky by day.
func _openings_light(r: Room, clock: DayCycle) -> void:
	if clock == null or clock.config == null:
		return
	var tn := tune()
	var cfg := clock.config
	var moon := 0.0
	if clock.moon and cfg.moon_max_energy > 0.0 and clock.moon.visible:
		moon = clock.moon.light_energy / cfg.moon_max_energy
	var day := clock.get_daylight()
	for o: Dictionary in r.openings:
		var s := o.spot as SpotLight3D
		if not is_instance_valid(s):
			continue
		var rect: Rect2 = o.rect
		var size := clampf(sqrt(float(o.get("area", rect.get_area())) / WINDOW_AREA), 0.15, sqrt(tn.opening_max_area / WINDOW_AREA))
		var night_e := cfg.moon_window_energy * moon * tn.opening_night_gain
		var day_e := tn.opening_day_energy * day
		var e := (night_e + day_e) * size
		var shown := e > 0.001
		if s.visible != shown:
			s.visible = shown
		if not shown:
			continue
		# Written only when it's moved on (each write wakes the render thread when it's on).
		var colour := cfg.moon_window_colour.lerp(tn.opening_day_colour, day_e / maxf(night_e + day_e, 0.0001))
		if absf(s.light_energy - e) > 0.002 * e or not s.light_color.is_equal_approx(colour):
			s.light_energy = e
			s.light_color = colour
		if not o.get("shaped", false) or s.spot_range != cfg.moon_window_reach:
			o["shaped"] = true
			s.spot_range = cfg.moon_window_reach
			s.spot_angle = clampf(rad_to_deg(atan2(rect.size.x * 0.6, 2.0)) + 34.0, 15.0, 80.0)
			s.spot_attenuation = 0.8
			s.spot_angle_attenuation = 5.0


## A member broke: if it was in one of a building's walls, that patch of wall is probed for a hole
## once the pieces are clear.
func _on_member_broken(id: StringName) -> void:
	if not active:
		return
	var sid := StringName(String(id).get_slice("/", 0))
	for b: FalseFrontBuilding in _rooms.keys():
		if not is_instance_valid(b) or b.structure_id != sid:
			continue
		var m := b.get_member(id)
		if m == null:
			return
		var found := wall_patch(b, m.transform * AABB(-m.size * 0.5, m.size))
		if found.is_empty():
			return
		var r: Room = _rooms[b]
		# One patch for every break that touches it (a stud, then the boards either side).
		var rect: Rect2 = found.rect
		for p: Dictionary in r.pending.duplicate():
			if p.wall == found.wall and (p.rect as Rect2).grow(0.2).intersects(rect):
				rect = rect.merge(p.rect)
				r.pending.erase(p)
		r.pending.append({"wall": found.wall, "rect": rect, "wait": tune().hole_delay, "again": true})
		return


## Which wall a member's box (building space) is in, and its patch of it (along, up); empty if none.
static func wall_patch(b: FalseFrontBuilding, box: AABB) -> Dictionary:
	var c := box.get_center()
	var near := 0.25
	var thin := 0.3
	if box.size.y < 0.15:
		return {}  # lying down (a floor board, a plate): not a wall's
	if box.size.z < thin and absf(c.z) < near and c.x > 0.0 and c.x < b.width:
		return {"wall": &"front", "rect": Rect2(box.position.x, box.position.y, box.size.x, box.size.y)}
	if box.size.z < thin and absf(c.z - b.depth) < near and c.x > 0.0 and c.x < b.width:
		return {"wall": &"back", "rect": Rect2(box.position.x, box.position.y, box.size.x, box.size.y)}
	if box.size.x < thin and absf(c.x) < near and c.z > 0.0 and c.z < b.depth:
		return {"wall": &"left", "rect": Rect2(box.position.z, box.position.y, box.size.z, box.size.y)}
	if box.size.x < thin and absf(c.x - b.width) < near and c.z > 0.0 and c.z < b.depth:
		return {"wall": &"right", "rect": Rect2(box.position.z, box.position.y, box.size.z, box.size.y)}
	return {}


## A patch of wall to probe: it and any hole already found that it touches (that hole is probed
## again with it, and replaced).
func _begin_probe(r: Room, wall: StringName, rect: Rect2) -> void:
	rect = rect.grow(0.1)
	for o: Dictionary in r.openings.duplicate():
		if o.kind == &"hole" and o.wall == wall and (o.rect as Rect2).grow(0.1).intersects(rect):
			rect = rect.merge(o.rect)
			if is_instance_valid(o.spot):
				(o.spot as Node).queue_free()
			r.openings.erase(o)
	var tn := tune()
	var cell := maxf(tn.hole_cell, sqrt(rect.get_area() / float(tn.hole_max_cells)))
	var cells := PackedVector2Array()
	var y := rect.position.y + cell * 0.5
	while y < rect.end.y:
		var x := rect.position.x + cell * 0.5
		while x < rect.end.x:
			var at := Vector2(x, y)
			if not _in_own_opening(r, wall, at):
				cells.append(at)
			x += cell
		y += cell
	r.probing.append({"wall": wall, "rect": rect, "cell": cell, "cells": cells, "open": PackedVector2Array(), "next": 0})


func _in_own_opening(r: Room, wall: StringName, at: Vector2) -> bool:
	for o: Dictionary in r.openings:
		if o.kind != &"hole" and o.wall == wall and (o.rect as Rect2).has_point(at):
			return true
	return false


## Rays straight through the wall at each cell: nothing in the way is open.
func _probe_step(r: Room, p: Dictionary, rays: int) -> int:
	var b := r.building
	var space := World.space(b)
	var w := _wall_frame(b, p.wall)
	var cells: PackedVector2Array = p.cells
	var open: PackedVector2Array = p.open  # (a packed array is a value: written back below)
	while rays > 0 and p.next < cells.size():
		var c := cells[p.next]
		p.next += 1
		rays -= 1
		var on: Vector3 = (w.origin as Vector3) + (w.along as Vector3) * c.x + Vector3.UP * c.y
		var inward: Vector3 = w.inward
		var from := b.to_global(on - inward * 0.15)
		var to := b.to_global(on + inward * (FalseFrontBuilding.STUD_D + 0.08))
		var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
		if space.intersect_ray(q).is_empty():
			open.append(c)
	p.open = open
	return rays


func _end_probe(r: Room, p: Dictionary) -> void:
	var open: PackedVector2Array = p.open
	var cell: float = p.cell
	var area := open.size() * cell * cell
	if area < tune().hole_min_area:
		return
	var box := Rect2(open[0], Vector2.ZERO)
	for c in open:
		box = box.expand(c)
	box = box.grow(cell * 0.5)
	# A hole found beside one already there (probed apart) is one hole.
	for h: Dictionary in r.openings.duplicate():
		if h.kind == &"hole" and h.wall == p.wall and (h.rect as Rect2).grow(cell).intersects(box):
			box = box.merge(h.rect)
			area += float(h.get("area", 0.0))
			if is_instance_valid(h.spot):
				(h.spot as Node).queue_free()
			r.openings.erase(h)
	var o := _add_opening(r, p.wall, box, &"hole")
	o["area"] = area  # what it lets in is its open area's, not its bounding box's


# --- haze ----------------------------------------------------------------------------------------

func _add_haze(at: Vector3, amount: float) -> void:
	if not active or amount <= 0.0:
		return
	var b := _building_at(at)
	if b and _rooms.has(b):
		var r: Room = _rooms[b]
		r.haze_extra = minf(r.haze_extra + amount, tune().haze_max)


func _haze(r: Room, delta: float) -> void:
	if not is_instance_valid(r.haze) or not r.haze.material is FogMaterial:
		return
	var fm := r.haze.material as FogMaterial
	if r.haze_base < 0.0 or not is_equal_approx(fm.density, r.haze_written):
		r.haze_base = fm.density  # (set by something else: the look's night haze)
	if r.haze_extra > 0.0:
		r.haze_extra *= pow(0.5, delta / maxf(tune().haze_half_life, 0.01))
		if r.haze_extra < 0.0002:
			r.haze_extra = 0.0
	var want := r.haze_base + r.haze_extra
	if not is_equal_approx(fm.density, want):
		fm.density = want
	r.haze_written = fm.density


# --- for the tests and the lab -------------------------------------------------------------------

func bounces_of(b: FalseFrontBuilding) -> Array[SpotLight3D]:
	return (_rooms[b] as Room).spots if _rooms.has(b) else ([] as Array[SpotLight3D])


func openings_of(b: FalseFrontBuilding) -> Array:
	return (_rooms[b] as Room).openings if _rooms.has(b) else []


func haze_extra_of(b: FalseFrontBuilding) -> float:
	return (_rooms[b] as Room).haze_extra if _rooms.has(b) else 0.0


func busy() -> bool:
	for l: Lamp in _lamps.values():
		if l.dirty:
			return true
	for r: Room in _rooms.values():
		if r.merge_due or not r.pending.is_empty() or not r.probing.is_empty():
			return true
	return false


## Every lamp looked at again now (the lab's dials changed: LookPreset `room.<dial>`).
func redo() -> void:
	for l: Lamp in _lamps.values():
		l.pos = Vector3.INF
	_since = tune().refresh_seconds

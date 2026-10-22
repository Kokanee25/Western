class_name FloorMarks
extends Node3D
## What's on the boards (docs/briefs/mopping.md): mud and dust boots bring in off the street, wet
## patches where a drink went down, and the stains they soak into bare wood. One per world (group
## `floor_marks`; `find`, `ensure`).
##
## A sparse grid of CELL cells over every wooden surface something lands on (a floor, the bar top,
## a table: found by a ray onto a structure member facing up), each holding dirt (g/m²), liquid (ml,
## by kind) and stain (ml soaked in, by kind). The grid is the water lab's substrate: its spills will
## move liquid cell to cell (roadmap, water lab 2); here liquid stays where it fell, dries and soaks.
## - **Boots:** every walker (people, the player) picks up dirt on the street, `boot_pickup` a metre
##   (mud `mud_pickup` times faster), and sheds it step by step onto boards, most in the first
##   `shed_metres`; so it builds at the door and along the bar.
## - **Spills:** `Events.liquid_spilled` lays its litres as a `film_mm` film round where they landed
##   (a broken bottle, a knocked cup); a film dries `evaporate` mm a game hour, `soak` of it a game
##   hour going into the wood as a stain.
## - **Blood** is Blood's own painted marks; `take` reaches them too (Blood.take).
## - **Drawn** as one Decal a CHUNK of cells, a texel a cell (dust, wet and dark, stain), redrawn
##   only when its cells change, at most a few chunks a tick; decals draw on the world's layer only.
## `take(at, radius, share)` lifts a share of what's under a mop or a rag; `mess(at, radius)` sums it.

const CELL := 0.125
const CHUNK := 32
const BAND := 0.05
## Members walkers track dirt onto (the boards); liquid lands on any wooden surface facing up.
const FLOOR_KINDS := [&"floor_board"]
const STEP := 0.25  ## s between its passes (boots, drying, drawing)
const STRIDE := 0.35  ## m between the marks a pair of boots leaves
const FOOT_APART := 0.11  ## m each boot is off the line he walks
## Game hours a real second with no town clock (a lab): the game's default day, 24 h in 45 min.
const HOURS_PER_SECOND := 24.0 / 2700.0
const DRAW_PER_STEP := 4

var tuning: FloorMarksTuning
## Vector3i(x, band, z) -> {"y", "dirt" (g/m²), "mud" (share of that dirt that's mud), "liq": {kind: ml}, "stain": {kind: ml}}
var cells := {}
var _wet := {}  # cells holding liquid (what dries)
var _chunks := {}  # Vector3i(cx, band, cz) -> Decal
var _dirty_chunks := {}
var _walkers := {}  # node -> {"boots": g, "mud": share, "last": Vector3, "on_floor": bool, "side": 1.0, "acc": m}
var _t := 0.0
var _day: Node


func _ready() -> void:
	add_to_group(&"floor_marks")
	if tuning == null:
		tuning = load("res://config/floor_marks.tres")
	Events.liquid_spilled.connect(_on_spilled)


static func find(tree: SceneTree) -> FloorMarks:
	return tree.get_first_node_in_group(&"floor_marks") as FloorMarks if tree else null


## The world's, made under `parent` if there isn't one.
static func ensure(parent: Node) -> FloorMarks:
	var fm := find(parent.get_tree())
	if fm == null:
		fm = FloorMarks.new()
		fm.name = "FloorMarks"
		parent.add_child(fm)
	return fm


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_t -= delta
	if _t <= 0.0:
		_t = STEP
		_track_boots()
		if _day == null or not is_instance_valid(_day):
			_day = get_tree().get_first_node_in_group(&"day_cycle")
		if _day == null:
			age(STEP * HOURS_PER_SECOND)  # (with a town clock, DayCycle.pass_hours ages it)
	_draw_some()
	Prof.stop(&"floor_marks", t)


# --- Where things land -------------------------------------------------------------------------

## The wooden surface facing up under `at` (within `reach` above and below): {at, member, floor}
## (floor: one of FLOOR_KINDS), or empty.
func surface_at(at: Vector3, reach := 0.3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	# Right on the seam between two boards a ray meets a board's edge: a few mm off, the top.
	for off: Vector3 in [Vector3.ZERO, Vector3(0.006, 0, 0.006), Vector3(-0.006, 0, -0.006)]:
		var q := PhysicsRayQueryParameters3D.create(at + off + Vector3.UP * reach, at + off - Vector3.UP * reach, Layers.WORLD)
		var hit := space.intersect_ray(q)
		if hit.is_empty() or not hit.collider is StructureMember:
			return {}
		if (hit.normal as Vector3).y < 0.8:
			continue
		var m := hit.collider as StructureMember
		return {"at": hit.position, "member": m, "floor": m.kind in FLOOR_KINDS}
	return {}


func key(at: Vector3) -> Vector3i:
	return Vector3i(floori(at.x / CELL), roundi(at.y / BAND), floori(at.z / CELL))


func centre(k: Vector3i) -> Vector3:
	var c: Dictionary = cells.get(k, {})
	return Vector3((k.x + 0.5) * CELL, c.get("y", k.y * BAND), (k.z + 0.5) * CELL)


func _cell(k: Vector3i, y: float) -> Dictionary:
	if not cells.has(k):
		cells[k] = {"y": y, "dirt": 0.0, "mud": 0.0, "liq": {}, "stain": {}}
	return cells[k]


func _touched(k: Vector3i) -> void:
	_dirty_chunks[Vector3i(floori(float(k.x) / CHUNK), k.y, floori(float(k.z) / CHUNK))] = true


# --- Dirt --------------------------------------------------------------------------------------

## Dirt on the surface at `at` (g), `mud` the share of it that's wet mud.
func add_dirt(at: Vector3, grams: float, mud := 0.0) -> void:
	if grams <= 0.0:
		return
	var k := key(at)
	var c := _cell(k, at.y)
	var before: float = c.dirt
	c.dirt = before + grams / (CELL * CELL)
	c.mud = (float(c.mud) * before + mud * grams / (CELL * CELL)) / maxf(c.dirt, 1e-6)
	_touched(k)


## Boots: picked up on the street, shed on the boards, a stride at a time.
func _track_boots() -> void:
	var tree := get_tree()
	for n: Node in tree.get_nodes_in_group(&"people") + tree.get_nodes_in_group(&"player"):
		if not n is Node3D or (n is HumanBody and ((n as HumanBody).limp or (n as HumanBody).prone)):
			continue
		var w: Dictionary = _walkers.get_or_add(n, {"boots": 0.0, "mud": 0.0, "last": (n as Node3D).global_position, "side": 1.0, "acc": 0.0})
		var at := (n as Node3D).global_position
		var moved := at - (w.last as Vector3)
		moved.y = 0.0
		var d := moved.length()
		if d < 0.05:
			continue
		if d > 3.0:  # placed, not walked
			w.last = at
			continue
		var under := surface_at(at, 0.35)
		if under.is_empty() or not under.floor:
			# The street: dust, or mud when it's wet.
			var wet := tuning.street_wet
			var pick := tuning.boot_pickup * lerpf(1.0, tuning.mud_pickup, wet) * d
			var room := maxf(tuning.boot_max - float(w.boots), 0.0)
			var got := minf(pick, room)
			w.mud = (float(w.mud) * float(w.boots) + wet * got) / maxf(float(w.boots) + got, 1e-6)
			w.boots = float(w.boots) + got
		else:
			_shed(n as Node3D, w, w.last as Vector3, at, (under.at as Vector3).y)
		w.last = at
	for gone in _walkers.keys():
		if not is_instance_valid(gone):
			_walkers.erase(gone)


func _shed(n: Node3D, w: Dictionary, from: Vector3, to: Vector3, y: float) -> void:
	var along := to - from
	along.y = 0.0
	var d := along.length()
	var dir := along / d
	var across := Vector3(-dir.z, 0.0, dir.x)
	var walked := 0.0
	var acc: float = w.acc
	while walked < d:
		var stride := minf(STRIDE - acc, d - walked)
		walked += stride
		acc += stride
		if acc < STRIDE - 1e-4:
			break
		acc = 0.0
		var lose := float(w.boots) * (1.0 - exp(-STRIDE / tuning.shed_metres))
		if lose < 1e-4:
			continue
		w.boots = float(w.boots) - lose
		w.side = -float(w.side)
		var foot := from + dir * walked + across * FOOT_APART * float(w.side)
		foot.y = y
		add_dirt(foot, lose, float(w.mud))
	w.acc = acc


## How much dirt a walker's boots carry now (g; tests and the lab).
func boots_of(n: Node) -> float:
	return float(_walkers.get(n, {}).get("boots", 0.0))


# --- Liquid ------------------------------------------------------------------------------------

func _on_spilled(at: Vector3, liquid: StringName, litres: float, _source: Node) -> void:
	add_liquid(at, liquid, litres * 1000.0)


## `ml` of a liquid down at `at`: lies as a film round it on whatever surface is there (nothing on
## the street's dirt: it soaks straight in). `radius` < 0: as wide as a `film_mm` film of it.
func add_liquid(at: Vector3, kind: StringName, ml: float, radius := -1.0) -> void:
	if ml <= 0.0:
		return
	var under := surface_at(at, 0.4)
	if under.is_empty():
		return
	var y: float = (under.at as Vector3).y
	var r := radius if radius > 0.0 else clampf(sqrt(ml * 1e-6 / (tuning.film_mm * 1e-3) / PI), CELL * 0.5, tuning.spread_max)
	var ks := _disc(under.at, r)
	var each := ml / ks.size()
	for k: Vector3i in ks:
		var p := centre(k)
		p.y = y
		# Only where there's the same surface (a spill at the bar's edge doesn't float off it).
		if ks.size() > 1 and surface_at(Vector3(p.x, y, p.z), 0.06).is_empty():
			continue
		var c := _cell(k, y)
		c.liq[kind] = float(c.liq.get(kind, 0.0)) + each
		_wet[k] = true
		_touched(k)


func _disc(at: Vector3, r: float) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var k0 := key(at)
	var n := ceili(r / CELL)
	for dx in range(-n, n + 1):
		for dz in range(-n, n + 1):
			var k := Vector3i(k0.x + dx, k0.y, k0.z + dz)
			var p := Vector3((k.x + 0.5) * CELL, at.y, (k.z + 0.5) * CELL)
			if Vector2(p.x - at.x, p.z - at.z).length() <= r + CELL * 0.5:
				out.append(k)
	if out.is_empty():
		out.append(k0)
	return out


## Game hours go by: films dry and soak in.
func age(hours: float) -> void:
	if hours <= 0.0:
		return
	var per_mm := CELL * CELL * 1000.0  # ml a mm deep in a cell
	for k: Vector3i in _wet.keys():
		var c: Dictionary = cells.get(k, {})
		var liq: Dictionary = c.get("liq", {})
		for kind: StringName in liq.keys():
			var ml: float = liq[kind]
			var soaked := ml * (1.0 - exp(-float(tuning.soak.get(kind, 0.1)) * hours))
			var dried := float(tuning.evaporate.get(kind, 0.25)) * per_mm * hours
			if soaked > 0.0:
				c.stain[kind] = float(c.stain.get(kind, 0.0)) + soaked
			ml = maxf(ml - soaked - dried, 0.0)
			if ml < 0.05:
				liq.erase(kind)
			else:
				liq[kind] = ml
		if liq.is_empty():
			_wet.erase(k)
		_touched(k)


# --- Cleaning ------------------------------------------------------------------------------------

## Lift `share` (0..1) of what's within `radius` of `at` (a mop, a rag): dirt, liquid, and a smaller
## share of stains (`stain_share`: soaked in, they come up slowly); blood marks too (Blood.take).
## Returns what came up: {dirt (g), liquid: {kind: ml}, stain (ml), blood (ml)}.
func take(at: Vector3, radius: float, share: float, stain_share := 0.0) -> Dictionary:
	var out := {"dirt": 0.0, "liquid": {}, "stain": 0.0, "blood": 0.0}
	share = clampf(share, 0.0, 1.0)
	for k: Vector3i in _disc(at, radius):
		for band in [-1, 0, 1]:
			var kk := Vector3i(k.x, k.y + band, k.z)
			if not cells.has(kk):
				continue
			var c: Dictionary = cells[kk]
			if absf(float(c.y) - at.y) > 0.12:
				continue
			var got: float = c.dirt * share
			c.dirt -= got
			out.dirt += got * CELL * CELL
			for kind: StringName in (c.liq as Dictionary).keys():
				var ml: float = c.liq[kind] * share
				c.liq[kind] = float(c.liq[kind]) - ml
				out.liquid[kind] = float(out.liquid.get(kind, 0.0)) + ml
				if float(c.liq[kind]) < 0.05:
					c.liq.erase(kind)
			if stain_share > 0.0:
				for kind: StringName in (c.stain as Dictionary).keys():
					var s: float = c.stain[kind] * stain_share
					c.stain[kind] = float(c.stain[kind]) - s
					out.stain += s
			if (c.liq as Dictionary).is_empty():
				_wet.erase(kk)
			_touched(kk)
	out.blood = Blood.take(self, at, radius, share)
	return out


## How much is within `radius` of `at`: {dirt (g), liquid (ml), stain (ml), blood (ml)}.
func mess(at: Vector3, radius: float) -> Dictionary:
	var out := {"dirt": 0.0, "liquid": 0.0, "stain": 0.0, "blood": Blood.amount_near(at, radius)}
	for k: Vector3i in cells:
		var p := centre(k)
		if absf(p.y - at.y) > 0.6 or Vector2(p.x - at.x, p.z - at.z).length() > radius:
			continue
		var c: Dictionary = cells[k]
		out.dirt += float(c.dirt) * CELL * CELL
		for kind: StringName in c.liq:
			out.liquid += float(c.liq[kind])
		for kind: StringName in c.stain:
			out.stain += float(c.stain[kind])
	return out


## The cells within `radius` of `at` worth mopping (dirt past `dirt_min` g/m², any liquid), dirtiest
## first: [[key, how dirty]], for a mop to work along.
func dirty_cells(at: Vector3, radius: float, dirt_min := 4.0) -> Array:
	var out := []
	for k: Vector3i in cells:
		var p := centre(k)
		if absf(p.y - at.y) > 0.6 or Vector2(p.x - at.x, p.z - at.z).length() > radius:
			continue
		var c: Dictionary = cells[k]
		var wet := 0.0
		for kind: StringName in c.liq:
			wet += float(c.liq[kind])
		var score: float = float(c.dirt) / maxf(tuning.dirt_full, 1e-3) + wet / 5.0
		if float(c.dirt) >= dirt_min or wet > 0.5:
			out.append([k, score])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return out


# --- Drawing ---------------------------------------------------------------------------------------

func _draw_some() -> void:
	var n := 0
	for ck: Vector3i in _dirty_chunks.keys():
		_dirty_chunks.erase(ck)
		_draw_chunk(ck)
		n += 1
		if n >= DRAW_PER_STEP:
			break


func _draw_chunk(ck: Vector3i) -> void:
	var img := Image.create(CHUNK, CHUNK, false, Image.FORMAT_RGBA8)
	var any := false
	var y := INF
	var per_mm := CELL * CELL * 1000.0
	for x in CHUNK:
		for z in CHUNK:
			var k := Vector3i(ck.x * CHUNK + x, ck.y, ck.z * CHUNK + z)
			if not cells.has(k):
				continue
			var c: Dictionary = cells[k]
			y = minf(y, float(c.y))
			var col := Color(0, 0, 0, 0)
			var dirt := 1.0 - exp(-float(c.dirt) / tuning.dirt_full)
			if dirt > 0.02:
				col = tuning.dust.lerp(tuning.mud, float(c.mud))
				col.a = dirt * 0.85
			# The strongest stain soaked in, over or under the dirt.
			var stained := 0.0
			var sc := Color(0, 0, 0, 0)
			for kind: StringName in c.stain:
				var s := 1.0 - exp(-float(c.stain[kind]) / tuning.stain_full)
				if s > stained:
					stained = s
					sc = tuning.stain.get(kind, Color(0.3, 0.2, 0.1))
			if stained > 0.02:
				var a := maxf(col.a, stained * 0.7)
				col = Color(sc.r, sc.g, sc.b) if col.a <= 0.0 else Color(col.r, col.g, col.b).lerp(Color(sc.r, sc.g, sc.b), stained)
				col.a = a
			var wet := 0.0
			for kind: StringName in c.liq:
				wet += float(c.liq[kind])
			if wet > 0.05:
				var film := clampf(wet / (per_mm * tuning.film_mm), 0.0, 1.0)
				var dark := Color(0.06, 0.045, 0.035, tuning.wet_dark * (0.4 + 0.6 * film))
				col = dark if col.a <= 0.0 else Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, maxf(col.a, dark.a))
			if col.a > 0.01:
				any = true
				img.set_pixel(x, z, col)
	var d: Decal = _chunks.get(ck)
	if not any:
		if d != null and is_instance_valid(d):
			d.queue_free()
		_chunks.erase(ck)
		return
	if d == null or not is_instance_valid(d):
		d = Decal.new()
		d.name = "FloorMarks_%d_%d_%d" % [ck.x, ck.y, ck.z]
		d.cull_mask = Layers.WORLD
		d.upper_fade = 0.0
		d.lower_fade = 0.0
		d.distance_fade_enabled = true
		d.distance_fade_begin = 30.0
		d.distance_fade_length = 10.0
		add_child(d)
		_chunks[ck] = d
	d.texture_albedo = ImageTexture.create_from_image(img)
	d.size = Vector3(CHUNK * CELL, 0.12, CHUNK * CELL)
	d.global_position = Vector3((ck.x + 0.5) * CHUNK * CELL, y, (ck.z + 0.5) * CHUNK * CELL)
	d.global_basis = Basis.IDENTITY


## How many chunk decals it's drawing (the lab's count of draws).
func chunk_count() -> int:
	return _chunks.size()


func to_dict() -> Dictionary:
	var out := {}
	for k: Vector3i in cells:
		out["%d,%d,%d" % [k.x, k.y, k.z]] = cells[k]
	return out

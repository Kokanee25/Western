class_name SmokeField
extends Node3D
## The smoke round one burning building (docs/briefs/smoke.md): a box of cells, square to the
## world, from the ground to well over its roof and a few metres past it on every side, worked by
## the native plugin's `SmokeGrid` (rising, the ceiling jet, spreading, the wind, thinning: its
## rules are in smoke.rs). Here: the members are drawn into its cells (a member blocks smoke; one
## burnt away, broken or shattered doesn't), and again every couple of seconds as the fire eats them,
## a slice a frame; the burning members put smoke into the open cells beside them; it's stepped 15
## times a second with the wind (`SmokeTuning.wind`, the gun smoke's); and drawn as one FogVolume
## with the smoke as a 3D density texture, for Godot's volumetric fog to light. FireSystem makes one
## per burning building (`around`) and it frees itself once the fire's out and the smoke's gone.
## No native plugin (the web build): `available()` is false and FireFX's particle smoke stands in.

const STEP := 1.0 / 15.0
## Members drawn into the cells a physics frame while the box is re-drawn.
const RASTER_A_FRAME := 200
## The members are drawn in again this often (s): what's burnt away lets smoke through.
const RASTER_EVERY := 2.0
## Cells at most (a big building is cut down to fit, the cells kept their size).
const MAX_CELLS := 70000
## The cells' corners sit this far off round numbers (m), so a wall on a round coordinate (most
## are) falls inside one layer of cells rather than on the line between two (it was drawn two
## cells thick, and a burning board's smoke had nowhere to go but out of the back).
const OFFSET := 0.13

var fire: FireSystem
var tuning: FireTuning
var grid: RefCounted  # SmokeGrid
var cell := 0.5
## The box's lowest corner (world) and its cells along x, y, z.
var origin := Vector3.ZERO
var dims := Vector3i.ONE
## The building it was made for (it's kept while that burns).
var structure: Structure

var _accum := 0.0
var _ready_cells := false
var _raster: Array[StructureMember] = []
var _raster_at := 0
var _solid := PackedByteArray()
var _raster_wait := 0.0
## Member -> the open cells beside it its smoke goes into.
var _vents := {}
var _quiet := 0.0
var _wind := Vector3.ZERO

var _fog: FogVolume
var _tex: ImageTexture3D
var _drawn_step := -1


static func available() -> bool:
	return ClassDB.class_exists(&"SmokeGrid")


## A field round `box` (world), made a child of the fire.
static func around(fire_system: FireSystem, box: AABB, building: Structure = null) -> SmokeField:
	var f := SmokeField.new()
	f.fire = fire_system
	f.tuning = fire_system.tuning
	f.structure = building
	f.cell = fire_system.tuning.smoke_cell
	var m := fire_system.tuning.smoke_margin
	var lo := Vector3(box.position.x - m, minf(box.position.y, 0.0), box.position.z - m)
	lo = ((lo - Vector3.ONE * OFFSET) / f.cell).floor() * f.cell + Vector3.ONE * OFFSET
	lo.y = minf(lo.y, minf(box.position.y, 0.0) - 0.12)
	var hi := Vector3(box.end.x + m, box.end.y + fire_system.tuning.smoke_above, box.end.z + m)
	var n := Vector3i(ceili((hi.x - lo.x) / f.cell), ceili((hi.y - lo.y) / f.cell), ceili((hi.z - lo.z) / f.cell))
	while n.x * n.y * n.z > MAX_CELLS:
		n.y = maxi(4, int(n.y * 0.9))
		if n.x * n.y * n.z > MAX_CELLS:
			n.x = maxi(4, int(n.x * 0.95))
			n.z = maxi(4, int(n.z * 0.95))
	f.dims = n
	f.origin = lo
	f.name = "SmokeField"
	fire_system.add_child(f)
	return f


func _ready() -> void:
	grid = ClassDB.instantiate(&"SmokeGrid")
	grid.call(&"setup", dims.x, dims.y, dims.z, cell)
	for k: String in ["rise", "rise_hot", "jet", "ceiling_spread", "mix", "fade", "fade_open"]:
		grid.call(&"tune", k, float(tuning.get("smoke_" + k)))
	var gun_smoke: Resource = load("res://config/smoke.tres")
	_wind = gun_smoke.get(&"wind") if gun_smoke else Vector3.ZERO
	_start_raster()
	if _can_draw():
		_make_fog()


## The box in world space.
func box() -> AABB:
	return AABB(origin, Vector3(dims) * cell)


func covers(at: Vector3) -> bool:
	return box().has_point(at)


func cell_of(at: Vector3) -> Vector3i:
	var c := ((at - origin) / cell).floor()
	return Vector3i(int(c.x), int(c.y), int(c.z))


func index_of(c: Vector3i) -> int:
	if c.x < 0 or c.y < 0 or c.z < 0 or c.x >= dims.x or c.y >= dims.y or c.z >= dims.z:
		return -1
	return c.x + dims.x * (c.y + dims.y * c.z)


## How smoky it is at a point: 0 clear, 1 a full cell.
func density_at(at: Vector3) -> float:
	var c := cell_of(at)
	return float(grid.call(&"density", c.x, c.y, c.z)) if index_of(c) >= 0 else 0.0


func total() -> float:
	return float(grid.call(&"total"))


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"fire", t)


func _physics_step(delta: float) -> void:
	_raster_step()
	if not _ready_cells:
		return
	# A step at a time on a worker thread (SmokeGrid.step_async): handed off when the last is done,
	# so a frame never waits on one; a long frame's backlog is dropped rather than run all at once.
	_accum = minf(_accum + delta, STEP * 3.0)
	if _accum >= STEP and not grid.call(&"is_busy"):
		var burning := _emit()
		if grid.call(&"step_async", STEP, _wind.x, _wind.z):
			_accum -= STEP
			_quiet = 0.0 if burning > 0 else _quiet + STEP
	var done: int = grid.call(&"steps")
	if _fog and done != _drawn_step:
		_drawn_step = done
		_upload()
	# Out, and the smoke gone: done.
	if _quiet > 2.0 and total() < 0.5:
		queue_free()


## Each burning member's smoke into the open cells beside it; how many were burning.
func _emit() -> int:
	var n := 0
	for m: StructureMember in _vents:
		if not is_instance_valid(m) or not m.burning or m.consumed:
			continue
		var vents: PackedInt32Array = _vents[m]
		if vents.is_empty():
			continue
		n += 1
		var each := tuning.smoke_per_m2 * clampf(FireSystem._broadest_face(m), 0.05, 2.0) / vents.size()
		for v in vents:
			grid.call(&"emit", v, each, tuning.smoke_heat)
	for sp: Dictionary in fire.spills:
		var c := index_of(cell_of((sp.position as Vector3) + Vector3.UP * 0.3))
		if c >= 0:
			grid.call(&"emit", c, tuning.smoke_per_m2 * 0.5, tuning.smoke_heat)
			n += 1
	return n


# --- The members in the cells ---------------------------------------------------------------------

func _start_raster() -> void:
	_raster = fire._query(box())
	_raster_at = 0
	_solid = PackedByteArray()
	_solid.resize(dims.x * dims.y * dims.z)
	_raster_wait = RASTER_EVERY


func _raster_step() -> void:
	if _raster_at >= _raster.size():
		_raster_wait -= get_physics_process_delta_time()
		if _raster_wait <= 0.0:
			_start_raster()
		return
	var to := mini(_raster_at + RASTER_A_FRAME, _raster.size())
	for i in range(_raster_at, to):
		var m := _raster[i]
		if is_instance_valid(m) and _blocks(m):
			_draw_member(m)
	_raster_at = to
	if _raster_at >= _raster.size():
		grid.call(&"set_solid", _solid)
		_find_vents()
		_ready_cells = true


## What smoke can't pass: a member standing in its place (burnt away, broken and falling, or a
## shattered pane, it can).
static func _blocks(m: StructureMember) -> bool:
	return not m.consumed and not m.broken


## Every cell whose middle is inside the member (a thin board fills the one layer of cells its
## plane passes through).
func _draw_member(m: StructureMember) -> void:
	var xf := m.global_transform
	var inv := xf.affine_inverse()
	var half := m.size * 0.5
	var pad := cell * 0.5
	var reach := Vector3(maxf(half.x, pad), maxf(half.y, pad), maxf(half.z, pad))
	var wb := xf * AABB(-half, m.size)
	var lo := cell_of(wb.position)
	var hi := cell_of(wb.end)
	for z in range(maxi(lo.z, 0), mini(hi.z, dims.z - 1) + 1):
		for y in range(maxi(lo.y, 0), mini(hi.y, dims.y - 1) + 1):
			for x in range(maxi(lo.x, 0), mini(hi.x, dims.x - 1) + 1):
				var p := inv * (origin + (Vector3(x, y, z) + Vector3(0.5, 0.5, 0.5)) * cell)
				if p.x >= -reach.x and p.x < reach.x and p.y >= -reach.y and p.y < reach.y and p.z >= -reach.z and p.z < reach.z:
					_solid[x + dims.x * (y + dims.y * z)] = 1


## For each member that could burn, the open cells round its middle (its smoke comes out of both
## faces of a wall): those a cell away, or if none (it's in among others), two.
func _find_vents() -> void:
	_vents.clear()
	for m in _raster:
		if not is_instance_valid(m) or m.consumed or not fire.flammable(m):
			continue
		var c := cell_of(m.global_position)
		if index_of(c) < 0:
			continue
		var out := PackedInt32Array()
		for r in [1, 2]:
			for dz in range(-r, r + 1):
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						var j := index_of(c + Vector3i(dx, dy, dz))
						if j >= 0 and _solid[j] == 0 and not out.has(j):
							out.append(j)
			if not out.is_empty():
				break
		_vents[m] = out


# --- Drawing it -------------------------------------------------------------------------------------

func _can_draw() -> bool:
	return DisplayServer.get_name() != "headless" and GunSmoke.supports_fog_volumes()


func _make_fog() -> void:
	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	_fog.size = Vector3(dims) * cell
	var mat := FogMaterial.new()
	mat.density = tuning.smoke_draw_density
	mat.albedo = tuning.smoke_colour
	mat.edge_fade = 0.5
	_tex = ImageTexture3D.new()
	_tex.create(Image.FORMAT_R8, dims.x, dims.y, dims.z, false, _slices())
	mat.density_texture = _tex
	_fog.material = mat
	add_child(_fog)
	_fog.global_position = origin + _fog.size * 0.5


func _slices() -> Array[Image]:
	var bytes: PackedByteArray = grid.call(&"latest_bytes")
	var per := dims.x * dims.y
	var out: Array[Image] = []
	for z in dims.z:
		out.append(Image.create_from_data(dims.x, dims.y, false, Image.FORMAT_R8, bytes.slice(z * per, (z + 1) * per)))
	return out


func _upload() -> void:
	_tex.update(_slices())

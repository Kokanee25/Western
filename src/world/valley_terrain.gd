class_name ValleyTerrain
extends RefCounted
## The valley's ground as baked (docs/briefs/valley-plan.md §12, G2): `tools/valley/valley_plan.py
## --bake` samples its terrain function (the thin-plate spline through valley.json's
## terrain.control, the town's plane and the places' pads, the rail's formation, the creek and the
## arroyo carved by their bed profiles) every 2 m into config/valley_ground/heights.r16.gz (gzip of
## little-endian uint16, rows north to south) and heights.json (the grid, height = offset + scale *
## value). The bake is the source: nothing here re-does the spline. Pure data, no nodes; read once
## (`main()`).
##
## Between the points the ground is the height field Jolt makes of them (ValleyGround's chunks):
## each quad split from its (i + 1, j) corner to its (i, j + 1) one (Jolt's split; measured
## 2026-11-08 on 65- and 81-point fields), so `height(x, z)` is where a ray straight down meets the
## ground's collision.

const DIR := "res://config/valley_ground/"

var width := 0
var depth := 0
var spacing := 2.0
var x0 := 0.0
var z0 := 0.0
var offset := 0.0
var scale := 0.0
## width x depth heights (m), row by row along x, rows along z.
var heights := PackedFloat32Array()
var meta := {}

static var _main: ValleyTerrain


## The bake (read the first time).
static func main() -> ValleyTerrain:
	if _main == null:
		_main = ValleyTerrain.load_from(DIR)
	return _main


static func load_from(dir: String) -> ValleyTerrain:
	var t := ValleyTerrain.new()
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("heights.json")))
	if not m is Dictionary:
		push_error("ValleyTerrain: no bake at %s (python3 tools/valley/valley_plan.py --bake)" % dir)
		return t
	t.meta = m
	t.width = int(m.width)
	t.depth = int(m.depth)
	t.spacing = float(m.spacing)
	t.x0 = float(m.x0)
	t.z0 = float(m.z0)
	t.offset = float(m.offset)
	t.scale = float(m.scale)
	var gz := FileAccess.get_file_as_bytes(dir.path_join(String(m.file)))
	var raw := gz.decompress(int(m.bytes), FileAccess.COMPRESSION_GZIP)
	var n := t.width * t.depth
	if raw.size() != n * 2:
		push_error("ValleyTerrain: %s holds %d bytes, not %d" % [m.file, raw.size(), n * 2])
		return t
	t.heights.resize(n)
	var off := t.offset
	var sc := t.scale
	for k in n:
		t.heights[k] = off + sc * raw.decode_u16(k * 2)
	return t


func is_loaded() -> bool:
	return not heights.is_empty()


## The baked area (world xz).
func rect() -> Rect2:
	return Rect2(x0, z0, (width - 1) * spacing, (depth - 1) * spacing)


## The baked height at point (i, j), clamped to the grid.
func sample(i: int, j: int) -> float:
	return heights[clampi(j, 0, depth - 1) * width + clampi(i, 0, width - 1)]


## The ground's height at (x, z) (world), as its height field has it; clamped at the bake's edge.
func height(x: float, z: float) -> float:
	var u := clampf((x - x0) / spacing, 0.0, width - 1.0)
	var v := clampf((z - z0) / spacing, 0.0, depth - 1.0)
	var i := mini(floori(u), width - 2)
	var j := mini(floori(v), depth - 2)
	var fu := u - i
	var fv := v - j
	var k := j * width + i
	var h00 := heights[k]
	var h10 := heights[k + 1]
	var h01 := heights[k + width]
	if fu + fv <= 1.0:
		return h00 + (h10 - h00) * fu + (h01 - h00) * fv
	var h11 := heights[k + width + 1]
	return h11 + (h01 - h11) * (1.0 - fu) + (h10 - h11) * (1.0 - fv)


## The ground's slope (dy/dx, dy/dz) at point (i, j), by central differences `step` points apart
## (the level of detail's own spacing, so a far mesh shades as smooth as it's drawn).
func gradient(i: int, j: int, step := 1) -> Vector2:
	var span := 2.0 * step * spacing
	return Vector2((sample(i + step, j) - sample(i - step, j)) / span, (sample(i, j + step) - sample(i, j - step)) / span)

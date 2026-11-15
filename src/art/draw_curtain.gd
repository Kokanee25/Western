class_name DrawCurtain
extends Node3D
## A stage's draw curtain (#902, saloon B's stage): two halves of heavy cloth on a rod, drawn aside
## to the stage's sides and back across it. `open_curtain()` / `close_curtain()` move them, `to_dict`
## / `from_dict` save and restore where they stand.
##
## Not a cloth simulation: each half is a strip of pleats (a sine across it, a little uneven pleat to
## pleat) whose width is where the half has been drawn to and whose folds deepen as it gathers, the
## cloth's length kept (each half-pleat a slope of the same length: depth from the width). At 3 to 10
## m that reads as a curtain drawn aside, for two small meshes rebuilt only while it moves. A gold
## fringe along the hem. It burns and falls as a fitting: the building's Fittings drops it when what
## it hangs on (the rod, the header) is gone.
##
## In its own space: the opening runs along x from -width/2 to +width/2, the rod at y 0, the cloth
## hanging down to -height, its folds about z 0.

signal finished(open: bool)

## The opening between the stage's posts (m) and the cloth's drop from the rod.
@export var width := 4.8
@export var height := 2.3
## Cloth to opening: 1.6 is a stage curtain's (deep folds closed, packed tight open).
@export var fullness := 1.6
## How far each half passes the middle closed (the overlap), and how wide it packs open.
@export var overlap := 0.12
@export var packed := 0.42
## A pleat's width hanging closed (m).
@export var pleat := 0.2
## Seconds to draw it fully open or shut (a stagehand hand over hand).
@export var travel := 3.0
@export var color := Color(0.36, 0.035, 0.05)
@export var fringe_color := Color(0.62, 0.45, 0.16)
@export var fringe := 0.07
@export var seed := 902

## Where it is (0 shut, 1 open) and where it's going.
var amount := 0.0
var target := 0.0

var _halves: Array[MeshInstance3D] = []
var _pleats := 0
var _jitter: PackedFloat32Array = []
static var _material: StandardMaterial3D


func _ready() -> void:
	_build()
	set_process(false)


func open_curtain() -> void:
	set_open(true)


func close_curtain() -> void:
	set_open(false)


## Draw it to open (true) or shut; `instant` puts it there with no travel (a load, a build).
func set_open(open: bool, instant := false) -> void:
	target = 1.0 if open else 0.0
	if instant:
		amount = target
		_shape()
		set_process(false)
		return
	set_process(not is_equal_approx(amount, target))


func is_open() -> bool:
	return target > 0.5


func moving() -> bool:
	return not is_equal_approx(amount, target)


## What a save needs: where it's drawn to (a curtain half way when saved is put where it was going).
func to_dict() -> Dictionary:
	return {"open": is_open()}


func from_dict(d: Dictionary) -> void:
	set_open(bool(d.get("open", false)), true)


func _process(delta: float) -> void:
	amount = move_toward(amount, target, delta / maxf(travel, 0.01))
	_shape()
	if not moving():
		set_process(false)
		finished.emit(is_open())


func _build() -> void:
	for h in _halves:
		h.free()
	_halves.clear()
	_pleats = maxi(3, roundi((width * 0.5 + overlap) / pleat))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_jitter.resize(_pleats * 2)
	for i in _jitter.size():
		_jitter[i] = rng.randf_range(0.75, 1.25)
	for side in 2:
		var mi := MeshInstance3D.new()
		mi.name = "Left" if side == 0 else "Right"
		mi.material_override = _mat()
		add_child(mi)
		_halves.append(mi)
	_shape()


static func _mat() -> StandardMaterial3D:
	if _material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color.WHITE
		m.roughness = 0.92
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Wool velvet: the light caught on the folds' edges, the hollows deep.
		m.rim_enabled = true
		m.rim = 0.45
		m.rim_tint = 0.65
		_material = m
	return _material


## Each half's width now: from the stage's side, closed past the middle by `overlap`, open packed.
func half_width() -> float:
	var ease_t := amount * amount * (3.0 - 2.0 * amount)
	return lerpf(width * 0.5 + overlap, packed, ease_t)


func _shape() -> void:
	if _halves.size() < 2:
		return
	var w := half_width()
	var cloth := (width * 0.5 + overlap) * fullness  # each half's length of cloth, kept
	# A half-pleat's run across and the slope it takes: depth = sqrt(slope^2 - run^2).
	var run := w / (_pleats * 2.0)
	var slope := cloth / (_pleats * 2.0)
	var depth := sqrt(maxf(slope * slope - run * run, 0.0))
	for side in 2:
		_halves[side].mesh = _strip(side, w, depth)


## One half: columns across the pleats, rows down the drop (the heading, the fringe's top, the hem).
func _strip(side: int, w: float, depth: float) -> ArrayMesh:
	var per := 8
	var cols := _pleats * per + 1
	var sgn := -1.0 if side == 0 else 1.0
	var x_side := sgn * width * 0.5
	var rows: Array = [[0.0, color, 0.6], [-(height - fringe), color, 1.0], [-(height - fringe), fringe_color, 1.0], [-height, fringe_color, 1.1]]
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols_c := PackedColorArray()
	var idx := PackedInt32Array()
	for r in rows.size():
		var y: float = rows[r][0]
		var c: Color = rows[r][1]
		var flare: float = rows[r][2]  # the folds a little deeper at the hem than at the heading
		for i in cols:
			var u := float(i) / (cols - 1)
			var p := u * _pleats * TAU
			var k := mini(int(u * _pleats), _pleats - 1)
			var a := depth * 0.5 * _jitter[k + side * _pleats] * flare
			var x := x_side - sgn * u * w
			var z := a * sin(p)
			# The slope of the folds across: dz/dx (x runs toward the middle), the normal across it.
			var dzdx := a * cos(p) * _pleats * TAU / maxf(w, 0.001) * -sgn
			var n := Vector3(-dzdx, 0.0, 1.0).normalized()
			# Shade the hollows (they see less of the room): darker toward the back of each fold.
			var hollow := 0.78 + 0.22 * (0.5 + 0.5 * sin(p))
			verts.append(Vector3(x, y, z))
			norms.append(n)
			cols_c.append(Color(c.r * hollow, c.g * hollow, c.b * hollow))
	for r in [0, 2]:
		for i in cols - 1:
			var a0: int = r * cols + i
			var b0: int = (r + 1) * cols + i
			# Front faces toward +z, clockwise as Godot's are (the left half's columns run +x, the right's -x).
			if side == 0:
				idx.append_array([a0, a0 + 1, b0, a0 + 1, b0 + 1, b0])
			else:
				idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols_c
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

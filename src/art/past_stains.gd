class_name PastStains
extends Node3D
## A building's old blood by its history (#1187, the undertaker's cellar): the spec's `past` events'
## `blood` laid once the building stands in a world, through the game's own systems, so it is what any
## blood is: dried splats (Blood: decals, scrubbed by a mop or a rag, saved) and stains soaked into the
## flags and treads (FloorMarks: cells, `take` with a stain share lifts them, saved). Nothing painted:
## every mark is placed by the spec's props (`by` a dressing id, `off` in the building's x and z) or
## points, and drawn by a rng seeded from the building and the event, the same every build.
##
## The forms (experiments/building_lab/FORMAT.md `past`):
## - `soak`: `ml` soaked into the surface round `at` within `r`, or along `points` `width` wide (ml a
##   metre); the flags' or treads' height found by a ray down.
## - `drips`: dried splats every `every` [min, max] m along `points` (`ml` [min, max] each), each
##   drawn long the way the dead were carried (`carry`: "path", or an [x, z] heading, or none).
## - `splash`: `n` splats round `at` between `r` [min, max] m, thrown outward low.
## - `smear`: `n` splats run down a wall: rays from along `points` (inside the room) `toward` the wall,
##   at heights `y` [min, max] over the level.
## Lamps the spec calls `smoky` get soot up the boards over them (a dark decal: the lamp's own smoke).
## The floor stains are laid once a world (FloorMarks' meta `past`): a rebuild doesn't lay them twice.

## How long ago it all dried: years of it (game hours), so Blood draws it fully DRIED.
const OLD_HOURS := 24.0 * 365.0
## How far a point's ray looks over and under its height (m).
const REACH := 0.6

var spec: Dictionary
var building: Node3D
## What it laid: {splats, cells, soot, unplaced}.
var laid := {"splats": 0, "cells": 0, "soot": 0, "unplaced": []}
var done := false


func _ready() -> void:
	# The building's members are bodies in the world's space only once a physics frame has gone by.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	lay()


func lay() -> void:
	if done:
		return
	done = true
	var fm := FloorMarks.find(get_tree())
	if fm == null and get_parent() and building.get_parent():
		fm = FloorMarks.ensure(building.get_parent())
	var once: Dictionary = fm.get_meta(&"past", {}) if fm else {}
	for ev: Dictionary in spec.get("past", []):
		var list: Array = ev.get("blood", [])
		if list.is_empty():
			continue
		var key := "%s/%s" % [String(building.get(&"structure_id")), String(ev.id)]
		var floor_too := fm != null and not once.has(key)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key) ^ int(ev.get("seed", 0))
		for i in list.size():
			var e: Dictionary = list[i]
			match String(e.what):
				"soak":
					if floor_too:
						_soak(fm, e)
				"drips":
					_drips(e, rng)
				"splash":
					_splash(e, rng)
				"smear":
					_smear(e, rng)
		if floor_too:
			once[key] = true
	if fm:
		fm.set_meta(&"past", once)
	_soot()


# --- where -------------------------------------------------------------------------------------------

## A spec point in the building's space (x, z; y the level's top or its own third number).
func _point(p: Variant, level: String) -> Vector3:
	var y := _level_y(level)
	if p is Dictionary:
		var n := _dressed(String(p.by))
		if n == null:
			(laid.unplaced as Array).append("no prop %s" % p.by)
			return Vector3(NAN, NAN, NAN)
		var at := building.to_local(n.global_position)
		var off: Array = p.get("off", [0, 0])
		return Vector3(at.x + float(off[0]), y, at.z + float(off[1]))
	var a: Array = p
	return Vector3(float(a[0]), float(a[2]) if a.size() > 2 else y, float(a[1]))


func _level_y(level: String) -> float:
	var lv: Dictionary = spec.levels.get(level, spec.levels.ground)
	return float(lv.get("top", lv.get("floor", 0.0)))


func _dressed(id: String) -> Node3D:
	var d: Dictionary = building.get(&"dressed")
	for b: String in d:
		if (d[b] as Dictionary).has(id):
			return d[b][id] as Node3D
	return null


## The surface under a building-space point: the world's point on it, or null (a prop's top, nothing
## there, or more than `over` above the point's height: a drip doesn't lie on the pail's rim).
func _ground(p: Vector3, over := 0.12) -> Variant:
	if is_nan(p.x):
		return null
	var g := building.to_global(p)
	var space := World.space(self)
	for off: Vector3 in [Vector3.ZERO, Vector3(0.007, 0, 0.007), Vector3(-0.007, 0, 0.007)]:
		var q := PhysicsRayQueryParameters3D.create(g + off + Vector3.UP * over, g + off - Vector3.UP * REACH, Layers.WORLD)
		var hit := space.intersect_ray(q)
		# Through what isn't a member (a stair's walking ramp) to the boards and flags under it.
		var tries := 0
		while not hit.is_empty() and not hit.collider is StructureMember and tries < 3:
			q.exclude = q.exclude + [hit.rid]
			hit = space.intersect_ray(q)
			tries += 1
		if hit.is_empty() or not hit.collider is StructureMember or (hit.normal as Vector3).y < 0.8:
			continue
		if _on_prop(hit.collider as StructureMember):
			return null
		return hit.position
	return null


func _on_prop(m: StructureMember) -> bool:
	var n: Node = m.get_parent()
	while n != null and n != building:
		if n is KitProp:
			return true
		n = n.get_parent()
	return false


## Points along a polyline (building space) every `step` m, from a seeded draw each.
func _along(pts: Array[Vector3], every: Array, rng: RandomNumberGenerator) -> Array:
	var out := []  # [point, heading]
	var s := rng.randf_range(0.0, float(every[0]))
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var len := a.distance_to(b)
		var t := s
		while t < len:
			out.append([a.lerp(b, t / len), (b - a).normalized()])
			t += rng.randf_range(float(every[0]), float(every[1]))
		s = t - len
	return out


func _points(e: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p: Variant in e.get("points", []):
		var v := _point(p, String(e.get("level", "ground")))
		if not is_nan(v.x):
			out.append(v)
	return out


# --- the marks -----------------------------------------------------------------------------------------

func _soak(fm: FloorMarks, e: Dictionary) -> void:
	var level := String(e.get("level", "ground"))
	if e.has("at"):
		var hit: Variant = _ground(_point(e.at, level))
		if hit == null:
			(laid.unplaced as Array).append("soak at %s" % [e.at])
			return
		laid.cells += fm.soak_in(hit, &"blood", float(e.ml), float(e.r))
		return
	# Along a run: discs every half its width, ml a metre shared among them.
	var pts := _points(e)
	var w := float(e.get("width", 0.2))
	for i in pts.size() - 1:
		var len := pts[i].distance_to(pts[i + 1])
		var n := maxi(1, ceili(len / (w * 0.5)))
		for k in n + 1:
			var hit: Variant = _ground(pts[i].lerp(pts[i + 1], float(k) / n))
			if hit != null:
				laid.cells += fm.soak_in(hit, &"blood", float(e.ml) * len / (n + 1), w * 0.5)


func _drips(e: Dictionary, rng: RandomNumberGenerator) -> void:
	var over := float(e.get("over", 0.12))
	var carry: Variant = e.get("carry", null)
	for ph: Array in _along(_points(e), e.every, rng):
		var ml := rng.randf_range(float(e.ml[0]), float(e.ml[1]))
		var hit: Variant = _ground(ph[0], over)
		if hit == null:
			continue
		var v := Vector3(0, -3.0, 0)
		if carry is String and carry == "path":
			v += building.global_basis * (ph[1] as Vector3) * 1.1
		elif carry is Array:
			v += building.global_basis * Vector3(float(carry[0]), 0, float(carry[1])) * 1.1
		_splat(hit, Vector3.UP, ml, v)


func _splash(e: Dictionary, rng: RandomNumberGenerator) -> void:
	var c := _point(e.at, String(e.get("level", "ground")))
	for k in int(e.n):
		var a := rng.randf() * TAU
		var d := rng.randf_range(float(e.r[0]), float(e.r[1]))
		var out := Vector3(cos(a), 0, sin(a))
		var hit: Variant = _ground(c + out * d)
		if hit == null:
			continue
		_splat(hit, Vector3.UP, rng.randf_range(float(e.ml[0]), float(e.ml[1])), building.global_basis * out * 2.5 + Vector3(0, -1.5, 0))


func _smear(e: Dictionary, rng: RandomNumberGenerator) -> void:
	var pts := _points(e)
	if pts.size() < 2:
		return
	var to := building.global_basis * Vector3(float(e.toward[0]), 0, float(e.toward[1])).normalized()
	var space := World.space(self)
	var base := _level_y(String(e.get("level", "ground")))
	for k in int(e.n):
		var p := pts[0].lerp(pts[1], rng.randf())
		p.y = base + rng.randf_range(float(e.y[0]), float(e.y[1]))
		var g := building.to_global(p)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(g, g + to * 0.8, Layers.WORLD))
		if hit.is_empty() or not hit.collider is StructureMember or _on_prop(hit.collider as StructureMember):
			(laid.unplaced as Array).append("smear at %s" % [p])
			continue
		var n := hit.normal as Vector3
		# Run down the boards (most), or wiped across them.
		var side := n.cross(Vector3.UP).normalized() * rng.randf_range(-1.0, 1.0)
		var v := Vector3(0, -3.0, 0) - n * 0.6 if rng.randf() < 0.7 else side * 3.0 - n * 0.6
		_splat(hit.position, n, rng.randf_range(float(e.ml[0]), float(e.ml[1])), v)


## One dried splat: Blood's own, aged as Blood.dry ages it, kept from the cap's cull (`past`).
func _splat(at: Vector3, normal: Vector3, ml: float, velocity: Vector3) -> void:
	var d := Blood.splat(self, at, normal, ml, velocity)
	if d == null:
		return
	d.set_meta(&"past", true)
	if not d.has_meta(&"fresh"):
		d.set_meta(&"fresh", d.modulate)
	var age := float(d.get_meta(&"age_h", 0.0))
	if age < OLD_HOURS:
		d.set_meta(&"age_h", OLD_HOURS)
		var fresh: Color = d.get_meta(&"fresh")
		var k := 1.0 - exp(-OLD_HOURS / Blood.DRY_HOURS)
		var c := fresh * Color(lerpf(1.0, Blood.DRIED.r, k), lerpf(1.0, Blood.DRIED.g, k), lerpf(1.0, Blood.DRIED.b, k), 1.0)
		c.a = fresh.a
		d.modulate = c
	laid.splats += 1


## Soot up the boards over each smoky lamp: a soft dark plume on the wall from the chimney to the joists.
func _soot() -> void:
	var lamps: Array = building.get(&"lamps")
	for lamp: OilLamp in lamps:
		var s := float(lamp.get_meta(&"smoky", 0.0))
		if s <= 0.0:
			continue
		var prop := lamp.get_parent() as Node3D
		var into := prop.global_basis.z.normalized()  # out of the wall, into the room
		var top := lamp.global_position + Vector3(0, 0.25, 0)
		var d := Decal.new()
		d.name = "Soot"
		d.texture_albedo = _soot_texture()
		d.modulate = Color(0.08, 0.07, 0.06, clampf(s, 0.0, 1.0))
		d.cull_mask = Layers.WORLD
		d.upper_fade = 0.0
		d.lower_fade = 0.0
		add_child(d)
		# The decal projects along its -Y: its Y the wall's normal, its +Z (the texture's foot) down to the chimney.
		var plume := 1.1
		d.global_basis = Basis(into.cross(Vector3.DOWN).normalized(), into, Vector3.DOWN)
		d.global_position = top + Vector3(0, plume * 0.5, 0) - into * 0.1
		d.size = Vector3(0.7, 0.3, plume)
		laid.soot += 1


static var _soot_tex: Texture2D


## A plume: dark over the chimney (the texture's foot), spreading and fading as it rises.
static func _soot_texture() -> Texture2D:
	if _soot_tex:
		return _soot_tex
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		var up := 1.0 - y / 31.0  # 0 at the chimney (the texture's foot), 1 at the top
		var half := lerpf(0.18, 0.5, up)
		for x in 16:
			var u := absf((x + 0.5) / 16.0 - 0.5)
			var a := clampf(1.0 - u / half, 0.0, 1.0)
			a = a * a * lerpf(0.9, 0.35, up) * smoothstep(0.0, 0.12, up + 0.02)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_soot_tex = ImageTexture.create_from_image(img)
	return _soot_tex

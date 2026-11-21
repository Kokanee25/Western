class_name Corral
extends Structure
## A post-and-rail corral: posts round a rectangle `size` (x along +X from the origin, z along
## +Z), three rails between each pair, and a gap for the gate in the side along z = 0.

@export var size := Vector2(12.0, 10.0)
@export var post_spacing := 2.4
@export var height := 1.6
## Where along the z = 0 side the gate's gap starts, and how wide.
@export var gate_at := 4.8
@export var gate_width := 2.4
## A rail's section [height, thickness] (a sawn rail's 0.1 x 0.05; a peeled pole's about square, #1126).
@export var rail_section := Vector2(0.1, 0.05)
@export var rail_wood := &"weathered_pine"
## Rails left broken (#1126, Harlan's: a repair job), by "<side>_<bay>_<rail>": snapped near one end,
## the long piece hanging from the far post with its end on the ground, the stub on its post. Each
## piece's meta `repair` is `broken_rail`.
@export var broken: Array[String] = []

const RAILS := 3


func build() -> void:
	var sides := [
		[Vector3.ZERO, Vector3(size.x, 0.0, 0.0), true],
		[Vector3(size.x, 0.0, 0.0), Vector3(size.x, 0.0, size.y), false],
		[Vector3(size.x, 0.0, size.y), Vector3(0.0, 0.0, size.y), false],
		[Vector3(0.0, 0.0, size.y), Vector3.ZERO, false],
	]
	var posts := {}
	for s in sides.size():
		var a: Vector3 = sides[s][0]
		var b: Vector3 = sides[s][1]
		var n := maxi(int(round(a.distance_to(b) / post_spacing)), 1)
		for i in n:
			var p0 := a.lerp(b, float(i) / n)
			var p1 := a.lerp(b, float(i + 1) / n)
			for p: Vector3 in [p0, p1]:
				var key := "%d_%d" % [int(round(p.x * 10.0)), int(round(p.z * 10.0))]
				if not posts.has(key):
					posts[key] = true
					add_member("post/%s" % key, &"post", &"framing", Vector3(0.14, height, 0.14), Vector3(p.x, height * 0.5, p.z))
			# The gate's gap: no rails across it.
			if sides[s][2]:
				var mid := (p0.x + p1.x) * 0.5
				if mid > gate_at and mid < gate_at + gate_width:
					continue
			var along := p1 - p0
			var basis := Basis(Vector3.UP, atan2(-along.z, along.x))
			for r in RAILS:
				var y := height * (0.3 + 0.32 * r)
				var key := "%d_%d_%d" % [s, i, r]
				var size := Vector3(along.length() + 0.12, rail_section.x, rail_section.y)
				if broken.has(key):
					_broken_rail(key, p0, p1, y, size)
					continue
				add_member("rail/" + key, &"beam", rail_wood, size, (p0 + p1) * 0.5 + Vector3(0.0, y, 0.0), basis)


## A rail snapped a third of the way along: the stub on the first post, the long piece hanging from the
## second with its broken end down on the ground.
func _broken_rail(key: String, p0: Vector3, p1: Vector3, y: float, size: Vector3) -> void:
	var along := (p1 - p0).normalized()
	var length := p0.distance_to(p1) + 0.12
	var stub := length * 0.3
	var a0 := p0 - along * 0.06
	var flat := Basis(Vector3.UP, atan2(-along.z, along.x))
	var m := add_member("rail/%s/stub" % key, &"beam", rail_wood, Vector3(stub, size.y, size.z), a0 + along * (stub * 0.5) + Vector3.UP * y, flat)
	m.set_meta(&"repair", &"broken_rail")
	# The long piece: from its post's top down to the ground, turned about the rail's level cross axis.
	var piece := length - stub - 0.03
	var drop := minf(y - size.y * 0.5, piece * 0.9)
	var ang := asin(drop / piece)
	var top := p1 + along * 0.06 + Vector3.UP * y
	var dir := (-along * cos(ang) + Vector3.DOWN * sin(ang)).normalized()
	var xa := -dir
	var ya := Vector3.UP.slide(xa).normalized()
	var h := add_member("rail/%s/hanging" % key, &"beam", rail_wood, Vector3(piece, size.y, size.z), top + dir * (piece * 0.5), Basis(xa, ya, xa.cross(ya)))
	h.set_meta(&"repair", &"broken_rail")

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
				add_member("rail/%d_%d_%d" % [s, i, r], &"beam", &"weathered_pine", Vector3(along.length() + 0.12, 0.1, 0.05),
						(p0 + p1) * 0.5 + Vector3(0.0, y, 0.0), basis)

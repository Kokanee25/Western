extends Structure
## The falls lab's roofs and floors (issue #759): a bay of the game's own members for a man to land
## on, sized as the building lab's saloon has them (experiments/building_lab/saloon.json,
## spec_building.gd), so they break as the game's timber does (BodyImpacts' from-above case).
## `kind`:
## - "roof": roof boards (1x8, 0.195 x 0.025 weathered pine) across rafters (0.05 x 0.15) 0.61 m
##   apart, the rafters on two beams on four posts, nearly flat;
## - "porch": PorchRoof itself (the street's awnings: rafters 0.75 apart, a shallow slope);
## - "floor": floor boards (0.146 x 0.025 floor wood) across joists (0.05 x 0.25) 0.406 apart (the
##   balcony's and the gallery's).
## Its top is at `top` (m, where a man lands); 3 m wide along x, 3 deep along z, centred on its origin.

var kind := "roof"
var top := 3.0
const W := 3.0
const D := 3.0


func build() -> void:
	match kind:
		"porch":
			# Along x from -W/2, the street side at -z: centred, its boards' middle about `top`.
			PorchRoof.build(self, "porch", W, 2.2, top - 0.45, {"x0": -W * 0.5})
		"floor":
			_bay(0.406, Vector3(0.05, 0.25, D + 0.2), &"joist", 0.146, &"floor_board", &"floor")
		_:
			_bay(0.61, Vector3(0.05, 0.15, D + 0.2), &"rafter", 0.195, &"roof_board", &"weathered_pine")


func _bay(every: float, joist: Vector3, joist_kind: StringName, board_w: float, board_kind: StringName, wood: StringName) -> void:
	var t := 0.025
	var j_top := top - t
	var beam_top := j_top - joist.y
	var post_h := beam_top - 0.2
	for i in 4:
		var x := (-W * 0.5 + 0.07) if i % 2 == 0 else (W * 0.5 - 0.07)
		var z := (-D * 0.5) if i < 2 else (D * 0.5)
		add_member("post%d" % i, &"post", &"framing", Vector3(0.14, post_h, 0.14), Vector3(x, post_h * 0.5, z))
	for i in 2:
		var z := -D * 0.5 if i == 0 else D * 0.5
		add_member("beam%d" % i, &"beam", &"framing", Vector3(W + 0.2, 0.2, 0.16), Vector3(0.0, beam_top - 0.1, z))
	var n := 0
	var x := -W * 0.5 + 0.1
	while x <= W * 0.5 - 0.05:
		add_member("%s%02d" % [joist_kind, n], joist_kind, &"framing", joist, Vector3(x, beam_top + joist.y * 0.5, 0.0))
		x += every
		n += 1
	n = 0
	var z := -D * 0.5
	while z < D * 0.5 - 0.02:
		var bw := minf(board_w, D * 0.5 - z)
		add_member("%s%02d" % [board_kind, n], board_kind, wood, Vector3(W + 0.2, t, bw), Vector3(0.0, top - t * 0.5, z + bw * 0.5))
		z += board_w + 0.005
		n += 1
